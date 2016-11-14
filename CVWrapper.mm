//
//  CVWrapper.m
//  CVOpenTemplate
//
//  Created by Washe on 02/01/2013.
//  Copyright (c) 2013 foundry. All rights reserved.
//

#import "CVWrapper.h"
#import "UIImage+OpenCV.h"
#import "UIImage+Rotate.h"
#include <time.h>
#import "stichingDetail.hpp"
#import "stitching.h"


@implementation CVWrapper

+ (UIImage*) processImageWithOpenCV: (UIImage*) inputImage
{
    NSArray* imageArray = [NSArray arrayWithObject:inputImage];
    UIImage* result = [[self class] processImages:imageArray];
    return result;
}

+ (UIImage*) processWithOpenCVImage1:(UIImage*)inputImage1 image2:(UIImage*)inputImage2;
{
    NSArray* imageArray = [NSArray arrayWithObjects:inputImage1,inputImage2,nil];
    UIImage* result = [[self class] processImages:imageArray];
    return result;
}

+ (UIImage*) processImagesTest:(NSArray<NSString *> *)imageArray
{
    clock_t start, finish;
    double duration;
    
    
    if ([imageArray count]==0){
        NSLog (@"imageArray is empty");
        return 0;
    }
    std::vector<cv::Mat> matImages;
    NSLog (@"imageArray is: %@", imageArray );
    
    
    for (id image in imageArray) {
        
        if ([image isKindOfClass:[NSString class]]) {
            /*
             All images taken with the iPhone/iPa cameras are LANDSCAPE LEFT orientation. The  UIImage imageOrientation flag is an instruction to the OS to transform the image during display only. When we feed images into openCV, they need to be the actual orientation that we expect them to be for stitching. So we rotate the actual pixel matrix here if required.
             */
            UIImage *theImage = [UIImage imageWithContentsOfFile:image];
            NSLog (@"theImage: %@",theImage);
            
            if (theImage) {
                UIImage *rotatedImage = [theImage rotateToImageOrientation];
                cv::Mat matImage = [rotatedImage CVMat3];
                NSLog (@"matImage: %@",theImage);
                NSData* data = UIImagePNGRepresentation(rotatedImage);
                [data writeToFile:image atomically:YES];
                matImages.push_back(matImage);
                
            }
            
        }
    }
    
    start = clock();
    NSLog (@"stitching...");
    
    //    stichingDetail st = *new stichingDetail();
    //    cv::Mat stitchedMat = st.stiching(matImages);
    //
    cv::Mat stitchedMat = stitch(matImages);
    UIImage* result =  [UIImage imageWithCVMat:stitchedMat];
    
    finish = clock();
    duration = (double)(finish - start) / 1000000;
    NSLog (@"Finish stitching, time used: %f", duration);
    
    return result;
}

+ (UIImage*) processImages:(NSArray<UIImage *> *)imageArray
{
    clock_t start, finish;
    double duration;
    
    
    if ([imageArray count]==0){
        NSLog (@"imageArray is empty");
        return 0;
        }
    std::vector<cv::Mat> matImages;
    NSLog (@"imageArray is: %@", imageArray );


    for (id image in imageArray) {

        if ([image isKindOfClass:[UIImage class]]) {
            /*
             All images taken with the iPhone/iPa cameras are LANDSCAPE LEFT orientation. The  UIImage imageOrientation flag is an instruction to the OS to transform the image during display only. When we feed images into openCV, they need to be the actual orientation that we expect them to be for stitching. So we rotate the actual pixel matrix here if required.
             */

            if (image) {
                UIImage *rotatedImage = [image rotateToImageOrientation];
                cv::Mat matImage = [rotatedImage CVMat3];
                matImages.push_back(matImage);

            }

        }
    }
    
    start = clock();
    NSLog (@"stitching...");
    
//    stichingDetail st = *new stichingDetail();
//    cv::Mat stitchedMat = st.stiching(matImages);
//    
    cv::Mat stitchedMat = stitch(matImages);
    UIImage* result =  [UIImage imageWithCVMat:stitchedMat];
    
    finish = clock();
    duration = (double)(finish - start) / 1000000;
    NSLog (@"Finish stitching, time used: %f", duration);

    return result;
}


@end
