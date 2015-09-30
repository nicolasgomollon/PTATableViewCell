//
//  PTATableViewHeaderFooterView.swift
//  PTATableViewCell
//
//  Objective-C code Copyright (c) 2014 Ali Karagoz. All rights reserved.
//  Swift adaptation Copyright (c) 2015 Nicolas Gomollon. All rights reserved.
//

import Foundation
import UIKit


@objc
public protocol ObjC_PTATableViewHeaderFooterViewDelegate: NSObjectProtocol {
	
	/** Asks the delegate whether a given header/footer view should be swiped. Defaults to `true` if not implemented. */
	optional func tableViewHeaderFooterViewShouldSwipe(view: PTATableViewHeaderFooterView) -> Bool
	
	/** Tells the delegate that the specified header/footer view is being swiped with a percentage. */
	optional func tableViewHeaderFooterViewIsSwiping(view: PTATableViewHeaderFooterView, withPercentage percentage: Double)
	
	/** Tells the delegate that the specified header/footer view started swiping. */
	optional func tableViewHeaderFooterViewDidStartSwiping(view: PTATableViewHeaderFooterView)
	
	/** Tells the delegate that the specified header/footer view ended swiping. */
	optional func tableViewHeaderFooterViewDidEndSwiping(view: PTATableViewHeaderFooterView)
	
}

/** The delegate of a PTATableViewHeaderFooterView object must adopt the PTATableViewHeaderFooterViewDelegate protocol in order to perform an action when triggered. Optional methods of the protocol allow the delegate to be notified of a header/footer view’s swipe state, and determine whether a header/footer view should be swiped. */
public protocol PTATableViewHeaderFooterViewDelegate: ObjC_PTATableViewHeaderFooterViewDelegate {
	
	/** Tells the delegate that the specified cell’s state was triggered. */
	func tableViewHeaderFooterView(view: PTATableViewHeaderFooterView, didTriggerState state: PTATableViewItemState, withMode mode: PTATableViewItemMode)
	
}


public class PTATableViewHeaderFooterView: UITableViewHeaderFooterView {
	
	/** The object that acts as the delegate of the receiving table view header/footer view. */
	public weak var delegate: PTATableViewHeaderFooterViewDelegate!
	
	private var initialized: Bool = false
	
	private var panGestureRecognizer: UIPanGestureRecognizer!
	
	private var direction: PTATableViewItemState = .None
	
	private var stateOptions: PTATableViewItemState = .None
	
	
	/** The color that’s revealed before an action is triggered. Defaults to a light gray color. */
	public var defaultColor = UIColor(red: 227.0/255.0, green: 227.0/255.0, blue: 227.0/255.0, alpha: 1.0)
	
	/** The attributes used when swiping the header/footer view from left to right. */
	public var leftToRightAttr = PTATableViewItemStateAttributes()
	
	/** The attributes used when swiping the header/footer view from right to left. */
	public var rightToLeftAttr = PTATableViewItemStateAttributes()
	
	
	private var _slidingView: UIView?
	private var slidingView: UIView! {
		get {
			if let slidingView = _slidingView {
				return slidingView
			}
			
			_slidingView = UIView()
			_slidingView!.contentMode = .Center
			
			return _slidingView
		}
		set {
			_slidingView = newValue
		}
	}
	
	private var _colorIndicatorView: UIView?
	private var colorIndicatorView: UIView! {
		get {
			if let colorIndicatorView = _colorIndicatorView {
				return colorIndicatorView
			}
			
			_colorIndicatorView = UIView(frame: bounds)
			_colorIndicatorView!.autoresizingMask = ([.FlexibleHeight, .FlexibleWidth])
			_colorIndicatorView!.backgroundColor = defaultColor
			
			return _colorIndicatorView
		}
		set {
			_colorIndicatorView = newValue
		}
	}
	
	private func addSubviewToSlidingView(view: UIView) {
		for subview in slidingView.subviews {
			subview.removeFromSuperview()
		}
		slidingView.addSubview(view)
	}
	
	
	public override init(reuseIdentifier: String?) {
		super.init(reuseIdentifier: reuseIdentifier)
		initialize()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}
	
