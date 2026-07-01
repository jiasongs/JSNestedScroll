//
//  NestedScrollMediator.swift
//  JSNestedScroll
//
//  Created by jiasong on 2023/6/27.
//

import UIKit
import JSCoreKit

internal typealias NestedScrollDidScrollHandler = (UIScrollView) -> Void

internal struct NestedScrollMediator {
    
    static func handleScrollView(
        _ scrollView: UIScrollView,
        in nestedScrollView: NestedScrollView,
        didScrollHandler: @escaping NestedScrollDidScrollHandler
    ) {
        let scrollListener = {
            if let listener = scrollView.js_nestedScrollListener {
                return listener
            } else {
                let listener = NestedScrollListener(scrollView: scrollView)
                scrollView.js_nestedScrollListener = listener
                return listener
            }
        }()
        guard scrollListener.nestedScrollView != nestedScrollView else {
            return
        }
        scrollListener.setNestedScrollView(nestedScrollView, didScrollHandler: didScrollHandler)
        
        nestedScrollView.updateLayout()
        
        guard !_JSNestedScrollViewMediator.shared.isHooked else {
            return
        }
        _JSNestedScrollViewMediator.shared.onceHook(
            adjustContentOffset: {
                $0.js_nestedScrollListener?.isAdjustingContentOffset = !$1
            },
            setContentOffset: {
                $0.js_nestedScrollListener?.callSetContentOffset($1, animated: $2)
            }
        )
    }
    
    static func resetScrollView(_ scrollView: UIScrollView) {
        scrollView.js_nestedScrollListener?.setNestedScrollView(nil, didScrollHandler: nil)
    }
    
    static func setContentOffset(_ contentOffset: CGPoint, for scrollView: UIScrollView) {
        scrollView.js_nestedScrollListener?.isUpdatingContentOffset = true
        scrollView.contentOffset = contentOffset
        scrollView.js_nestedScrollListener?.isUpdatingContentOffset = false
    }
    
    private init() {
        
    }
    
}

extension UIScrollView {
    
    fileprivate var js_nestedScrollListener: NestedScrollListener? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.scrollListener) as? NestedScrollListener
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.scrollListener, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private enum AssociatedKeys {
        static var scrollListener: UInt8 = 0
    }
    
}

private final class NestedScrollListener {
    
    fileprivate var isAdjustingContentOffset: Bool = false
    fileprivate var isUpdatingContentOffset: Bool = false
    
    private weak var bindingScrollView: UIScrollView?
    private(set) weak var nestedScrollView: NestedScrollView?
    private var didScrollHandler: NestedScrollDidScrollHandler?
    
    private var isAlreadyMonitor: Bool = false
    private var observations: [NSKeyValueObservation] = []
    private var didScrollCancellable: JSNotificationCancellable?
    private var adjustedContentInsetCancellable: JSNotificationCancellable?
    
    fileprivate init(scrollView: UIScrollView) {
        self.bindingScrollView = scrollView
        
        self.addListener()
    }
    
    deinit {
        self.removeListener()
    }
    
    fileprivate func setNestedScrollView(_ nestedScrollView: NestedScrollView?, didScrollHandler: NestedScrollDidScrollHandler?) {
        self.nestedScrollView = nestedScrollView
        self.didScrollHandler = didScrollHandler
    }
    
    fileprivate func callSetContentOffset(_ offset: CGPoint, animated: Bool) {
        guard let bindingScrollView = self.bindingScrollView, let nestedScrollView = self.nestedScrollView else {
            return
        }
        guard !self.isUpdatingContentOffset && !self.isAdjustingContentOffset else {
            return
        }
        nestedScrollView.scrollTo(bindingScrollView, with: offset, animated: animated)
    }
    
    private func callDidScrollHandler() {
        guard let bindingScrollView = self.bindingScrollView, self.nestedScrollView != nil else {
            return
        }
        guard !self.isUpdatingContentOffset else {
            return
        }
        self.didScrollHandler?(bindingScrollView)
    }
    
    private func addListener() {
        guard let bindingScrollView = self.bindingScrollView else {
            assertionFailure()
            return
        }
        guard !self.isAlreadyMonitor else {
            return
        }
        self.isAlreadyMonitor = true
        
        let changeHandler = { (scrollView: UIScrollView, equatable: @autoclosure () -> Bool) in
            guard let scrollListener = scrollView.js_nestedScrollListener, let nestedScrollView = scrollListener.nestedScrollView else {
                return
            }
            guard !equatable() else {
                return
            }
            nestedScrollView.updateLayout()
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
        self.didScrollCancellable = bindingScrollView.js_addDidScrollSubscriber {
            guard let scrollListener = $0.js_nestedScrollListener else {
                return
            }
            scrollListener.callDidScrollHandler()
        }
        self.adjustedContentInsetCancellable = bindingScrollView.js_addAdjustedContentInsetSubscriber {
            guard let scrollListener = $0.js_nestedScrollListener, let nestedScrollView = scrollListener.nestedScrollView else {
                return
            }
            nestedScrollView.updateLayout()
        }
    }
    
    private func removeListener() {
        guard self.isAlreadyMonitor else {
            return
        }
        self.isAlreadyMonitor = false
        
        self.observations.removeAll {
            $0.invalidate()
            return true
        }
        self.didScrollCancellable?.cancel()
        self.didScrollCancellable = nil
        self.adjustedContentInsetCancellable?.cancel()
        self.adjustedContentInsetCancellable = nil
    }
    
}
