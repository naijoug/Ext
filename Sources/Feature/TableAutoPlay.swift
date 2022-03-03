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

public class TableAutoPlay {
    
    public weak var delegate: AutoPlayDelegate?
    
    private weak var tableView: UITableView?
    
    public init(_ tableView: UITableView) {
        self.tableView = tableView
    }
    
    public var logEnabled: Bool = false
    
    /// 是否停止自动播放处理
    public var isStopping: Bool = false {
        didSet {
            if !isStopping, !isDragScrolling {
                Ext.debug("开启自动播放，并且没有拖动滚动", logEnabled: logEnabled)
                playBest()
            }
        }
    }
    
    /// 是否拖拽时自动播放处理
    public var draggingEnabled: Bool = false
    
    /// 当前最佳播放索引
    public private(set) var playableIndexPath: IndexPath? {
        didSet {
            Ext.debug("play indexPath: \(oldValue?.description ?? "") -> \(playableIndexPath?.description ?? "")", logEnabled: logEnabled)
            
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
        Ext.debug("", logEnabled: logEnabled)
        playBest()
    }
    /// 暂停播放
    func pause() {
        Ext.debug("", logEnabled: logEnabled)
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
        Ext.debug("current playable indexPath: \(playableIndexPath?.description ?? "")", logEnabled: logEnabled)
        guard let cell = bestVisibleCell(), let indexPath = tableView?.indexPath(for: cell) else { return }
        play(at: indexPath)
    }
    
    /// 播放指定索引
    private func play(at indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        Ext.debug("play \(indexPath)", logEnabled: logEnabled)
        guard playableIndexPath != indexPath else {
            guard let playable = playableFor(indexPath), !playable.isPlaying else { return }
            Ext.debug("当前播放索引 \(playableIndexPath?.description ?? "") 未开始播放，play", logEnabled: logEnabled)
            playable.play()
            return
        }
        Ext.debug("play indexPath changed.", tag: .target, logEnabled: logEnabled)
        pause(at: playableIndexPath)
        playableIndexPath = indexPath
        delegate?.autoPlay(self, didAction: .play(indexPath))
        playableFor(indexPath)?.play()
    }
    
    /// 暂停指定索引
    func pause(at indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        Ext.debug("pause \(indexPath)", logEnabled: logEnabled)
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
            Ext.debug("手指正在拖拽...", logEnabled: logEnabled)
            scrollTracking()
        case .willBeginDragging:
            Ext.debug("开始拖拽", logEnabled: logEnabled)
            dragIndexPath = playableIndexPath
            
            isDragScrolling = true
        case .willEndDragging(_, let velocity, let targetContentOffset):
            Ext.debug("将要结束拖拽", logEnabled: logEnabled)
            Ext.debug("target offset: \(targetContentOffset.pointee) | velocity \(velocity)", logEnabled: logEnabled)
        case .didEndDragging(_, let decelerate):
            guard !decelerate else { return }
            Ext.debug("拖拽无减速，直接静止", logEnabled: logEnabled)
            innerScrollEnd()
        case .willBeginDecelerating:
            Ext.debug("停止拖拽，开始减速", logEnabled: logEnabled)
        case .didEndDecelerating:
            Ext.debug("拖拽之后减速停止", logEnabled: logEnabled)
            innerScrollEnd()
        }
    }
    
}
private extension TableAutoPlay {
    
    func innerScrollEnd() {
        Ext.debug("isDragScrolling: \(isDragScrolling)", logEnabled: logEnabled)
        guard isDragScrolling else { return }
        isDragScrolling = false
        
        scrollToEnd()
    }
    
    /// 正在手指拖拽
    @objc
    func scrollTracking() {
        guard !isStopping, draggingEnabled else { return }
        Ext.debug("处理手指拖动...", logEnabled: logEnabled)
        playBest()
    }
    /// 滚动结束
    @objc
    func scrollToEnd() {
        guard !isStopping else { return }
        Ext.debug("处理滚动结束...", logEnabled: logEnabled)
        playBest()
    }
    /// 滚动到顶部
    @objc
    func scrollToTop() {
        
    }
    
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
        //Ext.debug("superView: \(superView)")
        guard let point = visible.playableView.superview?.convert(visible.playableView.frame.origin, to: superView) else { return nil }
        let minY = max(visibleMinY, min(visibleMaxY, point.y))
        let maxY = min(visibleMaxY, max(visibleMinY, point.y + visible.playableView.frame.height))
        let delta = maxY - minY
        //Ext.debug("\(log) delta: \(delta) | visible: \(minY) ~ \(maxY) in range: [\(visibleMinY) ~ \(visibleMaxY)] | height: \(visible.visibleView.frame.height) | \(point)", logEnabled: true)
        return delta
    }
}
