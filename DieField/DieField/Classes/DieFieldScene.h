/**
 *  DieFieldScene.h
 *  DieField
 *
 *  Created by default on 10/17/12.
 *  Copyright Eric S. Johnsen 2012. All rights reserved.
 */


#import "CC3Scene.h"
#import "CC3Node.h"

@class SpinningNode;
@interface DieFieldScene : CC3Scene {

    SpinningNode *dieCube;
    CC3Node *selectedNode;
    struct timeval lastTouchEventTime;
    CGPoint lastTouchEventPoint;
    CC3Node *camTarget;
}

/**
 * Start dragging whatever object is below the touch point of this gesture.
 *
 * This method is invoked once at the beginning of each single-finger gesture.
 * This method invokes the pickNodeFromTapAt: method to pick the node under the
 * gesture, and cache that node. If that node is either of the two rotating cubes,
 * subsequent invocations of the dragBy:atVelocity: method will spin that node.
 */
-(void) startDraggingAt: (CGPoint) touchPoint;

/**
 * Dragging whatever object was below the initial touch point of this gesture.
 *
 * If the selected node is either of the spinning cubes, spin it based on the
 * specified velocity,
 * 
 * Each component of the specified movement has a value of +/-1 if the user drags one
 * finger completely across the width or height of the CC3Layer, or a proportionally
 * smaller value for shorter drags. The value changes as the panning gesture continues.
 * At any time, it represents the movement from the initial position when the gesture
 * began, and the startDraggingAt: method was invoked. The movement does not represent
 * a delta movement from the previous invocation of this method.
 * 
 * Each component of the specified velocity is also normalized to the CC3Layer, so that
 * a steady drag completely across the layer taking one second would have a value of
 * +/-1 in the X or Y components.
 *
 * This method is invoked repeatedly during a single-finger panning gesture.
 */
-(void) dragBy: (CGPoint) aMovement atVelocity: (CGPoint) aVelocity;

/**
 * Stop dragging whatever object was below the initial touch point of this gesture.
 *
 * This method is invoked once at the end of each single-finger pan gesture.
 * This method simply clears the cached selected node.
 */
-(void) stopDragging;

@end

#pragma mark -
#pragma mark SpinningNode

/**
 * A customized node that automatically rotates by adjusting its rotational aspects on
 * each update pass, and can slow the rotation speed over time based on a friction property.
 *
 * To rotate a node using changes in rotation using the rotateBy... family of methods,
 * as is done to this node, does NOT requre a specialized class. This specialized class
 * is required to handle the freewheeling and friction nature of the behaviour after the
 * rotation has begun.
 */
@interface SpinningNode : CC3Node {
	CC3Vector spinAxis;
	GLfloat spinSpeed;
	GLfloat friction;
	BOOL isFreeWheeling;
}

/**
 * The axis that the cube spins around.
 *
 * This is different than the rotationAxis property, because this is the axis around which
 * a CHANGE in rotation will occur. Depending on how the node is already rotated, this may
 * be very different than the rotationAxis.
 */
@property(nonatomic, assign) CC3Vector spinAxis;

/**
 * The speed of rotation. This value can be directly updated, and then will automatically
 * be slowed down over time according to the value of the friction property.
 */
@property(nonatomic, assign) GLfloat spinSpeed;

/**
 * The friction value that is applied to the spinSpeed to slow it down over time.
 *
 * A value of zero will not slow rotation down at all and the node will continue
 * spinning indefinitely.
 */
@property(nonatomic, assign) GLfloat friction;

/** Indicates whether the node is spinning without direct control by touch events. */
@property(nonatomic, assign) BOOL isFreeWheeling;

@end