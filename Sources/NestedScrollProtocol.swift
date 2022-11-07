//
//  NestedScrollProtocol.swift
//  JSNestedScroll
//
//  Created by jiasong on 2022/6/1.
//

@objc(JSNestedScrollViewSupplementarySubview)
public protocol NestedScrollViewSupplementarySubview {
    
    @objc(preferredHeightInNestedScrollView:)
    optional func preferredHeight(in nestedScrollView: NestedScrollView) -> CGFloat
    
}

@objc(JSNestedScrollViewScrollSubview)
public protocol NestedScrollViewScrollSubview: NestedScrollViewSupplementarySubview {
    
    @objc(preferredScrollViewInNestedScrollView:)
    optional func preferredScrollView(in nestedScrollView: NestedScrollView) -> UIScrollView?
    
}
