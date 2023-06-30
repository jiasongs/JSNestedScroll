//
//  NestedScroll.swift
//  JSNestedScroll
//
//  Created by jiasong on 2022/6/1.
//

import UIKit
import WebKit

public protocol NestedScrollViewSupplementarySubview: UIView {
    
    func preferredHeight(in nestedScrollView: NestedScrollView) -> CGFloat
    
}

public protocol NestedScrollViewScrollSubview: NestedScrollViewSupplementarySubview {
    
    func preferredScrollView(in nestedScrollView: NestedScrollView) -> UIScrollView?
    
}

extension NestedScrollViewSupplementarySubview {
    
    public func preferredHeight(in nestedScrollView: NestedScrollView) -> CGFloat {
        return NestedScrollView.automaticDimension
    }
    
}

extension NestedScrollViewScrollSubview where Self: UIScrollView {
    
    public func preferredScrollView(in nestedScrollView: NestedScrollView) -> UIScrollView? {
        return self
    }
    
}

extension NestedScrollViewScrollSubview where Self: WKWebView {
    
    public func preferredScrollView(in nestedScrollView: NestedScrollView) -> UIScrollView? {
        return self.scrollView
    }
    
}
