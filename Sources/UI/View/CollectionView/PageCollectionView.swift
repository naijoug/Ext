//
//  PageCollectionView.swift
//  Ext
//
//  Created by guojian on 2022/1/19.
//

import UIKit

public protocol PageCollectionCellable: UICollectionViewCell {
    associatedtype Item
    
    /// 数据绑定
    func bind(_ item: Item)
}

public protocol PageCollectionItem {
    associatedtype Item
    
    /// 当前页索引
    var currentIndex: Int { get set }
    /// 滚动数据 item
    var items: [Item] { get set }
}

open class PageCollectionView<Item: PageCollectionItem, Cell: PageCollectionCellable>: ExtView,
                                                                                       UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
                                                                                       where Item.Item == Cell.Item {
    
    /// action 处理者
    private var actionHandlers = [Ext.DataHandler<PageCollectionView.Action>]()
    
    /// log 标识
    public var logEnabled: Bool = true
    
// MARK: - Data
    
    public private(set) var item: Item?
    private var items = [Item.Item]()
    
    public func bind(_ item: Item) {
        self.item = item
        self.items = item.items
        
        collectionView.reloadData()
    }
    
// MARK: - Ovrride
    
    /// 左边偏移
    open var leftOffset: CGFloat { 0 }
    /// item 间距
    open var spacing: CGFloat { 0 }
    /// 右侧偏移
    open var rightOffset: CGFloat { 0 }
    /// 分页视图高度
    open var pageH: CGFloat { UIScreen.main.ext.screenWidth }
    
// MARK: - UI
    
    public private(set) lazy var collectionView: UICollectionView = {
        let layout = PageableFlowLayout( .left)
        layout.logEnabled = true
        let collectionView = ext.add(UICollectionView(frame: .zero, collectionViewLayout: layout))
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.decelerationRate = .fast
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.ext.registerClass(Cell.self)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: leftOffset, bottom: 0, right: rightOffset)
        return collectionView
    }()
    
    open override func setupUI() {
        super.setupUI()
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.heightAnchor.constraint(equalToConstant: pageH),
            collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.ext.dequeueReusableCell(Cell.self, for: indexPath)
        cell.bind(items[indexPath.item])
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemH = collectionView.frame.height
        let itemW = collectionView.frame.width - leftOffset - rightOffset
        return CGSize(width: itemW, height: itemH)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        spacing
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        UICollectionReusableView()
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        .zero
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        .zero
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let item = item else { return }
        let offsetX = targetContentOffset.pointee.x
        let itemW = scrollView.frame.height - leftOffset - rightOffset
        let index = itemW > 0 ? Int(offsetX/itemW) : 0
        Ext.debug("offsetX: \(offsetX) | index: \(index) | velocity \(velocity)", logEnabled: logEnabled)
        guard index != item.currentIndex, 0 <= index, index < item.items.count else {
            Ext.debug("dialog index 没有改变.", logEnabled: logEnabled)
            return
        }
        self.didScrollTo(index, isManual: true)
    }
}

// MARK: - Public

public extension PageCollectionView {
    
    enum Action {
        case scrollTo(_ index: Int)
    }
    
    func addAction(_ actionHandler: @escaping Ext.DataHandler<PageCollectionView.Action>) {
        actionHandlers.append(actionHandler)
    }
    
    var currentCell: Cell? { cellFor(item?.currentIndex) }
    
    func cellFor(_ index: Int?) -> Cell? {
        guard let index = index else { return nil }
        return collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? Cell
    }
}

// MARK: - Private

private extension PageCollectionView {
    
    /// 滚动到指定索引
    private func scrollTo(_ index: Int?, animated: Bool = true) {
        guard let index = index, 0 <= index, index < (item?.items.count ?? 0) else { return }
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .left, animated: animated)
        Ext.debug("scroll to \(index)", logEnabled: logEnabled)
    }
    
    /// 滚动完成
    private func didScrollTo(_ index: Int, isManual: Bool) {
        Ext.debug("did scroll To \(index) | isManual: \(isManual)", logEnabled: logEnabled)
        item?.currentIndex = index
        UISelectionFeedbackGenerator().selectionChanged()
        doAction(.scrollTo(index))
    }
    
    private func doAction(_ action: PageCollectionView.Action) {
        Ext.debug("\(actionHandlers)")
        for handler in actionHandlers {
            handler(action)
        }
    }
}
