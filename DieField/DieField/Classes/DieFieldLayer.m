/**
 *  DieFieldLayer.m
 *  DieField
 *
 *  Created by default on 10/17/12.
 *  Copyright Eric S. Johnsen 2012. All rights reserved.
 */

#import "DieFieldLayer.h"
#import "DieFieldScene.h"
#import "CC3ActionInterval.h"
#import "CC3CC2Extensions.h"
#import "CC3IOSExtensions.h"
#import "ccMacros.h"

@interface CC3Layer (TemplateMethods)
- (BOOL)handleTouch:(UITouch *) ofType:(uint)touchType;
@end

@interface DieFieldLayer (TemplateMethods)
@property (readonly, nonatomic) DieFieldScene *dieFieldScene;
@end

@implementation DieFieldLayer

- (void)dealloc {
    [super dealloc];
}

- (DieFieldScene *)dieFieldScene {
    
    return ((DieFieldScene *) cc3Scene);
}

/**
 * Override to set up your 2D controls and other initial state.
 *
 * For more info, read the notes of this method on CC3Layer.
 */
-(void) initializeControls {
    
    self.isTouchEnabled = NO;
}

#pragma mark Touch handling

/**
 * Invoked when this layer is being opened on the view.
 *
 * If we want to use gestures, we add the gesture recognizers here.
 *
 * By using the cc3AddGestureRecognizer: method to add the gesture recognizers,
 * we ensure that they will be torn down when this layer is removed from the view.
 *
 * This layer has child buttons on it. To ensure that those buttons receive their
 * touch events, we set cancelsTouchesInView to NO on the tap gestures recognizer
 * so that that gesture recognizer allows the touch events to propagate to the buttons.
 * We do not need to do that for the other recognizers because we don't want buttons
 * to receive touch events in the middle of a pan or pinch.
 */

- (void)onOpenCC3Layer {
    
    // Register for tap gestures to select 3D nodes.
	// This layer has child buttons on it. To ensure that those buttons receive their
	// touch events, we set cancelsTouchesInView to NO so that the gesture recognizer
	// allows the touch events to propagate to the buttons.
	UITapGestureRecognizer* tapSelector = [[UITapGestureRecognizer alloc] autorelease];
	[tapSelector initWithTarget: self action: @selector(handleTapSelection:)];
	tapSelector.numberOfTapsRequired = 1;
	tapSelector.cancelsTouchesInView = NO;		// Ensures touches are passed to buttons
	[self cc3AddGestureRecognizer: tapSelector];
	
	// Register for single-finger dragging gestures used to spin the two cubes.
	UIPanGestureRecognizer* dragPanner = [[UIPanGestureRecognizer alloc] autorelease];
	[dragPanner initWithTarget: self action: @selector(handleDrag:)];
	dragPanner.minimumNumberOfTouches = 1;
	dragPanner.maximumNumberOfTouches = 1;
	[self cc3AddGestureRecognizer: dragPanner];
    
	// Register for double-finger dragging to pan the camera.
	UIPanGestureRecognizer* cameraPanner = [[UIPanGestureRecognizer alloc] autorelease];
	[cameraPanner initWithTarget: self action: @selector(handleCameraPan:)];
	cameraPanner.minimumNumberOfTouches = 2;
	cameraPanner.maximumNumberOfTouches = 2;
	[self cc3AddGestureRecognizer: cameraPanner];
	
	// Register for double-finger dragging to pan the camera.
	UIPinchGestureRecognizer* cameraMover = [[UIPinchGestureRecognizer alloc] autorelease];
	[cameraMover initWithTarget: self action: @selector(handleCameraMove:)];
	[self cc3AddGestureRecognizer: cameraMover];

}

/**
 * This handler is invoked when a single-tap gesture is recognized.
 *
 * If the tap occurs within a descendant CCNode that wants to capture the touch,
 * such as a menu or button, the gesture is cancelled. Otherwise, the tap is 
 * forwarded to the CC3Scene to pick the 3D node under the tap.
 */
-(void) handleTapSelection: (UITapGestureRecognizer*) gesture {
    
	// Once the gesture has ended, convert the UI location to a 2D node location and
	// pick the 3D node under that location. Don't forget to test that the gesture is
	// valid and does not conflict with touches handled by this layer or its descendants.
	if ( [self cc3ValidateGesture: gesture] && (gesture.state == UIGestureRecognizerStateEnded) ) {
		CGPoint touchPoint = [self cc3ConvertUIPointToNodeSpace: gesture.location];
		[self.dieFieldScene pickNodeFromTapAt: touchPoint];
	}
}

/**
 * This handler is invoked when a single-finger drag gesture is recognized.
 *
 * If the drag starts within a descendant CCNode that wants to capture the touch,
 * such as a menu or button, the gesture is cancelled.
 *
 * The CC3Scene marks where dragging begins to determine the node that is underneath
 * the touch point at that time, and is further notified as dragging proceeds.
 * It uses the velocity of the drag to spin the cube nodes. Finally, the scene is
 * notified when the dragging gesture finishes.
 *
 * The dragging movement is normalized to be specified relative to the size of the
 * layer, making it independant of the size of the layer.
 */
-(void) handleDrag: (UIPanGestureRecognizer*) gesture {
	switch (gesture.state) {
		case UIGestureRecognizerStateBegan:
			if ( [self cc3ValidateGesture: gesture] ) {
				[self.dieFieldScene startDraggingAt: [self cc3ConvertUIPointToNodeSpace: gesture.location]];
			}
			break;
		case UIGestureRecognizerStateChanged:
			[self.dieFieldScene dragBy: [self cc3NormalizeUIMovement: gesture.translation]
						  atVelocity:[self cc3NormalizeUIMovement: gesture.velocity]];
			break;
		case UIGestureRecognizerStateEnded:
			[self.dieFieldScene stopDragging];
			break;
		default:
			break;
	}
}

/**
 * Override to perform tear-down activity prior to the scene disappearing.
 *
 * For more info, read the notes of this method on CC3Layer.
 */
-(void) onCloseCC3Layer {}

/**
 * The ccTouchMoved:withEvent: method is optional for the <CCTouchDelegateProtocol>.
 * The event dispatcher will not dispatch events for which there is no method
 * implementation. Since the touch-move events are both voluminous and seldom used,
 * the implementation of ccTouchMoved:withEvent: has been left out of the default
 * CC3Layer implementation. To receive and handle touch-move events for object
 * picking, uncomment the following method implementation.
 */

-(void) ccTouchMoved: (UITouch *)touch withEvent: (UIEvent *)event {
	[self handleTouch: touch ofType: kCCTouchMoved];
}

@end
