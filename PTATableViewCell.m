//
//  PTATableViewCell.m
//  PTATableViewCell
//
//  Objective-C code Copyright (c) 2014 Ali Karagoz. All rights reserved.
//  Swift adaptation Copyright (c) 2014 Nicolas Gomollon. All rights reserved.
//  Re-adapted Obj-C Copyright (c) 2014 Nicolas Gomollon. All rights reserved.
//

#import "PTATableViewCell.h"


@implementation PTATableViewCellStateAttributes

- (id)init {
	return [self initWithMode:PTATableViewCellModeNone color:nil view:nil];
}

- (id)initWithMode:(PTATableViewCellMode)mode color:(UIColor *)color view:(UIView *)view {
	if (self = [super init]) {
		self.mode = mode;
		self.triggerPercentage = 0.2f;
		self.rubberbandBounce = YES;
		self.color = color;
		self.view = view;
		self.viewBehavior = PTATableViewCellSlidingViewBehaviorStickThenDragWithPan;
	}
	return self;
}

@end


@implementation PTATableViewCell

@synthesize slidingView, colorIndicatorView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		direction = PTATableViewCellStateNone;
		stateOptions = PTATableViewCellStateNone;
		defaultColor = [UIColor colorWithRed:227.0f/255.0f green:227.0f/255.0f blue:227.0f/255.0f alpha:1.0f];
		[self initialize];
	}
	return self;
}

- (void)initialize {
	panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
	panGestureRecognizer.delegate = self;
	[self addGestureRecognizer:panGestureRecognizer];
}

- (void)prepareForReuse {
	[super prepareForReuse];
	
	[self removeSwipingView];
	stateOptions = PTATableViewCellStateNone;
	self.leftToRightAttr = [[PTATableViewCellStateAttributes alloc] init];
	self.rightToLeftAttr = [[PTATableViewCellStateAttributes alloc] init];
}

- (UIView *)slidingView {
	if (slidingView) {
		return slidingView;
	}
	
	slidingView = [[UIView alloc] init];
	slidingView.contentMode = UIViewContentModeCenter;
	
	return slidingView;
}

- (UIView *)colorIndicatorView {
	if (colorIndicatorView) {
		return colorIndicatorView;
	}
	
	colorIndicatorView = [[UIView alloc] initWithFrame:self.bounds];
	colorIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	colorIndicatorView.backgroundColor = defaultColor;
	
	return colorIndicatorView;
}

- (void)addSubviewToSlidingView:(UIView *)view {
	for (UIView *subview in self.slidingView.subviews) {
		[subview removeFromSuperview];
	}
	[self.slidingView addSubview:view];
}


- (void)setupSwipingView {
	if (colorIndicatorView) { return; }
	[self.colorIndicatorView addSubview:self.slidingView];
	[self insertSubview:self.colorIndicatorView belowSubview:self.contentView];
}

- (void)removeSwipingView {
	if (!colorIndicatorView) { return; }
	
	if (slidingView) {
		[slidingView removeFromSuperview];
		slidingView = nil;
	}
	
	if (colorIndicatorView) {
		[colorIndicatorView removeFromSuperview];
		colorIndicatorView = nil;
	}
}


- (CGFloat)offsetWithPercentage:(CGFloat)percentage relativeToWidth:(CGFloat)width {
	CGFloat offset = percentage * width;
	
	if (offset < -width) {
		offset = -width;
	} else if (offset > width) {
		offset = width;
	}
	
	return offset;
}

- (CGFloat)percentageWithOffset:(CGFloat)offset relativeToWidth:(CGFloat)width {
	CGFloat percentage = offset / width;
	
	if (percentage < -1.0f) {
		percentage = -1.0f;
	} else if (percentage > 1.0f) {
		percentage = 1.0f;
	}
	
	return percentage;
}

