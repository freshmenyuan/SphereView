//
//  CVWrapper.h
//  CVOpenTemplate
//
//  Created by Washe on 02/01/2013.
//  Copyright (c) 2013 foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@interface CVWrapper : NSObject

+ (UIImage*) processImageWithOpenCV: (NSString*) inputImage;

+ (UIImage*) processWithOpenCVImage1:(NSString*)inputImage1 image2:(NSString*)inputImage2;

+ (UIImage*) processImages:(NSArray*)imageArray;

+ (UIImage*) processImagesTest:(NSArray*)imageArray;


@end
