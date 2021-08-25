//
//  PlayableTableController.swift
//  Ext
//
//  Created by naijoug on 2020/11/10.
//

import UIKit

/// 可视化协议 : 用于判断在屏幕的可以范围
public protocol Visible: AnyObject {
    /// 可视视图: 用于计算可视范围的视图
    var visibleView: UIView { get }
}

/// 可播放协议
public protocol Playable: AnyObject {
    /// 是否正在播放
    var isPlaying: Bool { get }
    /// 是否可以进行播放
    var isPlayable: Bool { get set }
    /// 播放
    func play() -> Void
    /// 暂停
    func pause() -> Void
}

// MARK: - Playable Table

open class PlayableTableController: TableController {
    
    /// 标签
    public var playableTag: String = ""
    
// MARK: - Playable
    
    public var playableLog: Bool = false
    public var visibleLog: Bool = false
    public var scrollLog: Bool = false
    
    private func playableLog(_ msg: String = "") -> String {
        guard self.playableLog else { return "" }
        return "\(self.playableTag) : isPlayable: \(isPlayable) | playableIndex: \(playableIndex) | \(msg) | \(self)"
    }
    
    /// 自动播放▶️: 进入页面最佳可播放 Cell 进行播放
    public var autoPlay: Bool = true
    
    /// 可播放状态
    open var isPlayable: Bool = true {
        didSet {
            Ext.debug(playableLog())
            guard oldValue != isPlayable else { return }
            guard !isPlayable else { return }
            self.stop()
        }
    }
    /// 开始播放
    @objc
    open func play() {
        guard isPlayable else { return }
        Ext.debug(playableLog())
        // 播放可播放 Item
        guard let playable = playableFor(playableIndex), playable.isPlayable else { return }
        playable.play()
    }
    /// 暂停播放
    @objc
    open func pause() {
        Ext.debug(playableLog())
        guard let _ = viewIfLoaded else { return }
        
        guard tableView.visibleCells.count > 0 else { return }
        for cell in tableView.visibleCells {
            (cell as? Playable)?.pause()
        }
    }
    
    /// 最佳可播放索引
    open var playableIndex: Int = 0 {
        didSet {
            guard oldValue != playableIndex else { return }
            Ext.debug(playableLog("\(oldValue) -> \(playableIndex)"), logEnabled: playableLog)
            guard let _ = viewIfLoaded else { return }
            
            guard tableView.visibleCells.count > 0 else { return }
            for cell in tableView.visibleCells {
                //Ext.debug("\(cell)")
                (cell as? Playable)?.isPlayable = false
            }
            playableFor(playableIndex)?.isPlayable = true
        }
    }
    
    /// 最大可播放索引 (**子类必须返回**)
    @objc
    open var maxPlayableIndex: Int { return 0 }
    
// MARK: - Drag Scroll
    
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
    var isDragScrolling: Bool = false
    /// 开始拖拽时偏移量
    var dragOffsetY: CGFloat = 0
    /// 拖拽时的最佳可视索引
    var dragIndex: Int?
    
// MARK: - Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Ext.debug(playableLog())
        
        if autoPlay {
            self.start()
        }
    }
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Ext.debug(playableLog("begin stop scroll..."))
        tableView.ext.stopScroll()
        Ext.debug(playableLog("end stop scroll"))
        stop()
    }
}

// MARK: - Playable

public extension PlayableTableController {
    
    /// 启动播放
    func start() {
        Ext.debug("\(playableIndex)", logEnabled: playableLog)
        guard let _ = viewIfLoaded else { return }
        
        guard let playable = playableFor(playableIndex) else { return }
        playable.isPlayable = true
        playable.play()
    }
    
    /// 停止播放
    func stop() {
        Ext.debug("\(playableIndex) | \(self) | \(self.playableTag)", logEnabled: playableLog)
        guard let _ = viewIfLoaded else { return }
        
        for cell in tableView.visibleCells {
            (cell as? Playable)?.isPlayable = false
        }
    }
    
    /// 播放指定索引
    private func play(at index: Int?) {
        guard let index = index else { return }
        Ext.debug("play \(index)", logEnabled: playableLog)
        if playableIndex != index {
            playableIndex = index
            play()
        } else {
            if !(playableFor(index)?.isPlaying ?? false) {
                Ext.debug("当前播放索引未开始播放，play")
                play()
            }
        }
    }
    /// 播放最佳
    func playBest() {
        Ext.debug("current playable index: \(playableIndex)", logEnabled: playableLog)
        guard let index = clacBestPlayableIndex() else { return }
        play(at: index)
    }
    /// 暂停指定索引
    func pause(at index: Int?) {
        guard let index = index else { return }
        Ext.debug("pause \(index)", logEnabled: playableLog)
        playableFor(index)?.pause()
    }
    
