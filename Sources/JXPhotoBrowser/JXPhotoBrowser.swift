//
//  JXPhotoBrowser.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2019/11/11.
//  Copyright © 2019 JiongXing. All rights reserved.
//

import UIKit

@objc public protocol JXPhotoBrowserDelegate {
    func onSaveTapped()
    func onForwardTapped()
    func onShareTapped()
    @objc optional func onDeleteTapped()
}

/// 图片浏览器
/// - 不支持复用，每次使用请新建实例
open class JXPhotoBrowser: UIViewController, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate {
    
    /// 通过本回调，把图片浏览器嵌套在导航控制器里
    public typealias PresentEmbedClosure = (JXPhotoBrowser) -> UINavigationController
    
    open var jxPhotoBrowserDelegate: JXPhotoBrowserDelegate?
    
    /// 打开方式类型
    public enum ShowMethod {
        case push(inNC: UINavigationController?)
        case present(fromVC: UIViewController?, embed: PresentEmbedClosure?)
        case presentInNav(fromVC: UIViewController?, embed: PresentEmbedClosure?)
    }
    
    /// 滑动方向类型
    public enum ScrollDirection {
        case horizontal
        case vertical
    }
    
    open lazy var saveLocalizedString = "Save"
    open lazy var forwardLocalizedString = "Forward"
    open lazy var shareLocalizedString = "Share"
    open lazy var cancelLocalizedString = "Cancel"
    
