//
//  PTATableViewCell.h
//  PTATableViewCell
//
//  Objective-C code Copyright (c) 2014 Ali Karagoz. All rights reserved.
//  Swift adaptation Copyright (c) 2014 Nicolas Gomollon. All rights reserved.
//  Re-adapted Obj-C Copyright (c) 2014 Nicolas Gomollon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PTATableViewCell;


/** Describes the mode used during a pan. */
typedef enum {
	
	/** The pan to trigger action is effectively disabled. */
	PTATableViewCellModeNone,
	
	/** The cell bounces back to its original position after it’s released. */
	PTATableViewCellModeSwitch,
	
	/** The cell slides off screen in the direction it’s being dragged ONLY if it’s released after `triggerPercentage` is reached. If `triggerPercentage` is NOT reached when the cell is released, the cell bounces back to its original position. */
	PTATableViewCellModeExit
	
} PTATableViewCellMode;


/** Describes the slide behaviors that the sliding view can use when the cell is dragged. */
typedef enum {
	
	/** The view remains still as the cell is dragged. */
	PTATableViewCellSlidingViewBehaviorNone,
	
	/** The view is dragged with the cell until `triggerPercentage` is reached, at which point the view remains still. */
	PTATableViewCellSlidingViewBehaviorDragWithPanThenStick,
	
	/** The view remains still until `triggerPercentage` is reached, at which point the view is dragged with the cell. */
	PTATableViewCellSlidingViewBehaviorStickThenDragWithPan,
	
	/** The view is dragged with the cell. */
	PTATableViewCellSlidingViewBehaviorDragWithPan
	
} PTATableViewCellSlidingViewBehavior;


/** Describes the state that has been triggered by the user. */
typedef enum {
	
	/** No state has been triggered. */
	PTATableViewCellStateNone,
	
	/** The state triggered during a left-to-right swipe. */
	PTATableViewCellStateLeftToRight,
	
	/** The state triggered during a right-to-left swipe. */
	PTATableViewCellStateRightToLeft
	
} PTATableViewCellState;


/** The attributes used when swiping the cell in a specific state. */
@interface PTATableViewCellStateAttributes : NSObject

/** The mode to use with the cell state. Defaults to `.None`. */
@property (nonatomic, assign) PTATableViewCellMode mode;

/** The percent of the width of the cell required to be panned before the action is triggered. Defaults to 20%. */
@property (nonatomic, assign) CGFloat triggerPercentage;

/** The rubberband effect applied the farther the cell is dragged. Defaults to `true`. */
@property (nonatomic, assign) BOOL rubberbandBounce;

/** The color that’s revealed when an action is triggered. Defaults to `nil`. */
@property (nonatomic, strong) UIColor *color;

/** The view below the cell that’s revealed when an action is triggered. Defaults to `nil`. */
@property (nonatomic, strong) UIView *view;

/** The slide behavior that `view` should use when the cell is panned. Defaults to `.StickThenDragWithPan`. */
@property (nonatomic, assign) PTATableViewCellSlidingViewBehavior viewBehavior;

- (id)init;
- (id)initWithMode:(PTATableViewCellMode)mode color:(UIColor *)color view:(UIView *)view;

@end


/** The delegate of a PTATableViewCell object must adopt the PTATableViewCellDelegate protocol in order to perform an action when triggered. Optional methods of the protocol allow the delegate to be notified of a cell’s swipe state, and determine whether a cell should be swiped. */
@protocol PTATableViewCellDelegate <NSObject>

@required

/** Tells the delegate that the specified cell’s state was triggered. */
- (void)tableViewCell:(PTATableViewCell *)cell didTriggerState:(PTATableViewCellState)state withMode:(PTATableViewCellMode)mode;

@optional

/** Asks the delegate whether a given cell should be swiped. Defaults to `true` if not implemented. */
- (BOOL)tableViewCellShouldSwipe:(PTATableViewCell *)cell;

/** Tells the delegate that the specified cell is being swiped with a percentage. */
- (void)tableViewCellIsSwiping:(PTATableViewCell *)cell withPercentage:(CGFloat)percentage;

/** Tells the delegate that the specified cell started swiping. */
- (void)tableViewCellDidStartSwiping:(PTATableViewCell *)cell;

/** Tells the delegate that the specified cell ended swiping. */
- (void)tableViewCellDidEndSwiping:(PTATableViewCell *)cell;

@end


@interface PTATableViewCell : UITableViewCell {
	UIPanGestureRecognizer *panGestureRecognizer;
	PTATableViewCellState direction;
	PTATableViewCellState stateOptions;
	
	UIColor *defaultColor;
	UIView *slidingView;
	UIView *colorIndicatorView;
}

@property (nonatomic, strong, readonly) UIView *slidingView;
@property (nonatomic, strong, readonly) UIView *colorIndicatorView;

/** The object that acts as the delegate of the receiving table view cell. */
@property (nonatomic, weak) id<PTATableViewCellDelegate> delegate;

/** The attributes used when swiping the cell from left to right. */
@property (nonatomic, strong) PTATableViewCellStateAttributes *leftToRightAttr;

/** The attributes used when swiping the cell from right to left. */
@property (nonatomic, strong) PTATableViewCellStateAttributes *rightToLeftAttr;

/** Sets a pan gesture for the specified state and mode. Don’t forget to implement the delegate method `tableViewCell(cell:didTriggerState:withMode:)` to perform an action when the cell’s state is triggered. */
- (void)setPanGestureState:(PTATableViewCellState)state mode:(PTATableViewCellMode)mode color:(UIColor *)color view:(UIView *)view;

@end
