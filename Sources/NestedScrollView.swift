//
//  NestedScrollView.swift
//  JSNestedScroll
//
//  Created by jiasong on 2022/5/31.
//

import UIKit
import JSCoreKit

public final class NestedScrollView: UIScrollView {
    
    public static let automaticDimension: CGFloat = -1
    
    public var headerView: NestedScrollViewScrollSubview? {
        didSet {
            self.addSubview(self.headerView, oldView: oldValue)
        }
    }
    
    public var middleView: NestedScrollViewSupplementarySubview? {
        didSet {
            self.addSubview(self.middleView, oldView: oldValue)
        }
    }
    
    public var floatingView: NestedScrollViewSupplementarySubview? {
        didSet {
            self.addSubview(self.floatingView, oldView: oldValue)
        }
    }
    
    public var floatingOffset: CGFloat = 0 {
        didSet {
            guard oldValue != self.floatingOffset else {
                return
            }
            
            self.reload()
        }
    }
    
    public var contentView: NestedScrollViewScrollSubview? {
        didSet {
            self.addSubview(self.contentView, oldView: oldValue)
        }
    }
    
    public private(set) lazy var containerView: UIView = {
        return UIView()
    }()
    
    public override weak var delegate: UIScrollViewDelegate? {
        get {
            return self.delegateProxy.scrollViewDelegateTarget
        }
        set {
            super.delegate = self.delegateProxy
            
            if newValue is NestedScrollViewDelegateProxy {
                return
            }
            self.delegateProxy.scrollViewDelegateTarget = newValue
        }
    }
    
    private lazy var scrollSubviewDidScrollHandler: NestedScrollDidScrollHandler = {
        return { [weak self] (scrollView) in
            guard let self = self else {
                return
            }
            self.handleDidScoll()
        }
    }()
    
    private lazy var delegateProxy: NestedScrollViewDelegateProxy = {
        return NestedScrollViewDelegateProxy(interceptor: self)
    }()
    
    private var isNeedsHandleScolling: Bool = false
    private var isUpdatingContentSize: Bool = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.didInitialize()
    }
    
    private func didInitialize() {
        self.addSubview(self.containerView)
        
        self.contentInsetAdjustmentBehavior = .never
        self.alwaysBounceVertical = true
        self.bounces = true
        self.contentInset = .zero
        self.delegate = self.delegateProxy
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = CGRect(
            x: 0.0,
            y: 0.0,
            width: self.bounds.width - JSUIEdgeInsetsGetHorizontalValue(self.adjustedContentInset),
            height: self.bounds.height
        )
        
        let headerHeight = {
            var height = self.calculateHeight(for: self.headerView)
            if self.headerScrollView != nil {
                height = min(height, bounds.height)
            }
            return height
        }()
        self.headerView?.frame = JSCGRectSetHeight(bounds, headerHeight)
        
        let middleHeight = self.calculateHeight(for: self.middleView)
        self.middleView?.frame = JSCGRectSetHeight(JSCGRectSetY(bounds, headerHeight), middleHeight)
        
        let floatingHeight = self.calculateHeight(for: self.floatingView)
        self.floatingView?.js_frameApplyTransform = JSCGRectSetHeight(JSCGRectSetY(bounds, headerHeight + middleHeight), floatingHeight)
        
        let contentHeight = {
            var height = self.calculateHeight(for: self.contentView)
            if self.contentScrollView != nil {
                height = min(height, bounds.height)
            }
            return height
        }()
        self.contentView?.frame = JSCGRectSetHeight(JSCGRectSetY(bounds, headerHeight + middleHeight + floatingHeight), contentHeight)
        
        self.containerView.js_frameApplyTransform = JSCGRectSetHeight(bounds, headerHeight + middleHeight + floatingHeight + contentHeight)
        
        self.updateScrollSettings()
        
        let isContentSizeChanged = self.updateContentSize()
        if isContentSizeChanged || self.isNeedsHandleScolling {
            self.isNeedsHandleScolling = false
            
            self.handleDidScoll()
        }
    }
    
}

extension NestedScrollView {
    
    public func reload() {
        self.isNeedsHandleScolling = true
        self.setNeedsLayout()
    }
    
    public func scrollToHeaderView(with offset: CGPoint, animated: Bool) {
        var contentOffset = self.headerViewMinimumPosition
        contentOffset.x += offset.x
        contentOffset.y += offset.y
        self.js_scrollTo(contentOffset, animated: animated)
    }
    