    open lazy var actionButton: UIBarButtonItem = {
        let actionButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(handleActions))
        return actionButton
    }()
    
    open lazy var deleteButton: UIBarButtonItem = {
        let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(handleDelete))
        return deleteButton
    }()
    
    /// 自实现转场动画
    open lazy var transitionAnimator: JXPhotoBrowserAnimatedTransitioning = JXPhotoBrowserFadeAnimator()
    
    open lazy var isHideDeleteButtonInToolBar = true
    
    open lazy var navBarView: UIView = {
        let navBarView = UIView()
        navBarView.backgroundColor = .red
        navBarView.translatesAutoresizingMaskIntoConstraints = false
        return navBarView
    }()
    
    /// 滑动方向
    open var scrollDirection: JXPhotoBrowser.ScrollDirection {
        set { browserView.scrollDirection = newValue }
        get { return browserView.scrollDirection }
    }
    
    /// 项间距
    open var itemSpacing: CGFloat {
        set { browserView.itemSpacing = newValue }
        get { return browserView.itemSpacing }
    }
    
    /// 当前页码
    open var pageIndex: Int {
        set { browserView.pageIndex = newValue }
        get { return browserView.pageIndex }
    }
    
    /// 浏览过程中实时获取数据总量
    open var numberOfItems: () -> Int {
        set { browserView.numberOfItems = newValue }
        get { return browserView.numberOfItems }
    }
    
    /// 返回可复用的Cell类。用户可根据index返回不同的类。本闭包将在每次复用Cell时实时调用。
    open var cellClassAtIndex: (_ index: Int) -> JXPhotoBrowserCell.Type {
        set { browserView.cellClassAtIndex = newValue }
        get { return browserView.cellClassAtIndex }
    }
    
    /// Cell刷新时用的上下文。index: 刷新的Cell对应的index；currentIndex: 当前显示的页
    public typealias ReloadCellContext = (cell: JXPhotoBrowserCell, index: Int, currentIndex: Int)
    
    /// 刷新Cell数据。本闭包将在Cell完成位置布局后调用。
    open var reloadCellAtIndex: (ReloadCellContext) -> Void {
        set { browserView.reloadCellAtIndex = newValue }
        get { return browserView.reloadCellAtIndex }
    }
    
    /// 自然滑动引起的页码改变时回调
    open lazy var didChangedPageIndex: (_ index: Int) -> Void = { _ in }
    
    /// Cell将显示
    open var cellWillAppear: (JXPhotoBrowserCell, Int) -> Void {
        set { browserView.cellWillAppear = newValue }
        get { return browserView.cellWillAppear }
    }
    
    /// Cell将不显示
    open var cellWillDisappear: (JXPhotoBrowserCell, Int) -> Void {
        set { browserView.cellWillDisappear = newValue }
        get { return browserView.cellWillDisappear }
    }
    
    /// Cell已显示
    open var cellDidAppear: (JXPhotoBrowserCell, Int) -> Void {
        set { browserView.cellDidAppear = newValue }
        get { return browserView.cellDidAppear }
    }
    
    /// 主视图
    open lazy var browserView = JXPhotoBrowserView()
    
    /// 页码指示
    open var pageIndicator: JXPhotoBrowserPageIndicator?
    
    /// 背景蒙版
    open lazy var maskView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    open weak var previousNavigationControllerDelegate: UINavigationControllerDelegate?
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 显示图片浏览器
    open func show(method: ShowMethod = .present(fromVC: nil, embed: nil)) {
        switch method {
        case .push(let inNC):
            let nav = inNC ?? JXPhotoBrowser.topMost?.navigationController
            previousNavigationControllerDelegate = nav?.delegate
            nav?.delegate = self
            nav?.pushViewController(self, animated: true)
        case .present(let fromVC, let embed):
            let toVC = embed?(self) ?? self
            toVC.modalPresentationStyle = .custom
            toVC.modalPresentationCapturesStatusBarAppearance = true
            toVC.transitioningDelegate = self
            let from = fromVC ?? JXPhotoBrowser.topMost
            from?.present(toVC, animated: true, completion: nil)
        case let .presentInNav(fromVC, embed):
            let toVC = UINavigationController(rootViewController: embed?(self) ?? self)
            toVC.modalPresentationStyle = .custom
            toVC.modalPresentationCapturesStatusBarAppearance = true
            toVC.transitioningDelegate = self
            let from = fromVC ?? JXPhotoBrowser.topMost
            from?.present(toVC, animated: true, completion: nil)
        }
    }
    
    /// 刷新
    open func reloadData() {
        browserView.reloadData()
        pageIndicator?.reloadData(numberOfItems: numberOfItems(), pageIndex: pageIndex)
    }
    
    private func setupNavBarView() {
        view.addSubview(navBarView)
        navBarView.layer.zPosition = 1
        NSLayoutConstraint.activate([
            navBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBarView.topAnchor.constraint(equalTo: view.topAnchor),
            navBarView.heightAnchor.constraint(equalToConstant: topBarHeight)
        ])
    }
    
    @objc private func handleDelete() {
        guard let delegate = jxPhotoBrowserDelegate else { return }
        delegate.onDeleteTapped?()
    }
    
    private func setupToolBarView() {
        navigationController?.setToolbarHidden(false, animated: true)
        var items = [UIBarButtonItem]()
        let flexibleButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        items.append(actionButton)
        items.append(flexibleButton)
        if !isHideDeleteButtonInToolBar {
            items.append(deleteButton)
        }
        self.toolbarItems = items
        
        automaticallyAdjustsScrollViewInsets = false
    }
    
    @objc private func handleActions() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: saveLocalizedString, style: .default) { [unowned self] _ in
            guard let delegate = self.jxPhotoBrowserDelegate else { return }
            delegate.onSaveTapped()
        })
        alertController.addAction(UIAlertAction(title: forwardLocalizedString, style: .default) { [unowned self] _ in
            guard let delegate = self.jxPhotoBrowserDelegate else { return }
            delegate.onForwardTapped()
        })
        
        alertController.addAction(UIAlertAction(title: shareLocalizedString, style: .default) { [unowned self] _ in
            guard let delegate = self.jxPhotoBrowserDelegate else { return }
            delegate.onShareTapped()
        })
        
        alertController.addAction(UIAlertAction(title: cancelLocalizedString, style: .cancel))
        present(alertController, animated: true, completion: nil)
    }
    open override func viewDidLoad() {
        super.viewDidLoad()
        
//        setupNavBarView()
        setupToolBarView()
        
        hideNavigationBar(true)
        browserView.photoBrowser = self
        transitionAnimator.photoBrowser = self
        
        view.backgroundColor = .clear
        view.addSubview(maskView)
        view.addSubview(browserView)
        
        browserView.didChangedPageIndex = { [weak self] index in
            guard let `self` = self else { return }
            self.pageIndicator?.didChanged(pageIndex: index)
            self.didChangedPageIndex(index)
        }
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        maskView.frame = view.bounds
        browserView.frame = view.bounds
        pageIndicator?.reloadData(numberOfItems: numberOfItems(), pageIndex: pageIndex)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavigationBar(true)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.delegate = previousNavigationControllerDelegate
        if let indicator = pageIndicator {
            view.addSubview(indicator)
            indicator.setup(with: self)
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navBarView.isHidden = true
        navigationController?.setToolbarHidden(true, animated: true)
        hideNavigationBar(false)
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        browserView.isRotating = true
    }
    
    //
    // MARK: - Navigation Bar
    //
    
    /// 在PhotoBrowser打开之前，导航栏是否隐藏
    open var isPreviousNavigationBarHidden: Bool?
    
    private func hideNavigationBar(_ hide: Bool) {
        if hide {
            if isPreviousNavigationBarHidden == nil {
                isPreviousNavigationBarHidden = navigationController?.isNavigationBarHidden
            }
            navigationController?.setNavigationBarHidden(true, animated: false)
        } else {
            if let barHidden = isPreviousNavigationBarHidden {
                navigationController?.setNavigationBarHidden(barHidden, animated: false)
            }
        }
    }
    
    //
    // MARK: - Status Bar
    //
    
    private lazy var isPreviousStatusBarHidden: Bool = {
        var previousVC: UIViewController?
        if let vc = self.presentingViewController {
            previousVC = vc
        } else {
            if let navVCs = self.navigationController?.viewControllers, navVCs.count >= 2 {
                previousVC = navVCs[navVCs.count - 2]
            }
        }
        return previousVC?.prefersStatusBarHidden ?? false
    }()
    
    private lazy var isStatusBarHidden = self.isPreviousStatusBarHidden
    
    open override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }
    
    open func setStatusBar(hidden: Bool) {
        if hidden {
            isStatusBarHidden = true
        } else {
            isStatusBarHidden = isPreviousStatusBarHidden
        }
        setNeedsStatusBarAppearanceUpdate()
    }
    
    //
    // MARK: - 转场
    //
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isForShow = true
        transitionAnimator.photoBrowser = self
        return transitionAnimator
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isForShow = false
        transitionAnimator.photoBrowser = self
        return transitionAnimator
    }
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isForShow = (operation == .push)
        transitionAnimator.photoBrowser = self
        transitionAnimator.isNavigationAnimation = true
        return transitionAnimator
    }
    
    /// 关闭PhotoBrowser
    open func dismiss() {
        setStatusBar(hidden: false)
        pageIndicator?.removeFromSuperview()
        if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.delegate = self
            navigationController?.popViewController(animated: true)
        }
    }
    
    deinit {
        JXPhotoBrowserLog.low("deinit - \(self.classForCoder)")
        navigationController?.delegate = previousNavigationControllerDelegate
    }
    
    //
    // MARK: - 取顶层控制器
    //

    /// 取最顶层的ViewController
    open class var topMost: UIViewController? {
        return topMost(of: UIApplication.shared.keyWindow?.rootViewController)
    }
    
    open class func topMost(of viewController: UIViewController?) -> UIViewController? {
        // presented view controller
        if let presentedViewController = viewController?.presentedViewController {
            return self.topMost(of: presentedViewController)
        }
        
        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return self.topMost(of: selectedViewController)
        }
        
        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return self.topMost(of: visibleViewController)
        }
        
        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
            pageViewController.viewControllers?.count == 1 {
            return self.topMost(of: pageViewController.viewControllers?.first)
        }
        
        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return self.topMost(of: childViewController)
            }
        }
        
        return viewController
    }
}

