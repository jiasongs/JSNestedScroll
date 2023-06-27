//
//  NestedScrollManager.swift
//  JSNestedScroll
//
//  Created by jiasong on 2023/6/27.
//

import UIKit

typealias NestedScrollDidScrollHandler = (UIScrollView) -> Void

internal class NestedScrollManager {
    
    static func handleScrollView(
        _ scrollView: UIScrollView,
        in nestedScrollView: NestedScrollView,
        didScrollHandler: @escaping NestedScrollDidScrollHandler
    ) {
        let initializeHanlder = {
            let listener = NestedScrollListener()
            listener.bindingScrollView = scrollView
            scrollView.js_nestedScrollListener = listener
            return listener
        }
        let scrollListener = scrollView.js_nestedScrollListener ?? initializeHanlder()
        guard scrollListener.nestedScrollView != nestedScrollView else {
            return
        }
        
        scrollListener.nestedScrollView = nestedScrollView
        scrollListener.didScrollHandler = didScrollHandler
        
        if scrollView.superview != nil {
            scrollListener.addListener()
        } else {
            scrollListener.removeListener()
        }
        
        _JSNestedScrollModifier.hook(scrollView, layoutSubviews: { (scrollView, isExecuted) in
            scrollView.js_nestedScrollListener?.isLayoutingSubviews = !isExecuted
        }, willMoveToSuperview: { (scrollView, newSuperview) in
            if newSuperview != nil {
                scrollView.js_nestedScrollListener?.addListener()
            } else {
                scrollView.js_nestedScrollListener?.removeListener()
            }
        }, didScroll: { (scrollView) in
            scrollView.js_nestedScrollListener?.callDidScrollHandler()
        }, adjustedContentInset: { (scrollView) in
            scrollView.js_nestedScrollListener?.nestedScrollView?.reload()
        }, adjustContentOffset: { (scrollView, isExecuted) in
            scrollView.js_nestedScrollListener?.isAdjustingContentOffset = !isExecuted
        }, setContentOffset: { (scrollView, offset, animated) in
            scrollView.js_nestedScrollListener?.callSetContentOffset(offset, animated: animated)
        })
    }
    
}

extension UIScrollView {
    
    struct AssociatedKeys {
        static var scrollListener = "js_nestedScrollListener"
    }
    
    internal var js_nestedScrollListener: NestedScrollListener? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.scrollListener) as? NestedScrollListener
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.scrollListener, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}

internal class NestedScrollListener {
    weak var bindingScrollView: UIScrollView?
    weak var nestedScrollView: NestedScrollView?
    
    lazy var isAlreadyMonitor: Bool = false
    lazy var isUpdatingContentOffset: Bool = false
    lazy var isAdjustingContentOffset: Bool = false
    lazy var isLayoutingSubviews: Bool = false
    var didScrollHandler: NestedScrollDidScrollHandler?
    
    private var observations: [NSKeyValueObservation] = []
    
    func addListener() {
        guard let bindingScrollView = self.bindingScrollView else {
            return
        }
        guard !self.isAlreadyMonitor else {
            return
        }
        self.isAlreadyMonitor = true
        
        let changeHandler = { (scrollView: UIScrollView, equatable: @autoclosure () -> Bool) in
            guard let scrollListener = scrollView.js_nestedScrollListener else {
                return
            }
            guard !equatable() else {
                return
            }
            scrollListener.nestedScrollView?.reload()
        }
        self.observations.append(
            bindingScrollView.observe(\.contentSize, options: [.old, .new], changeHandler: { (scrollView, value) in
                changeHandler(scrollView, value.oldValue == value.newValue)
            })
        )
        self.observations.append(
            bindingScrollView.observe(\.contentInset, options: [.old, .new], changeHandler: { (scrollView, value) in
                changeHandler(scrollView, value.oldValue == value.newValue)
            })
        )
    }
    
    func removeListener() {
        guard self.bindingScrollView != nil else {
            return
        }
        guard self.isAlreadyMonitor else {
            return
        }
        self.isAlreadyMonitor = false
        
        self.observations.removeAll { observation in
            observation.invalidate()
            return true
        }
    }
    
    func callDidScrollHandler() {
        guard let bindingScrollView = self.bindingScrollView else {
            return
        }
        guard !self.isUpdatingContentOffset && !self.isLayoutingSubviews else {
            return
        }
        
        self.didScrollHandler?(bindingScrollView)
    }
    
    func callSetContentOffset(_ offset: CGPoint, animated: Bool) {
        guard let bindingScrollView = self.bindingScrollView else {
            return
        }
        
        guard !self.isUpdatingContentOffset && !self.isAdjustingContentOffset else {
            return
        }
        
        self.nestedScrollView?.scrollTo(bindingScrollView, with: offset, animated: animated)
    }
}
