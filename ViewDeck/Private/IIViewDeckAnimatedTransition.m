//
//  IIViewDeckAnimatedTransition.m
//  IIViewDeck
//
//  Copyright (C) 2016, ViewDeck
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//  of the Software, and to permit persons to whom the Software is furnished to do
//  so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "IIViewDeckAnimatedTransition.h"

#import "IISideContainerViewController.h"


NS_ASSUME_NONNULL_BEGIN


@interface IIViewDeckAnimatedTransition ()

@property (nonatomic, readonly, getter=isAppearing) BOOL appearing;

@end


@implementation IIViewDeckAnimatedTransition

- (instancetype)init {
    NSAssert(NO, @"Please use initWithViewDeckSide:appearing: instead.");
    return self;
}

- (instancetype)initWithTypeAppearing:(BOOL)appearing {
    self = [super init];

    _appearing = appearing;

    return self;
}



#pragma mark - appearance

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.5;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewAnimationOptions animationOptions = (transitionContext.isInteractive ? UIViewAnimationOptionCurveLinear : UIViewAnimationCurveEaseInOut);

    if (self.appearing) {
        IISideContainerViewController *sideViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        NSParameterAssert([sideViewController isKindOfClass:[IISideContainerViewController class]]);

        CGRect initialFrame = [transitionContext initialFrameForViewController:sideViewController];
        CGRect finalFrame = [transitionContext finalFrameForViewController:sideViewController];
        NSParameterAssert(CGRectEqualToRect(initialFrame, CGRectZero));
        NSParameterAssert(!CGRectEqualToRect(finalFrame, CGRectZero));

        IIViewDeckSide side = sideViewController.side;
        initialFrame = finalFrame;
        if (side == IIViewDeckSideLeft) {
            initialFrame.origin.x -= CGRectGetWidth(initialFrame);
        } else if (side == IIViewDeckSideRight) {
            initialFrame.origin.x += CGRectGetWidth(initialFrame);
        }

        UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
        toView.frame = initialFrame;
        UIView *containerView = transitionContext.containerView;
        [containerView addSubview:toView];
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 options:animationOptions animations:^{
            toView.frame = finalFrame;
        } completion:^(BOOL finished) {
            BOOL completed = !transitionContext.transitionWasCancelled; // evalutate this value. Otherwise cancelling breaks the view hierarchy!
            [transitionContext completeTransition:completed];
        }];
    } else {
        IISideContainerViewController *sideViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        NSParameterAssert([sideViewController isKindOfClass:[IISideContainerViewController class]]);

        CGRect initialFrame = [transitionContext initialFrameForViewController:sideViewController];
        CGRect finalFrame = [transitionContext finalFrameForViewController:sideViewController];
        NSParameterAssert(!CGRectEqualToRect(initialFrame, CGRectZero));
//        NSParameterAssert(CGRectEqualToRect(finalFrame, CGRectZero)); // - why is that not the case?

        IIViewDeckSide side = sideViewController.side;
        finalFrame = initialFrame;
        if (side == IIViewDeckSideLeft) {
            finalFrame.origin.x -= CGRectGetWidth(finalFrame);
        } else if (side == IIViewDeckSideRight) {
            finalFrame.origin.x += CGRectGetWidth(finalFrame);
        }

        UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        UIView *containerView = transitionContext.containerView;
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 options:animationOptions animations:^{
            fromView.frame = finalFrame;
        } completion:^(BOOL finished) {
            BOOL completed = !transitionContext.transitionWasCancelled; // evalutate this value. Otherwise cancelling breaks the view hierarchy!
            [transitionContext completeTransition:completed];
        }];
    }
}

- (void)animationEnded:(BOOL) transitionCompleted {
    ;
}


@end

NS_ASSUME_NONNULL_END
