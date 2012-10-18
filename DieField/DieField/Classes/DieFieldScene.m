/**
 *  DieFieldScene.m
 *  DieField
 *
 *  Created by default on 10/17/12.
 *  Copyright Eric S. Johnsen 2012. All rights reserved.
 */

#import "DieFieldScene.h"
#import "CC3PODResourceNode.h"
#import "CC3ActionInterval.h"
#import "CC3MeshNode.h"
#import "CC3Camera.h"
#import "CC3Light.h"
#import "CGPointExtension.h"
#import "CCTouchDispatcher.h"

// File names
#define kDieCubePODFile					@"DieCube.pod"

// Model names
#define kDieCubeName					@"DieCube"
#define kDieCubePODName					@"Cube"

@interface DieFieldScene (Private)
- (void)addDieCube;
- (void)rotateCubeFromSwipeAt:(CGPoint)touchPoint interval:(ccTime)dt;
- (void)rotate:(SpinningNode *)aNode fromSwipeAt:(CGPoint)touchPoint interval:(ccTime)dt;
- (void)rotate:(SpinningNode *)aNode fromSwipeVelocity:(CGPoint)swipeVelocity;
@end

@implementation DieFieldScene

-(void) dealloc {
    
    dieCube = nil;  // not retained
    
	[super dealloc];
}

/**
 * Constructs the 3D scene.
 *
 * Adds 3D objects to the scene, loading a 3D DieCube
 * from a POD file, and creating the camera and light programatically.
 */
-(void) initializeScene {

	// Create the camera, place it back a bit, and add it to the scene
	CC3Camera* cam = [CC3Camera nodeWithName: @"Camera"];
	cam.location = cc3v( 0.0, 0.0, 6.0 );
	[self addChild: cam];

	// Create a light, place it back and to the left at a specific
	// position (not just directional lighting), and add it to the scene
	CC3Light* lamp = [CC3Light nodeWithName: @"Lamp"];
	lamp.location = cc3v( -2.0, 0.0, 0.0 );
	lamp.isDirectionalOnly = NO;
	[cam addChild: lamp];
    
    [self addDieCube];
	
	// Create OpenGL ES buffers for the vertex arrays to keep things fast and efficient,
	// and to save memory, release the vertex data in main memory because it is now redundant.
	[self createGLBuffers];
	[self releaseRedundantData];
		
	// Displays short descriptive text for each node (including class, node name & tag).
	// The text is displayed centered on the pivot point (origin) of the node.
//	self.shouldDrawAllDescriptors = YES;
	
	// Displays bounding boxes around those nodes with local content (eg- meshes).
//	self.shouldDrawAllLocalContentWireframeBoxes = YES;
	
	// Displays bounding boxes around all nodes. The bounding box for each node
	// will encompass its child nodes.
//	self.shouldDrawAllWireframeBoxes = YES;
	
	// Moves the camera so that it will display the entire scene.
//	[self.activeCamera moveWithDuration: 3.0 toShowAllOf: self];
	
	// If you encounter issues creating and adding nodes, or loading models from
	// files, the following line is used to log the full structure of the scene.
	LogCleanDebug(@"The structure of this scene is: %@", [self structureDescription]);
	
	// ------------------------------------------
}

