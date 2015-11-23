//
//  DemoAboutViewController.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 3/4/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DemoAboutViewController.h"
#import "DTLazyImageView.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

@interface DemoAboutViewController ()<UIActionSheetDelegate, DTAttributedTextContentViewDelegate, DTLazyImageViewDelegate>

@property (nonatomic, strong) NSString *fileName;

@property (nonatomic, strong) NSURL *lastActionLink;

@property (nonatomic, strong) NSURL *baseURL;
@end

@implementation DemoAboutViewController

- (id)init
{
    self = [super initWithNibName:@"DemoAboutViewController" bundle:nil];
    if (self)
	 {
        // Custom initialization
		 self.navigationItem.title = @"About DTCoreText";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"About" ofType:@"html"];
	NSData *data = [NSData dataWithContentsOfFile:path];
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithHTMLData:data documentAttributes:NULL];
    
    // we draw images and links via subviews provided by delegate methods
    self.attributedTextView.shouldDrawImages = YES;
    self.attributedTextView.shouldDrawLinks = YES;
    self.attributedTextView.textDelegate = self; // delegate for custom sub views
	self.attributedTextView.attributedString = attributedString;
	self.attributedTextView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
}

#pragma mark - DTLazyImageViewDelegate

- (void)lazyImageView:(DTLazyImageView *)lazyImageView didChangeImageSize:(CGSize)size {
    NSURL *url = lazyImageView.url;
    CGSize imageSize = size;
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"contentURL == %@", url];
    
    BOOL didUpdate = NO;
    
    // update all attachments that matchin this URL (possibly multiple images with same size)
    for (DTTextAttachment *oneAttachment in [self.attributedTextView.attributedTextContentView.layoutFrame textAttachmentsWithPredicate:pred])
    {
        // update attachments that have no original size, that also sets the display size
        if (CGSizeEqualToSize(oneAttachment.originalSize, CGSizeZero))
        {
            oneAttachment.originalSize = imageSize;
            
            didUpdate = YES;
        }
    }
    
    if (didUpdate)
    {
        // layout might have changed due to image sizes
        [self.attributedTextView relayoutText];
    }
}

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttachment:(DTTextAttachment *)attachment frame:(CGRect)frame
{
    if ([attachment isKindOfClass:[DTImageTextAttachment class]])
    {
        // if the attachment has a hyperlinkURL then this is currently ignored
        DTLazyImageView *imageView = [[DTLazyImageView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, 320, 320)];
        imageView.backgroundColor = [UIColor redColor];
        imageView.delegate = self;
        
        // sets the image if there is one
        imageView.image = [(DTImageTextAttachment *)attachment image];
        
        // url for deferred loading
        imageView.url = attachment.contentURL;
        
        // if there is a hyperlink then add a link button on top of this image
        if (attachment.hyperLinkURL)
        {
            // NOTE: this is a hack, you probably want to use your own image view and touch handling
            // also, this treats an image with a hyperlink by itself because we don't have the GUID of the link parts
            imageView.userInteractionEnabled = YES;
            
            DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:imageView.bounds];
            button.URL = attachment.hyperLinkURL;
            button.minimumHitSize = CGSizeMake(25, 25); // adjusts it's bounds so that button is always large enough
            button.GUID = attachment.hyperLinkGUID;
            [imageView addSubview:button];
        }
        
        return imageView;
    }
    return nil;
}

- (void)viewDidUnload
{
    [self setAttributedTextView:nil];
    [super viewDidUnload];
}
@end