- (NSTimeInterval)animationDurationWithVelocity:(CGPoint)velocity {
	NSTimeInterval DurationHighLimit = 0.1;
	NSTimeInterval DurationLowLimit = 0.25;
	
	CGFloat width = CGRectGetWidth(self.bounds);
	NSTimeInterval animationDurationDiff = DurationHighLimit - DurationLowLimit;
	CGFloat horizontalVelocity = velocity.x;
	
	if (horizontalVelocity < -width) {
		horizontalVelocity = -width;
	} else if (horizontalVelocity > width) {
		horizontalVelocity = width;
	}
	
	return (DurationHighLimit + DurationLowLimit) - fabsf((horizontalVelocity / width) * animationDurationDiff);
}

- (PTATableViewCellState)directionWithPercentage:(CGFloat)percentage {
	if (percentage < 0.0f) {
		return PTATableViewCellStateRightToLeft;
	} else if (percentage > 0.0f) {
		return PTATableViewCellStateLeftToRight;
	}
	return PTATableViewCellStateNone;
}

- (UIView *)viewWithPercentage:(CGFloat)percentage {
	if (percentage < 0.0f) {
		return self.rightToLeftAttr.view;
	} else if (percentage > 0.0f) {
		return self.leftToRightAttr.view;
	}
	return nil;
}

- (PTATableViewCellSlidingViewBehavior)viewBehaviorWithPercentage:(CGFloat)percentage {
	if (([self directionWithPercentage:percentage] == PTATableViewCellStateLeftToRight) && (self.leftToRightAttr.mode != PTATableViewCellModeNone)) {
		return self.leftToRightAttr.viewBehavior;
	} else if (([self directionWithPercentage:percentage] == PTATableViewCellStateRightToLeft) && (self.rightToLeftAttr.mode != PTATableViewCellModeNone)) {
		return self.rightToLeftAttr.viewBehavior;
	}
	return PTATableViewCellSlidingViewBehaviorNone;
}

- (CGFloat)alphaWithPercentage:(CGFloat)percentage {
	if ((percentage > 0.0f) && (percentage < self.leftToRightAttr.triggerPercentage)) {
		return percentage / self.leftToRightAttr.triggerPercentage;
	} else if ((percentage < 0.0f) && (percentage > -self.rightToLeftAttr.triggerPercentage)) {
		return fabsf(percentage / self.rightToLeftAttr.triggerPercentage);
	}
	return 1.0f;
}

- (UIColor *)colorWithPercentage:(CGFloat)percentage {
	if ((percentage >= self.leftToRightAttr.triggerPercentage) && (self.leftToRightAttr.mode != PTATableViewCellModeNone) && self.leftToRightAttr.color) {
		return self.leftToRightAttr.color;
	} else if ((percentage <= -self.rightToLeftAttr.triggerPercentage) && (self.rightToLeftAttr.mode != PTATableViewCellModeNone) && self.rightToLeftAttr.color) {
		return self.rightToLeftAttr.color;
	}
	return defaultColor;
}

- (PTATableViewCellState)stateWithPercentage:(CGFloat)percentage {
	if ((percentage >= self.leftToRightAttr.triggerPercentage) && (self.leftToRightAttr.mode != PTATableViewCellModeNone)) {
		return PTATableViewCellStateLeftToRight;
	} else if ((percentage <= -self.rightToLeftAttr.triggerPercentage) && (self.rightToLeftAttr.mode != PTATableViewCellModeNone)) {
		return PTATableViewCellStateRightToLeft;
	}
	return PTATableViewCellStateNone;
}


- (void)animateWithOffset:(CGFloat)offset {
	CGFloat percentage = [self percentageWithOffset:offset relativeToWidth:CGRectGetWidth(self.bounds)];
	
	UIView *view = [self viewWithPercentage:percentage];
	if (view) {
		[self addSubviewToSlidingView:view];
		self.slidingView.alpha = [self alphaWithPercentage:percentage];
		[self slideViewWithPercentage:percentage];
	}
	
	self.colorIndicatorView.backgroundColor = [self colorWithPercentage:percentage];
}

