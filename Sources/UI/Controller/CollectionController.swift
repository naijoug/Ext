//
//  CollectionController.swift
//  Ext
//
//  Created by guojian on 2022/3/9.
//

import UIKit

open class CollectionController: BaseScrollController {
    
    open override var scrollView: UIScrollView { collectionView }
    
    public private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        configCollection(collectionView)
        return collectionView
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        layoutCollection(collectionView)
    }
}

// MARK: - Override

extension CollectionController {
    
    /// collectionView 布局 (默认: FlowLayout)
    @objc
    open var layout: UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        return layout
    }
    
    /// 配置 collection
    @objc
    open func configCollection(_ collectionView: UICollectionView) {}
    
    /// 布局 collection
    @objc
    open func layoutCollection(_ collectionView: UICollectionView) {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

// MARK: - DataSource & Delegate

extension CollectionController: UICollectionViewDataSource {
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        0
    }
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        UICollectionViewCell()
    }
}

extension CollectionController: UICollectionViewDelegate {}
extension CollectionController: UICollectionViewDelegateFlowLayout {}
