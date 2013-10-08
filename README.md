## Supports

KRImageGrayscale supports ARC.

## How To Get Started

KRImageGrayscale can easy transfor image to grayscale with 4 bits, 8 bits, 16 bits, 24 bits and 32 bits.

``` objective-c
#import "KRImageGrayscale.h"

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
```

## Version

KRImageGrayscale now is V0.2 beta.

## License

KRImageGrayscale is available under the MIT license ( or Whatever you wanna do ). See the LICENSE file for more info.

## References

Google, StackOverflow, Andrew Kuo, Others Coder. Thanks for their help more people.
