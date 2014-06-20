//
//  PTATableViewCell.swift
//  PTATableViewCell
//
//  Created by Nicolas Gomollon on 6/18/14.
//  Copyright (c) 2014 Techno-Magic. All rights reserved.
//

import Foundation
import UIKit


protocol PTATableViewCellDelegate: NSObjectProtocol {
	
	func tableViewCell(cell: PTATableViewCell, didTriggerState state: PTATableViewCellState, withMode mode: PTATableViewCellMode)
	
}

@objc
protocol PTATableViewCellDelegateOptional: NSObjectProtocol {
	
	@optional func tableViewCellDidSwipe(cell: PTATableViewCell, withPercentage percentage: Double)
	
	@optional func tableViewCellDidStartSwiping(cell: PTATableViewCell)
	
	@optional func tableViewCellDidEndSwiping(cell: PTATableViewCell)
	
}


enum PTATableViewCellMode {
	case None, Switch, Exit
}


enum PTATableViewCellSlidingViewBehavior {
	case None, DragWithPanThenStick, StickThenDragWithPan, DragWithPan
}


struct PTATableViewCellState: RawOptionSet {
	var value: UInt = 0
	init(_ value: UInt) { self.value = value }
	func toRaw() -> UInt { return self.value }
	func getLogicValue() -> Bool { return self.value != 0 }
	static func fromRaw(raw: UInt) -> PTATableViewCellState? { return PTATableViewCellState(raw) }
	static func fromMask(raw: UInt) -> PTATableViewCellState { return PTATableViewCellState(raw) }
	
	static var None: PTATableViewCellState			{ return PTATableViewCellState(0) }
	static var LeftToRight: PTATableViewCellState	{ return PTATableViewCellState(1 << 0) }
	static var RightToLeft: PTATableViewCellState	{ return PTATableViewCellState(1 << 1) }
}

func == (left: PTATableViewCellState, right: PTATableViewCellState) -> Bool { return left.value == right.value }


class PTATableViewCellStateAttributes {
	
	var mode: PTATableViewCellMode
	var triggerPercentage: Double
	var rubberbandBounce: Bool
	var color: UIColor?
	var view: UIView?
	var viewBehavior: PTATableViewCellSlidingViewBehavior
	
	convenience init() {
		self.init(mode: .None, color: nil, view: nil)
	}
	
	init(mode: PTATableViewCellMode, color: UIColor?, view: UIView?) {
		self.mode = mode
		triggerPercentage = 0.2
		rubberbandBounce = true
		self.color = color
		self.view = view
		viewBehavior = .StickThenDragWithPan
	}
	
}


class PTATableViewCell: UITableViewCell {
	
	var defaultColor = UIColor(red: 227.0/255.0, green: 227.0/255.0, blue: 227.0/255.0, alpha: 1.0)
	
	var delegate: PTATableViewCellDelegate!
	var delegateOptional: PTATableViewCellDelegateOptional!
	var panGestureRecognizer: UIPanGestureRecognizer!
	var direction: PTATableViewCellState = .None
	
	var stateOptions: PTATableViewCellState = .None
	var leftToRightAttr = PTATableViewCellStateAttributes()
	var rightToLeftAttr = PTATableViewCellStateAttributes()
	
	var _slidingView: UIView?
	var slidingView: UIView! {
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
	
	var _colorIndicatorView: UIView?
	var colorIndicatorView: UIView! {
	get {
		if let colorIndicatorView = _colorIndicatorView {
			return colorIndicatorView
		}
		
		_colorIndicatorView = UIView(frame: bounds)
		_colorIndicatorView!.autoresizingMask = (.FlexibleHeight | .FlexibleWidth)
		_colorIndicatorView!.backgroundColor = defaultColor
		
		return _colorIndicatorView
	}
	set {
		_colorIndicatorView = newValue
	}
	}
	
	var _contentSnapshotView: UIView?
	var contentSnapshotView: UIView! {
	get {
		if let contentSnapshotView = _contentSnapshotView {
			return contentSnapshotView
		}
		
		let isContentViewBackgroundClear = !contentView.backgroundColor
		if isContentViewBackgroundClear {
			contentView.backgroundColor = (backgroundColor == UIColor.clearColor()) ? UIColor.whiteColor() : backgroundColor
		}
		
		_contentSnapshotView = snapshotViewAfterScreenUpdates(true)
		
		if isContentViewBackgroundClear {
			contentView.backgroundColor = nil
		}
		
		addSubview(colorIndicatorView)
		colorIndicatorView.addSubview(slidingView)
		addSubview(_contentSnapshotView)
		
		return _contentSnapshotView
	}
	set {
		if newValue {
			_contentSnapshotView = newValue
		} else {
			slidingView?.removeFromSuperview()
			slidingView = nil
			
			colorIndicatorView?.removeFromSuperview()
			colorIndicatorView = nil
			
			_contentSnapshotView?.removeFromSuperview()
			_contentSnapshotView = nil
		}
	}
	}
	
	func addSubviewToSlidingView(view: UIView) {
		for subview in slidingView.subviews as Array<UIView> {
			subview.removeFromSuperview()
		}
		slidingView.addSubview(view)
	}
	
	
	init(style: UITableViewCellStyle, reuseIdentifier: String!) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		initialize()
	}
	
