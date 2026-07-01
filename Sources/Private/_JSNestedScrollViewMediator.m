//
//  _JSNestedScrollViewMediator.m
//  JSNestedScroll
//
//  Created by jiasong on 2022/6/1.
//

#import "_JSNestedScrollViewMediator.h"
#import <WebKit/WKWebView.h>
#import "JSCoreMacroMethod.h"
#import "JSCoreMacroVariable.h"

@interface UIScrollView (_JSNestedScrollViewMediator)

@property (nonatomic, assign) BOOL js_isUpdatingContentOffset;

@end

@implementation UIScrollView (_JSNestedScrollViewMediator)

JSSynthesizeBOOLProperty(js_isUpdatingContentOffset, setJs_isUpdatingContentOffset)

@end

@interface _JSNestedScrollViewMediator ()

@property (nonatomic, assign, readwrite) BOOL isHooked;

@end

@implementation _JSNestedScrollViewMediator

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if DEBUG
        if (@available(iOS 27.0, *)) {
            SEL scrollToSel = NSSelectorFromString([NSString stringWithFormat:@"_%@%@%@:%@:%@:%@%@:", @"scrollTo", @"ContentScroll", @"Position", @"scrollOrigin", @"animated", @"interrupt", @"Animation"]);
            NSCAssert([WKWebView instancesRespondToSelector:scrollToSel], @"");
            Method scrollToMethod = class_getInstanceMethod(WKWebView.class, scrollToSel);
            NSString *scrollToMethodEncoding = [NSString stringWithUTF8String:method_getTypeEncoding(scrollToMethod)];
            NSCAssert([scrollToMethodEncoding isEqualToString:@"v40@0:8{FloatPoint=ff}16{IntPoint=ii}24B32B36"], @"");
        }
#endif
    });
}

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static _JSNestedScrollViewMediator *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self shared];
}

- (void)onceHookAdjustContentOffset:(void(^)(UIScrollView *scrollView, BOOL isExecuted))adjustContentOffset
                   setContentOffset:(void(^)(UIScrollView *scrollView, CGPoint offset, BOOL animated))setContentOffset {
    if (self.isHooked) {
        return;
    }
    self.isHooked = YES;
    
    NSString *adjustContentOffsetName = [NSString stringWithFormat:@"_%@%@%@", @"adjust", @"ContentOffset", @"IfNecessary"];
    JSRuntimeOverrideImplementation(UIScrollView.class, NSSelectorFromString(adjustContentOffsetName), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
        return ^(UIScrollView *selfObject) {
            
            adjustContentOffset(selfObject, NO);
            
            // call super
            void (*originSelectorIMP)(id, SEL);
            originSelectorIMP = (void (*)(id, SEL))originalIMPProvider();
            originSelectorIMP(selfObject, originCMD);
            
            adjustContentOffset(selfObject, YES);
        };
    });
    JSRuntimeOverrideImplementation(UIScrollView.class, @selector(setContentOffset:animated:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
        return ^(UIScrollView *selfObject, CGPoint contentOffset, BOOL animated) {
            
            // call super
            void (*originSelectorIMP)(id, SEL, CGPoint, BOOL);
            originSelectorIMP = (void (*)(id, SEL, CGPoint, BOOL))originalIMPProvider();
            originSelectorIMP(selfObject, originCMD, contentOffset, animated);
            
            if (!selfObject.js_isUpdatingContentOffset) {
                setContentOffset(selfObject, contentOffset, animated);
            } else {
                NSCAssert(NO, @"请检查%@内部是否又调用了此方法", NSStringFromClass(selfObject.class));
            }
        };
    });
    if (@available(iOS 26.2, *)) {
        /// 实测iOS 26.2以上，UICollectionView.setContentOffset内部不会调用UIScrollView.setContentOffset，而是其自身的实现
        JSRuntimeOverrideImplementation(UICollectionView.class, @selector(setContentOffset:animated:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UICollectionView *selfObject, CGPoint contentOffset, BOOL animated) {
                
                selfObject.js_isUpdatingContentOffset = YES;
                
                // call super
                void (*originSelectorIMP)(id, SEL, CGPoint, BOOL);
                originSelectorIMP = (void (*)(id, SEL, CGPoint, BOOL))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, contentOffset, animated);
                
                selfObject.js_isUpdatingContentOffset = NO;
                
                setContentOffset(selfObject, contentOffset, animated);
            };
        });
    }
    if (@available(iOS 27.0, *)) {
        /// 实测iOS 27.0以上，WKScrollView.setContentOffset内部不会调用UIScrollView.setContentOffset，而是其自身的实现
        struct JSWKWebFloatPoint { float x; float y; }; typedef struct JSWKWebFloatPoint JSWKWebFloatPoint;
        struct JSWKWebIntPoint { int x; int y; }; typedef struct JSWKWebIntPoint JSWKWebIntPoint;
        SEL scrollToSel = NSSelectorFromString([NSString stringWithFormat:@"_%@%@%@:%@:%@:%@%@:", @"scrollTo", @"ContentScroll", @"Position", @"scrollOrigin", @"animated", @"interrupt", @"Animation"]);
        JSRuntimeOverrideImplementation(WKWebView.class, scrollToSel, ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(WKWebView *selfObject, JSWKWebFloatPoint position, JSWKWebIntPoint scrollOrigin, BOOL animated, BOOL interruptAnimation) {
                
                if (!animated) {
                    selfObject.scrollView.js_isUpdatingContentOffset = YES;
                }
                
                // call super
                void (*originSelectorIMP)(id, SEL, JSWKWebFloatPoint, JSWKWebIntPoint, BOOL, BOOL);
                originSelectorIMP = (void (*)(id, SEL, JSWKWebFloatPoint, JSWKWebIntPoint, BOOL, BOOL))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, position, scrollOrigin, animated, interruptAnimation);
                
                if (!animated) {
                    selfObject.scrollView.js_isUpdatingContentOffset = NO;
                    
                    setContentOffset(selfObject.scrollView, CGPointMake(position.x, position.y), animated);
                }
            };
        });
    }
}

@end
