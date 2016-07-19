//
//  IIViewDeckController.m
//  IIViewDeck
//
//  Copyright (C) 2011-2016, ViewDeck
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

#import "IIViewDeckController+Private.h"

#import "IIViewDeckLayoutSupport.h"
#import "UIViewController+Private.h"
#import "IIDelegateProxy.h"
#import "IIViewDeckDefaultTransitionAnimator.h"
#import "IIViewDeckTransition.h"


NS_ASSUME_NONNULL_BEGIN

NSString* NSStringFromIIViewDeckSide(IIViewDeckSide side) {
    switch (side) {
        case IIViewDeckSideLeft:
            return @"left";
            
        case IIViewDeckSideRight:
            return @"right";
            
        default:
            return @"unknown";
    }
}


// View subclasses for easier view debugging:
@interface IIViewDeckView : UIView @end

@implementation IIViewDeckView @end


@interface IIViewDeckController () {
    struct {
        unsigned int isInSideChange: 1;
    } _flags;
}

@property (nonatomic) id<IIViewDeckControllerDelegate> delegateProxy;

@property (nonatomic) IIViewDeckLayoutSupport *layoutSupport;
@property (nonatomic) IIViewDeckTransition *currentTransition;
@property (nonatomic) UIGestureRecognizer *currentInteractiveGesture;

@end


@implementation IIViewDeckController

II_DELEGATE_PROXY(IIViewDeckControllerDelegate);

#pragma mark - Object Initialization

- (instancetype)initWithCenterViewController:(UIViewController*)centerViewController {
    return [self initWithCenterViewController:centerViewController leftViewController:nil rightViewController:nil];
}

- (instancetype)initWithCenterViewController:(UIViewController*)centerViewController leftViewController:(nullable UIViewController*)leftViewController {
    return [self initWithCenterViewController:centerViewController leftViewController:leftViewController rightViewController:nil];
}

- (instancetype)initWithCenterViewController:(UIViewController*)centerViewController rightViewController:(nullable UIViewController*)rightViewController {
    return [self initWithCenterViewController:centerViewController leftViewController:nil rightViewController:rightViewController];
}

- (instancetype)initWithCenterViewController:(UIViewController*)centerViewController leftViewController:(nullable UIViewController*)leftViewController rightViewController:(nullable UIViewController*)rightViewController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        NSParameterAssert(centerViewController);

        // Trigger the setter as they keep track of the view controller hierarchy!
        self.centerViewController = centerViewController;
        self.leftViewController = leftViewController;
        self.rightViewController = rightViewController;

        self.layoutSupport = [[IIViewDeckLayoutSupport alloc] initWithViewDeckController:self];
    }
    return self;
}



#pragma mark - View Lifecycle

- (void)loadView {
    CGRect screenFrame = UIScreen.mainScreen.bounds;
    self.view = [[IIViewDeckView alloc] initWithFrame:screenFrame];
}

- (void)viewDidLoad {
    [super viewDidLoad];

//    UIView *view = self.view;
//    [view addGestureRecognizer:transitioningDelegate.leftEdgeGestureRecognizer];
//    [view addGestureRecognizer:transitioningDelegate.rightEdgeGestureRecognizer];

    [self ii_exchangeViewFromController:nil toController:self.centerViewController inContainerView:self.view];
}



#pragma mark - Child Controller Lifecycle

- (void)setCenterViewController:(UIViewController *)centerViewController {
    if (_centerViewController && _centerViewController == centerViewController) {
        return;
    }
    
    UIViewController *oldViewController = _centerViewController;
    _centerViewController = centerViewController;

    [self ii_exchangeViewController:oldViewController withViewController:centerViewController viewTransition:^{
        [self ii_exchangeViewFromController:oldViewController toController:centerViewController inContainerView:self.view];
    }];
    
    [self setNeedsStatusBarAppearanceUpdate];

    // TODO: Start monitoring tab bar items here...
}

- (void)setLeftViewController:(nullable UIViewController *)leftViewController {
    if (_leftViewController && _leftViewController == leftViewController) {
        return;
    }
    NSAssert(_leftViewController == nil || self.openSide != IIViewDeckSideLeft, @"You can not exchange a side view controller while it is being presented.");
    UIViewController *oldViewController = _leftViewController;
    _leftViewController = leftViewController;

    [self ii_exchangeViewController:oldViewController withViewController:leftViewController viewTransition:NULL];

    [self updateSideGestureRecognizer];
}

- (void)setRightViewController:(nullable UIViewController *)rightViewController {
    if (_rightViewController && _rightViewController == rightViewController) {
        return;
    }
    NSAssert(_rightViewController == nil || self.openSide != IIViewDeckSideRight, @"You can not exchange a side view controller while it is being presented.");
    UIViewController *oldViewController = _rightViewController;
    _rightViewController = rightViewController;

    [self ii_exchangeViewController:oldViewController withViewController:rightViewController viewTransition:NULL];

    [self updateSideGestureRecognizer];
}



#pragma mark - Managing Transitions