/**
 * Adds a die cube that can be rotated by the user touching it and then swiping in any
 * direction. The die cube rotates in the direction of the swipe, at a speed proportional
 * to the speed and length of the swipe, and then steadily slows down over time.
 *
 * While the user is touching the cube and moving the finger, the die cube is rotated
 * under direct finger motion. Once the finger is lifted, the die cube spins in a
 * freewheel fashion, and slows down over time due to friction.
 *
 * This die cube does not use a CCAction to rotate. Instead, a custom SpinningNode class
 * replaces the node loaded from the POD file. This custom class spins by adjusting its
 * rotational state on each update pass. It contains a spinSpeed property to indicate how
 * fast it is currently spinning, and a friction property to adjust the spinSpeed on each
 * update.
 *
 * To handle the behaviour of the node while it is freewheeling, we create it as a
 * specialized subclass. Since this node is loaded from a POD file, one way to do this
 * is to load the POD class and then copy it to the subclass we want. That is done here.
 *
 * To rotate a node using changes in rotation using the rotateBy... family of methods,
 * as is done to this node, does NOT requre a specialized class. This specialized class
 * is required to handle the freewheeling and friction nature of the behaviour after the
 * rotation has begun.
 *
 * The die cube POD file was created from a Blender model available from the Blender
 * "Two dice" modeling tutorial available online at:
 * http://wiki.blender.org/index.php/Doc:Tutorials/Modeling/Two_dice
 */
-(void) addDieCube {
    
	// Fetch the die cube model from the POD file.
	CC3PODResourceNode *podRezNode = [CC3PODResourceNode nodeFromFile:kDieCubePODFile];
	CC3Node *podDieCube = [podRezNode getNodeNamed:kDieCubePODName];
	
	// We want this node to be a SpinningNode class instead of the CC3PODNode class that
	// is loaded from the POD file. We can swap it out by creating a copy of the loaded
	// POD node, using a different node class as the base.
	dieCube = [[podDieCube copyWithName:kDieCubeName
								asClass:[SpinningNode class]] autorelease];
    
	// Now set some properties, including the friction, and add the die cube to the scene
	dieCube.uniformScale = 1.0;
	dieCube.location = cc3v(0.0, 0.0, 0.0);
	dieCube.isTouchEnabled = YES;
	dieCube.friction = 1.0;
	[self addChild: dieCube];
}

#pragma mark -
#pragma mark Updating custom activity

/**
 * This template method is invoked periodically whenever the 3D nodes are to be updated.
 *
 * This method provides your app with an opportunity to perform update activities before
 * any changes are applied to the transformMatrix of the 3D nodes in the scene.
 *
 * For more info, read the notes of this method on CC3Node.
 */
-(void) updateBeforeTransform: (CC3NodeUpdatingVisitor*) visitor {}

/**
 * This template method is invoked periodically whenever the 3D nodes are to be updated.
 *
 * This method provides your app with an opportunity to perform update activities after
 * the transformMatrix of the 3D nodes in the scen have been recalculated.
 *
 * For more info, read the notes of this method on CC3Node.
 */
-(void) updateAfterTransform: (CC3NodeUpdatingVisitor*) visitor {}

#pragma mark -
#pragma mark Scene opening and closing

/**
 * Callback template method that is invoked automatically when the CC3Layer that
 * holds this scene is first displayed.
 *
 * This method is a good place to invoke one of CC3Camera moveToShowAllOf:... family
 * of methods, used to cause the camera to automatically focus on and frame a particular
 * node, or the entire scene.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) onOpen {

	// Uncomment this line to have the camera move to show the entire scene.
	// This must be done after the CC3Layer has been attached to the view,
	// because this makes use of the camera frustum and projection.
//	[self.activeCamera moveWithDuration: 3.0 toShowAllOf: self];

	// Uncomment this line to draw the bounding box of the scene.
//	self.shouldDrawWireframeBox = YES;
}

/**
 * Callback template method that is invoked automatically when the CC3Layer that
 * holds this scene has been removed from display.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) onClose {}

#pragma mark -
#pragma mark Gesture handling

- (void)startDraggingAt:(CGPoint)touchPoint {
    
    [self pickNodeFromTapAt:touchPoint];
}

- (void)dragBy:(CGPoint)aMovement atVelocity:(CGPoint)aVelocity {
    
    [self rotate:((SpinningNode *)selectedNode) fromSwipeVelocity:aVelocity];
}

- (void)stopDragging {
    
    selectedNode = nil;
}

/** Set this parameter to adjust the rate of rotation from the length of swipe gesture. */
#define kSwipeVelocityScale		400

