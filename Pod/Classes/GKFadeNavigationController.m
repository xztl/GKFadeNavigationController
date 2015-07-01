//
//  GKFadeNavigationController.m
//  
//
//  Created by GK on 15.06.25..
//
//

#import "GKFadeNavigationController.h"

#define kGKDefaultVisibility YES

@interface GKFadeNavigationController ()

@property (nonatomic, strong) UIVisualEffectView *visualEffectView;
@property (nonatomic) GKFadeNavigationControllerNavigationBarVisibility navigationBarVisibility;
@property (nonatomic, strong) UIColor *originalTintColor;

@end


@implementation GKFadeNavigationController

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Base values
    self.navigationBarVisibility = GKFadeNavigationControllerNavigationBarVisibilitySystem;
    self.originalTintColor = [self.navigationBar tintColor];
    
    [self setNavigationBarVisibilityForController:self.topViewController animated:NO];
}

#pragma mark Accessors

- (void)setNavigationBarVisibility:(GKFadeNavigationControllerNavigationBarVisibility)navigationBarVisibility
{
    if (_navigationBarVisibility == navigationBarVisibility) return;
    
    if (_navigationBarVisibility == GKFadeNavigationControllerNavigationBarVisibilitySystem) {
        if (navigationBarVisibility == GKFadeNavigationControllerNavigationBarVisibilityHidden ||
            navigationBarVisibility == GKFadeNavigationControllerNavigationBarVisibilityVisible) {
            [self transitionFromSystemNavigationBarToCustom];
        }
    } else if (_navigationBarVisibility == GKFadeNavigationControllerNavigationBarVisibilityHidden ||
               _navigationBarVisibility == GKFadeNavigationControllerNavigationBarVisibilityVisible) {
        if (navigationBarVisibility == GKFadeNavigationControllerNavigationBarVisibilitySystem) {
            [self transitionFromCustomNavigationBarToSystem];
        }
    }
    
    if (navigationBarVisibility == GKFadeNavigationControllerNavigationBarVisibilityUndefined) {
        NSLog(@"Error: This should not happen: somebody tried to transition from System/Hidden/Visible state to Undefined");
    }
    
    _navigationBarVisibility = navigationBarVisibility;
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark UI support

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.navigationBarVisibility == GKFadeNavigationControllerNavigationBarVisibilityHidden) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

#pragma mark Navigation Controller overrides

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [super pushViewController:viewController animated:animated];
    [self setNavigationBarVisibilityForController:viewController animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    UIViewController *viewController = [super popViewControllerAnimated:animated];
    [self setNavigationBarVisibilityForController:self.topViewController animated:animated];
    return viewController;
}

#pragma mark Core functions

/**
 Add custom navigation bar background, and set the colors for a hideable navigation bar
 */
- (void)transitionFromSystemNavigationBarToCustom
{
    // Hide the original navigation bar's background
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationBar.translucent = YES;
    self.navigationBar.shadowImage = [UIImage new];
    
    // Create a the fake navigation bar background
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    
    self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.visualEffectView.frame = CGRectMake(0, -20.f, self.view.frame.size.width, 64.f);
    self.visualEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.visualEffectView.userInteractionEnabled = NO;
    
    // Shadow line
    UIView *shadowView = [[UIView alloc] initWithFrame:CGRectMake(0, 63.5f, self.view.frame.size.width, 0.5f)];
    shadowView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2f];
    shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.visualEffectView addSubview:shadowView];
    
    // Add as subviews
    [self.navigationBar addSubview:self.visualEffectView];
    [self.navigationBar sendSubviewToBack:self.visualEffectView];
}

/**
 Remove custom navigation bar background, and reset to the system default
 */
- (void)transitionFromCustomNavigationBarToSystem
{
    [self.visualEffectView removeFromSuperview];
    self.visualEffectView = nil;
    
    // Revert to original values
    [self.navigationBar setBackgroundImage:[[UINavigationBar appearance] backgroundImageForBarMetrics:UIBarMetricsDefault] forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setTranslucent:[[UINavigationBar appearance] isTranslucent]];
    [self.navigationBar setShadowImage:[[UINavigationBar appearance] shadowImage]];
    [self.navigationBar setTitleTextAttributes:[[UINavigationBar appearance] titleTextAttributes]];
    [self.navigationBar setTintColor:self.originalTintColor];
}

/**
 Determines if the given view controller conforms to GKFadeNavigationControllerDelegate or not. If conforms,
 asks it about the desired navigation bar visibility (visible or hidden). If it does not conform, then
 falls back to system navigation controller.
 
 @param viewController The view controller which will be presented
 @param animated Present using animation or instantly
 */
- (void)setNavigationBarVisibilityForController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([viewController conformsToProtocol:@protocol(GKFadeNavigationControllerDelegate)]) {
        self.navigationBarVisibility = (GKFadeNavigationControllerNavigationBarVisibility)[viewController performSelector:@selector(preferredNavigationBarVisibility)];
    } else {
        self.navigationBarVisibility = GKFadeNavigationControllerNavigationBarVisibilitySystem;
    }

    if (self.navigationBarVisibility == GKFadeNavigationControllerNavigationBarVisibilityVisible ||
        self.navigationBarVisibility == GKFadeNavigationControllerNavigationBarVisibilityHidden) {
        [self setNeedsNavigationBarVisibilityUpdateAnimated:animated];
    }
}

/**
 Show or hide the navigation custom navigation bar

 @param show If YES, the navigation bar will be shown. If no, it will be hidden.
 @param animated Animate the change or not
 */
- (void)showCustomNavigaitonBar:(BOOL)show withFadeAnimation:(BOOL)animated
{
    [UIView animateWithDuration:(animated ? 0.2 : 0) animations:^{
        if (show) {
            self.visualEffectView.alpha = 1;
            self.navigationBar.tintColor = [self originalTintColor];
            self.navigationBar.titleTextAttributes = [[UINavigationBar appearance] titleTextAttributes];
        } else {
            self.visualEffectView.alpha = 0;
            self.navigationBar.tintColor = [UIColor whiteColor];
            self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor clearColor]};
        }
    } completion:^(BOOL finished) {
        [self setNeedsStatusBarAppearanceUpdate];
        self.navigationBarVisibility = show ? GKFadeNavigationControllerNavigationBarVisibilityVisible : GKFadeNavigationControllerNavigationBarVisibilityHidden;
    }];
}

#pragma mark Public

- (void)setNeedsNavigationBarVisibilityUpdateAnimated:(BOOL)animated
{
    if ([self.topViewController conformsToProtocol:@protocol(GKFadeNavigationControllerDelegate)]) {
        GKFadeNavigationControllerNavigationBarVisibility topControllerPrefersVisibility = (GKFadeNavigationControllerNavigationBarVisibility)[self.topViewController performSelector:@selector(preferredNavigationBarVisibility)];

        if (topControllerPrefersVisibility == GKFadeNavigationControllerNavigationBarVisibilityVisible) {
            [self showCustomNavigaitonBar:YES withFadeAnimation:animated];
        } else if (topControllerPrefersVisibility == GKFadeNavigationControllerNavigationBarVisibilityHidden) {
            [self showCustomNavigaitonBar:NO withFadeAnimation:animated];
        }
    } else {
        NSLog(@"GKFadeNavigationController error: setNeedsNavigationBarVisibilityUpdateAnimated is called but the current topmost view controller does not conform to GKFadeNavigationControllerDelegate protocol!");
    }
}

@end
