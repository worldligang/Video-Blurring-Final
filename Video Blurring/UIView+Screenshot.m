//
//  UIView+Screenshot.m
//  Video Blurring
//
//  Created by Mike Jaoudi on 12/11/13.
//  Copyright (c) 2013 Mike Jaoudi. All rights reserved.
//

#import "UIView+Screenshot.h"

@implementation UIView (Screenshot)

-(UIImage*)convertViewToImage{
    UIGraphicsBeginImageContext(self.bounds.size);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


@end
