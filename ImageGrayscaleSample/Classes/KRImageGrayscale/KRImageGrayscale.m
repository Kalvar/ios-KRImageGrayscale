//
//  KRImageGrayscale.m
//  V0.2 Beta
//
//  References from Google, StackOverflow, Andrew Kuo and more coders, Thanks them to help more people.
//
//  Created by Kalvar on 13/10/3.
//  Copyright (c) 2013年 Kalvar. All rights reserved.
//

#import "KRImageGrayscale.h"

//static NSInteger _kKRImageGrayscaleBytesPerPixel    = 1;
//static NSInteger _kKRImageGrayscaleBitsPerComponent = 8;

typedef struct RGBAData {
    Byte r;
    Byte g;
    Byte b;
    Byte a;
}RGBAData;

typedef struct RGBData {
    Byte r;
    Byte g;
    Byte b;
}RGBData;

#define BITS_PER_COMPONENT 8
#define PER_PIXEL_32_BYTE_ 4
#define PER_PIXEL_24_BYTE_ 3

@implementation KRImageGrayscale (fixPrivate)

-(void)_initWithVars
{
    self.bytesHandler      = nil;
    self.binaryDataHandler = nil;
    self.errorHandler      = nil;
}

-(UIImage *)_imageNoCacheWithName:(NSString *)_imageName
{
    return [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], _imageName]];
}