/**
 * Rotates the specified spinning node by setting its rotation axis
 * and spin speed from the specified 2D drag velocity.
 */
- (void)rotate:(SpinningNode *)aNode fromSwipeVelocity:(CGPoint)swipeVelocity {
	
	// The 2D rotation axis is perpendicular to the drag velocity.
	CGPoint axis2d = ccpPerp(swipeVelocity);
	
	// Project the 2D rotation axis into a 3D axis by mapping the 2D X & Y screen
	// coords to the camera's rightDirection and upDirection, respectively.
	CC3Camera* cam = self.activeCamera;
	aNode.spinAxis = CC3VectorAdd(CC3VectorScaleUniform(cam.rightDirection, axis2d.x),
								  CC3VectorScaleUniform(cam.upDirection, axis2d.y));
    
	// Set the spin speed from the scaled drag velocity.
	aNode.spinSpeed = ccpLength(swipeVelocity) * kSwipeVelocityScale;
    
	// Mark the spinning node as free-wheeling, so that it will start spinning.
	aNode.isFreeWheeling = YES;
}

#pragma mark -
#pragma mark Handling touch events 

/**
 * This method is invoked from the CC3Layer whenever a touch event occurs, if that layer
 * has indicated that it is interested in receiving touch events, and is handling them.
 *
 * Override this method to handle touch events, or remove this method to make use of
 * the superclass behaviour of selecting 3D nodes on each touch-down event.
 *
 * This method is not invoked when gestures are used for user interaction. Your custom
 * CC3Layer processes gestures and invokes higher-level application-defined behaviour
 * on this customized CC3Scene subclass.
 *
 * For more info, read the notes of this method on CC3Scene.
 **
 * Handle touch events in the scene:
 *   - Touch-down events are used to select nodes. Forward these to the touched node picker.
 *   - Touch-move events are used to generate a swipe gesture to rotate the die cube
 *   - Touch-up events are used to mark the die cube as freewheeling if the touch-up event
 *     occurred while the finger is moving.
 * This is a poor UI. We really should be using the touch-stationary event to mark definitively
 * whether the finger stopped before being lifted. But we're just working with what we have handy.
 *
 * If gestures are being used (see the shouldUseGestures variable in the initializeControls method
 * of CC3DemoMashUpLayer), this method will not be invoked. Instead, the gestures invoke handler
 * methods on the CC3DemoMashUpLayer, which then issues higher-level control messages to this scene.
 *
 * It is generally recommended that you use gestures to provide user interaction with the 3D scene.
 */
- (void)touchEvent:(uint)touchType at:(CGPoint)touchPoint {
    struct timeval now;
	gettimeofday(&now, NULL);
    
	// Time since last event
	ccTime dt = (now.tv_sec - lastTouchEventTime.tv_sec) + (now.tv_usec - lastTouchEventTime.tv_usec) / 1000000.0f;
    
	switch (touchType) {
		case kCCTouchBegan:
			[self pickNodeFromTouchEvent: touchType at: touchPoint];
			break;
		case kCCTouchMoved:
            [self rotate:((SpinningNode *)selectedNode) fromSwipeAt:touchPoint interval:dt];
			break;
		case kCCTouchEnded:
            // If the user lifted the finger while in motion, let the cubes know
            // that they can freewheel now. But if the user paused before lifting
            // the finger, consider it stopped.
            ((SpinningNode *)selectedNode).isFreeWheeling = (dt < 0.5);
			selectedNode = nil;
			break;
		default:
			break;
	}
	
	// For all event types, remember when and where the touchpoint was, for subsequent events.
	lastTouchEventPoint = touchPoint;
	lastTouchEventTime = now;
}

/** Set this parameter to adjust the rate of rotation from the length of touch-move swipe. */
#define kSwipeScale 0.6