	private func initialize() {
		if initialized { return }
		initialized = true
		
		contentView.backgroundColor = .whiteColor()
		panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "_pan:")
		panGestureRecognizer.delegate = self
		addGestureRecognizer(panGestureRecognizer)
	}
	
	public override func prepareForReuse() {
		super.prepareForReuse()
		
		removeSwipingView()
		stateOptions = .None
		leftToRightAttr = PTATableViewItemStateAttributes()
		rightToLeftAttr = PTATableViewItemStateAttributes()
	}
	
}

private extension PTATableViewHeaderFooterView {
	
	private func setupSwipingView() {
		if _colorIndicatorView != nil { return }
		colorIndicatorView.addSubview(slidingView)
		// TODO: Check this out on iOS 7.
		insertSubview(colorIndicatorView, belowSubview: contentView)
	}
	
	private func removeSwipingView() {
		if _colorIndicatorView == nil { return }
		
		slidingView?.removeFromSuperview()
		slidingView = nil
		
		colorIndicatorView?.removeFromSuperview()
		colorIndicatorView = nil
	}
	
}

private extension PTATableViewHeaderFooterView {
	
	private func animationDurationWith(velocity velocity: CGPoint) -> NSTimeInterval {
		let DurationHighLimit = 0.1
		let DurationLowLimit = 0.25
		
		let width = CGRectGetWidth(bounds)
		let animationDurationDiff = DurationHighLimit - DurationLowLimit
		var horizontalVelocity = velocity.x
		
		if horizontalVelocity < -width {
			horizontalVelocity = -width
		} else if horizontalVelocity > width {
			horizontalVelocity = width
		}
		
		return (DurationHighLimit + DurationLowLimit) - abs(Double(horizontalVelocity / width) * animationDurationDiff)
	}
	
	private func viewWith(percentage percentage: Double) -> UIView? {
		if percentage < 0.0 {
			return rightToLeftAttr.view
		} else if percentage > 0.0 {
			return leftToRightAttr.view
		}
		return nil
	}
	
	private func viewBehaviorWith(percentage percentage: Double) -> PTATableViewItemSlidingViewBehavior {
		if (PTATableViewItemHelper.directionWith(percentage: percentage) == .LeftToRight) && (leftToRightAttr.mode != .None) {
			return leftToRightAttr.viewBehavior
		} else if (PTATableViewItemHelper.directionWith(percentage: percentage) == .RightToLeft) && (rightToLeftAttr.mode != .None) {
			return rightToLeftAttr.viewBehavior
		}
		return .None
	}
	
	private func alphaWith(percentage percentage: Double) -> CGFloat {
		if (percentage > 0.0) && (percentage < leftToRightAttr.triggerPercentage) {
			return CGFloat(percentage / leftToRightAttr.triggerPercentage)
		} else if (percentage < 0.0) && (percentage > -rightToLeftAttr.triggerPercentage) {
			return CGFloat(abs(percentage / rightToLeftAttr.triggerPercentage))
		}
		return 1.0
	}
	
	private func colorWith(percentage percentage: Double) -> UIColor {
		if (percentage >= leftToRightAttr.triggerPercentage) && (leftToRightAttr.mode != .None) && (leftToRightAttr.color != nil) {
			return leftToRightAttr.color!
		} else if (percentage <= -rightToLeftAttr.triggerPercentage) && (rightToLeftAttr.mode != .None) && (rightToLeftAttr.color != nil) {
			return rightToLeftAttr.color!
		}
		return defaultColor
	}
	
	private func stateWith(percentage percentage: Double) -> PTATableViewItemState {
		if (percentage >= leftToRightAttr.triggerPercentage) && (leftToRightAttr.mode != .None) {
			return .LeftToRight
		} else if (percentage <= -rightToLeftAttr.triggerPercentage) && (rightToLeftAttr.mode != .None) {
			return .RightToLeft
		}
		return .None
	}
	
}

