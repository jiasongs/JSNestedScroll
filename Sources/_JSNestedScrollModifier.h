//
//  _JSNestedScrollModifier.h
//  JSNestedScroll
//
//  Created by jiasong on 2022/6/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface _JSNestedScrollModifier : NSObject

+ (void)hookScrollView:(__kindof UIScrollView *)scrollView
        layoutSubviews:(void(^)(UIScrollView *scrollView, BOOL isExecuted))layoutSubviews
   willMoveToSuperview:(void(^)(UIScrollView *scrollView, UIView * _Nullable newSuperview))willMoveToSuperview
             didScroll:(void(^)(UIScrollView *scrollView))didScroll
  adjustedContentInset:(void(^)(UIScrollView *scrollView))adjustedContentInset
   adjustContentOffset:(void(^)(UIScrollView *scrollView, BOOL isExecuted))adjustContentOffset
      setContentOffset:(void(^)(UIScrollView *scrollView, CGPoint offset, BOOL animated))setContentOffset;

@end

NS_ASSUME_NONNULL_END
