//
//  ViewController.m
//  ImageGrayscaleSample
//
//  Created by Kalvar on 13/10/3.
//  Copyright (c) 2013年 Kalvar. All rights reserved.
//

#import "ViewController.h"
#import "KRImageGrayscale.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    KRImageGrayscale *_krImageGrayscale = [KRImageGrayscale sharedManager];
    UIImage *_image = [_krImageGrayscale imageNoCacheWithName:@"test.jpg"];
    _image = [_krImageGrayscale scaleImage:_image toWidth:640.0f toHeight:960.0f];
    //8
	[_krImageGrayscale saveBmpToDeviceWithImage:[_krImageGrayscale grayscaleImageAt8Bits:_image]];
    //16 ( Not Success Yet. )
    //[_krImageGrayscale saveBmpToDeviceWithImage:[_krImageGrayscale grayscaleImageAt16Bits:_image]];
    //24
    [_krImageGrayscale saveBmpToDeviceWithImage:[_krImageGrayscale grayscaleImageAt24Bits:_image]];
    //24
    [_krImageGrayscale saveBmpToDeviceWithImage:[_krImageGrayscale grayscaleImageNoAlphaAt24Bits:_image]];
    //24
    [_krImageGrayscale saveBmpToDeviceWithImage:[_krImageGrayscale transforImageNoAlphaAt24Bits:_image]];
    //32
    [_krImageGrayscale saveBmpToDeviceWithImage:[_krImageGrayscale grayscaleImageAt32Bits:_image]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
