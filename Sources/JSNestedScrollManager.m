//
//  JSNestedScrollManager.m
//  JSNestedScroll
//
//  Created by jiasong on 2022/6/1.
//

#import "JSNestedScrollManager.h"
#import "JSCoreHelper.h"
#import "JSCoreMacroMethod.h"
#import "JSCoreMacroVariable.h"
#if __has_include(<JSNestedScroll/JSNestedScroll-Swift.h>)
#import <JSNestedScroll/JSNestedScroll-Swift.h>
#else
#import "JSNestedScroll-Swift.h"
#endif

@implementation JSNestedScrollManager

+ (void)handleScrollView:(__kindof UIScrollView *)scrollView
      inNestedScrollView:(JSNestedScrollView *)nestedScrollView
        didScrollHandler:(JSNestedScrollDidScrollHandler)didScrollHandler {
    JSNestedScrollListener *scrollListener = scrollView.js_nestedScrollListener;
    if (!scrollListener) {
        scrollListener = [[JSNestedScrollListener alloc] init];
        scrollListener.bindingScrollView = scrollView;
        scrollView.js_nestedScrollListener = scrollListener;
    }
    if (scrollListener.nestedScrollView == nestedScrollView) {
        return;
    }
    scrollListener.nestedScrollView = nestedScrollView;
    scrollListener.didScrollHandler = didScrollHandler;
    
    if (scrollView.superview) {
        [scrollListener addListener];
    } else {
        [scrollListener removeListener];
    }
    
    Class class = scrollView.class;
    [JSCoreHelper executeOnceWithIdentifier:[NSString stringWithFormat:@"JSNestedScrollManager %@", NSStringFromClass(class)]
                                 usingBlock:^{
        JSRuntimeOverrideImplementation(class, @selector(willMoveToSuperview:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIScrollView *selfObject, UIView *newSuperview) {
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIView *);
                originSelectorIMP = (void (*)(id, SEL, UIView *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, newSuperview);
                
                if (![selfObject isMemberOfClass:class]) {
                    return;
                }
                
                if (newSuperview) {
                    [selfObject.js_nestedScrollListener addListener];
                } else {
                    [selfObject.js_nestedScrollListener removeListener];
                }
            };
        });
        NSString *didScroll = [NSString stringWithFormat:@"_%@%@%@", @"notify", @"Did", @"Scroll"];
        JSRuntimeOverrideImplementation(class, NSSelectorFromString(didScroll), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIScrollView *selfObject) {
                
                // call super
                void (*originSelectorIMP)(id, SEL);
                originSelectorIMP = (void (*)(id, SEL))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD);
                
                if (![selfObject isMemberOfClass:class]) {
                    return;
                }
                
                [selfObject.js_nestedScrollListener callDidScrollHandler];
            };
        });
        JSRuntimeOverrideImplementation(class, @selector(adjustedContentInsetDidChange), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIScrollView *selfObject) {
                
                // call super
                void (*originSelectorIMP)(id, SEL);
                originSelectorIMP = (void (*)(id, SEL))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD);
                
                if (![selfObject isMemberOfClass:class]) {
                    return;
                }
                
                [selfObject.js_nestedScrollListener.nestedScrollView reload];
            };
        });
        JSRuntimeOverrideImplementation(class, @selector(layoutSubviews), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIScrollView *selfObject) {
                
                selfObject.js_nestedScrollListener.isLayoutingSubviews = YES;
                
                // call super
                void (*originSelectorIMP)(id, SEL);
                originSelectorIMP = (void (*)(id, SEL))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD);
                
                selfObject.js_nestedScrollListener.isLayoutingSubviews = NO;
            };
        });
        NSString *adjustContentOffset = [NSString stringWithFormat:@"_%@%@%@", @"adjust", @"ContentOffset", @"IfNecessary"];
        JSRuntimeOverrideImplementation(class, NSSelectorFromString(adjustContentOffset), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIScrollView *selfObject) {
                
                selfObject.js_nestedScrollListener.isAdjustingContentOffset = YES;
                
                // call super
                void (*originSelectorIMP)(id, SEL);
                originSelectorIMP = (void (*)(id, SEL))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD);
                
                selfObject.js_nestedScrollListener.isAdjustingContentOffset = NO;
            };
        });
        JSRuntimeOverrideImplementation(class, @selector(setContentOffset:animated:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIScrollView *selfObject, CGPoint contentOffset, BOOL animated) {
                
                // call super
                void (*originSelectorIMP)(id, SEL, CGPoint, BOOL);
                originSelectorIMP = (void (*)(id, SEL, CGPoint, BOOL))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, contentOffset, animated);
                
                if (![selfObject isMemberOfClass:class]) {
                    return;
                }
                
                [selfObject.js_nestedScrollListener callSetContentOffset:contentOffset animated:animated];
            };
        });
    }];
}

@end

@implementation UIScrollView (JSNestedScrollManager)

JSSynthesizeIdStrongProperty(js_nestedScrollListener, setJs_nestedScrollListener)

@end

@implementation JSNestedScrollListener

- (void)addListener {
    if (!self.bindingScrollView) {
        return;
    }
    
    if (self.isAlreadyMonitor) {
        return;
    }
    self.isAlreadyMonitor = YES;
    
    [self.bindingScrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    [self.bindingScrollView addObserver:self forKeyPath:@"contentInset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
}

- (void)removeListener {
    if (!self.bindingScrollView) {
        return;
    }
    
    if (!self.isAlreadyMonitor) {
        return;
    }
    self.isAlreadyMonitor = NO;
    
    [self.bindingScrollView removeObserver:self forKeyPath:@"contentSize"];
    [self.bindingScrollView removeObserver:self forKeyPath:@"contentInset"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (![object isKindOfClass:UIScrollView.class]) {
        return;
    }
    
    UIScrollView *scrollView = object;
    JSNestedScrollListener *scrollListener = scrollView.js_nestedScrollListener;
    if (!scrollListener) {
        return;
    }
    
    if ([keyPath isEqualToString:@"contentSize"]) {
        CGSize previousContentSize = [[change objectForKey:NSKeyValueChangeOldKey] CGSizeValue];
        CGSize contentSize = [[change objectForKey:NSKeyValueChangeNewKey] CGSizeValue];
        if (!CGSizeEqualToSize(previousContentSize, contentSize)) {
            [scrollListener.nestedScrollView reload];
        }
    } else if ([keyPath isEqualToString:@"contentInset"]) {
        UIEdgeInsets previousContentInset = [[change objectForKey:NSKeyValueChangeOldKey] UIEdgeInsetsValue];
        UIEdgeInsets contentInset = [[change objectForKey:NSKeyValueChangeNewKey] UIEdgeInsetsValue];
        if (!UIEdgeInsetsEqualToEdgeInsets(previousContentInset, contentInset)) {
            [scrollListener.nestedScrollView reload];
        }
    }
}

- (void)callDidScrollHandler {
    if (!self.bindingScrollView) {
        return;
    }
    
    if (self.isUpdatingContentOffset || self.isLayoutingSubviews) {
        return;
    }
    
    if (self.didScrollHandler) {
        self.didScrollHandler(self.bindingScrollView);
    }
}

- (void)callSetContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    if (!self.bindingScrollView) {
        return;
    }
    
    if (self.isUpdatingContentOffset || self.isAdjustingContentOffset) {
        return;
    }
    
    [self.nestedScrollView scrollToView:self.bindingScrollView withOffset:contentOffset animated:animated];
}

@end