- (void)slideViewWithPercentage:(CGFloat)percentage {
	[self slideViewWithPercentage:percentage view:[self viewWithPercentage:percentage] andDragBehavior:[self viewBehaviorWithPercentage:percentage]];
}

- (void)slideViewWithPercentage:(CGFloat)percentage view:(UIView *)view andDragBehavior:(PTATableViewCellSlidingViewBehavior)dragBehavior {
	CGPoint position = CGPointZero;
	position.y = CGRectGetHeight(self.bounds) / 2.0f;
	
	CGFloat width = CGRectGetWidth(self.bounds);
	CGFloat halfLeftToRightTriggerPercentage = self.leftToRightAttr.triggerPercentage / 2.0f;
	CGFloat halfRightToLeftTriggerPercentage = self.rightToLeftAttr.triggerPercentage / 2.0f;
	
	switch (dragBehavior) {
		case PTATableViewCellSlidingViewBehaviorStickThenDragWithPan: {
			if ((percentage >= 0.0f) && (percentage < self.leftToRightAttr.triggerPercentage)) {
				position.x = [self offsetWithPercentage:halfLeftToRightTriggerPercentage relativeToWidth:width];
			} else if (percentage >= self.leftToRightAttr.triggerPercentage) {
				position.x = [self offsetWithPercentage:(percentage - halfLeftToRightTriggerPercentage) relativeToWidth:width];
			} else if ((percentage < 0.0f) && (percentage >= -self.rightToLeftAttr.triggerPercentage)) {
				position.x = width - [self offsetWithPercentage:halfRightToLeftTriggerPercentage relativeToWidth:width];
			} else if (percentage <= -self.rightToLeftAttr.triggerPercentage) {
				position.x = width + [self offsetWithPercentage:(percentage + halfRightToLeftTriggerPercentage) relativeToWidth:width];
			}
			break;
		}
			
		case PTATableViewCellSlidingViewBehaviorDragWithPanThenStick: {
			if ((percentage >= 0.0f) && (percentage < self.leftToRightAttr.triggerPercentage)) {
				position.x = [self offsetWithPercentage:(percentage - halfLeftToRightTriggerPercentage) relativeToWidth:width];
			} else if (percentage >= self.leftToRightAttr.triggerPercentage) {
				position.x = [self offsetWithPercentage:halfLeftToRightTriggerPercentage relativeToWidth:width];
			} else if ((percentage < 0.0f) && (percentage >= -self.rightToLeftAttr.triggerPercentage)) {
				position.x = width + [self offsetWithPercentage:(percentage + halfRightToLeftTriggerPercentage) relativeToWidth:width];
			} else if (percentage <= -self.rightToLeftAttr.triggerPercentage) {
				position.x = width - [self offsetWithPercentage:halfRightToLeftTriggerPercentage relativeToWidth:width];
			}
			break;
		}
			
		case PTATableViewCellSlidingViewBehaviorDragWithPan: {
			if (direction == PTATableViewCellStateLeftToRight) {
				position.x = [self offsetWithPercentage:(percentage - halfLeftToRightTriggerPercentage) relativeToWidth:width];
			} else if (direction == PTATableViewCellStateRightToLeft) {
				position.x = width + [self offsetWithPercentage:(percentage + halfRightToLeftTriggerPercentage) relativeToWidth:width];
			}
			break;
		}
			
		case PTATableViewCellSlidingViewBehaviorNone: {
			if (direction == PTATableViewCellStateLeftToRight) {
				position.x = [self offsetWithPercentage:halfLeftToRightTriggerPercentage relativeToWidth:width];
			} else if (direction == PTATableViewCellStateRightToLeft) {
				position.x = width - [self offsetWithPercentage:halfRightToLeftTriggerPercentage relativeToWidth:width];
			}
			break;
		}
	}
	
	if (view) {
		CGRect activeViewFrame = view.bounds;
		activeViewFrame.origin.x = position.x - (activeViewFrame.size.width / 2.0f);
		activeViewFrame.origin.y = position.y - (activeViewFrame.size.height / 2.0f);
		
		slidingView.frame = activeViewFrame;
	}
}

