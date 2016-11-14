//
//  CVWrapper.h
//  CVOpenTemplate
//
//  Created by peidong yuan on 01/09/2016.
//  Copyright © 2016 peidong yuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@interface CVWrapper : NSObject

+ (UIImage*) processImageWithOpenCV: (NSString*) inputImage;

+ (UIImage*) processWithOpenCVImage1:(NSString*)inputImage1 image2:(NSString*)inputImage2;

+ (UIImage*) processImages:(NSArray*)imageArray;

+ (UIImage*) processImagesTest:(NSArray*)imageArray;


@end
