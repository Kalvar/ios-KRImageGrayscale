//
//  KRImageGrayscale.h
//  V0.2 Beta
//
//  References from Google, StackOverflow, Andrew Kuo and more coders, Thanks them to help more people.
//
//  Created by Kalvar on 13/10/3.
//  Copyright (c) 2013年 Kalvar. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^KRImageGrayscaleBytesHandler)(Byte *bytes);
typedef void (^KRImageGrayscaleBinaryDataHandler)(NSData *binaryData);
typedef void (^KRImageGrayscaleErrorHandler)(BOOL finished);

@interface KRImageGrayscale : NSObject
{
    
}

@property (nonatomic, copy) void (^bytesHandler)(Byte *bytes);
@property (nonatomic, copy) void (^binaryDataHandler)(NSData *binaryData);
@property (nonatomic, copy) void (^errorHandler)(NSError *error);

+(KRImageGrayscale *)sharedManager;
-(id)init;

#pragma --mark Dump Images
-(void)dumpImageInfoWithName:(NSString *)_imageName;

#pragma --mark Saves
-(void)saveBmpToDeviceWithImage:(UIImage *)_image;

#pragma --mark 4 Bits
-(UIImage *)grayscaleImageAt4Bits:(UIImage *)_image byteHandler:(KRImageGrayscaleBytesHandler)_byteHandler binaryDataHandler:(KRImageGrayscaleBinaryDataHandler)_binaryDataHandler;
-(UIImage *)grayscaleImageAt4Bits:(UIImage *)_image;

#pragma --mark 8 Bits
-(UIImage *)grayscaleImageAt8Bits:(UIImage *)_image;

#pragma --mark 16 Bits
-(UIImage *)grayscaleImageAt16Bits:(UIImage *)_image;

#pragma --mark 24 Bits
-(UIImage *)transforImageNoAlphaAt24Bits:(UIImage *)image;
-(UIImage *)grayscaleImageNoAlphaAt24Bits:(UIImage *)_image;
-(UIImage *)grayscaleImageAt24Bits:(UIImage *)_image;

#pragma --mark 32 Bits
-(UIImage *)grayscaleImageAlpha255At32Bits:(UIImage *)_image;
-(UIImage *)grayscaleImageAt32Bits:(UIImage *)_image;


#pragma --mark Texts
-(UIImage *)addTextOnImage:(UIImage *)img text:(NSString *)someText;

#pragma --mark UIImage
-(UIImage *)imageNoCacheWithName:(NSString *)_imageName;
-(UIImage *)scaleImage:(UIImage *)_image toWidth:(float)_toWidth toHeight:(float)_toHeight;

@end