/**
 * Rotates the specified node, by determining the direction of each touch move event.
 *
 * The touch-move swipe is measured in 2D screen coordinates, which are mapped to
 * 3D coordinates by recognizing that the screen's X-coordinate maps to the camera's
 * rightDirection vector, and the screen's Y-coordinates maps to the camera's upDirection.
 *
 * The node rotates around an axis perpendicular to the swipe. The rotation angle is
 * determined by the length of the touch-move swipe.
 */
- (void)rotate:(SpinningNode *)aNode fromSwipeAt:(CGPoint)touchPoint interval:(ccTime)dt {
    
    CC3Camera *cam = self.activeCamera;
    
	// Get the direction and length of the movement since the last touch move event, in
	// 2D screen coordinates. The 2D rotation axis is perpendicular to this movement.
	CGPoint swipe2d = ccpSub(touchPoint, lastTouchEventPoint);
	CGPoint axis2d = ccpPerp(swipe2d);
	
	// Project the 2D axis into a 3D axis by mapping the 2D X & Y screen coords
	// to the camera's rightDirection and upDirection, respectively.
	CC3Vector axis = CC3VectorAdd(CC3VectorScaleUniform(cam.rightDirection, axis2d.x),
								  CC3VectorScaleUniform(cam.upDirection, axis2d.y));
	GLfloat angle = ccpLength(swipe2d) * kSwipeScale;
    
	// Rotate the cube under direct finger control, by directly rotating by the angle
	// and axis determined by the swipe. If the die cube is just to be directly controlled
	// by finger movement, and is not to freewheel, this is all we have to do.
	[aNode rotateByAngle: angle aroundAxis: axis];
    
	// To allow the cube to freewheel after lifting the finger, have the cube remember
	// the spin axis and spin speed. The spin speed is based on the angle rotated on
	// this event and the interval of time since the last event. Also mark that the
	// die cube is not freewheeling until the finger is lifted.
	aNode.isFreeWheeling = NO;
	aNode.spinAxis = axis;
	aNode.spinSpeed = angle / dt;
}

/**
 * This callback template method is invoked automatically when a node has been picked
 * by the invocation of the pickNodeFromTapAt: or pickNodeFromTouchEvent:at: methods,
 * as a result of a touch event or tap gesture.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
- (void)nodeSelected:(CC3Node *)aNode byTouchEvent:(uint)touchType at:(CGPoint)touchPoint {

    // Remember the node that was selected
	selectedNode = aNode;
}

@end

#pragma mark -
#pragma mark SpinningNode

@implementation SpinningNode

@synthesize spinAxis, spinSpeed, friction, isFreeWheeling;

- (id)initWithTag:(GLuint)aTag withName:(NSString *)aName {
	
    if ((self = [super initWithTag:aTag withName:aName])) {
		spinAxis = kCC3VectorZero;
		spinSpeed = 0.0f;
		friction = 0.0f;
		isFreeWheeling = NO;
	}
	return self;
}

// Don't bother continuing to rotate once below this speed (in degrees per second)
#define kSpinningMinSpeed	6.0

/**
 * On each update, if freewheeling, rotate the node around the spinAxis, by an
 * angle determined by the spinSpeed. Then slow the spinSpeed down based on the
 * friction value and how long the friction has been applied since the last update.
 * Stop rotating altogether once the speed is low enough to be unnoticable, so that
 * we don't continue to perform transforms (and rebuilding shadows) unnecessarily.
 */
- (void)updateBeforeTransform:(CC3NodeUpdatingVisitor *)visitor {

	GLfloat dt = visitor.deltaTime;
	if (isFreeWheeling && spinSpeed > kSpinningMinSpeed) {
		GLfloat deltaAngle = spinSpeed * dt;
		[self rotateByAngle: deltaAngle aroundAxis: spinAxis];
		spinSpeed -= (deltaAngle * friction);
		LogCleanTrace(@"Spinning %@ by %.3f at speed %.3f", self, deltaAngle, spinSpeed);
	}
}

@end