	func initialize() {
		panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "pan:")
		panGestureRecognizer.delegate = self
		addGestureRecognizer(panGestureRecognizer)
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		contentSnapshotView = nil
		stateOptions = .None
		leftToRightAttr = PTATableViewCellStateAttributes()
		rightToLeftAttr = PTATableViewCellStateAttributes()
	}
	
}

extension PTATableViewCell {
	
	func offsetWith(#percentage: Double, relativeToWidth width: Double) -> Double {
		var offset = percentage * width
		
		if offset < -width {
			offset = -width
		} else if offset > width {
			offset = width
		}
		
		return offset
	}
	
	func percentageWith(#offset: Double, relativeToWidth width: Double) -> Double {
		var percentage = offset / width
		
		if percentage < -1.0 {
			percentage = -1.0
		} else if percentage > 1.0 {
			percentage = 1.0
		}
		
		return percentage
	}
	
	func animationDurationWith(#velocity: CGPoint) -> NSTimeInterval {
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
		
		return (DurationHighLimit + DurationLowLimit) - abs((horizontalVelocity / width) * animationDurationDiff)
	}
	
	func directionWith(#percentage: Double) -> PTATableViewCellState {
		if percentage < 0.0 {
			return .RightToLeft
		} else if percentage > 0.0 {
			return .LeftToRight
		}
		return .None
	}
	
	func viewWith(#percentage: Double) -> UIView? {
		if percentage < 0.0 {
			return rightToLeftAttr.view
		} else if percentage > 0.0 {
			return leftToRightAttr.view
		}
		return nil
	}
	
	func viewBehaviorWith(#percentage: Double) -> PTATableViewCellSlidingViewBehavior {
		if (directionWith(percentage: percentage) == .LeftToRight) && (leftToRightAttr.mode != .None) {
			return leftToRightAttr.viewBehavior
		} else if (directionWith(percentage: percentage) == .RightToLeft) && (rightToLeftAttr.mode != .None) {
			return rightToLeftAttr.viewBehavior
		}
		return .None
	}
	
	func alphaWith(#percentage: Double) -> Double {
		if (percentage > 0.0) && (percentage < leftToRightAttr.triggerPercentage) {
			return percentage / leftToRightAttr.triggerPercentage
		} else if (percentage < 0.0) && (percentage > -rightToLeftAttr.triggerPercentage) {
			return abs(percentage / rightToLeftAttr.triggerPercentage)
		}
		return 1.0
	}
	
	func colorWith(#percentage: Double) -> UIColor {
		if (percentage >= leftToRightAttr.triggerPercentage) && (leftToRightAttr.mode != .None) && leftToRightAttr.color {
			return leftToRightAttr.color!
		} else if (percentage <= -rightToLeftAttr.triggerPercentage) && (rightToLeftAttr.mode != .None) && rightToLeftAttr.color {
			return rightToLeftAttr.color!
		}
		return defaultColor
	}
	
	func stateWith(#percentage: Double) -> PTATableViewCellState {
		if (percentage >= leftToRightAttr.triggerPercentage) && (leftToRightAttr.mode != .None) {
			return .LeftToRight
		} else if (percentage <= -rightToLeftAttr.triggerPercentage) && (rightToLeftAttr.mode != .None) {
			return .RightToLeft
		}
		return .None
	}
	
}

extension PTATableViewCell {
	
	func animateWith(#offset: Double) {
		let percentage = percentageWith(offset: offset, relativeToWidth: CGRectGetWidth(bounds))
		
		if let view = viewWith(percentage: percentage) {
			addSubviewToSlidingView(view)
			slidingView.alpha = alphaWith(percentage: percentage)
			slideViewWith(percentage: percentage)
		}
		
		colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
	}
	
	func slideViewWith(#percentage: Double) {
		slideViewWith(percentage: percentage, view: viewWith(percentage: percentage), andDragBehavior: viewBehaviorWith(percentage: percentage))
	}
	