private extension PTATableViewHeaderFooterView {
	
	private func animateWith(offset offset: Double) {
		let percentage = PTATableViewItemHelper.percentageWith(offset: offset, relativeToWidth: Double(CGRectGetWidth(bounds)))
		
		if let view = viewWith(percentage: percentage) {
			addSubviewToSlidingView(view)
			slidingView.alpha = alphaWith(percentage: percentage)
			slideViewWith(percentage: percentage)
		}
		
		colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
	}
	
	private func slideViewWith(percentage percentage: Double) {
		slideViewWith(percentage: percentage, view: viewWith(percentage: percentage), andDragBehavior: viewBehaviorWith(percentage: percentage))
	}
	
	private func slideViewWith(percentage percentage: Double, view: UIView?, andDragBehavior dragBehavior: PTATableViewItemSlidingViewBehavior) {
		var position = CGPointZero
		position.y = CGRectGetHeight(bounds) / 2.0
		
		let width = CGRectGetWidth(bounds)
		let halfLeftToRightTriggerPercentage = leftToRightAttr.triggerPercentage / 2.0
		let halfRightToLeftTriggerPercentage = rightToLeftAttr.triggerPercentage / 2.0
		
		switch dragBehavior {
			
		case .StickThenDragWithPan:
			if direction == .LeftToRight {
				if (percentage >= 0.0) && (percentage < leftToRightAttr.triggerPercentage) {
					position.x = PTATableViewItemHelper.offsetWith(percentage: halfLeftToRightTriggerPercentage, relativeToWidth: width)
				} else if percentage >= leftToRightAttr.triggerPercentage {
					position.x = PTATableViewItemHelper.offsetWith(percentage: percentage - halfLeftToRightTriggerPercentage, relativeToWidth: width)
				}
			} else if direction == .RightToLeft {
				if (percentage <= 0.0) && (percentage >= -rightToLeftAttr.triggerPercentage) {
					position.x = width - PTATableViewItemHelper.offsetWith(percentage: halfRightToLeftTriggerPercentage, relativeToWidth: width)
				} else if percentage <= -rightToLeftAttr.triggerPercentage {
					position.x = width + PTATableViewItemHelper.offsetWith(percentage: percentage + halfRightToLeftTriggerPercentage, relativeToWidth: width)
				}
			}
			
		case .DragWithPanThenStick:
			if direction == .LeftToRight {
				if (percentage >= 0.0) && (percentage < leftToRightAttr.triggerPercentage) {
					position.x = PTATableViewItemHelper.offsetWith(percentage: percentage - halfLeftToRightTriggerPercentage, relativeToWidth: width)
				} else if percentage >= leftToRightAttr.triggerPercentage {
					position.x = PTATableViewItemHelper.offsetWith(percentage: halfLeftToRightTriggerPercentage, relativeToWidth: width)
				}
			} else if direction == .RightToLeft {
				if (percentage <= 0.0) && (percentage >= -rightToLeftAttr.triggerPercentage) {
					position.x = width + PTATableViewItemHelper.offsetWith(percentage: percentage + halfRightToLeftTriggerPercentage, relativeToWidth: width)
				} else if percentage <= -rightToLeftAttr.triggerPercentage {
					position.x = width - PTATableViewItemHelper.offsetWith(percentage: halfRightToLeftTriggerPercentage, relativeToWidth: width)
				}
			}
			
		case .DragWithPan:
			if direction == .LeftToRight {
				position.x = PTATableViewItemHelper.offsetWith(percentage: percentage - halfLeftToRightTriggerPercentage, relativeToWidth: width)
			} else if direction == .RightToLeft {
				position.x = width + PTATableViewItemHelper.offsetWith(percentage: percentage + halfRightToLeftTriggerPercentage, relativeToWidth: width)
			}
			
		case .None:
			if direction == .LeftToRight {
				position.x = PTATableViewItemHelper.offsetWith(percentage: halfLeftToRightTriggerPercentage, relativeToWidth: width)
			} else if direction == .RightToLeft {
				position.x = width - PTATableViewItemHelper.offsetWith(percentage: halfRightToLeftTriggerPercentage, relativeToWidth: width)
			}
			
		}
		
		if let activeView = view {
			var activeViewFrame = activeView.bounds
			activeViewFrame.origin.x = position.x - (activeViewFrame.size.width / 2.0)
			activeViewFrame.origin.y = position.y - (activeViewFrame.size.height / 2.0)
			
			slidingView.frame = activeViewFrame
		}
	}
	