- (void)moveWithPercentage:(CGFloat)percentage duration:(NSTimeInterval)duration direction:(PTATableViewCellState)_direction {
	CGFloat origin = 0.0f;
	
	if (_direction == PTATableViewCellStateRightToLeft) {
		origin -= CGRectGetWidth(self.bounds);
	} else if (_direction == PTATableViewCellStateLeftToRight) {
		origin += CGRectGetWidth(self.bounds);
	}
	
	CGRect frame = self.contentView.frame;
	frame.origin.x = origin;
	
	colorIndicatorView.backgroundColor = [self colorWithPercentage:percentage];
	
	[UIView animateWithDuration:duration delay:0.0 options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction) animations:^{
		self.contentView.frame = frame;
		self.slidingView.alpha = 0.0f;
		[self slideViewWithPercentage:[self percentageWithOffset:origin relativeToWidth:CGRectGetWidth(self.bounds)] view:[self viewWithPercentage:percentage] andDragBehavior:[self viewBehaviorWithPercentage:percentage]];
	} completion:^(BOOL finished) {
		[self executeCompletionBlockWithPercentage:percentage];
	}];
}

- (void)swipeToOriginWithPercentage:(CGFloat)percentage {
	[self executeCompletionBlockWithPercentage:percentage];
	
	CGFloat offset = [self offsetWithPercentage:percentage relativeToWidth:CGRectGetWidth(self.bounds)];
	
	[UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.6f initialSpringVelocity:(offset / 100.0f) options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction) animations:^{
		self.contentView.frame = self.contentView.bounds;
		self.colorIndicatorView.backgroundColor = defaultColor;
		self.slidingView.alpha = 0.0f;
		[self slideViewWithPercentage:0.0f view:[self viewWithPercentage:percentage] andDragBehavior:PTATableViewCellSlidingViewBehaviorNone];
	} completion:^(BOOL finished) {
		[self removeSwipingView];
	}];
}

