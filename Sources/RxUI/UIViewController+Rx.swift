//
//  UIViewController+Rx.swift
//  Ext
//
//  Created by guojian on 2023/2/13.
//

import UIKit
import RxSwift
import RxCocoa

public extension Reactive where Base: UIViewController {
    
    var viewDidLoad: ControlEvent<Void> {
        ControlEvent(events: methodInvoked(#selector(Base.viewDidLoad)).map({ _ in }))
    }
    var viewWillAppear: ControlEvent<Bool> {
        ControlEvent(events: methodInvoked(#selector(Base.viewWillAppear(_:))).map({ $0.first as? Bool ?? false }))
    }
    var viewDidAppear: ControlEvent<Bool> {
        ControlEvent(events: methodInvoked(#selector(Base.viewDidAppear(_:))).map({ $0.first as? Bool ?? false }))
    }
    var viewWillDisappear: ControlEvent<Bool> {
        ControlEvent(events: methodInvoked(#selector(Base.viewWillDisappear(_:))).map({ $0.first as? Bool ?? false }))
    }
    var viewDidDisappear: ControlEvent<Bool> {
        ControlEvent(events: methodInvoked(#selector(Base.viewDidDisappear(_:))).map({ $0.first as? Bool ?? false }))
    }
    
    var isVisible: Observable<Bool> {
        Observable<Bool>.merge(base.rx.viewDidAppear.map({ _ in true }), base.rx.viewWillDisappear.map({ _ in false }))
    }
    var isDismissing: ControlEvent<Bool> {
        ControlEvent(events: sentMessage(#selector(Base.dismiss(animated:completion:))).map({ $0.first as? Bool ?? false }))
    }
}

public extension Reactive where Base: UIViewController {
    var viewWillLayoutSubviews: ControlEvent<Void> {
        ControlEvent(events: methodInvoked(#selector(Base.viewWillLayoutSubviews)).map({ _ in }))
    }
    var viewDidLayoutSubviews: ControlEvent<Void> {
        ControlEvent(events: methodInvoked(#selector(Base.viewDidLayoutSubviews)).map({ _ in }))
    }
    
    var viewMove: ControlEvent<UIViewController?> {
        ControlEvent(events: methodInvoked(#selector(Base.willMove(toParent:))).map({ $0.first as? UIViewController }))
    }
    var didMove: ControlEvent<UIViewController?> {
        ControlEvent(events: methodInvoked(#selector(Base.didMove(toParent:))).map({ $0.first as? UIViewController }))
    }
}
