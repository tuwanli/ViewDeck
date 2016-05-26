//
//  IIViewDeckTransitioningDelegate.m
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

#import "IIViewDeckTransitioningDelegate.h"

#import "IIEnvironment+Private.h"
#import "IIViewDeckAnimatedTransition.h"
#import "IIViewDeckController+Private.h"
#import "IIViewDeckPresentationController.h"
#import "IISideContainerViewController.h"


NS_ASSUME_NONNULL_BEGIN


@interface IIViewDeckTransitioningDelegate () {
    struct {
        unsigned int isInteractiveTransition: 1;
    } _flags;
}

@property (nonatomic, assign) IIViewDeckController *viewDeckController; // this is not weak as it is a required link! If the corresponding view deck controller will be removed, this class can no longer fullfill its purpose!

@property (nonatomic, nullable) UIPercentDrivenInteractiveTransition *currentInteractiveTransition;

@end


@implementation IIViewDeckTransitioningDelegate

- (instancetype)init {
    NSAssert(NO, @"Please use initWithViewDeckController: instead.");
    return self;
}

- (instancetype)initWithViewDeckController:(IIViewDeckController *)viewDeckController {
    NSParameterAssert(viewDeckController);
    self = [super init];

    _viewDeckController = viewDeckController; 

    UIScreenEdgePanGestureRecognizer *leftEdgeGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(edgeGestureRecognized:)];
    leftEdgeGestureRecognizer.edges = UIRectEdgeLeft;
    _leftEdgeGestureRecognizer = leftEdgeGestureRecognizer;

    UIScreenEdgePanGestureRecognizer *rightEdgeGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(edgeGestureRecognized:)];
    rightEdgeGestureRecognizer.edges = UIRectEdgeRight;
    _rightEdgeGestureRecognizer = rightEdgeGestureRecognizer;

    return self;
}



#pragma mark - Transition Context

- (nullable UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(/*nullable*/ UIViewController *)presenting sourceViewController:(UIViewController *)source {
    IIViewDeckController *viewDeckController = self.viewDeckController;
    NSParameterAssert([presented isKindOfClass:[IISideContainerViewController class]]);
    NSParameterAssert(source == viewDeckController);
    IISideContainerViewController *container = (IISideContainerViewController *)presented;
    NSParameterAssert(container.innerViewController == viewDeckController.leftViewController || container.innerViewController == viewDeckController.rightViewController);

    IIViewDeckPresentationController *presentationController = [[IIViewDeckPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
    presentationController.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(closeGestureRecognized:)];
    return presentationController;
}



#pragma mark - Animated Transitions

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    IIViewDeckController *viewDeckController = self.viewDeckController;
    NSParameterAssert(presenting == viewDeckController);
    NSParameterAssert([presented isKindOfClass:[IISideContainerViewController class]]);
    IISideContainerViewController *container = (IISideContainerViewController *)presented;
    NSParameterAssert(container.innerViewController == viewDeckController.leftViewController || container.innerViewController == viewDeckController.rightViewController);

    IIViewDeckSide side = container.side;
    IIViewDeckAnimatedTransition *transition = [[IIViewDeckAnimatedTransition alloc] initWithTypeAppearing:YES];
    return transition;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    IIViewDeckController *viewDeckController = self.viewDeckController;
    NSParameterAssert(dismissed.presentingViewController == viewDeckController);
    NSParameterAssert([dismissed isKindOfClass:[IISideContainerViewController class]]);
    IISideContainerViewController *container = (IISideContainerViewController *)dismissed;
    NSParameterAssert(container.innerViewController == viewDeckController.leftViewController || container.innerViewController == viewDeckController.rightViewController);

    IIViewDeckSide side = container.side;
    IIViewDeckAnimatedTransition *transition = [[IIViewDeckAnimatedTransition alloc] initWithTypeAppearing:NO];
    return transition;
}



#pragma mark - Interactive Transitions

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id <UIViewControllerAnimatedTransitioning>)animator {
    if (self->_flags.isInteractiveTransition == NO) {
        return nil;
    }
    NSParameterAssert(self.currentInteractiveTransition == nil);
    UIPercentDrivenInteractiveTransition *interactiveTransition = [UIPercentDrivenInteractiveTransition new];
    self.currentInteractiveTransition = interactiveTransition;
    return interactiveTransition;
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator {
    if (self->_flags.isInteractiveTransition == NO) {
        return nil;
    }
    NSParameterAssert(self.currentInteractiveTransition == nil);
    UIPercentDrivenInteractiveTransition *interactiveTransition = [UIPercentDrivenInteractiveTransition new];
    self.currentInteractiveTransition = interactiveTransition;
    return interactiveTransition;
}

- (IBAction)edgeGestureRecognized:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer {
    IIViewDeckSide side = IIViewDeckSideUnknown;
    if (gestureRecognizer == self.leftEdgeGestureRecognizer) {
        side = IIViewDeckSideLeft;
    } else if (gestureRecognizer == self.rightEdgeGestureRecognizer) {
        side = IIViewDeckSideRight;
    }
    NSParameterAssert(side != IIViewDeckSideUnknown);

    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSParameterAssert(!self.currentInteractiveTransition);
            self->_flags.isInteractiveTransition = YES;
            [self.viewDeckController openSide:side animated:YES notify:YES completion:NULL];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            NSParameterAssert(self.currentInteractiveTransition);
            CGPoint point = [gestureRecognizer locationInView:gestureRecognizer.view];
            UIViewController *presentedController = self.viewDeckController.presentedViewController;
            if (side == IIViewDeckSideRight) {
                point.x -= CGRectGetWidth(gestureRecognizer.view.bounds) - CGRectGetWidth(presentedController.view.bounds);
            }
            CGFloat percentage = point.x / CGRectGetWidth(presentedController.view.bounds);
            if (side == IIViewDeckSideRight) {
                percentage = 1.0 - percentage;
            }
            percentage = IILimit(0.0, percentage, 0.99); // if we allow a value of 1.0 this breaks the interactive transition once we call `finishInteractiveTransition`.
            [self.currentInteractiveTransition updateInteractiveTransition:percentage];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            NSParameterAssert(self.currentInteractiveTransition);
            CGFloat translation = [gestureRecognizer velocityInView:gestureRecognizer.view].x;
            if (side == IIViewDeckSideRight) {
                translation *= -1.0;
            }
            if (translation > 0.0) {
                [self.currentInteractiveTransition finishInteractiveTransition];
            } else {
                [self.currentInteractiveTransition cancelInteractiveTransition];
            }
            self.currentInteractiveTransition = nil;
            self->_flags.isInteractiveTransition = NO;
            break;
        }
        case UIGestureRecognizerStateCancelled: {
            NSParameterAssert(self.currentInteractiveTransition);
            [self.currentInteractiveTransition cancelInteractiveTransition];
            self.currentInteractiveTransition = nil;
            self->_flags.isInteractiveTransition = NO;
            break;
        }
        default:
            break;
    }
}