	func slideViewWith(#percentage: Double, view: UIView?, andDragBehavior dragBehavior: PTATableViewCellSlidingViewBehavior) {
		var position = CGPointZero
		position.y = CGRectGetHeight(bounds) / 2.0
		
		let width = CGRectGetWidth(bounds)
		let halfLeftToRightTriggerPercentage = leftToRightAttr.triggerPercentage / 2.0
		let halfRightToLeftTriggerPercentage = rightToLeftAttr.triggerPercentage / 2.0
		
		switch dragBehavior {
			
		case .StickThenDragWithPan:
			if (percentage >= 0.0) && (percentage < leftToRightAttr.triggerPercentage) {
				position.x = offsetWith(percentage: halfLeftToRightTriggerPercentage, relativeToWidth: width)
			} else if percentage >= leftToRightAttr.triggerPercentage {
				position.x = offsetWith(percentage: percentage - halfLeftToRightTriggerPercentage, relativeToWidth: width)
			} else if (percentage < 0.0) && (percentage >= -rightToLeftAttr.triggerPercentage) {
				position.x = width - offsetWith(percentage: halfRightToLeftTriggerPercentage, relativeToWidth: width)
			} else if percentage <= -rightToLeftAttr.triggerPercentage {
				position.x = width + offsetWith(percentage: percentage + halfRightToLeftTriggerPercentage, relativeToWidth: width)
			}
			
		case .DragWithPanThenStick:
			if (percentage >= 0.0) && (percentage < leftToRightAttr.triggerPercentage) {
				position.x = offsetWith(percentage: percentage - halfLeftToRightTriggerPercentage, relativeToWidth: width)
			} else if percentage >= leftToRightAttr.triggerPercentage {
				position.x = offsetWith(percentage: halfLeftToRightTriggerPercentage, relativeToWidth: width)
			} else if (percentage < 0.0) && (percentage >= -rightToLeftAttr.triggerPercentage) {
				position.x = width + offsetWith(percentage: percentage + halfRightToLeftTriggerPercentage, relativeToWidth: width)
			} else if percentage <= -rightToLeftAttr.triggerPercentage {
				position.x = width - offsetWith(percentage: halfRightToLeftTriggerPercentage, relativeToWidth: width)
			}
			
		case .DragWithPan:
			if direction == .LeftToRight {
				position.x = offsetWith(percentage: percentage - halfLeftToRightTriggerPercentage, relativeToWidth: width)
			} else if direction == .RightToLeft {
				position.x = width + offsetWith(percentage: percentage + halfRightToLeftTriggerPercentage, relativeToWidth: width)
			}
			
		case .None:
			if direction == .LeftToRight {
				position.x = offsetWith(percentage: halfLeftToRightTriggerPercentage, relativeToWidth: width)
			} else if direction == .RightToLeft {
				position.x = width - offsetWith(percentage: halfRightToLeftTriggerPercentage, relativeToWidth: width)
			}
			
		}
		
		if var activeView = view {
			var activeViewFrame = activeView.bounds
			activeViewFrame.origin.x = position.x - (activeViewFrame.size.width / 2.0)
			activeViewFrame.origin.y = position.y - (activeViewFrame.size.height / 2.0)
			
			slidingView.frame = activeViewFrame
		}
	}
	
	func moveWith(#percentage: Double, duration: NSTimeInterval, direction: PTATableViewCellState) {
		var origin = 0.0
		
		if direction == .RightToLeft {
			origin -= CGRectGetWidth(bounds)
		} else if direction == .LeftToRight {
			origin += CGRectGetWidth(bounds)
		}
		
		var frame = contentSnapshotView.frame
		frame.origin.x = origin
		
		colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
		
		UIView.animateWithDuration(duration, delay: 0.0, options: (.CurveEaseOut | .AllowUserInteraction), animations: {
				self.contentSnapshotView.frame = frame
				self.slidingView.alpha = 0.0
				self.slideViewWith(percentage: self.percentageWith(offset: origin, relativeToWidth: CGRectGetWidth(self.bounds)), view: self.viewWith(percentage: percentage), andDragBehavior: self.viewBehaviorWith(percentage: percentage))
			}, completion: { (completed: Bool) -> Void in
				self.executeCompletionBlockWith(percentage: percentage)
			})
	}
	