-(UIImage *)_resizeImage:(UIImage *)_image toSize:(CGSize)_size
{
    UIGraphicsBeginImageContext(_size);
    [_image drawInRect:CGRectMake(0, 0, _size.width, _size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

-(UIImage *)_scaleCutImage:(UIImage *)_image toWidth:(float)_toWidth toHeight:(float)_toHeight
{
    float _x = 0.0f;
    float _y = 0.0f;
    CGRect _frame = CGRectMake(_x, _y, _toWidth, _toHeight);
    //取得原始圖片寬高
    float _oldWidth  = _image.size.width;
    float _oldHeight = _image.size.height;
    //中心剪裁
    //先進行等比例縮圖
    float _scaleRatio   = MAX( (_toWidth / _oldWidth), (_toHeight / _oldHeight) );
    float _equalWidth   = (int)( _oldWidth * _scaleRatio );
    float _equalHeight  = (int)( _oldHeight * _scaleRatio );
    _image = [self _resizeImage:_image toSize:CGSizeMake(_equalWidth, _equalHeight)];
    //取得起始剪裁的 X(寬), Y(高) 軸，iPhone 的 (0, 0) 為左上角開始起算
    _x = floor( (_equalWidth -  _toWidth) / 2 );
    _y = floor( (_equalHeight - _toHeight) / 2 );
    _frame = CGRectMake(_x, _y, _toWidth, _toHeight);
    //開始進行裁圖
    CGImageRef _smallImage = CGImageCreateWithImageInRect( [_image CGImage], _frame );
    UIImage *_doneImage    = [UIImage imageWithCGImage:_smallImage];
    CGImageRelease(_smallImage);
    
    return _doneImage;
}


@end

@implementation KRImageGrayscale

@synthesize bytesHandler;
@synthesize binaryDataHandler;
@synthesize errorHandler;

+(KRImageGrayscale *)sharedManager
{
    static dispatch_once_t pred;
    static KRImageGrayscale *_object = nil;
    dispatch_once(&pred, ^{
        _object = [[KRImageGrayscale alloc] init];
        [_object _initWithVars];
    });
    return _object;
}

-(id)init
{
    self = [super init];
    if( self )
    {
        [self _initWithVars];
    }
    return self;
}

#pragma --mark Dump Images
-(void)dumpImageInfoWithName:(NSString *)_imageName
{
    UIImage *image     = [self _imageNoCacheWithName:_imageName];
    CGImageRef cgimage = image.CGImage;
    
    size_t width  = CGImageGetWidth(cgimage);
    size_t height = CGImageGetHeight(cgimage);
    
    size_t bpr = CGImageGetBytesPerRow(cgimage);
    size_t bpp = CGImageGetBitsPerPixel(cgimage);
    size_t bpc = CGImageGetBitsPerComponent(cgimage);
    size_t bytes_per_pixel = bpp / bpc;
    
    CGBitmapInfo info = CGImageGetBitmapInfo(cgimage);
    
    NSLog(
          @"\n"
          "===== %@ =====\n"
          "CGImageGetHeight: %d\n"
          "CGImageGetWidth:  %d\n"
          "CGImageGetColorSpace: %@\n"
          "CGImageGetBitsPerPixel:     %d\n"
          "CGImageGetBitsPerComponent: %d\n"
          "CGImageGetBytesPerRow:      %d\n"
          "CGImageGetBitmapInfo: 0x%.8X\n"
          "  kCGBitmapAlphaInfoMask     = %s\n"
          "  kCGBitmapFloatComponents   = %s\n"
          "  kCGBitmapByteOrderMask     = %s\n"
          "  kCGBitmapByteOrderDefault  = %s\n"
          "  kCGBitmapByteOrder16Little = %s\n"
          "  kCGBitmapByteOrder32Little = %s\n"
          "  kCGBitmapByteOrder16Big    = %s\n"
          "  kCGBitmapByteOrder32Big    = %s\n",
          _imageName,
          (int)width,
          (int)height,
          CGImageGetColorSpace(cgimage),
          (int)bpp,
          (int)bpc,
          (int)bpr,
          (unsigned)info,
          (info & kCGBitmapAlphaInfoMask)     ? "YES" : "NO",
          (info & kCGBitmapFloatComponents)   ? "YES" : "NO",
          (info & kCGBitmapByteOrderMask)     ? "YES" : "NO",
          (info & kCGBitmapByteOrderDefault)  ? "YES" : "NO",
          (info & kCGBitmapByteOrder16Little) ? "YES" : "NO",
          (info & kCGBitmapByteOrder32Little) ? "YES" : "NO",
          (info & kCGBitmapByteOrder16Big)    ? "YES" : "NO",
          (info & kCGBitmapByteOrder32Big)    ? "YES" : "NO"
          );
    
    CGDataProviderRef provider = CGImageGetDataProvider(cgimage);
    NSData *data = (id)CFBridgingRelease(CGDataProviderCopyData(provider));
    const uint8_t* bytes = [data bytes];
    
    printf("Pixel Data:\n");
    for(size_t row = 0; row < height; row++)
    {
        for(size_t col = 0; col < width; col++)
        {
            const uint8_t* pixel =
            &bytes[row * bpr + col * bytes_per_pixel];
            
            printf("(");
            for(size_t x = 0; x < bytes_per_pixel; x++)
            {
                printf("%.2X", pixel[x]);
                if( x < bytes_per_pixel - 1 )
                    printf(",");
            }
            
            printf(")");
            if( col < width - 1 )
                printf(", ");
        }
        
        printf("\n");
    }
}

#pragma --mark Saves
-(void)saveBmpToDeviceWithImage:(UIImage *)_image
{
    NSData *_imageData          = UIImagePNGRepresentation(_image);
    NSDate *_date               = [NSDate date];
    NSDateFormatter *_formatter = [[NSDateFormatter alloc] init];
    [_formatter setDateFormat:@"yyyyMMddHHmmssSSS"];
    NSString *_fileName         = [_formatter stringFromDate:_date];
    NSString *_tempPath         = [NSString stringWithFormat:@"%@/%@.%@", NSTemporaryDirectory(), _fileName, @"bmp"];
    [_imageData writeToURL:[NSURL fileURLWithPath:_tempPath] atomically:YES];
    NSLog(@"saved path : %@", _tempPath);
}

#pragma --mark 4 Bits
-(UIImage *)grayscaleImageAt4Bits:(UIImage *)_image byteHandler:(KRImageGrayscaleBytesHandler)_byteHandler binaryDataHandler:(KRImageGrayscaleBinaryDataHandler)_binaryDataHandler
{
    //先轉 8 Bits 再轉 4 Bits
    _image = [self grayscaleImageAt8Bits:_image];
    
    //將圖片轉換成 CGImageRef 格式並取得大小
    CGImageRef imageRef = [_image CGImage];
    int width  = CGImageGetWidth(imageRef);
    int height = CGImageGetHeight(imageRef);
    
    //資料結構的參數和色域
    NSInteger _bitsPerComponent = 8;
    NSInteger _bytesPerPixel    = 1;
    NSInteger _bytesPerRow      = _bytesPerPixel * width;
    CGColorSpaceRef colorSpace  = CGColorSpaceCreateDeviceGray();
    
    //宣告一個與圖片大小相同的資料結構一維陣列
    //unsigned char *sourceData = malloc(height * width * bytesPerPixel);
    uint8_t *sourceData = malloc(height * width * _bytesPerPixel);
    
    //將圖片資訊寫入資料結構陣列中
    CGContextRef context = CGBitmapContextCreate(sourceData,
                                                 width,
                                                 height,
                                                 _bitsPerComponent,
                                                 _bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaNone);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    const int _redIndex   = 0;
    const int _greenIndex = 1;
    const int _blueIndex  = 2;
    
    int _byteIndex  = 0;
    int _bitIndex   = 0;
    //處理成 4 Bits
    //先宣告一個準備容納「重新處理」完成的圖片 Byte Data Array
    uint8_t *_newImageBits = malloc( height * width * _bytesPerPixel / 2 );
    //取出每一個 Pixel 後，重新處理成 1 個 Byte 擁有 2 個 Pixel ( 1 個 Pixel 為 4 Bits )
    for(int j=0;j<height;j++)
    {
        for(int k=0;k<width;k++)
        {
            //讓 1 Bype for 2 Pixel，同一個 byte 會被取出來處理 2 次 ( 每 4 Bits 處理 1 Pixel )
            UInt8 _perPixel = _newImageBits[_byteIndex];
            
            //取出 pixel 的顏色
            UInt8 *rgbPixel = (UInt8 *) &sourceData[j * width + k];
            
            //NSLog(@"rgbaPixel : %d", _perPixel);
            
            int _red   = rgbPixel[_redIndex];
            int _green = rgbPixel[_greenIndex];
            int _blue  = rgbPixel[_blueIndex];
            
            //NSLog(@"r %i, g %i, b %i", _red, _green, _blue);
            
            //算顏色 ( 256 色降為 16 色，再分成 16 份 )
            //int _pixelGrayValue = (_green + _red + _blue) % 16 / 16;
            //int _pixelGrayValue = (_green + _red + _blue) / 3 / 16;
            int _pixelGrayValue = (_green + _red + _blue) / 16;
            UInt8 _pixelByte = (UInt8)_pixelGrayValue;
            
            //NSLog(@"_pixelByte : %d", _pixelByte);
            
            //算顏色( 承上 ; 算 16 階的 0 ~ 255 值是哪些 )
            //_perPixel &= (~(0xff<<_bitIndex)); //clear
            //_perPixel |= (_pixelByte<<_bitIndex);
            
            //256色降為16色
            //R = R%16
            //把256色分為16份
            //應該是 R=R/16
            //然後再pixel = (r1<<4)|r2     ( 4bit的每一點 )
            _perPixel |= (_pixelByte<<4);
            
            //NSLog(@"_perPixel : %d", _perPixel);
            
            _newImageBits[_byteIndex] = _perPixel;
            //_newImageBits[_byteIndex] = _pixelByte;
            
            _bitIndex += 4;
            if(_bitIndex > 7)
            {
                _byteIndex++;
                _bitIndex = 0;
            }
        }
    }
    
    free(sourceData);
    //Direct fetch Bytes of 4-Bits.
    sourceData = _newImageBits;
    
    if( _byteHandler )
    {
        _byteHandler(sourceData);
    }
    
    //再由CGContextRef轉成CGImageRef
    CGImageRef cgImage  = CGBitmapContextCreateImage(context);
    UIImage *_grayImage = [UIImage imageWithCGImage:cgImage];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    //CGImageRelease(cgImage);
    
    //NSLog(@"width : %i, height : %i", width, height);
    
    //NSLog(@"_newImageBits : %s", _newImageBits);
    //NSLog(@"sourceData : %s", sourceData);
    
    //Convert to NSData type.
    NSData *_sourceImageData  = [NSData dataWithBytes:sourceData length:(width * height * _bytesPerPixel)];
    
    if( _binaryDataHandler )
    {
        _binaryDataHandler(_sourceImageData);
    }
    
    //NSLog(@"_sourceImageData : %@", _sourceImageData);
    //NSLog(@"_sourceImageData bytes : %s", [_sourceImageData bytes]);
    
    //UIImage *_saveImage = [UIImage imageWithData:_sourceImageData];
    
    //NSLog(@"_grayImage : %@", _grayImage);
    //NSLog(@"_saveImage : %@", _saveImage);
    
    /*
     //會再轉回 8 Bits
     colorSpace = CGColorSpaceCreateDeviceGray();
     context = CGBitmapContextCreate(sourceData, width, height, 8, width, colorSpace, kCGImageAlphaNone);
     CGImageRef image = CGBitmapContextCreateImage(context);
     CGContextRelease(context);
     CGColorSpaceRelease(colorSpace);
     UIImage *resultImage = [UIImage imageWithCGImage:image];
     CGImageRelease(image);
     */
    
    
    //NSLog(@"\n\n\n === 4Bit.bmp === \n\n\n");
    //UIImage *_4bitBmp = [UIImage imageNamed:@"4bit.bmp"];
    //NSData *_4BitImageData = UIImagePNGRepresentation(_4bitBmp);
    //NSLog(@"_4BitImageData : %@", _4BitImageData);
    //NSLog(@"_4BitImageData bytes : %s", [_4BitImageData bytes]);
    
    //[self saveToDeviceWithImage:resultImage];
    
    free(sourceData);
    
    //return _grayImage;
    return _grayImage;
}

-(UIImage *)grayscaleImageAt4Bits:(UIImage *)_image
{
    return [self grayscaleImageAt4Bits:_image byteHandler:self.bytesHandler binaryDataHandler:self.binaryDataHandler];
}

#pragma --mark 8 Bits
//可轉 8 Bit Grayscale
-(UIImage *)grayscaleImageAt8Bits:(UIImage *)_image
{
    //將圖片轉換成 CGImageRef 格式並取得大小
    CGImageRef imageRef = [_image CGImage];
    int width  = CGImageGetWidth(imageRef);
    int height = CGImageGetHeight(imageRef);
    
    //資料結構的參數和色域
    NSUInteger _bitsPerComponent = 8;
    NSUInteger _bytesPerPixel    = 1;
    NSUInteger _bytesPerRow      = _bytesPerPixel * width;
    CGColorSpaceRef colorSpace   = CGColorSpaceCreateDeviceGray();
    
    //宣告一個與圖片大小相同的資料結構一維陣列
    //unsigned char *sourceData = malloc(height * width * bytesPerPixel);
    uint8_t *sourceData = malloc(height * width * _bytesPerPixel);
    
    //將圖片資訊寫入資料結構陣列中
    CGContextRef context = CGBitmapContextCreate(sourceData,
                                                 width,
                                                 height,
                                                 _bitsPerComponent,
                                                 _bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaNone);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    //再由CGContextRef轉成CGImageRef
    CGImageRef cgImage  = CGBitmapContextCreateImage(context);
    UIImage *_grayImage = [UIImage imageWithCGImage:cgImage];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(cgImage);
    free(sourceData);
    
    return _grayImage;
}

#pragma --mark 16 Bits
//待補，未成功
-(UIImage *)grayscaleImageAt16Bits:(UIImage *)_image
{
    const int RED   = 1;
    const int GREEN = 2;
    const int BLUE  = 3;

    CGRect imageRect = CGRectMake(0, 0, _image.size.width * _image.scale, _image.size.height * _image.scale);
    
    int width  = imageRect.size.width;
    int height = imageRect.size.height;
    
    uint32_t *pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    memset(pixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder16Little | kCGImageAlphaNoneSkipLast);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [_image CGImage]);
    
    for(int y = 0; y < height; y++)
    {
        for(int x = 0; x < width; x++)
        {
            uint8_t *rgbaPixel = (uint8_t *) &pixels[y * width + x];
            
            uint8_t gray = (uint8_t) ((30 * rgbaPixel[RED] + 59 * rgbaPixel[GREEN] + 11 * rgbaPixel[BLUE]) / 100);
            
            
            rgbaPixel[RED]   = gray;
            rgbaPixel[GREEN] = gray;
            rgbaPixel[BLUE]  = gray;
        }
    }
    
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    
    UIImage *resultUIImage = [UIImage imageWithCGImage:image
                                                 scale:_image.scale
                                           orientation:UIImageOrientationUp];
    
    CGImageRelease(image);
    
    return resultUIImage;
}

#pragma --mark 24 Bits
//24 Bits
- (UIImage *)transforImageNoAlphaAt24Bits:(UIImage *)image
{    
    //將圖片轉換成 CGImageRef 格式並取得大小
    CGImageRef imageRef = [image CGImage];
    int width  = CGImageGetWidth(imageRef);
    int height = CGImageGetHeight(imageRef);
    
    //資料結構的參數和色域
    NSUInteger bytesPerRow      = PER_PIXEL_32_BYTE_ * width;
    NSUInteger bitsPerComponent = BITS_PER_COMPONENT;
    CGColorSpaceRef colorSpace  = CGColorSpaceCreateDeviceRGB();
    
    //宣告一個與圖片大小相同的資料結構一維陣列
    RGBAData *sourceData = malloc(height * width * PER_PIXEL_32_BYTE_);
    
    //將圖片資訊寫入資料結構陣列中
    CGContextRef context = CGBitmapContextCreate(sourceData,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    /*
    //宣告一個與圖片大小相同但是去掉alpha的資料結構一維陣列
    RGBData *bmpData = malloc(height * width * PER_PIXEL_24_BYTE_);
    
    //將alpha channel以外的資訊存入結構中
    for (int x=0; x!=width; x++)
    {
        for (int y=0; y!=height; y++)
        {
            bmpData[y*width + x].r = sourceData[y*width + x].r;
            bmpData[y*width + x].g = sourceData[y*width + x].g;
            bmpData[y*width + x].b = sourceData[y*width + x].b;
        }
    }
    */
    
    CGImageRef _24BitsImage = CGBitmapContextCreateImage(context);
    free(sourceData);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage *_24BitsResultImage = [UIImage imageWithCGImage:_24BitsImage];
    CGImageRelease(_24BitsImage);
    
    //free(sourceData);
    //CGContextRelease(context);
    
    /*
    //Drawing to BMP Again.
    unsigned char *bmpChar = (unsigned char *)bmpData;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate(bmpChar, width, height, 8, width * PER_PIXEL_32_BYTE_, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGImageRef _24BitsImage = CGBitmapContextCreateImage(context);
    free(sourceData);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage *_24BitsResultImage = [UIImage imageWithCGImage:_24BitsImage];
    CGImageRelease(_24BitsImage);
    free(bmpChar);
    */
    
    return _24BitsResultImage;
}

-(UIImage *)grayscaleImageNoAlphaAt24Bits:(UIImage *)_image
{
    int kRed   = 1;
    int kGreen = 2;
    int kBlue  = 4;
    
    int colors   = kGreen;
    int m_width  = _image.size.width;
    int m_height = _image.size.height;
    
    uint32_t *rgbImage = (uint32_t *) malloc(m_width * m_height * sizeof(uint32_t));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImage, m_width, m_height, 8, m_width * 4, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, NO);
    CGContextDrawImage(context, CGRectMake(0, 0, m_width, m_height), [_image CGImage]);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // now convert to grayscale
    uint8_t *m_imageData = (uint8_t *) malloc(m_width * m_height);
    for(int y = 0; y < m_height; y++)
    {
        for(int x = 0; x < m_width; x++)
        {
            uint32_t rgbPixel=rgbImage[y*m_width+x];
            uint32_t sum=0,count=0;
            if (colors & kRed) {sum += (rgbPixel>>24)&255; count++;}
            if (colors & kGreen) {sum += (rgbPixel>>16)&255; count++;}
            if (colors & kBlue) {sum += (rgbPixel>>8)&255; count++;}
            m_imageData[y*m_width+x]=sum/count;
        }
    }
    free(rgbImage);
    
    // convert from a gray scale image back into a UIImage
    uint8_t *result = (uint8_t *) calloc(m_width * m_height *sizeof(uint32_t), 1);
    
    // process the image back to rgb
    for(int i = 0; i < m_height * m_width; i++)
    {
        result[i*4]=0;
        int val=m_imageData[i];
        result[i*4+1]=val;
        result[i*4+2]=val;
        result[i*4+3]=val;
    }
    
    // create a UIImage
    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate(result, m_width, m_height, 8, m_width * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage *resultUIImage = [UIImage imageWithCGImage:image];
    CGImageRelease(image);
    
    free(m_imageData);
    
    // make sure the data will be released by giving it to an autoreleased NSData
    [NSData dataWithBytesNoCopy:result length:m_width * m_height];
    
    return resultUIImage;
}

-(UIImage *)grayscaleImageAt24Bits:(UIImage *)_image
{
    const int RED   = 1;
    const int GREEN = 2;
    const int BLUE  = 3;
    
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, _image.size.width * _image.scale, _image.size.height * _image.scale);
    
    int width  = imageRect.size.width;
    int height = imageRect.size.height;
    
    // the pixels will be painted to this array
    uint32_t *pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [_image CGImage]);
    
    for(int y = 0; y < height; y++)
    {
        for(int x = 0; x < width; x++)
        {
            uint8_t *rgbaPixel = (uint8_t *) &pixels[y * width + x];
            
            uint8_t gray = (uint8_t) ((30 * rgbaPixel[RED] + 59 * rgbaPixel[GREEN] + 11 * rgbaPixel[BLUE]) / 100);
            
            // set the pixels to gray
            rgbaPixel[RED]   = gray;
            rgbaPixel[GREEN] = gray;
            rgbaPixel[BLUE]  = gray;
        }
    }
    
    // create a new CGImageRef from our context with the modified pixels
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    // we're done with the context, color space, and pixels
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    
    // make a new UIImage to return
    UIImage *resultUIImage = [UIImage imageWithCGImage:image
                                                 scale:_image.scale
                                           orientation:UIImageOrientationUp];
    
    // we're done with image now too
    CGImageRelease(image);
    
    return resultUIImage;
}

#pragma --mark 32 Bits
-(UIImage *)grayscaleImageAlpha255At32Bits:(UIImage *)_image
{
    //將圖片轉換成 CGImageRef 格式並取得大小
    CGImageRef imageRef = [_image CGImage];
    int _width  = CGImageGetWidth(imageRef);
    int _height = CGImageGetHeight(imageRef);
    
    //資料結構的參數和色域
    int _bytesPerPixel    = 4;
    int _bytesPerRow      = _bytesPerPixel * _width;
    int _bitsPerComponent = 8;
    CGColorSpaceRef _colorSpace = CGColorSpaceCreateDeviceRGB();
    
    //宣告一個與圖片大小相同的資料結構一維陣列
    RGBAData *_sourceData = malloc(_height * _width * _bytesPerPixel);
    
    //將圖片資訊寫入資料結構陣列中
    CGContextRef context = CGBitmapContextCreate((unsigned char *)_sourceData,
                                                 _width,
                                                 _height,
                                                 _bitsPerComponent,
                                                 _bytesPerRow,
                                                 _colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, _width, _height), imageRef);
    RGBAData *_resultData = malloc(_height * _width * _bytesPerPixel);
    //影像轉灰階（gray= 0.299*R+ 0.587*G + 0.114*B）
    for (int y=0; y!=_height; y++)
    {
        for (int x=0; x!=_width; x++) {
            
            //取得陣列中像素的索引值
            int pixelIndex = (_width * y) + x ;
            
            //轉灰階
            float grayValue = 0.299 * _sourceData[pixelIndex].r +
                              0.587 * _sourceData[pixelIndex].g +
                              0.114 * _sourceData[pixelIndex].b;
            
            int gray = round(grayValue);
            _resultData[pixelIndex].r = gray;
            _resultData[pixelIndex].g = gray;
            _resultData[pixelIndex].b = gray;
            _resultData[pixelIndex].a = 255;
        }
    }
    
    free(_sourceData);
    
    //先轉成CGContextRef
    context = CGBitmapContextCreate((unsigned char *)_resultData,
                                    _width,
                                    _height,
                                    _bitsPerComponent,
                                    _bytesPerRow,
                                    _colorSpace,
                                    kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //再由CGContextRef轉成CGImageRef
    CGImageRef cgImage=CGBitmapContextCreateImage(context);
    UIImage *_resultImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGContextRelease(context);
    CGColorSpaceRelease(_colorSpace);
    
    free(_resultData);
    
    //返回UIImage
    return _resultImage;
}

-(UIImage *)grayscaleImageAt32Bits:(UIImage *)_image
{
    const int RED   = 1;
    const int GREEN = 2;
    const int BLUE  = 3;
    
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, _image.size.width * _image.scale, _image.size.height * _image.scale);
    
    int width  = imageRect.size.width;
    int height = imageRect.size.height;
    
    // the pixels will be painted to this array
    uint32_t *pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [_image CGImage]);
    
    for(int y = 0; y < height; y++)
    {
        for(int x = 0; x < width; x++)
        {
            uint8_t *rgbaPixel = (uint8_t *) &pixels[y * width + x];
            
            uint8_t gray = (uint8_t) ((30 * rgbaPixel[RED] + 59 * rgbaPixel[GREEN] + 11 * rgbaPixel[BLUE]) / 100);
            
            // set the pixels to gray
            rgbaPixel[RED]   = gray;
            rgbaPixel[GREEN] = gray;
            rgbaPixel[BLUE]  = gray;
        }
    }
    
    // create a new CGImageRef from our context with the modified pixels
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    // we're done with the context, color space, and pixels
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    
    // make a new UIImage to return
    UIImage *resultUIImage = [UIImage imageWithCGImage:image
                                                 scale:_image.scale
                                           orientation:UIImageOrientationUp];
    
    // we're done with image now too
    CGImageRelease(image);
    
    return resultUIImage;
}

#pragma --mark Texts
-(UIImage *)addTextOnImage:(UIImage *)img text:(NSString *)someText
{
    int w = img.size.width;
    int h = img.size.height;
    //lon = h - lon;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage);
    CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 1);
    CGContextSetRGBFillColor(context, 255, 255, 255, 1);
    UIGraphicsPushContext(context);
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0.0, -40);
    CGContextRotateCTM(context, 0.0f);
    [someText drawAtPoint:CGPointMake(15, 10) withFont: [UIFont fontWithName:@"Arial" size:38.0f]];
    UIGraphicsPopContext();
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return [UIImage imageWithCGImage:imageMasked];
}

#pragma --mark UIImage
-(UIImage *)imageNoCacheWithName:(NSString *)_imageName
{
    return [self _imageNoCacheWithName:_imageName];
}

-(UIImage *)scaleImage:(UIImage *)_image toWidth:(float)_toWidth toHeight:(float)_toHeight
{
    return [self _scaleCutImage:_image toWidth:_toWidth toHeight:_toHeight];
}

@end