    public func scrollToMiddleView(with offset: CGPoint, animated: Bool) {
        var contentOffset = self.middleViewMinimumPosition
        contentOffset.x += offset.x
        contentOffset.y += offset.y
        self.js_scrollTo(contentOffset, animated: animated)
    }
    
    public func scrollToContentView(with offset: CGPoint, animated: Bool) {
        var contentOffset = self.contentViewMinimumPosition
        contentOffset.x += offset.x
        contentOffset.y += offset.y
        self.js_scrollTo(contentOffset, animated: animated)
    }
    
    public func scrollTo(_ view: UIView, with offset: CGPoint, animated: Bool) {
        if view == self.headerView || view == self.headerScrollView {
            self.scrollToHeaderView(with: offset, animated: animated)
        } else if view == self.middleView {
            self.scrollToMiddleView(with: offset, animated: animated)
        } else if view == self.contentView || view == self.contentScrollView {
            self.scrollToContentView(with: offset, animated: animated)
        } else {
            assertionFailure("不支持此View")
        }
    }
    
    public var headerViewMinimumPosition: CGPoint {
        return self.js_minimumContentOffset
    }
    
    public var middleViewMinimumPosition: CGPoint {
        return CGPoint(
            x: self.js_minimumContentOffset.x,
            y: self.js_minimumContentOffset.y + self.headerViewContentHeight
        )
    }
    
    public var contentViewMinimumPosition: CGPoint {
        return CGPoint(
            x: self.js_minimumContentOffset.x,
            y: self.js_minimumContentOffset.y + self.headerViewContentHeight + (self.middleView?.bounds.height ?? 0) + self.adjustedContentInset.top - self.floatingOffset
        )
    }
    
}

extension NestedScrollView {
    
    private var headerScrollView: UIScrollView? {
        guard let scrollView = self.headerView?.preferredScrollView(in: self) else {
            return nil
        }
        return scrollView
    }
    
    private var headerViewContentHeight: CGFloat {
        let headerHeight = self.headerView?.bounds.height ?? 0
        var headerContentHeight = 0.0
        if let headerScrollView = self.headerScrollView {
            headerContentHeight = headerScrollView.contentSize.height
            headerContentHeight += JSUIEdgeInsetsGetVerticalValue(headerScrollView.adjustedContentInset)
            /// 内容高度小于视图本身的高度时, 需要设置为视图本身的高度
            headerContentHeight = max(headerContentHeight, headerHeight)
        } else {
            headerContentHeight = headerHeight
        }
        return headerContentHeight
    }
    
    private var contentScrollView: UIScrollView? {
        guard let scrollView = self.contentView?.preferredScrollView(in: self) else {
            return nil
        }
        return scrollView
    }
    
    private var contentViewContentHeight: CGFloat {
        let contentViewHeight = self.contentView?.bounds.height ?? 0
        var contentViewContentHeight = 0.0
        if let contentScrollView = self.contentScrollView {
            contentViewContentHeight = contentScrollView.contentSize.height
            contentViewContentHeight += JSUIEdgeInsetsGetVerticalValue(contentScrollView.adjustedContentInset)
            /// 内容高度小于视图本身的高度时, 需要设置为视图本身的高度
            contentViewContentHeight = max(contentViewContentHeight, contentViewHeight)
        } else {
            contentViewContentHeight = contentViewHeight
        }
        return contentViewContentHeight
    }
    
    private func calculateHeight(for subview: NestedScrollViewSupplementarySubview?) -> CGFloat {
        guard let subview = subview, subview.superview == self.containerView else {
            return 0
        }
        
        var result = subview.preferredHeight(in: self)
        if result < 0 {
            if let scrollSubview = subview as? NestedScrollViewScrollSubview, let scrollView = scrollSubview.preferredScrollView(in: self) {
                if scrollView.contentSize.height > 0 {
                    result = scrollView.contentSize.height + JSUIEdgeInsetsGetVerticalValue(scrollView.adjustedContentInset)
                } else {
                    result = 0
                }
            } else {
                result = subview.sizeThatFits(self.bounds.size).height
                result = result > 0 ? result : subview.bounds.height
            }
        }
        return max(result, 0)
    }
    
