//
//  _JSNestedScrollModifier.m
//  JSNestedScroll
//
//  Created by jiasong on 2022/6/1.
//

#import "_JSNestedScrollModifier.h"
#import "JSCoreHelper.h"
#import "JSCoreMacroMethod.h"

@implementation _JSNestedScrollModifier

+ (void)onceHookScrollView:(__kindof UIScrollView *)scrollView
            layoutSubviews:(void(^)(UIScrollView *scrollView, BOOL isExecuted))layoutSubviews
       willMoveToSuperview:(void(^)(UIScrollView *scrollView, UIView * _Nullable newSuperview))willMoveToSuperview
                 didScroll:(void(^)(UIScrollView *scrollView))didScroll
      adjustedContentInset:(void(^)(UIScrollView *scrollView))adjustedContentInset
       adjustContentOffset:(void(^)(UIScrollView *scrollView, BOOL isExecuted))adjustContentOffset
          setContentOffset:(void(^)(UIScrollView *scrollView, CGPoint offset, BOOL animated))setContentOffset {
    Class class = scrollView.class;
    [JSCoreHelper executeOnceWithIdentifier:[NSString stringWithFormat:@"_JSNestedScrollModifier %@", NSStringFromClass(class)]
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
                
                willMoveToSuperview(selfObject, newSuperview);
            };
        });
        NSString *didScrollName = [NSString stringWithFormat:@"_%@%@%@", @"notify", @"Did", @"Scroll"];
        JSRuntimeOverrideImplementation(class, NSSelectorFromString(didScrollName), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIScrollView *selfObject) {
                
                // call super
                void (*originSelectorIMP)(id, SEL);
                originSelectorIMP = (void (*)(id, SEL))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD);
                
                if (![selfObject isMemberOfClass:class]) {
                    return;
                }
                
                didScroll(selfObject);
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
                
                adjustedContentInset(selfObject);
            };
        });
        JSRuntimeOverrideImplementation(class, @selector(layoutSubviews), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIScrollView *selfObject) {
                
                layoutSubviews(selfObject, NO);
                
                // call super
                void (*originSelectorIMP)(id, SEL);
                originSelectorIMP = (void (*)(id, SEL))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD);
                
                layoutSubviews(selfObject, YES);
            };
        });
        NSString *adjustContentOffsetName = [NSString stringWithFormat:@"_%@%@%@", @"adjust", @"ContentOffset", @"IfNecessary"];
        JSRuntimeOverrideImplementation(class, NSSelectorFromString(adjustContentOffsetName), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIScrollView *selfObject) {
                
                adjustContentOffset(selfObject, NO);
                
                // call super
                void (*originSelectorIMP)(id, SEL);
                originSelectorIMP = (void (*)(id, SEL))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD);
                
                adjustContentOffset(selfObject, YES);
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
                
                setContentOffset(selfObject, contentOffset, animated);
            };
        });
    }];
}

@end
