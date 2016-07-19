//
//  IIViewDeckTransition.m
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

#import "IIViewDeckTransition.h"

#import "IIViewDeckController+Private.h"
#import "IIViewDeckLayoutSupport.h"


@interface IIViewDeckTransition ()

@property (nonatomic, assign) IIViewDeckController *viewDeckController; // this is not weak as it is a required link! If the corresponding view deck controller will be removed, this class can no longer fullfill its purpose!

@property (nonatomic, getter=isInteractive) BOOL interactive;
@property (nonatomic, getter=isCancelled) BOOL cancelled;

@property (nonatomic) UIViewController *centerViewController;
@property (nonatomic) UIViewController *sideViewController;

@property (nonatomic) id<IIViewDeckTransitionAnimator> animator;

@end


@implementation IIViewDeckTransition

@synthesize centerView = _centerView, initialCenterFrame = _initialCenterFrame, finalCenterFrame = _finalCenterFrame;
@synthesize sideView = _sideView, initialSideFrame = _initialSideFrame, finalSideFrame = _finalSideFrame;

- (instancetype)initWithViewDeckController:(IIViewDeckController *)viewDeckController from:(IIViewDeckSide)fromSide to:(IIViewDeckSide)toSide {
    NSParameterAssert(viewDeckController);
    NSParameterAssert(fromSide ^ toSide); // we need exactly one of these to be IIViewDeckSideNone for a valid transition
    self = [super init];
    if (self) {
        _viewDeckController = viewDeckController;

        IIViewDeckLayoutSupport *layoutSupport = viewDeckController.layoutSupport;

        _interactive = NO;
        _cancelled = NO;

        _centerViewController = viewDeckController.centerViewController;
        _centerView = _centerViewController.view;
        _initialCenterFrame = [layoutSupport frameForSide:IIViewDeckSideNone openSide:fromSide];
        _finalCenterFrame = [layoutSupport frameForSide:IIViewDeckSideNone openSide:toSide];

        IIViewDeckSide side = (fromSide | toSide);
        _sideViewController = (side == IIViewDeckSideLeft ? viewDeckController.leftViewController : viewDeckController.rightViewController);
        _sideView = _sideViewController.view;
        _initialSideFrame = [layoutSupport frameForSide:side openSide:fromSide];
        _finalSideFrame = [layoutSupport frameForSide:side openSide:toSide];
    }
    return self;
}

- (id<IIViewDeckTransitionAnimator>)animator {
    if (_animator) {
        return _animator;
    }
    _animator = [self.viewDeckController animatorForTransitionWithContext:self];
    return _animator;
}


#pragma mark - Controller and View Hierarchy

- (void)prepareControllerAndViewHierarchy:(BOOL)animated {
    UIView *containerView = self.viewDeckController.view;

    self.centerView.frame = self.initialCenterFrame;

    self.sideView.frame = self.initialSideFrame;
    if (!CGRectContainsRect(containerView.bounds, self.initialSideFrame)) {
        NSParameterAssert(!self.sideView.superview);
        [containerView addSubview:self.sideView];
        [self.sideViewController beginAppearanceTransition:YES animated:animated];
    } else {
        [self.sideViewController beginAppearanceTransition:NO animated:animated];
    }
}

- (void)cleanupControllerAndViewHierarchy {
    UIView *containerView = self.viewDeckController.view;

    self.centerView.frame = (self.cancelled ? self.initialCenterFrame : self.finalCenterFrame);

    self.sideView.frame = (self.cancelled ? self.initialSideFrame : self.finalSideFrame);
    if (!CGRectContainsRect(containerView.bounds, self.sideView.frame)) {
        [self.sideView removeFromSuperview];
    }
    [self.sideViewController endAppearanceTransition];

    if (self.isCancelled) {
        [self.sideViewController beginAppearanceTransition:CGRectContainsRect(containerView.bounds, self.sideView.frame) animated:NO];
        [self.sideViewController endAppearanceTransition];
    }
}



#pragma mark - Interactive Transitions

- (void)beginInteractiveTransition:(UIGestureRecognizer *)recognizer {
    self.interactive = YES;
    [self prepareControllerAndViewHierarchy:YES];
    [self.animator prepareForTransition:self];
}

- (void)updateInteractiveTransition:(UIGestureRecognizer *)recognizer {
    double fractionsComplete = 0.0;
    [self.animator updateInteractiveTransition:self fractionCompleted:fractionsComplete];
}

- (void)endInteractiveTransition:(UIGestureRecognizer *)recognizer {
    CGPoint velocity = CGPointZero; // TODO: Calculate that if recognizer supports it
    [self.animator animateTransition:self velocity:velocity];
}


#pragma mark - Animated Transitions

- (void)performTransition:(BOOL)animated {
    void(^completion)() = ^{
        [self cleanupControllerAndViewHierarchy];
        if (self.completionHandler) {
            self.completionHandler(self.cancelled);
        }
    };

    [self prepareControllerAndViewHierarchy:animated];
    if (animated) {
        [self.animator prepareForTransition:self];
        [self.animator animateTransition:self velocity:CGPointZero];
    }
}

- (void)completeTransition {
    [self cleanupControllerAndViewHierarchy];
    if (self.completionHandler) {
        self.completionHandler(self.cancelled);
    }
}

@end