final class JXHelper {
    static func getTopSafeAreaHeight() -> CGFloat {
        if #available(iOS 13.0, *) {
            guard UIApplication.shared.windows.count != 0 else { return 0 }
            let window = UIApplication.shared.windows[0]
            return window.safeAreaInsets.top
        } else if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            guard let topPadding = window?.safeAreaInsets.top else { return 0 }
            return topPadding
        }
        return 0
    }

    static func getBottomSafeAreaHeight() -> CGFloat {
        if #available(iOS 13.0, *) {
            guard UIApplication.shared.windows.count != 0 else { return 0 }
            let window = UIApplication.shared.windows[0]
            return window.safeAreaInsets.bottom
        } else if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            guard let bottomPadding = window?.safeAreaInsets.bottom else { return 0 }
            return bottomPadding
        }
        return 0
    }
}

extension UIViewController {
    var topBarHeight: CGFloat {
        var top = self.navigationController?.navigationBar.frame.height ?? 0.0
        if #available(iOS 13.0, *) {
            top += UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            top += UIApplication.shared.statusBarFrame.height
        }
        return top
    }
    var bottomBarHeight: CGFloat {
        var bottom = self.navigationController?.toolbar.frame.size.height ?? 0.0
        bottom += JXHelper.getBottomSafeAreaHeight()
        return bottom
    }
}
