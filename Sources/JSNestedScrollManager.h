//
//  JSNestedScrollManager.h
//  JSNestedScroll
//
//  Created by jiasong on 2022/6/1.
//

#import <Foundation/Foundation.h>

@class JSNestedScrollView;
@class JSNestedScrollListener;

NS_ASSUME_NONNULL_BEGIN

typedef void (^JSNestedScrollDidScrollHandler)(__kindof UIScrollView *scrollView);

@interface JSNestedScrollManager : NSObject

+ (void)handleScrollView:(__kindof UIScrollView *)scrollView
      inNestedScrollView:(JSNestedScrollView *)nestedScrollView
        didScrollHandler:(JSNestedScrollDidScrollHandler)didScrollHandler;

@end

@interface UIScrollView (JSNestedScrollManager)

@property (nullable, nonatomic, strong) JSNestedScrollListener *js_nestedScrollListener;

@end

@interface JSNestedScrollListener : NSObject

@property (nullable, nonatomic, weak) __kindof UIScrollView *bindingScrollView;

@property (nullable, nonatomic, weak) JSNestedScrollView *nestedScrollView;
@property (nonatomic, assign) BOOL isAlreadyMonitor;
@property (nonatomic, assign) BOOL isUpdatingContentOffset;
@property (nonatomic, assign) BOOL isAdjustingContentOffset;
@property (nonatomic, assign) BOOL isLayoutingSubviews;
@property (nullable, nonatomic, copy) JSNestedScrollDidScrollHandler didScrollHandler;

- (void)addListener;
- (void)removeListener;

- (void)callDidScrollHandler;
- (void)callSetContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
