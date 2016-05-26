//
//  IIViewDeckPresentationController.m
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

#import "IIViewDeckPresentationController.h"

#import "IIEnvironment.h"
#import "IIViewDeckController+Private.h"
#import "IISideContainerViewController.h"

@interface IIViewDeckPresentationController ()

@property (nonatomic, weak) UIView *dimmingView;
@property (nonatomic, readonly) IIViewDeckController *viewDeckController;

@end

@implementation IIViewDeckPresentationController

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController {
    NSParameterAssert([presentedViewController isKindOfClass:[IISideContainerViewController class]]);
    return [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
}



#pragma mark - Accessors

- (IIViewDeckController *)viewDeckController {
    UIViewController *viewDeckController = self.presentingViewController;
    NSParameterAssert([viewDeckController isKindOfClass:[IIViewDeckController class]]);
    return (IIViewDeckController *)viewDeckController;
}

- (IISideContainerViewController *)sideViewController {
    UIViewController *sideViewController = self.presentedViewController;
    NSParameterAssert([sideViewController isKindOfClass:[IISideContainerViewController class]]);
    return (IISideContainerViewController *)sideViewController;
}

- (BOOL)shouldRemovePresentersView {
    return NO;
}


#pragma mark - Layouting

- (CGRect)frameOfPresentedViewInContainerView {
    IISideContainerViewController *sideViewController = self.sideViewController;
    IIViewDeckSide side = sideViewController.side;
    CGFloat width = [self.presentedViewController preferredContentSize].width;
    NSAssert(width > 0.0, @"A view deck controller's side view needs to have a size greater than 0.0");

    UIView *containerView = self.containerView;
    CGRect frame = containerView.bounds;
    width = MIN(width, CGRectGetWidth(frame)); // max size should be container view size!

    if (side == IIViewDeckSideRight) {
        frame.origin.x = CGRectGetWidth(frame) - width;
    }

    frame.size.width = width;

    return frame;
}

- (void)presentationTransitionWillBegin {
    UIView *containerView = self.containerView;
    NSParameterAssert(containerView);
    UIView *dimmingView = [[UIView alloc] initWithFrame:containerView.bounds];
    dimmingView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth);
    dimmingView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.25];
    [containerView addSubview:dimmingView];
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPresentedViewController:)];
    [dimmingView addGestureRecognizer:tapRecognizer];
    if (const auto panGestureRecognizer = self.panGestureRecognizer) {
        [dimmingView addGestureRecognizer:panGestureRecognizer];
    }
    self.dimmingView = dimmingView;

    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.presentedViewController.transitionCoordinator;
    NSParameterAssert(transitionCoordinator);
    dimmingView.alpha = 0.0;
    [transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        dimmingView.alpha = 1.0;
    } completion:NULL];
}

- (void)dismissalTransitionWillBegin {
    UIView *dimmingView = self.dimmingView;
    NSParameterAssert(dimmingView);
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.presentedViewController.transitionCoordinator;
    NSParameterAssert(transitionCoordinator);
    [transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        dimmingView.alpha = 0.0;// (context.isCancelled ? 1.0 : 0.0);
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (!context.isCancelled) {
            [dimmingView removeFromSuperview];
        }
    }];
}



#pragma mark - Presentation Controls

- (IBAction)dismissPresentedViewController:(id)sender {
    [self.viewDeckController closeSide:YES notify:YES completion:NULL];
}

@end
