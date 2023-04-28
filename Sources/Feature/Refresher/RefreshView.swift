//
//  RefreshView.swift
//  Ext
//
//  Created by guojian on 2023/4/25.
//

import UIKit

class RefreshBaseView: ExtView, ExtInnerLogable {
    var logLevel: Ext.LogLevel = .off
    
    private let refreshHandler: Ext.VoidHandler
    init(_ refreshHandler: @escaping Ext.VoidHandler) {
        self.refreshHandler = refreshHandler
        
        super.init(frame: .zero)
    }
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
// MARK: - UI
    
    fileprivate weak var collectionView: UICollectionView? {
        didSet {
            ext.log("\(oldValue) -> \(collectionView)")
            backgroundColor = collectionView?.backgroundColor
        }
    }
    fileprivate var rawContentInset: UIEdgeInsets = .zero {
        didSet {
            ext.log("\(oldValue) -> \(rawContentInset)")
        }
    }
    fileprivate var isPagingEnabled: Bool = false
    
    private lazy var indicatorView = ext.add(UIActivityIndicatorView(style: .gray)).setup {
        $0.hidesWhenStopped = true
    }
    
    static let viewW: CGFloat = 50
    override func setupUI() {
        super.setupUI()
        //backgroundColor = .red
        
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicatorView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
    
    private var observers = [NSKeyValueObservation?]()
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        ext.log("\(newSuperview)")
        removeObservers()
        guard let newSuperview = newSuperview as? UICollectionView else { return }
        collectionView = newSuperview
        collectionView?.alwaysBounceHorizontal = true
        rawContentInset = newSuperview.adjustedContentInset
        isPagingEnabled = newSuperview.isSpringLoaded
        addObservers()
    }
    
// MARK: - Override
    
    fileprivate var isReadyToRefresh: Bool { false }
    
    /// 当 contentSize 发生变化时， 刷新空间 frame
    fileprivate func reloadFrame() {}
    /// 设置 normal 状态 inset (回复默认值)
    fileprivate func setInsetToNormal() {}
    /// 设置 loading 状态的 inset (为了将通过设置 offset 可以将刷新视图显示)
    fileprivate func setInsetToLoading() {}
    /// 设置 loading 状态下的偏移量 (为了显示 indicator)
    fileprivate func setOffsetToLoading() {}
    
// MARK: - State
    
    /// 刷新控件是否可用 (没有更多数据时，不可用)
    fileprivate var refreshEnabled: Bool = true
    
    enum RefreshState {
        case normal
        case dragging
        case loading
    }
    
    var refreshState: RefreshState = .normal {
        didSet {
            ext.log("\(oldValue) -> \(refreshState)")
            switch refreshState {
            case .normal:
                guard oldValue == .loading else { return }
                ext.log("")
                indicatorView.stopAnimating()
                setInsetToNormal()
            case .dragging:
                ext.log("")
            case .loading:
                indicatorView.startAnimating()
                setInsetToLoading()
                refreshHandler()
            }
        }
    }
}

private extension RefreshBaseView {
    func startAnimating() {
        refreshState = .loading
    }
    func stopAnimating() {
        refreshState = .normal
    }
}

// MARK: - Observer

private extension RefreshBaseView {
    
    func removeObservers() {
        for observer in observers {
            observer?.invalidate()
        }
        observers.removeAll()
    }
    
    func addObservers() {
        removeObservers()
        guard let collectionView else { return }
        observers.append(collectionView.observe(\.contentSize, options: [.old, .new]) { [weak self] collectionView, change in
            guard let self, collectionView == self.collectionView else { return }
            guard self.refreshEnabled else { return }
            self.ext.log("\(change.oldValue) -> \(change.newValue)")
            self.reloadFrame()
        })
        observers.append(collectionView.observe(\.contentOffset, options: [.old, .new]) { [weak self] collectionView, change in
            guard let self, collectionView == self.collectionView else { return }
            guard self.refreshEnabled else { return }
            self.ext.log("current state: \(self.refreshState) | isDragging: \(collectionView.isDragging) | isRefreshReady: \(isReadyToRefresh ? "👌" : "no") | \(change.oldValue) -> \(change.newValue)")
            switch self.refreshState {
            case .normal:
                guard collectionView.isDragging, self.isReadyToRefresh else { return }
                self.ext.log("正在拖拽，并且已准备好刷新，改为 dragging 状态")
                self.refreshState = .dragging
            case .dragging:
                guard !collectionView.isDragging else { return }
                self.ext.log("拖拽停止，isReadyToRefresh: \(isReadyToRefresh) | \(isReadyToRefresh ? "to loading" : "to normal")")
                self.refreshState = isReadyToRefresh ? .loading : .normal
            case .loading:
                guard collectionView.isDragging else {
                    self.ext.log("正加载数据， 停止拖拽，保持刷新 offset")
                    self.setOffsetToLoading()
                    return
                }
                self.ext.log("加载数据过程，继续拖拽")
            }
        })
    }
}