    /// 根据索引获取获取可播放内容
    func playableFor(_ index: Int?) -> Playable? {
        guard let index = index, 0 <= index, index <= maxPlayableIndex else { return nil }
        let indexPath = IndexPath(row: index, section: 0)
        return tableView.cellForRow(at: indexPath) as? Playable
    }
    
    /// 计算当前最佳播放索引
    func clacBestPlayableIndex() -> Int? {
        Ext.debug("当前最佳可播放索引: \(playableIndex)", logEnabled: playableLog)
        guard let cell = bestVisibleCell(), let indexPath = tableView.indexPath(for: cell) else { return nil }
        Ext.debug("best playable index: \(indexPath.row)", logEnabled: playableLog)
        return indexPath.row
    }
    
}

// MARK: - Visible

extension PlayableTableController {
    
    /// 最大可视索引
    public var maxVisibleIndex: Int {
        for cell in tableView.visibleCells.reversed() {
            guard let indexPath = tableView.indexPath(for: cell) else { continue }
            return indexPath.row
        }
        return 0
    }
    
    @objc
    open var visibleMinY: CGFloat { return 0 }
    @objc
    open var visibleMaxY: CGFloat { return self.view.frame.height }
    
    /// 计算最佳可视 Cell
    private func bestVisibleCell() -> UITableViewCell? {
        guard tableView.visibleCells.count > 0 else { return nil }
        var bestCell: Visible?
        for i in 0..<tableView.visibleCells.count {
            let cell = tableView.visibleCells[i]
            guard let visibleCell = cell as? Visible,
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
    public func calcVisible(_ visible: Visible?, log: String = "") -> CGFloat? {
        guard let visible = visible else { return nil }
        guard let point = visible.visibleView.superview?.convert(visible.visibleView.frame.origin, to: self.view) else { return nil }
        let minY = max(visibleMinY, min(visibleMaxY, point.y))
        let maxY = min(visibleMaxY, max(visibleMinY, point.y + visible.visibleView.frame.height))
        let delta = maxY - minY
        Ext.debug("\(log) delta: \(delta) | visible: \(minY) ~ \(maxY) in range: [\(visibleMinY) ~ \(visibleMaxY)] | height: \(visible.visibleView.frame.height) | \(point)", logEnabled: visibleLog)
        return delta
    }
}

// MARK: - Scroll

extension PlayableTableController {
    
    open func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? Playable else { return }
        cell.isPlayable = false
    }
    
    open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        guard scrollView.isDragging else { return }
        guard scrollView.isTracking else { return }
        Ext.debug("手指正在拖拽...", logEnabled: scrollLog)
        scrollTracking()
    }
    
    open override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        super.scrollViewWillBeginDragging(scrollView)
        Ext.debug("开始拖拽", logEnabled: scrollLog)
        dragIndex = playableIndex
        
        isDragScrolling = true
    }
    open override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        super.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        Ext.debug("将要结束拖拽", logEnabled: scrollLog)
        Ext.debug("target offset: \(targetContentOffset.pointee) | velocity \(velocity)", logEnabled: scrollLog)
    }
    open override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        super.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        guard !decelerate else { return }
        Ext.debug("拖拽无减速，直接静止", logEnabled: scrollLog)
        innerScrollEnd()
    }
    
    open override func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        super.scrollViewWillBeginDecelerating(scrollView)
        Ext.debug("停止拖拽，开始减速", logEnabled: scrollLog)
    }
    open override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        super.scrollViewDidEndDecelerating(scrollView)
        Ext.debug("拖拽之后减速停止", logEnabled: scrollLog)
        innerScrollEnd()
    }
    
    open func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        Ext.debug("已经滚动到最顶部", logEnabled: scrollLog)
        scrollToTop()
    }
}
extension PlayableTableController {
    private func innerScrollEnd() {
        Ext.debug("isDragScrolling: \(isDragScrolling)", logEnabled: scrollLog)
        guard isDragScrolling else { return }
        isDragScrolling = false
        
        scrollEnd()
    }
    
    /// 正在手指拖拽
    @objc
    open func scrollTracking() {
        playBest()
    }
    /// 滚动结束
    @objc
    open func scrollEnd() {
        playBest()
    }
    /// 滚动到顶部
    @objc
    open func scrollToTop() {
        play(at: 0)
    }
}
