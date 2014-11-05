//
//  ActionViewController.m
//  ActionScreenShot
//
//  Created by xiekw on 11/3/14.
//  Copyright (c) 2014 xiekw. All rights reserved.
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import "JGProgressHUD/JGProgressHUD.h"
#import "JGProgressHUD/JGProgressHUDErrorIndicatorView.h"
#import "JGProgressHUD/JGProgressHUDSuccessIndicatorView.h"
#import "JGProgressHUDIndeterminateIndicatorView.h"

@interface UIImage (ScreenShot)

@end

@implementation UIView (ScreenShot)

- (UIImage *)screenShotImageWithBounds:(CGRect)selfBounds
{
    UIGraphicsBeginImageContextWithOptions(selfBounds.size, NO, 0);
    [self drawViewHierarchyInRect:CGRectMake(-selfBounds.origin.x, -selfBounds.origin.y, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)screenShotImage;
{
    return [self screenShotImageWithBounds:self.bounds];
}

@end

@interface ActionViewController ()<UIWebViewDelegate>

@property(strong,nonatomic) IBOutlet UIWebView *webView;
@property(strong,nonatomic) IBOutlet UIToolbar *toolBar;
@property(strong,nonatomic) UIButton *backBtn;
@property(strong,nonatomic) UIButton *refreshBtn;
@property(strong,nonatomic) PHAssetCollection *album;
@property(strong,nonatomic) JGProgressHUD *hud;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolBarHeight;

@end

@implementation ActionViewController

static UIEdgeInsets __protraitBackInset;
static UIEdgeInsets __protraitRefreshInset;
static UIEdgeInsets __landScapeBackInset;
static UIEdgeInsets __landScapeRefreshInset;


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __protraitBackInset = UIEdgeInsetsMake(10, -30, -10, 0);
    __protraitRefreshInset = UIEdgeInsetsMake(10, -50.0, -10, 0);
    __landScapeBackInset = UIEdgeInsetsMake(0, -30, 0, 0);
    __landScapeRefreshInset = UIEdgeInsetsMake(0, -50.0, 0, 0);
    
    self.webView.suppressesIncrementalRendering = YES;
    self.webView.delegate = self;
    self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    self.hud.interactionType = JGProgressHUDInteractionTypeBlockNoTouches;

    // Get the item[s] we're handling from the extension context.
    
    // For example, look for an image and place it into an image view.
    // Replace this with something appropriate for the type[s] your extension supports.
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *item, NSError *error) {
                    [self.webView loadRequest:[NSURLRequest requestWithURL:item]];
                }];
                
                break;
            }
        }
    }

    
    self.toolBar.tintColor = [UIColor whiteColor];
    self.toolBar.barStyle = UIBarStyleBlack;
    [self.view addSubview:self.toolBar];
    
    UIEdgeInsets webViewInset = self.webView.scrollView.contentInset;
    webViewInset.top = CGRectGetHeight(self.toolBar.frame);
    self.webView.scrollView.contentInset = webViewInset;
    self.webView.scrollView.scrollIndicatorInsets = webViewInset;

    NSMutableArray *toolBarItems = [NSMutableArray array];
    
    CGRect buttonRect = CGRectMake(0, 0, 44, 44);
    
    self.backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backBtn setImage:[UIImage imageNamed:@"btn_nav_cancel_normal"] forState:UIControlStateNormal];
    [self.backBtn setImage:[UIImage imageNamed:@"btn_nav_cancel_selected"] forState:UIControlStateHighlighted];
    self.backBtn.frame = buttonRect;
    self.backBtn.imageEdgeInsets = __protraitBackInset;
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:self.backBtn];
    [toolBarItems addObject:back];
    [self.backBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    
    self.refreshBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.refreshBtn setImage:[UIImage imageNamed:@"btn_nav_refresh_normal"] forState:UIControlStateNormal];
    [self.refreshBtn setImage:[UIImage imageNamed:@"btn_nav_refresh_selected"] forState:UIControlStateHighlighted];
    self.refreshBtn.frame = buttonRect;
    self.refreshBtn.imageEdgeInsets = __protraitRefreshInset;
    UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithCustomView:self.refreshBtn];
    [toolBarItems addObject:refresh];
    [self.refreshBtn addTarget:self action:@selector(refresh) forControlEvents:UIControlEventTouchUpInside];

    
    UIBarButtonItem *flexibleSpaceToolbarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    [toolBarItems addObject:flexibleSpaceToolbarItem];
    
    UIBarButtonItem *fullImage = [[UIBarButtonItem alloc] initWithTitle:@"FullScreen" style:UIBarButtonItemStylePlain target:self action:@selector(shotFullImage)];;
    [toolBarItems addObject:fullImage];
    
    UIBarButtonItem *visibleImage = [[UIBarButtonItem alloc] initWithTitle:@"Visible" style:UIBarButtonItemStylePlain target:self action:@selector(shotVisibleImage)];
    [toolBarItems addObject:visibleImage];
    
    self.toolBar.items = toolBarItems;
    
    self.album = [PHAssetCollection transientAssetCollectionWithAssets:nil title:@"xiekw"];
    
    [self updateViewWithOrientation:self.preferredInterfaceOrientationForPresentation];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.hud dismissAnimated:YES];
    
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.hud showInView:self.view animated:YES];

}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    self.hud.textLabel.text = error.localizedDescription;
    [self.hud dismissAnimated:YES];
}


