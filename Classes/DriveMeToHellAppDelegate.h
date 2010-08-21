//
//  DriveMeToHellAppDelegate.h
//  DriveMeToHell
//
//  Created by William Carter on 8/20/10.
//  Copyright Nodesnoop LLC 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DriveMeToHellViewController;

@interface DriveMeToHellAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    DriveMeToHellViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet DriveMeToHellViewController *viewController;

@end