- (void)executeCompletionBlockWithPercentage:(CGFloat)percentage {
	PTATableViewCellState state = [self stateWithPercentage:percentage];
	PTATableViewCellMode mode = PTATableViewCellModeNone;
	
	switch (state) {
		case PTATableViewCellStateLeftToRight: {
			mode = self.leftToRightAttr.mode;
			break;
		}
			
		case PTATableViewCellStateRightToLeft: {
			mode = self.rightToLeftAttr.mode;
			break;
		}
			
		default: {
			mode = PTATableViewCellModeNone;
			break;
		}
	}
	
	if (self.delegate) {
		[self.delegate tableViewCell:self didTriggerState:state withMode:mode];
	}
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	if ([panGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
		CGPoint point = [panGestureRecognizer velocityInView:self];
		if (fabsf(point.x) > fabsf(point.y)) {
			
			if ((point.x < 0.0f) && !(stateOptions & PTATableViewCellStateRightToLeft)) {
				return NO;
			}
			
			if ((point.x > 0.0f) && !(stateOptions & PTATableViewCellStateLeftToRight)) {
				return NO;
			}
			
			if (self.delegate && [self.delegate respondsToSelector:@selector(tableViewCellDidStartSwiping:)]) {
				[self.delegate tableViewCellDidStartSwiping:self];
			}
			return YES;
		}
	}
	return NO;
}

- (void)pan:(UIPanGestureRecognizer *)gesture {
	if (self.delegate && [self.delegate respondsToSelector:@selector(tableViewCellShouldSwipe:)]) {
		if (![self.delegate tableViewCellShouldSwipe:self]) { return; }
	}
	
	CGFloat width = CGRectGetWidth(self.bounds);
	
	CGPoint translation = [gesture translationInView:self];
	CGPoint velocity = [gesture velocityInView:self];
	NSTimeInterval animationDuration = [self animationDurationWithVelocity:velocity];
	
	CGFloat panOffset = translation.x;
	if (((panOffset > 0.0f) && self.leftToRightAttr.rubberbandBounce) ||
		((panOffset < 0.0f) && self.rightToLeftAttr.rubberbandBounce)) {
		CGFloat offset = fabsf(panOffset);
		panOffset = (offset * 0.55f * width) / (offset * 0.55f + width);
		panOffset *= (translation.x < 0.0f) ? -1.0f : 1.0f;
	}
	
	CGPoint actualTranslation = CGPointMake(panOffset, translation.y);
	CGFloat percentage = [self percentageWithOffset:actualTranslation.x relativeToWidth:width];
	direction = [self directionWithPercentage:percentage];
	
	if ((gesture.state == UIGestureRecognizerStateBegan) || (gesture.state == UIGestureRecognizerStateChanged)) {
		[self setupSwipingView];
		
		self.contentView.frame = CGRectOffset(self.contentView.bounds, actualTranslation.x, 0.0f);
		self.colorIndicatorView.backgroundColor = [self colorWithPercentage:percentage];
		self.slidingView.alpha = [self alphaWithPercentage:percentage];
		
		UIView *view = [self viewWithPercentage:percentage];
		if (view) {
			[self addSubviewToSlidingView:view];
		}
		[self slideViewWithPercentage:percentage];
		
		if (self.delegate && [self.delegate respondsToSelector:@selector(tableViewCellIsSwiping:withPercentage:)]) {
			[self.delegate tableViewCellIsSwiping:self withPercentage:percentage];
		}
	} else if ((gesture.state == UIGestureRecognizerStateEnded) || (gesture.state == UIGestureRecognizerStateCancelled)) {
		PTATableViewCellState cellState = [self stateWithPercentage:percentage];
		PTATableViewCellMode cellMode = PTATableViewCellModeNone;
		
		if ((cellState == PTATableViewCellStateLeftToRight) && (self.leftToRightAttr.mode != PTATableViewCellModeNone)) {
			cellMode = self.leftToRightAttr.mode;
		} else if ((cellState == PTATableViewCellStateRightToLeft) && (self.rightToLeftAttr.mode != PTATableViewCellModeNone)) {
			cellMode = self.rightToLeftAttr.mode;
		}
		
		if ((cellMode == PTATableViewCellModeExit) && !(direction & PTATableViewCellStateNone)) {
			[self moveWithPercentage:percentage duration:animationDuration direction:cellState];
		} else {
			[self swipeToOriginWithPercentage:percentage];
		}
		
		if (self.delegate && [self.delegate respondsToSelector:@selector(tableViewCellDidEndSwiping:)]) {
			[self.delegate tableViewCellDidEndSwiping:self];
		}
	}
}


- (void)setPanGestureState:(PTATableViewCellState)state mode:(PTATableViewCellMode)mode color:(UIColor *)color view:(UIView *)view {
	stateOptions = stateOptions | state;
	
	if (state & PTATableViewCellStateLeftToRight) {
		self.leftToRightAttr = [[PTATableViewCellStateAttributes alloc] initWithMode:mode color:color view:view];
		
		if (mode == PTATableViewCellModeNone) {
			stateOptions = stateOptions & ~PTATableViewCellStateLeftToRight;
		}
	}
	
	if (state & PTATableViewCellStateRightToLeft) {
		self.rightToLeftAttr = [[PTATableViewCellStateAttributes alloc] initWithMode:mode color:color view:view];
		
		if (mode == PTATableViewCellModeNone) {
			stateOptions = stateOptions & ~PTATableViewCellStateRightToLeft;
		}
	}
}

@end
