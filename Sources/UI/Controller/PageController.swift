//
//  PageController.swift
//  Ext
//
//  Created by guojian on 2021/10/12.
//

import UIKit

public protocol PageControllerDelegate: AnyObject {
    func pageController(_ controller: PageController, didAction action: PageController.Action)
}

public class PageController: UIViewController {
    public enum Action {
        case scrollTo(_ index: Int)
    }
    public weak var delegate: PageControllerDelegate?
    
// MARK: - Data
    
    private var controllers = [UIViewController]()
    
// MARK: - Status
    
    public var logEnabled: Bool = false
    
    /// 当前页面索引
    public private(set) var currentIndex: Int = 0 {
        didSet {
            guard oldValue != currentIndex else { return }
            Ext.log("\(oldValue) -> \(currentIndex)", logEnabled: logEnabled)
            reloadPan()
        }
    }
    /// 全屏 pop 是否失效
    public var isInteractivePopDisabled: Bool = false
    
    /// 是否正在切换 page
    private var isTransitioning: Bool = false {
        didSet {
            guard oldValue != isTransitioning else { return }
            Ext.log("\(oldValue) -> \(isTransitioning)", logEnabled: logEnabled)
            reloadPan()
        }
    }
    
    /// 是否可以滑动
    public var isScrollEnabled: Bool = true {
        didSet {
            pageController.ext.scrollView?.isScrollEnabled = isScrollEnabled
        }
    }
    
// MARK: - UI
    
    private lazy var pageController: UIPageViewController = {
        let controller = ext.add(UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil))
        controller.delegate = self
        controller.dataSource = self
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controller.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            controller.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        return controller
    }()
    
// MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        pageController.ext.active()
        setupPan()
    }
    
}
extension PageController: UIGestureRecognizerDelegate {
    
    /**
     Solution:
        - https://www.jianshu.com/p/bc17e5dac995
     */
    
    private func setupPan() {
        guard Ext.Feature.fullscreenPop.isActive else { return }
        guard let scrollView = pageController.ext.scrollView else { return }
        let pan = UIPanGestureRecognizer()
        pan.delegate = self
        scrollView.addGestureRecognizer(pan)
        
        if !isInteractivePopDisabled, let gesture = navigationController?.ext.fullscreenPopGestureRecognizer {
            Ext.log("fullscreen gesture : \(gesture)", logEnabled: logEnabled)
            scrollView.panGestureRecognizer.require(toFail: gesture)
            pan.require(toFail: gesture)
        }
        if !isInteractivePopDisabled, let gesture = navigationController?.interactivePopGestureRecognizer {
            Ext.log("page gesture : \(gesture)", logEnabled: logEnabled)
            scrollView.panGestureRecognizer.require(toFail: gesture)
        }
    }
    
    private func reloadPan() {
        guard !isTransitioning, !self.isInteractivePopDisabled else { return }
        let isInteractivePopDisabled = isScrollEnabled && (currentIndex != 0)
        self.ext.interactionPopDisabled(isInteractivePopDisabled)
        var parent: UIViewController? = self.parent
        while parent != nil {
            Ext.log("parent: \(String(describing: parent))", logEnabled: logEnabled)
            parent?.ext.interactionPopDisabled(isInteractivePopDisabled)
            parent = parent?.parent
        }
        Ext.log("isInteractivePopDisabled: \(isInteractivePopDisabled) | currentIndex: \(currentIndex)", tag: .fire, logEnabled: logEnabled)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        var gestures = [UIGestureRecognizer]()
        controllers.compactMap({ $0 as? BaseScrollController }).forEach {
            gestures.append(contentsOf: $0.scrollView.gestureRecognizers ?? [])
        }
        return gestures.contains(otherGestureRecognizer)
    }
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isScrollEnabled, !isInteractivePopDisabled, let gesture = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let translation = gesture.translation(in: gestureRecognizer.view)
        Ext.log("translation: \(translation) | currentIndex \(currentIndex) | isTransitioning: \(isTransitioning) | isInteractivePopDisabled: \(isInteractivePopDisabled)", tag: .fire, logEnabled: logEnabled)
        guard translation.x != 0 else { return false }
        guard translation.x < 0 else {
            return !isInteractivePopDisabled && currentIndex == 0 && !isTransitioning
        }
        return currentIndex == (controllers.count - 1) && !isTransitioning
    }
}

public extension PageController {
    
    /// 绑定页面数据
    func bind(_ controllers: [UIViewController], index: Int = 0) {
        guard !controllers.isEmpty else { return }
        self.controllers = controllers
        currentIndex = 0
        if 0 <= index, index < controllers.count {
            currentIndex = index
        }
        pageController.setViewControllers([controllers[currentIndex]], direction: .forward, animated: false, completion: nil)
        Ext.log("\(index) - \(currentIndex) | \(controllers[currentIndex])", logEnabled: logEnabled)
    }
    
    /// 滚动到指定索引页面
    func scrollTo(_ index: Int) {
        guard index != currentIndex else { return }
        guard 0 <= index, index < controllers.count else { return }
        let isForward = index >= currentIndex
        Ext.log("page to \(index)", logEnabled: logEnabled)
        self.isTransitioning = true
        currentIndex = index
        pageController.setViewControllers([controllers[index]], direction: isForward ? .forward : .reverse, animated: true) { [weak self] completed in
            guard let `self` = self, completed else { return }
            Ext.log("page to \(index) end.", logEnabled: self.logEnabled)
            self.isTransitioning = false
        }
    }
}

// MARK: - Delegate

extension PageController: UIPageViewControllerDataSource {
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        controllers.pre(viewController)
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        controllers.next(viewController)
    }
}

extension PageController: UIPageViewControllerDelegate {
    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        isTransitioning = true
    }
    /// 翻页完成
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let controller = pageViewController.viewControllers?.first,
           let index = controllers.firstIndex(of: controller) {
            isTransitioning = false
            Ext.log("index: \(index)", logEnabled: logEnabled)
            self.currentIndex = index
            delegate?.pageController(self, didAction: .scrollTo(index))
        }
    }
}