	private func moveWith(percentage percentage: Double, duration: NSTimeInterval, direction: PTATableViewItemState) {
		var origin: CGFloat = 0.0
		
		if direction == .RightToLeft {
			origin -= CGRectGetWidth(bounds)
		} else if direction == .LeftToRight {
			origin += CGRectGetWidth(bounds)
		}
		
		var frame = contentView.frame
		frame.origin.x = origin
		
		colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
		
		UIView.animateWithDuration(duration, delay: 0.0, options: ([.CurveEaseOut, .AllowUserInteraction]), animations: { [unowned self] in
			self.contentView.frame = frame
			self.slidingView.alpha = 0.0
			self.slideViewWith(percentage: PTATableViewItemHelper.percentageWith(offset: Double(origin), relativeToWidth: Double(CGRectGetWidth(self.bounds))), view: self.viewWith(percentage: percentage), andDragBehavior: self.viewBehaviorWith(percentage: percentage))
			}, completion: { [unowned self] (completed: Bool) -> Void in
				self.executeCompletionBlockWith(percentage: percentage)
			})
	}
	
	private func swipeToOriginWith(percentage percentage: Double) {
		executeCompletionBlockWith(percentage: percentage)
		
		let offset = PTATableViewItemHelper.offsetWith(percentage: percentage, relativeToWidth: CGRectGetWidth(bounds))
		
		UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: offset / 100.0, options: ([.CurveEaseOut, .AllowUserInteraction]), animations: { [unowned self] in
			self.contentView.frame = self.contentView.bounds
			self.colorIndicatorView.backgroundColor = self.defaultColor
			self.slidingView.alpha = 0.0
			if ((self.stateWith(percentage: percentage) == .None) ||
				((self.direction == .LeftToRight) && (self.leftToRightAttr.viewBehavior == .StickThenDragWithPan)) ||
				((self.direction == .RightToLeft) && (self.rightToLeftAttr.viewBehavior == .StickThenDragWithPan))) {
					self.slideViewWith(percentage: 0.0, view: self.viewWith(percentage: percentage), andDragBehavior: self.viewBehaviorWith(percentage: percentage))
			} else {
				self.slideViewWith(percentage: 0.0, view: self.viewWith(percentage: percentage), andDragBehavior: .None)
			}
			}, completion: { [unowned self] (completed: Bool) -> Void in
				self.removeSwipingView()
			})
	}
	
	private func executeCompletionBlockWith(percentage percentage: Double) {
		let state = stateWith(percentage: percentage)
		var mode: PTATableViewItemMode = .None
		
		switch state {
		case PTATableViewItemState.LeftToRight:
			mode = leftToRightAttr.mode
		case PTATableViewItemState.RightToLeft:
			mode = rightToLeftAttr.mode
		default:
			mode = .None
		}
		
		delegate?.tableViewHeaderFooterView(self, didTriggerState: state, withMode: mode)
	}
	
}

extension PTATableViewHeaderFooterView: UIGestureRecognizerDelegate {
	