static inline BOOL IIIsAllowedTransition(IIViewDeckSide fromSide, IIViewDeckSide toSide) {
    return (fromSide == toSide) || (IIViewDeckSideIsValid(fromSide) && !IIViewDeckSideIsValid(toSide)) || (!IIViewDeckSideIsValid(fromSide) && IIViewDeckSideIsValid(toSide));
}

- (void)setOpenSide:(IIViewDeckSide)openSide {
    [self openSide:openSide animated:NO];
}

- (void)openSide:(IIViewDeckSide)side animated:(BOOL)animated {
    [self openSide:side animated:animated notify:NO completion:NULL];
}

- (void)openSide:(IIViewDeckSide)side animated:(BOOL)animated notify:(BOOL)notify completion:(nullable void(^)(BOOL cancelled))completion {
    if (side == _openSide) {
        return;
    }
    NSAssert(self->_flags.isInSideChange == NO, @"A side change is currently taking place. You can not switch the side while already transitioning from or to a side.");
    NSAssert(IIIsAllowedTransition(_openSide, side), @"Open and close transitions are only allowed between a side and the center. You can not transition straight from one side to another side.");

    self->_flags.isInSideChange = YES;

    IIViewDeckSide oldSide = _openSide;

    if (notify) {
        if (oldSide == IIViewDeckSideNone) {
            [self.delegateProxy viewDeckController:self willOpenSide:side];
        } else {
            [self.delegateProxy viewDeckController:self willCloseSide:oldSide];
        }
    }

    void(^innerComplete)(BOOL) = ^(BOOL cancelled){
        self.currentTransition = nil;
        if (cancelled) {
            self->_openSide = oldSide;
        } else {
            self->_openSide = side;
            NSAssert(IIIsAllowedTransition(oldSide, self->_openSide), @"A transition has taken place that is unexpected and unsupported. We are probably in an invalid state right now.");
        }
        if (completion) { completion(cancelled); }

        if (notify) {
            if (cancelled) {
                if (oldSide == IIViewDeckSideNone) {
                    [self.delegateProxy viewDeckController:self didCloseSide:side];
                } else {
                    [self.delegateProxy viewDeckController:self didOpenSide:oldSide];
                }
            } else {
                if (oldSide == IIViewDeckSideNone) {
                    [self.delegateProxy viewDeckController:self didOpenSide:side];
                } else {
                    [self.delegateProxy viewDeckController:self didCloseSide:oldSide];
                }
            }
        }
        
        self->_flags.isInSideChange = NO;
    };
    if (side != IIViewDeckSideNone) {
        // If we are closing, the current side is still visible until it is fully closed,
        // so in this case the state change is only done *after* the closing completes.
        // If we however are currently opening a side, this side is visible from the
        // first moment on, therefore we change the state immediately.
        _openSide = side;
    }

    if (self.currentInteractiveGesture) {
        // trigger interactive transition
    } else {
        IIViewDeckTransition *transition = [[IIViewDeckTransition alloc] initWithViewDeckController:self from:oldSide to:side];
        self.currentTransition = transition;
        transition.completionHandler = innerComplete;
        [transition performTransition:animated];
    }
}

- (void)closeSide:(BOOL)animated {
    [self closeSide:animated notify:NO completion:NULL];
}

- (void)closeSide:(BOOL)animated notify:(BOOL)notify completion:(nullable void(^)(void))completion {
    [self openSide:IIViewDeckSideNone animated:animated notify:notify completion:completion];
}



#pragma mark - Transitioning

- (void)interactiveTransitionRecognized:(UIGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSParameterAssert(self.currentInteractiveGesture);
            self.currentInteractiveGesture = recognizer;
            // TODO: Detect transition side
            IIViewDeckSide side = IIViewDeckSideNone;
            [self openSide:side animated:YES notify:YES completion:^{
                self.currentInteractiveGesture = nil;
            }];
        } break;
        case UIGestureRecognizerStateChanged: {
            [self.currentTransition updateInteractiveTransition:recognizer];
        } break;
        case UIGestureRecognizerStateCancelled: {
            [self.currentTransition endInteractiveTransition:recognizer];
        } break;
        case UIGestureRecognizerStateEnded: {
            [self.currentTransition endInteractiveTransition:recognizer];
        } break;
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStatePossible:
            break;
    }

}



#pragma mark - Customizing Transitions

- (id<IIViewDeckTransitionAnimator>)animatorForTransitionWithContext:(id<IIViewDeckTransitionContext>)context {
    return [IIViewDeckDefaultTransitionAnimator new];
}



#pragma mark - Interactive State Management

- (void)updateSideGestureRecognizer {
//    IIViewDeckTransitioningDelegate *transitioningDelegate = self.defaultTransitioningDelegate;
//    transitioningDelegate.leftEdgeGestureRecognizer.enabled = (self.leftViewController != nil);
//    transitioningDelegate.rightEdgeGestureRecognizer.enabled = (self.rightViewController != nil);
}

@end

NS_ASSUME_NONNULL_END