// MARK: - Header

class RefreshHeaderView: RefreshBaseView {
    
    override func reloadFrame() {
        guard let collectionView else { return }
        let frameX = -(Self.viewW + rawContentInset.left)
        frame = CGRect(x: frameX, y: 0, width: Self.viewW, height: collectionView.frame.height)
        ext.log("header: \(frameX) | \(frame)")
        self.isHidden = false
    }
    
    override var isReadyToRefresh: Bool {
        guard let collectionView else { return false }
        let offsetX = -(collectionView.contentInset.left + collectionView.contentOffset.x)
        let targetX = Self.viewW
        ext.log("header: 👈 \(offsetX) vs \(targetX) | \(collectionView.contentOffset) - \(collectionView.contentInset)")
        return offsetX > targetX
    }
    
    override func setInsetToNormal() {
        guard let collectionView else { return }
        collectionView.isPagingEnabled = isPagingEnabled
        UIView.animate(withDuration: .ext.animationDuration) {
            self.collectionView?.contentInset = self.rawContentInset
        }
    }
    override func setInsetToLoading() {
        guard let collectionView else { return }
        collectionView.isPagingEnabled = false
        var inset = collectionView.contentInset
        inset.left = Self.viewW + rawContentInset.left
        inset.left -= (collectionView.adjustedContentInset.left - collectionView.contentInset.left)
        ext.log("header: \(collectionView.contentInset) -> \(inset) | \(rawContentInset) - \(collectionView.adjustedContentInset)")
        UIView.animate(withDuration: .ext.animationDuration) {
            self.collectionView?.contentInset = inset
        }
    }
    override func setOffsetToLoading() {
        guard let collectionView, refreshState == .loading else { return }
        let targetX = -(Self.viewW + rawContentInset.left)
        let targetY = collectionView.contentOffset.y
        ext.log("header \(refreshState) : \(targetX), \(targetY)")
        collectionView.setContentOffset(CGPoint(x: targetX, y: targetY), animated: false)
    }
}

// MARK: - Footer

class RefreshFooterView: RefreshBaseView {
    
    override func reloadFrame() {
        guard let collectionView else { return }
        let frameX = collectionView.contentSize.width > collectionView.frame.width ?
            collectionView.contentSize.width + rawContentInset.right
            :
            collectionView.frame.width - rawContentInset.right
        ext.log("footer: \(collectionView.contentSize.width) - \(collectionView.frame.width) | \(frameX)")
        frame = CGRect(x: frameX, y: 0, width: Self.viewW, height: collectionView.frame.height)
        self.isHidden = false
    }
    
    override var isReadyToRefresh: Bool {
        guard let collectionView else { return false }
        let offsetX = collectionView.contentOffset.x
        let maxOffsetX = collectionView.contentSize.width - collectionView.frame.width + collectionView.contentInset.right
        let targetX = maxOffsetX + Self.viewW
        ext.log("\n\(collectionView.contentOffset) - \(collectionView.contentSize) - \(collectionView.frame) | \(collectionView.adjustedContentInset) - \(collectionView.contentInset) - \(rawContentInset)")
        ext.log("footer: 👉 \(offsetX) vs \(targetX) | \(maxOffsetX) ==> \(offsetX > targetX)")
        return offsetX > targetX
    }
    
