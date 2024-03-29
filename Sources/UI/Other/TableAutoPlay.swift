//
//  TableAutoPlay.swift
//  Ext
//
//  Created by guojian on 2022/1/14.
//

import Foundation

/// 可播放协议
public protocol Playable: AnyObject {
    /// 是否正在播放
    var isPlaying: Bool { get }
    /// 播放
    func play() -> Void
    /// 暂停
    func pause() -> Void
}

/// 可自动播放协议
public protocol AutoPlayable: Playable {
    /// 可自动播放播放视图: 用于计算可视范围的最佳播放视图
    var playableView: UIView { get }
}

public enum AutoPlayAction {
    case play(_ indexPath: IndexPath)
}

public protocol AutoPlayDelegate: AnyObject {
    func autoPlay(_ autoPlay: TableAutoPlay, didAction action: AutoPlayAction)
}

public class TableAutoPlay: ExtInnerLogable {
    public var logLevel: Ext.LogLevel = .off
    
    public weak var delegate: AutoPlayDelegate?
    
    private weak var tableView: UITableView?
    
    public init(_ tableView: UITableView) {
        self.tableView = tableView
    }
    
    /// 是否停止自动播放处理
    public var isStopping: Bool = false {
        didSet {
            if !isStopping, !isDragScrolling {
                ext.log("开启自动播放，并且没有拖动滚动")
                playBest()
            }
        }
    }
    
    /// 是否拖拽时自动播放处理
    public var draggingEnabled: Bool = false
    
    /// 当前最佳播放索引
    public private(set) var playableIndexPath: IndexPath? {
        didSet {
            ext.log("play indexPath: \(oldValue?.description ?? "") -> \(playableIndexPath?.description ?? "")")
            
        }
    }
    
    /**
     是否正在进行拖拽滚动
     一般滚动情况:
        无减速滚动
            - scrollViewWillBeginDragging
     @objc  - scrollViewWillEndDragging
            - scrollViewDidEndDragging(willDecelerate: false)
        有减速滚动
            - scrollViewWillBeginDragging
            - scrollViewWillEndDragging
            - scrollViewDidEndDragging(willDecelerate: true)
            - scrollViewWillBeginDecelerating
            - scrollViewDidEndDecelerating
     这个滚动状态用于解决:
        手指快速拖动时，可能会出现，无减速滚动和有减速滚动开始结束不是成对出现
        就是有减速滚动还未结束，又开始了一次无减速滚动
     */
    private var isDragScrolling: Bool = false
    /// 拖拽时的最佳可视索引
    private var dragIndexPath: IndexPath?
}

// MARK: - Play

public extension TableAutoPlay {
    
    /// 开始播放
    @objc
    func play() {
        ext.log("")
        playBest()
    }
    /// 暂停播放
    func pause() {
        ext.log("")
        //guard let _ = viewIfLoaded else { return }
        
        guard let tableView = self.tableView else { return }
        for cell in tableView.visibleCells {
            (cell as? AutoPlayable)?.pause()
        }
    }
}

private extension TableAutoPlay {
    
    /// 播放最佳
    func playBest() {
        ext.log("current playable indexPath: \(playableIndexPath?.description ?? "")")
        guard let cell = bestVisibleCell(), let indexPath = tableView?.indexPath(for: cell) else { return }
        play(at: indexPath)
    }
    
    /// 播放指定索引
    private func play(at indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        ext.log("play \(indexPath)")
        guard playableIndexPath != indexPath else {
            guard let playable = playableFor(indexPath), !playable.isPlaying else { return }
            ext.log("当前播放索引 \(playableIndexPath?.description ?? "") 未开始播放，play")
            playable.play()
            return
        }
        ext.log("play indexPath changed.")
        pause(at: playableIndexPath)
        playableIndexPath = indexPath
        delegate?.autoPlay(self, didAction: .play(indexPath))
        playableFor(indexPath)?.play()
    }
    