    private func addSubview(_ newView: UIView?, oldView: UIView?) {
        if oldView != newView {
            oldView?.removeFromSuperview()
            
            if let newView = newView {
                newView.removeFromSuperview()
                self.containerView.addSubview(newView)
            }
            
            self.setNeedsLayout()
        }
        
        let oldScrollView = (oldView as? NestedScrollViewScrollSubview)?.preferredScrollView(in: self)
        let newScrollView = (newView as? NestedScrollViewScrollSubview)?.preferredScrollView(in: self)
        if oldScrollView != newScrollView {
            oldScrollView?.js_nestedScrollListener = nil
        }
        if let newScrollView = newScrollView {
            NestedScrollManager.handleScrollView(newScrollView, in: self, didScrollHandler: self.scrollSubviewDidScrollHandler)
        }
        
        /// floatingView
        if let floatingView = self.floatingView, floatingView != self.containerView.subviews.last {
            self.containerView.bringSubviewToFront(floatingView)
        }
    }
    
    private func assertScrollView(_ scrollView: UIScrollView) {
        let message = "estimated特性会导致contenSize计算不准确, 产生跳动的问题"
        if let tableView = scrollView as? UITableView {
            assert(tableView.estimatedRowHeight == 0 && tableView.estimatedSectionHeaderHeight == 0 && tableView.estimatedSectionFooterHeight == 0, message)
        }
        if let collectionView = scrollView as? UICollectionView, let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            assert(flowLayout.estimatedItemSize == CGSize.zero, message)
        }
    }
    
    private func updateScrollSettings() {
        if !self.showsVerticalScrollIndicator {
            self.showsVerticalScrollIndicator = true
        }
        if let headerScrollView = self.headerScrollView {
            self.assertScrollView(headerScrollView)
            
            if headerScrollView.showsVerticalScrollIndicator {
                headerScrollView.showsVerticalScrollIndicator = false
            }
            if headerScrollView.scrollsToTop {
                headerScrollView.scrollsToTop = false
            }
            if headerScrollView.contentInsetAdjustmentBehavior != .never {
                headerScrollView.contentInsetAdjustmentBehavior = .never
            }
        }
        if let contentScrollView = self.contentScrollView {
            self.assertScrollView(contentScrollView)
            
            if contentScrollView.showsVerticalScrollIndicator {
                contentScrollView.showsVerticalScrollIndicator = false
            }
            if contentScrollView.scrollsToTop {
                contentScrollView.scrollsToTop = false
            }
            if contentScrollView.contentInsetAdjustmentBehavior != .never {
                contentScrollView.contentInsetAdjustmentBehavior = .never
            }
        }
    }
    
    private func updateContentSize() -> Bool {
        let headerContentHeight = self.headerViewContentHeight
        let contentViewContentHeight = self.contentViewContentHeight
        let middleHeight = self.middleView?.bounds.height ?? 0
        let floatingHeight = self.floatingView?.bounds.height ?? 0
        
        let contentSize = CGSize(width: self.bounds.width, height: headerContentHeight + middleHeight + floatingHeight + contentViewContentHeight)
        if self.contentSize != contentSize {
            self.isUpdatingContentSize = true
            self.contentSize = contentSize
            self.isUpdatingContentSize = false
            return true
        } else {
            return false
        }
    }
    
    private func handleDidScoll() {
        let containerView = self.containerView
        
        let headerHeight = self.headerView?.bounds.height ?? 0
        let headerViewContentHeight = self.headerScrollView != nil ? self.headerViewContentHeight : headerHeight
        let headerLessThanScreen = headerViewContentHeight < self.bounds.height
        
        let contentHeight = self.contentView?.bounds.height ?? 0
        let contentLessThanScreen = contentHeight < self.bounds.height
        
        let middleHeight = self.middleView?.bounds.height ?? 0
        let floatingHeight = self.floatingView?.bounds.height ?? 0
        
        let prefixContentHeight = headerViewContentHeight + middleHeight + floatingHeight
        let maximumOffsetY = headerViewContentHeight - headerHeight
        let contentOffsetY = self.contentOffset.y
        if contentOffsetY <= maximumOffsetY {
            /// container
            if contentOffsetY <= self.js_minimumContentOffset.y {
                if headerLessThanScreen {
                    self.updateView(containerView, translationY: 0)
                } else {
                    self.updateView(containerView, translationY: contentOffsetY - self.js_minimumContentOffset.y)
                }
            } else if contentOffsetY > self.js_minimumContentOffset.y && contentOffsetY <= 0 {
                self.updateView(containerView, translationY: 0)
            } else {
                self.updateView(containerView, translationY: contentOffsetY)
            }
            
            /// header
            if let headerScrollView = self.headerScrollView {
                var headerMinimumContentOffset = headerScrollView.js_minimumContentOffset
                if contentOffsetY <= self.js_minimumContentOffset.y {
                    if headerLessThanScreen {
                        self.updateScrollView(headerScrollView, contentOffset: headerMinimumContentOffset)
                    } else {
                        headerMinimumContentOffset.y += contentOffsetY
                        headerMinimumContentOffset.y -= self.js_minimumContentOffset.y
                        self.updateScrollView(headerScrollView, contentOffset: headerMinimumContentOffset)
                    }
                } else if contentOffsetY > self.js_minimumContentOffset.y && contentOffsetY <= 0 {
                    self.updateScrollView(headerScrollView, contentOffset: headerMinimumContentOffset)
                } else {
                    headerMinimumContentOffset.y += contentOffsetY
                    self.updateScrollView(headerScrollView, contentOffset: headerMinimumContentOffset)
                }
            }
            
            /// content
            if let contentScrollView = self.contentScrollView {
                self.updateScrollView(contentScrollView, contentOffset: contentScrollView.js_minimumContentOffset)
            }
        } else {
            if contentOffsetY <= prefixContentHeight || contentLessThanScreen {
                /// container
                self.updateView(containerView, translationY: maximumOffsetY)
                
                /// header
                if let headerScrollView = self.headerScrollView {
                    self.updateScrollView(headerScrollView, contentOffset: headerScrollView.js_maximumContentOffset)
                }
                
                /// content
                if let contentScrollView = self.contentScrollView {
                    self.updateScrollView(contentScrollView, contentOffset: contentScrollView.js_minimumContentOffset)
                }
            } else if contentOffsetY < self.js_maximumContentOffset.y - self.adjustedContentInset.bottom {
                /// container
                self.updateView(containerView, translationY: maximumOffsetY + (contentOffsetY - prefixContentHeight))
                
                /// header
                if let headerScrollView = self.headerScrollView {
                    self.updateScrollView(headerScrollView, contentOffset: headerScrollView.js_maximumContentOffset)
                }
                
                /// content
                if let contentScrollView = self.contentScrollView {
                    var contentScrollOffset = contentScrollView.js_minimumContentOffset
                    contentScrollOffset.y += contentOffsetY
                    contentScrollOffset.y -= prefixContentHeight
                    self.updateScrollView(contentScrollView, contentOffset: contentScrollOffset)
                }
            } else if contentOffsetY < self.js_maximumContentOffset.y {
                /// container
                self.updateView(containerView, translationY: maximumOffsetY + self.js_maximumContentOffset.y - prefixContentHeight - self.adjustedContentInset.bottom)
                
                /// header
                if let headerScrollView = self.headerScrollView {
                    self.updateScrollView(headerScrollView, contentOffset: headerScrollView.js_maximumContentOffset)
                }
                
                /// content
                if let contentScrollView = self.contentScrollView {
                    self.updateScrollView(contentScrollView, contentOffset: contentScrollView.js_maximumContentOffset)
                }
            } else {
                /// container
                if self.headerScrollView != nil || self.contentScrollView != nil {
                    self.updateView(containerView, translationY: maximumOffsetY + contentOffsetY - prefixContentHeight - self.adjustedContentInset.bottom)
                } else {
                    self.updateView(containerView, translationY: 0)
                }
                
                /// header
                if let headerScrollView = self.headerScrollView {
                    self.updateScrollView(headerScrollView, contentOffset: headerScrollView.js_maximumContentOffset)
                }
                
                /// content
                if let contentScrollView = self.contentScrollView {
                    var contentScrollOffset = contentScrollView.js_minimumContentOffset
                    contentScrollOffset.y += contentOffsetY
                    contentScrollOffset.y -= prefixContentHeight
                    contentScrollOffset.y -= self.adjustedContentInset.bottom
                    self.updateScrollView(contentScrollView, contentOffset: contentScrollOffset)
                }
            }
        }
        
        /// floating
        if let floatingView = self.floatingView {
            let finallyFloatingHeight = floatingHeight + self.floatingOffset
            let maximumFloatingOffsetY = prefixContentHeight - finallyFloatingHeight
            if contentOffsetY < maximumFloatingOffsetY {
                self.updateView(floatingView, translationY: 0)
            } else if contentOffsetY >= maximumFloatingOffsetY && (contentOffsetY <= prefixContentHeight || contentLessThanScreen) {
                self.updateView(floatingView, translationY: finallyFloatingHeight + (contentOffsetY - prefixContentHeight))
            } else if contentOffsetY < self.js_maximumContentOffset.y - self.adjustedContentInset.bottom {
                self.updateView(floatingView, translationY: finallyFloatingHeight)
            } else if contentOffsetY < self.js_maximumContentOffset.y {
                self.updateView(floatingView, translationY: finallyFloatingHeight + contentOffsetY - self.js_maximumContentOffset.y + self.adjustedContentInset.bottom)
            } else {
                self.updateView(floatingView, translationY: finallyFloatingHeight + self.adjustedContentInset.bottom)
            }
        }
    }
    
    private func updateScrollView(_ scrollView: UIScrollView, contentOffset: CGPoint) {
        if scrollView.contentOffset != contentOffset {
            scrollView.js_nestedScrollListener?.isUpdatingContentOffset = true
            scrollView.contentOffset = contentOffset
            scrollView.js_nestedScrollListener?.isUpdatingContentOffset = false
        }
    }
    
    private func updateView(_ view: UIView, translationY: CGFloat) {
        if view.transform.ty != translationY {
            view.transform = CGAffineTransform(translationX: view.transform.tx, y: translationY)
        }
    }
    
}