- (IBAction)closeGestureRecognized:(UIPanGestureRecognizer *)gestureRecognizer {
    IIViewDeckSide side = self.viewDeckController.openSide;
    NSParameterAssert(side != IIViewDeckSideUnknown);

    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSParameterAssert(!self.currentInteractiveTransition);
            self->_flags.isInteractiveTransition = YES;
            [self.viewDeckController closeSide:YES notify:YES completion:NULL];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            NSParameterAssert(self.currentInteractiveTransition);
            CGPoint point = [gestureRecognizer locationInView:gestureRecognizer.view];
            UIViewController *presentedController = self.viewDeckController.presentedViewController;
            if (side == IIViewDeckSideRight) {
                point.x -= CGRectGetWidth(gestureRecognizer.view.bounds) - CGRectGetWidth(presentedController.view.bounds);
            }
            CGFloat percentage = point.x / CGRectGetWidth(presentedController.view.bounds);
            if (side == IIViewDeckSideLeft) {
                percentage = 1.0 - percentage;
            }
            percentage = IILimit(0.0, percentage, 0.99); // if we allow a value of 1.0 this breaks the interactive transition once we call `finishInteractiveTransition`.
            [self.currentInteractiveTransition updateInteractiveTransition:percentage];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            NSParameterAssert(self.currentInteractiveTransition);
            CGFloat translation = [gestureRecognizer velocityInView:gestureRecognizer.view].x;
            if (side == IIViewDeckSideLeft) {
                translation *= -1.0;
            }
            if (translation > 0.0) {
                [self.currentInteractiveTransition finishInteractiveTransition];
            } else {
                [self.currentInteractiveTransition cancelInteractiveTransition];
            }
            self.currentInteractiveTransition = nil;
            self->_flags.isInteractiveTransition = NO;
            break;
        }
        case UIGestureRecognizerStateCancelled: {
            NSParameterAssert(self.currentInteractiveTransition);
            [self.currentInteractiveTransition cancelInteractiveTransition];
            self.currentInteractiveTransition = nil;
            self->_flags.isInteractiveTransition = NO;
            break;
        }
        default:
            break;
    }
}

@end


NS_ASSUME_NONNULL_END