	func swipeToOriginWith(#percentage: Double) {
		executeCompletionBlockWith(percentage: percentage)
		
		let offset = offsetWith(percentage: percentage, relativeToWidth: CGRectGetWidth(bounds))
		
		UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: offset / 100.0, options: (.CurveEaseOut | .AllowUserInteraction), animations: {
				self.contentSnapshotView.frame = self.contentView.bounds
				self.colorIndicatorView.backgroundColor = self.defaultColor
				self.slidingView.alpha = 0.0
				self.slideViewWith(percentage: 0.0, view: self.viewWith(percentage: percentage), andDragBehavior: .None)
			}, completion: { (completed: Bool) -> Void in
				self.contentSnapshotView = nil
			})
	}
	
	func executeCompletionBlockWith(#percentage: Double) {
		let state = stateWith(percentage: percentage)
		var mode: PTATableViewCellMode = .None
		
		switch state {
		case PTATableViewCellState.LeftToRight:
			mode = leftToRightAttr.mode
		case PTATableViewCellState.RightToLeft:
			mode = rightToLeftAttr.mode
		default:
			mode = .None
		}
		
		delegate?.tableViewCell(self, didTriggerState: state, withMode: mode)
	}
	
}

extension PTATableViewCell: UIGestureRecognizerDelegate {
	
	override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer!) -> Bool {
		if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
			let point = panGestureRecognizer.velocityInView(self)
			if abs(point.x) > abs(point.y) {
				
				if (point.x < 0.0) && !(stateOptions & .RightToLeft) {
					return false
				}
				
				if (point.x > 0.0) && !(stateOptions & .LeftToRight) {
					return false
				}
				
				delegateOptional?.tableViewCellDidStartSwiping?(self)
				return true
			}
		}
		return false
	}
	
	func pan(gesture: UIPanGestureRecognizer) {
		let width = CGRectGetWidth(bounds)
		
		let translation = gesture.translationInView(self)
		let velocity = gesture.velocityInView(self)
		let animationDuration = animationDurationWith(velocity: velocity)
		
		var panOffset = translation.x
		if ((panOffset > 0.0) && leftToRightAttr.rubberbandBounce ||
			(panOffset < 0.0) && rightToLeftAttr.rubberbandBounce) {
			let offset = abs(panOffset)
			panOffset = (offset * 0.55 * width) / (offset * 0.55 + width)
			panOffset *= (translation.x < 0) ? -1.0 : 1.0
		}
		
		let actualTranslation = CGPointMake(panOffset, translation.y)
		var percentage = percentageWith(offset: actualTranslation.x, relativeToWidth: width)
		direction = directionWith(percentage: percentage)
		
		if (gesture.state == UIGestureRecognizerState.Began) || (gesture.state == UIGestureRecognizerState.Changed) {
			contentSnapshotView.frame = CGRectOffset(contentView.bounds, actualTranslation.x, 0.0)
			colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
			slidingView.alpha = alphaWith(percentage: percentage)
			
			if let view = viewWith(percentage: percentage) {
				addSubviewToSlidingView(view)
			}
			slideViewWith(percentage: percentage)
			
			delegateOptional?.tableViewCellDidSwipe?(self, withPercentage: percentage)
		} else if (gesture.state == UIGestureRecognizerState.Ended) || (gesture.state == UIGestureRecognizerState.Cancelled) {
			let cellState = stateWith(percentage: percentage)
			var cellMode: PTATableViewCellMode = .None
			
			if (cellState == .LeftToRight) && (leftToRightAttr.mode != .None) {
				cellMode = leftToRightAttr.mode
			} else if (cellState == .RightToLeft) && (rightToLeftAttr.mode != .None) {
				cellMode = rightToLeftAttr.mode
			}
			
			if (cellMode == .Exit) && !(direction & .None) {
				moveWith(percentage: percentage, duration: animationDuration, direction: cellState)
			} else {
				swipeToOriginWith(percentage: percentage)
			}
			
			delegateOptional?.tableViewCellDidEndSwiping?(self)
		}
	}
	
}

extension PTATableViewCell {
	
	func setPanGesture(state: PTATableViewCellState, mode: PTATableViewCellMode, color: UIColor?, view: UIView?) {
			stateOptions = stateOptions | state
			
			if state & .LeftToRight {
				leftToRightAttr = PTATableViewCellStateAttributes(mode: mode, color: color, view: view)
				
				if mode == .None {
					stateOptions = stateOptions & ~PTATableViewCellState.LeftToRight
				}
			}
			
			if state & .RightToLeft {
				rightToLeftAttr = PTATableViewCellStateAttributes(mode: mode, color: color, view: view)
				
				if mode == .None {
					stateOptions = stateOptions & ~PTATableViewCellState.RightToLeft
				}
			}
	}
	
}