extension NestedScrollView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer, let otherGestureRecognizer = otherGestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        let uiSheetName = "_UISheet" + "Interaction" + "Background" + "DismissRecognizer"
        guard gestureRecognizer.name != uiSheetName && otherGestureRecognizer.name != uiSheetName else {
            return false
        }
        /// 两者的手势均为「垂直|」滑动
        let isVerticalScroll = {
            let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view)
            let otherVelocity = otherGestureRecognizer.velocity(in: otherGestureRecognizer.view)
            return abs(velocity.x) <= abs(velocity.y) && abs(otherVelocity.x) <= abs(otherVelocity.y)
        }()
        /// otherGestureRecognizer也是可以「垂直|」滑动的
        let canVerticalScrollForOther = {
            guard let otherScrollView = otherGestureRecognizer.view as? UIScrollView else {
                /// 不是UIScrollView时必须返回true，保证手势响应正确
                return true
            }
            guard otherScrollView.isScrollEnabled else {
                return false
            }
            if let collectionView = otherScrollView as? UICollectionView, let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.scrollDirection == .vertical
            } else if otherScrollView is UITableView {
                return true
            } else if otherScrollView.alwaysBounceVertical && !otherScrollView.alwaysBounceHorizontal {
                return true
            } else {
                return otherScrollView.contentSize.width <= otherScrollView.bounds.width
            }
        }()
        /// 综合判断下
        if isVerticalScroll && canVerticalScrollForOther {
            return true
        } else {
            return false
        }
    }
    
}