    /// 暂停指定索引
    func pause(at indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        ext.log("pause \(indexPath)")
        playableFor(indexPath)?.pause()
    }
    
    /// 根据索引获取获取可播放内容
    func playableFor(_ indexPath: IndexPath?) -> AutoPlayable? {
        guard let indexPath = indexPath else { return nil }
        return tableView?.cellForRow(at: indexPath) as? AutoPlayable
    }
    
}

// MARK: - Scroll

public extension TableAutoPlay {
    
    func handle(_ status: ScrollViewStatus) {
        switch status {
        case .didScroll(let scrollView):
            guard scrollView.isDragging, scrollView.isTracking else { return }
            ext.log("手指正在拖拽...")
            scrollTracking()
        case .willBeginDragging:
            ext.log("开始拖拽")
            dragIndexPath = playableIndexPath
            
            isDragScrolling = true
        case .willEndDragging(_, let velocity, let targetContentOffset):
            ext.log("将要结束拖拽 target offset: \(targetContentOffset.pointee) | velocity \(velocity)")
        case .didEndDragging(_, let decelerate):
            guard !decelerate else { return }
            ext.log("拖拽无减速，直接静止")
            scrollToEnd()
        case .willBeginDecelerating:
            ext.log("停止拖拽，开始减速")
        case .didEndDecelerating:
            ext.log("拖拽之后减速停止")
            scrollToEnd()
        }
    }
    
}
private extension TableAutoPlay {
    /// 正在手指拖拽
    @objc
    func scrollTracking() {
        guard !isStopping, draggingEnabled else { return }
        ext.log("处理手指拖动...")
        playBest()
    }
    /// 滚动结束
    @objc
    func scrollToEnd() {
        ext.log("isDragScrolling: \(isDragScrolling)")
        guard isDragScrolling else { return }
        isDragScrolling = false
        guard !isStopping else { return }
        ext.log("处理滚动结束...")
        playBest()
    }
    /// 滚动到顶部
    @objc
    func scrollToTop() {}
}

// MARK: - Visiable

private extension TableAutoPlay {
    @objc
    var visibleMinY: CGFloat { 0 }
    @objc
    var visibleMaxY: CGFloat { tableView?.frame.height ?? 0 }
}
private extension TableAutoPlay {
    /// 计算最佳可视 Cell
    private func bestVisibleCell() -> UITableViewCell? {
        guard let tableView = self.tableView, tableView.visibleCells.count > 0 else { return nil }
        var bestCell: AutoPlayable?
        for i in 0..<tableView.visibleCells.count {
            let cell = tableView.visibleCells[i]
            guard let visibleCell = cell as? AutoPlayable,
                  let delta = calcVisible(visibleCell, log: "visibleCell \(i) - "), delta > 0 else { continue }
            guard let currentBestCell = bestCell else {
                bestCell = visibleCell
                continue
            }
            guard let bestDelta = calcVisible(currentBestCell, log: "bestCell - "), delta > bestDelta else { continue }
            bestCell = visibleCell
        }
        return bestCell as? UITableViewCell
    }
    
    /// 计算可视范围
    private func calcVisible(_ visible: AutoPlayable?, log: String = "") -> CGFloat? {
        guard let visible = visible, let superView = tableView?.superview else { return nil }
        //ext.log("superView: \(superView)")
        guard let point = visible.playableView.superview?.convert(visible.playableView.frame.origin, to: superView) else { return nil }
        let minY = max(visibleMinY, min(visibleMaxY, point.y))
        let maxY = min(visibleMaxY, max(visibleMinY, point.y + visible.playableView.frame.height))
        let delta = maxY - minY
        //ext.log("\(log) delta: \(delta) | visible: \(minY) ~ \(maxY) in range: [\(visibleMinY) ~ \(visibleMaxY)] | height: \(visible.visibleView.frame.height) | \(point)")
        return delta
    }
}