- (void)back
{
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

- (void)refresh
{
    [self.webView loadRequest:self.webView.request];
    self.hud.indicatorView = [JGProgressHUDIndeterminateIndicatorView new];
    self.hud.textLabel.text = nil;
}

- (void)shotFullImage
{
    UIImage* image = nil;
    UIScrollView *scrollView = self.webView.scrollView;
    UIGraphicsBeginImageContextWithOptions(scrollView.contentSize, 0, 0);
    {
        CGPoint savedContentOffset = scrollView.contentOffset;
        CGRect savedFrame = scrollView.frame;
        
        scrollView.contentOffset = CGPointZero;
        scrollView.frame = CGRectMake(0, 0, scrollView.contentSize.width, scrollView.contentSize.height);
        
        [scrollView.layer renderInContext: UIGraphicsGetCurrentContext()];
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        scrollView.contentOffset = savedContentOffset;
        scrollView.frame = savedFrame;
    }
    UIGraphicsEndImageContext();
    [self addNewAssetWithImage:image toAlbum:self.album];
}

- (void)shotVisibleImage
{
    CGFloat toolBarHeight = CGRectGetHeight(self.toolBar.frame);
    UIImage* image = [self.webView screenShotImageWithBounds:CGRectMake(0, toolBarHeight, CGRectGetWidth(self.webView.bounds), CGRectGetHeight(self.webView.bounds)-toolBarHeight)];

    [self addNewAssetWithImage:image toAlbum:self.album];

}

- (void)addNewAssetWithImage:(UIImage *)image toAlbum:(PHAssetCollection *)album
{
    [self.hud showInView:self.view];
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        // Request creating an asset from the image.
        PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        
        // Request editing the album.
        PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:album];
        
        // Get a placeholder for the new asset and add it to the album editing request.
        PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
        [albumChangeRequest addAssets:@[ assetPlaceholder ]];
        
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                self.hud.textLabel.text = @"Saved!";
                self.hud.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
                [self.hud showInView:self.view];

            }else {
                self.hud.textLabel.text = @"Saved!";
                self.hud.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
                [self.hud showInView:self.view];
            }
            [self.hud dismissAfterDelay:3.0];
        });

        
        NSLog(@"Finished adding asset. %@", (success ? @"Success" : error));
    }];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self updateViewWithOrientation:toInterfaceOrientation];
}

- (void)updateViewWithOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        {
            UIEdgeInsets webViewInset = self.webView.scrollView.contentInset;
            self.toolBarHeight.constant = 44.0;
            webViewInset.top = self.toolBarHeight.constant;
            self.webView.scrollView.contentInset = webViewInset;
            self.webView.scrollView.scrollIndicatorInsets = webViewInset;
            
            self.refreshBtn.imageEdgeInsets = __landScapeRefreshInset;
            self.backBtn.imageEdgeInsets = __landScapeBackInset;
            
        }
            break;
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            UIEdgeInsets webViewInset = self.webView.scrollView.contentInset;
            self.toolBarHeight.constant = 64.0;
            webViewInset.top = self.toolBarHeight.constant;
            self.webView.scrollView.contentInset = webViewInset;
            self.webView.scrollView.scrollIndicatorInsets = webViewInset;
            
            self.refreshBtn.imageEdgeInsets = __protraitRefreshInset;
            self.backBtn.imageEdgeInsets = __protraitBackInset;
        }
            break;
        default:
            break;
    }
    [self.toolBar layoutIfNeeded];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
