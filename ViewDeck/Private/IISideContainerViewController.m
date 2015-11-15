//
//  IISideContainerViewController.m
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

#import "IISideContainerViewController.h"

#import "IIEnvironment.h"
#import "IIViewDeckController.h"
#import "UIViewController+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface IISideContainerViewController ()

@end

@implementation IISideContainerViewController

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
    [NSException raise:NSInternalInconsistencyException format:@"Use initWithViewController: instead."];
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    [NSException raise:NSInternalInconsistencyException format:@"Use initWithViewController: instead."];
    return nil;
}
#pragma clang diagnostic pop

- (instancetype)initWithViewController:(UIViewController *)viewController viewDeckController:(IIViewDeckController *)viewDeckController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _innerViewController = viewController;
        _viewDeckController = viewDeckController;
        [self ii_exchangeViewController:nil withViewController:viewController viewTransition:NULL];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(self.transitioningDelegate); // this should be set by now!

    UIView *containerView = self.view;
    UIViewController *innerViewController = self.innerViewController;
    [self ii_exchangeViewFromController:nil toController:innerViewController inContainerView:containerView];
}



#pragma mark - Accessors

- (IIViewDeckSide)side {
    IIViewDeckSide side = IIViewDeckSideUnknown;
    IIViewDeckController *viewDeckController = self.viewDeckController;
    if (self.innerViewController == viewDeckController.leftViewController) {
        side = IIViewDeckSideLeft;
    } else if (self.innerViewController == viewDeckController.rightViewController) {
        side = IIViewDeckSideRight;
    }
    NSParameterAssert(IIViewDeckSideIsValid(side));
    return side;
}



#pragma mark - Presentation

- (nullable id<UIViewControllerTransitioningDelegate>)transitioningDelegate {
    id<UIViewControllerTransitioningDelegate> delegate = self.innerViewController.transitioningDelegate;
    if (delegate == nil) {
        delegate = [super transitioningDelegate];
    }
    return delegate;
}

- (CGSize)preferredContentSize {
    CGSize preferredContentSize = self.innerViewController.preferredContentSize;
    if (preferredContentSize.width == 0.0) {
        // make an assumption that hopefully looks good on most screens
        preferredContentSize.width = CGRectGetWidth(UIScreen.mainScreen.bounds) * 2.0/3.0;
    }
    return preferredContentSize;
}

- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationCustom;
}

@end

NS_ASSUME_NONNULL_END