extension NestedScrollView: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !self.isUpdatingContentSize {
            self.handleDidScoll()
        }
        
        self.delegateProxy.scrollViewDelegateTarget?.scrollViewDidScroll?(scrollView)
    }
    
}

extension NestedScrollView {
    
    public override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        guard !super.accessibilityScroll(direction) else {
            return true
        }
        
        let contentOffset = { () -> CGPoint? in
            let offset = self.bounds.height / 1.5
            switch direction {
            case .up:
                return CGPoint(x: self.contentOffset.x, y: self.contentOffset.y - offset)
            case .down:
                return CGPoint(x: self.contentOffset.x, y: self.contentOffset.y + offset)
            default:
                return nil
            }
        }()
        guard let contentOffset = contentOffset else {
            return false
        }
        self.js_scrollTo(contentOffset, animated: true)
        UIAccessibility.post(notification: .pageScrolled, argument: nil)
        return true
    }
    
}

private class NestedScrollViewDelegateProxy: JSCoreWeakProxy, UIScrollViewDelegate {
    
    weak var interceptor: NestedScrollView?
    
    weak var scrollViewDelegateTarget: UIScrollViewDelegate? {
        get {
            return self.target as? UIScrollViewDelegate
        }
        set {
            self.target = newValue
        }
    }
    
    init(interceptor: NestedScrollView) {
        super.init(target: nil)
        self.interceptor = interceptor
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        if self.interceptor != nil, aSelector == #selector(UIScrollViewDelegate.scrollViewDidScroll(_:)) {
            return true
        }
        return super.responds(to: aSelector)
    }
    
    override func forwardingTarget(for aSelector: Selector) -> Any {
        if let interceptor = self.interceptor, aSelector == #selector(UIScrollViewDelegate.scrollViewDidScroll(_:)) {
            return interceptor
        }
        return super.forwardingTarget(for: aSelector)
    }
    
}