	public override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
		if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
			let point = panGestureRecognizer.velocityInView(self)
			if abs(point.x) > abs(point.y) {
				
				if (point.x < 0.0) && !stateOptions.contains(.RightToLeft) {
					return false
				}
				
				if (point.x > 0.0) && !stateOptions.contains(.LeftToRight) {
					return false
				}
				
				delegate?.tableViewHeaderFooterViewDidStartSwiping?(self)
				return true
			} else {
				return false
			}
		}
		return true
	}
	
	internal func _pan(gesture: UIPanGestureRecognizer) {
		if let shouldSwipe = delegate?.tableViewHeaderFooterViewShouldSwipe?(self) {
			if !shouldSwipe { return }
		}
		pan(gestureState: gesture.state, translation: gesture.translationInView(self), velocity: gesture.velocityInView(self))
	}
	
	public func pan(gestureState gestureState: UIGestureRecognizerState, translation: CGPoint) {
		pan(gestureState: gestureState, translation: translation, velocity: CGPointZero)
	}
	
	public func pan(gestureState gestureState: UIGestureRecognizerState, translation: CGPoint, velocity: CGPoint) {
		let actualTranslation = actualizeTranslation(translation)
		let percentage = PTATableViewItemHelper.percentageWith(offset: Double(actualTranslation.x), relativeToWidth: Double(CGRectGetWidth(bounds)))
		direction = PTATableViewItemHelper.directionWith(percentage: percentage)
		
		if (gestureState == .Began) || (gestureState == .Changed) {
			setupSwipingView()
			
			contentView.frame = CGRectOffset(contentView.bounds, actualTranslation.x, 0.0)
			colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
			slidingView.alpha = alphaWith(percentage: percentage)
			
			if let view = viewWith(percentage: percentage) {
				addSubviewToSlidingView(view)
			}
			slideViewWith(percentage: percentage)
			
			delegate?.tableViewHeaderFooterViewIsSwiping?(self, withPercentage: percentage)
		} else if (gestureState == .Ended) || (gestureState == .Cancelled) {
			let cellState = stateWith(percentage: percentage)
			var cellMode: PTATableViewItemMode = .None
			
			if (cellState == .LeftToRight) && (leftToRightAttr.mode != .None) {
				cellMode = leftToRightAttr.mode
			} else if (cellState == .RightToLeft) && (rightToLeftAttr.mode != .None) {
				cellMode = rightToLeftAttr.mode
			}
			
			if (cellMode == .Exit) && (direction != .None) {
				moveWith(percentage: percentage, duration: animationDurationWith(velocity: velocity), direction: cellState)
			} else {
				swipeToOriginWith(percentage: percentage)
			}
			
			delegate?.tableViewHeaderFooterViewDidEndSwiping?(self)
		}
	}
	
	public func actualizeTranslation(translation: CGPoint) -> CGPoint {
		let width = CGRectGetWidth(bounds)
		var panOffset = translation.x
		if ((panOffset > 0.0) && leftToRightAttr.rubberbandBounce ||
			(panOffset < 0.0) && rightToLeftAttr.rubberbandBounce) {
				let offset = abs(panOffset)
				panOffset = (offset * 0.55 * width) / (offset * 0.55 + width)
				panOffset *= (translation.x < 0) ? -1.0 : 1.0
		}
		return CGPointMake(panOffset, translation.y)
	}
	
	public func reset() {
		contentView.frame = contentView.bounds
		colorIndicatorView.backgroundColor = defaultColor
		removeSwipingView()
	}
	
}

public extension PTATableViewHeaderFooterView {
	
	/** Sets a pan gesture for the specified state and mode. Don’t forget to implement the delegate method `tableViewHeaderFooterView(view:didTriggerState:withMode:)` to perform an action when the header/footer view’s state is triggered. */
	public func setPanGesture(state: PTATableViewItemState, mode: PTATableViewItemMode, color: UIColor?, view: UIView?) {
		stateOptions.insert(state)
		
		if state.contains(.LeftToRight) {
			leftToRightAttr = PTATableViewItemStateAttributes(mode: mode, color: color, view: view)
			
			if mode == .None {
				stateOptions.remove(.LeftToRight)
			}
		}
		
		if state.contains(.RightToLeft) {
			rightToLeftAttr = PTATableViewItemStateAttributes(mode: mode, color: color, view: view)
			
			if mode == .None {
				stateOptions.remove(.RightToLeft)
			}
		}
	}
	
}