    override func setInsetToNormal() {
        guard let collectionView else { return }
        var inset = collectionView.contentInset
        inset.right = rawContentInset.right
        inset.right -= (collectionView.adjustedContentInset.right - collectionView.contentInset.right)
        ext.log("footer: \(collectionView.contentInset) -> \(inset) | \(rawContentInset) - \(collectionView.adjustedContentInset)")
        UIView.animate(withDuration: .ext.animationDuration) {
            self.collectionView?.contentInset = inset
        }
    }
    override func setInsetToLoading() {
        guard let collectionView else { return }
        let targetRight = rawContentInset.right + Self.viewW
        let showWidth = collectionView.frame.width - rawContentInset.right
        let spaceWidth = showWidth - collectionView.contentSize.width
        var inset = collectionView.contentInset
        inset.right = targetRight + max(0, spaceWidth)
        ext.log("footer: \(targetRight) - \(showWidth) - \(spaceWidth) | \(collectionView.contentInset) -> \(inset)")
        UIView.animate(withDuration: .ext.animationDuration) {
            self.collectionView?.contentInset = inset
        }
    }
    override func setOffsetToLoading() {
        guard let collectionView, refreshState == .loading else { return }
        let targetX = collectionView.contentSize.width - collectionView.frame.width + rawContentInset.right + Self.viewW
        let targetY = collectionView.contentOffset.y
        ext.log("footer \(refreshState): \(targetX), \(targetY) | \(collectionView.contentSize) - \(collectionView.frame.width) - \(rawContentInset)")
        collectionView.setContentOffset(CGPoint(x: targetX, y: targetY), animated: false)
    }
}

class RefreshEmptyView: ExtView, ExtInnerLogable {
    var logLevel: Ext.LogLevel = .debug
    
    override func setupUI() {
        setupUI()
        backgroundColor = .blue
    }
    
    private weak var collectionView: UICollectionView? {
        didSet {
            ext.log("\(oldValue) -> \(collectionView)")
            //backgroundColor = collectionView?.backgroundColor
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        ext.log("\(newSuperview)")
        removeObservers()
        guard let newSuperview = newSuperview as? UICollectionView else { return }
        collectionView = newSuperview
        addObservers()
    }
    
    private var observers = [NSKeyValueObservation?]()
    
    private func removeObservers() {
        for observer in observers {
            observer?.invalidate()
        }
        observers.removeAll()
    }
    
    private func addObservers() {
        removeObservers()
        guard let collectionView else { return }
        observers.append(collectionView.observe(\.contentSize) { [weak self] collectionView, change in
            guard let self, collectionView == self.collectionView else { return }
            self.ext.log("\(change.oldValue) -> \(change.newValue)")
            let frameX = collectionView.contentSize.width + collectionView.contentInset.right
            self.frame = CGRect(x: frameX, y: 0, width: 50, height: collectionView.frame.height)
        })
    }
}

private extension UICollectionView {
    
    private static var refreshHeaderKey: UInt8 = 0
    private static var refreshFooterKey: UInt8 = 0
    
    /// pop 手势不可用
    var refreshHeader: RefreshHeaderView? {
        get {
            ext.getAssociatedObject(&Self.refreshHeaderKey, valueType: RefreshHeaderView.self)
        }
        set {
            Ext.log("\(refreshHeader) -> \(newValue)")
            guard refreshHeader != newValue else {
                return
            }
            Ext.log("")
            refreshHeader?.removeFromSuperview()
            guard let newValue else { return }
            ext.setAssociatedObject(&Self.refreshHeaderKey, value: newValue, policy: .retainNonatomic)
            insertSubview(newValue, at: 0)
        }
    }
    
    /// pop 手势允许的距离屏幕左边最大距离
    var refreshFooter: RefreshFooterView? {
        get {
            ext.getAssociatedObject(&Self.refreshFooterKey, valueType: RefreshFooterView.self)
        }
        set {
            Ext.log("\(refreshFooter) -> \(newValue)")
            guard refreshFooter != newValue else {
                return
            }
            Ext.log("")
            refreshFooter?.removeFromSuperview()
            guard let newValue else { return }
            ext.setAssociatedObject(&Self.refreshFooterKey, value: newValue, policy: .retainNonatomic)
            addSubview(newValue)
        }
    }
    
}

// MARK: - Public

public extension ExtWrapper where Base == UICollectionView {
    /// 添加头部刷新 (下拉刷新)
    func addHeaderRefresh(handler: @escaping Ext.VoidHandler) {
        let header = RefreshHeaderView(handler)
        base.refreshHeader = header
    }
    /// 添加尾部刷新 (上拉刷新)
    func addFooterRefresh(handler: @escaping Ext.VoidHandler) {
        let footer = RefreshFooterView(handler)
        base.refreshFooter = footer
    }
    
    func endHeaderRefreshing() {
        base.refreshHeader?.stopAnimating()
    }
    func endFooterRefreshing() {
        base.refreshFooter?.stopAnimating()
    }
    
    func headerNoMoreData(_ noMore: Bool) {
        base.refreshHeader?.refreshEnabled = !noMore
    }
    func footerNoMoreData(_ noMore: Bool) {
        base.refreshFooter?.refreshEnabled = !noMore
    }
}
