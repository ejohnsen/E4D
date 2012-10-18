/**
 *  DieFieldAppDelegate.h
 *  DieField
 *
 *  Created by default on 10/17/12.
 *  Copyright __MyCompanyName__ 2012. All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "CCNodeController.h"
#import "CC3Scene.h"

@interface DieFieldAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow* window;
	CCNodeController* viewController;
}

@property (nonatomic, retain) UIWindow* window;

@end
