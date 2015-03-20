//
//  PTATableViewCell.swift
//  PTATableViewCell
//
//  Objective-C code Copyright (c) 2014 Ali Karagoz. All rights reserved.
//  Swift adaptation Copyright (c) 2014 Nicolas Gomollon. All rights reserved.
//

import Foundation
import UIKit


@objc
public protocol ObjC_PTATableViewCellDelegate: NSObjectProtocol {
	
	/** Asks the delegate whether a given cell should be swiped. Defaults to `true` if not implemented. */
	optional func tableViewCellShouldSwipe(cell: PTATableViewCell) -> Bool
	
	/** Tells the delegate that the specified cell is being swiped with a percentage. */
	optional func tableViewCellIsSwiping(cell: PTATableViewCell, withPercentage percentage: Double)
	
	/** Tells the delegate that the specified cell started swiping. */
	optional func tableViewCellDidStartSwiping(cell: PTATableViewCell)
	
	/** Tells the delegate that the specified cell ended swiping. */
	optional func tableViewCellDidEndSwiping(cell: PTATableViewCell)
	
}

/** The delegate of a PTATableViewCell object must adopt the PTATableViewCellDelegate protocol in order to perform an action when triggered. Optional methods of the protocol allow the delegate to be notified of a cell’s swipe state, and determine whether a cell should be swiped. */
public protocol PTATableViewCellDelegate: ObjC_PTATableViewCellDelegate {
	
	/** Tells the delegate that the specified cell’s state was triggered. */
	func tableViewCell(cell: PTATableViewCell, didTriggerState state: PTATableViewCellState, withMode mode: PTATableViewCellMode)
	
}


/** Describes the mode used during a pan. */
public enum PTATableViewCellMode {
	
	/** The pan to trigger action is effectively disabled. */
	case None
	
	/** The cell bounces back to its original position after it’s released. */
	case Switch
	
	/** The cell slides off screen in the direction it’s being dragged ONLY if it’s released after `triggerPercentage` is reached. If `triggerPercentage` is NOT reached when the cell is released, the cell bounces back to its original position. */
	case Exit
}


/** Describes the slide behaviors that the sliding view can use when the cell is dragged. */
public enum PTATableViewCellSlidingViewBehavior {
	
	/** The view remains still as the cell is dragged. */
	case None
	
	/** The view is dragged with the cell until `triggerPercentage` is reached, at which point the view remains still. */
	case DragWithPanThenStick
	
	/** The view remains still until `triggerPercentage` is reached, at which point the view is dragged with the cell. */
	case StickThenDragWithPan
	
	/** The view is dragged with the cell. */
	case DragWithPan
}


/** Describes the state that has been triggered by the user. */
public struct PTATableViewCellState: RawOptionSetType, BooleanType {
	private var value: UInt = 0
	
	public init(_ rawValue: UInt) { self.value = rawValue }
	
	// MARK: RawOptionSetType
	public init(rawValue: UInt) { self.value = rawValue }
	
	// MARK: NilLiteralConvertible
	public init(nilLiteral: ()) { self.value = 0}
	public static func convertFromNilLiteral() -> PTATableViewCellState { return self(0) }
	
	// MARK: RawRepresentable
	public var rawValue: UInt { return self.value }
	public func toRaw() -> UInt { return self.value }
	public static func fromRaw(raw: UInt) -> PTATableViewCellState? { return self(raw) }
	
	// MARK: BooleanType
	public var boolValue: Bool { return self.value != 0 }
	
	// MARK: BitwiseOperationsType
	public static var allZeros: PTATableViewCellState { return self(0) }
	public static func fromMask(raw: UInt) -> PTATableViewCellState { return self(raw) }
	
	/** No state has been triggered. */
	public static var None: PTATableViewCellState			{ return self(0) }
	
	/** The state triggered during a left-to-right swipe. */
	public static var LeftToRight: PTATableViewCellState	{ return self(1 << 0) }
	
	/** The state triggered during a right-to-left swipe. */
	public static var RightToLeft: PTATableViewCellState	{ return self(1 << 1) }
}

public func == (left: PTATableViewCellState, right: PTATableViewCellState) -> Bool { return left.value == right.value }


/** The attributes used when swiping the cell in a specific state. */
public class PTATableViewCellStateAttributes {
	
	/** The mode to use with the cell state. Defaults to `.None`. */
	public var mode: PTATableViewCellMode
	
	/** The percent of the width of the cell required to be panned before the action is triggered. Defaults to 20%. */
	public var triggerPercentage: Double
	
	/** The rubberband effect applied the farther the cell is dragged. Defaults to `true`. */
	public var rubberbandBounce: Bool
	
	/** The color that’s revealed when an action is triggered. Defaults to `nil`. */
	public var color: UIColor?
	
	/** The view below the cell that’s revealed when an action is triggered. Defaults to `nil`. */
	var view: UIView?
	
	/** The slide behavior that `view` should use when the cell is panned. Defaults to `.StickThenDragWithPan`. */
	public var viewBehavior: PTATableViewCellSlidingViewBehavior
	
	public convenience init() {
		self.init(mode: .None, color: nil, view: nil)
	}
	
	public init(mode: PTATableViewCellMode, color: UIColor?, view: UIView?) {
		self.mode = mode
		triggerPercentage = 0.2
		rubberbandBounce = true
		self.color = color
		self.view = view
		viewBehavior = .StickThenDragWithPan
	}
	
}


public class PTATableViewCell: UITableViewCell {
	
	/** The object that acts as the delegate of the receiving table view cell. */
	public weak var delegate: PTATableViewCellDelegate!
	
	private var panGestureRecognizer: UIPanGestureRecognizer!
	
	private var direction: PTATableViewCellState = .None
	
	private var stateOptions: PTATableViewCellState = .None
	
	
	/** The color that’s revealed before an action is triggered. Defaults to a light gray color. */
	public var defaultColor = UIColor(red: 227.0/255.0, green: 227.0/255.0, blue: 227.0/255.0, alpha: 1.0)
	
	/** The attributes used when swiping the cell from left to right. */
	public var leftToRightAttr = PTATableViewCellStateAttributes()
	
	/** The attributes used when swiping the cell from right to left. */
	public var rightToLeftAttr = PTATableViewCellStateAttributes()
	
	
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
			_colorIndicatorView!.autoresizingMask = (.FlexibleHeight | .FlexibleWidth)
			_colorIndicatorView!.backgroundColor = defaultColor
			
			return _colorIndicatorView
		}
		set {
			_colorIndicatorView = newValue
		}
	}
	
	private func addSubviewToSlidingView(view: UIView) {
		for subview in slidingView.subviews as Array<UIView> {
			subview.removeFromSuperview()
		}
		slidingView.addSubview(view)
	}
	
	
	public override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		initialize()
	}
	
	public required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}
	
	private func initialize() {
		contentView.backgroundColor = .whiteColor()
		panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "_pan:")
		panGestureRecognizer.delegate = self
		addGestureRecognizer(panGestureRecognizer)
	}
	
	public override func prepareForReuse() {
		super.prepareForReuse()
		
		removeSwipingView()
		stateOptions = .None
		leftToRightAttr = PTATableViewCellStateAttributes()
		rightToLeftAttr = PTATableViewCellStateAttributes()
	}
	
}

private extension PTATableViewCell {
	
	private func setupSwipingView() {
		if _colorIndicatorView != nil { return }
		colorIndicatorView.addSubview(slidingView)
		insertSubview(colorIndicatorView, atIndex: 0)
	}
	
	private func removeSwipingView() {
		if _colorIndicatorView == nil { return }
		
		slidingView?.removeFromSuperview()
		slidingView = nil
		
		colorIndicatorView?.removeFromSuperview()
		colorIndicatorView = nil
	}
	
}

private extension PTATableViewCell {
	
	private func offsetWith(#percentage: Double, relativeToWidth width: Double) -> Double {
		var offset = percentage * width
		
		if offset < -width {
			offset = -width
		} else if offset > width {
			offset = width
		}
		
		return offset
	}
	
	private func offsetWith(#percentage: Double, relativeToWidth width: CGFloat) -> CGFloat {
		return CGFloat(offsetWith(percentage: percentage, relativeToWidth: Double(width)))
	}
	
	private func percentageWith(#offset: Double, relativeToWidth width: Double) -> Double {
		var percentage = offset / width
		
		if percentage < -1.0 {
			percentage = -1.0
		} else if percentage > 1.0 {
			percentage = 1.0
		}
		
		return percentage
	}
	
	private func percentageWith(#offset: Double, relativeToWidth width: CGFloat) -> Double {
		return percentageWith(offset: offset, relativeToWidth: Double(width))
	}
	
	private func percentageWith(#offset: CGFloat, relativeToWidth width: Double) -> Double {
		return percentageWith(offset: Double(offset), relativeToWidth: width)
	}
	
	private func percentageWith(#offset: CGFloat, relativeToWidth width: CGFloat) -> Double {
		return percentageWith(offset: Double(offset), relativeToWidth: Double(width))
	}
	
	private func animationDurationWith(#velocity: CGPoint) -> NSTimeInterval {
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
	
	private func directionWith(#percentage: Double) -> PTATableViewCellState {
		if percentage < 0.0 {
			return .RightToLeft
		} else if percentage > 0.0 {
			return .LeftToRight
		}
		return .None
	}
	
	private func viewWith(#percentage: Double) -> UIView? {
		if percentage < 0.0 {
			return rightToLeftAttr.view
		} else if percentage > 0.0 {
			return leftToRightAttr.view
		}
		return nil
	}
	
	private func viewBehaviorWith(#percentage: Double) -> PTATableViewCellSlidingViewBehavior {
		if (directionWith(percentage: percentage) == .LeftToRight) && (leftToRightAttr.mode != .None) {
			return leftToRightAttr.viewBehavior
		} else if (directionWith(percentage: percentage) == .RightToLeft) && (rightToLeftAttr.mode != .None) {
			return rightToLeftAttr.viewBehavior
		}
		return .None
	}
	
	private func alphaWith(#percentage: Double) -> CGFloat {
		if (percentage > 0.0) && (percentage < leftToRightAttr.triggerPercentage) {
			return CGFloat(percentage / leftToRightAttr.triggerPercentage)
		} else if (percentage < 0.0) && (percentage > -rightToLeftAttr.triggerPercentage) {
			return CGFloat(abs(percentage / rightToLeftAttr.triggerPercentage))
		}
		return 1.0
	}
	
	private func colorWith(#percentage: Double) -> UIColor {
		if (percentage >= leftToRightAttr.triggerPercentage) && (leftToRightAttr.mode != .None) && (leftToRightAttr.color != nil) {
			return leftToRightAttr.color!
		} else if (percentage <= -rightToLeftAttr.triggerPercentage) && (rightToLeftAttr.mode != .None) && (rightToLeftAttr.color != nil) {
			return rightToLeftAttr.color!
		}
		return defaultColor
	}
	
	private func stateWith(#percentage: Double) -> PTATableViewCellState {
		if (percentage >= leftToRightAttr.triggerPercentage) && (leftToRightAttr.mode != .None) {
			return .LeftToRight
		} else if (percentage <= -rightToLeftAttr.triggerPercentage) && (rightToLeftAttr.mode != .None) {
			return .RightToLeft
		}
		return .None
	}
	
}

private extension PTATableViewCell {
	
	private func animateWith(#offset: Double) {
		let percentage = percentageWith(offset: offset, relativeToWidth: CGRectGetWidth(bounds))
		
		if let view = viewWith(percentage: percentage) {
			addSubviewToSlidingView(view)
			slidingView.alpha = alphaWith(percentage: percentage)
			slideViewWith(percentage: percentage)
		}
		
		colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
	}
	
	private func slideViewWith(#percentage: Double) {
		slideViewWith(percentage: percentage, view: viewWith(percentage: percentage), andDragBehavior: viewBehaviorWith(percentage: percentage))
	}
	
	private func slideViewWith(#percentage: Double, view: UIView?, andDragBehavior dragBehavior: PTATableViewCellSlidingViewBehavior) {
		var position = CGPointZero
		position.y = CGRectGetHeight(bounds) / 2.0
		
		let width = CGRectGetWidth(bounds)
		let halfLeftToRightTriggerPercentage = leftToRightAttr.triggerPercentage / 2.0
		let halfRightToLeftTriggerPercentage = rightToLeftAttr.triggerPercentage / 2.0
		
		switch dragBehavior {
			
		case .StickThenDragWithPan:
			if direction == .LeftToRight {
				if (percentage >= 0.0) && (percentage < leftToRightAttr.triggerPercentage) {
					position.x = offsetWith(percentage: halfLeftToRightTriggerPercentage, relativeToWidth: width)
				} else if percentage >= leftToRightAttr.triggerPercentage {
					position.x = offsetWith(percentage: percentage - halfLeftToRightTriggerPercentage, relativeToWidth: width)
				}
			} else if direction == .RightToLeft {
				if (percentage <= 0.0) && (percentage >= -rightToLeftAttr.triggerPercentage) {
					position.x = width - offsetWith(percentage: halfRightToLeftTriggerPercentage, relativeToWidth: width)
				} else if percentage <= -rightToLeftAttr.triggerPercentage {
					position.x = width + offsetWith(percentage: percentage + halfRightToLeftTriggerPercentage, relativeToWidth: width)
				}
			}
			
		case .DragWithPanThenStick:
			if direction == .LeftToRight {
				if (percentage >= 0.0) && (percentage < leftToRightAttr.triggerPercentage) {
					position.x = offsetWith(percentage: percentage - halfLeftToRightTriggerPercentage, relativeToWidth: width)
				} else if percentage >= leftToRightAttr.triggerPercentage {
					position.x = offsetWith(percentage: halfLeftToRightTriggerPercentage, relativeToWidth: width)
				}
			} else if direction == .RightToLeft {
				if (percentage <= 0.0) && (percentage >= -rightToLeftAttr.triggerPercentage) {
					position.x = width + offsetWith(percentage: percentage + halfRightToLeftTriggerPercentage, relativeToWidth: width)
				} else if percentage <= -rightToLeftAttr.triggerPercentage {
					position.x = width - offsetWith(percentage: halfRightToLeftTriggerPercentage, relativeToWidth: width)
				}
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
	
	private func moveWith(#percentage: Double, duration: NSTimeInterval, direction: PTATableViewCellState) {
		var origin: CGFloat = 0.0
		
		if direction == .RightToLeft {
			origin -= CGRectGetWidth(bounds)
		} else if direction == .LeftToRight {
			origin += CGRectGetWidth(bounds)
		}
		
		var frame = contentView.frame
		frame.origin.x = origin
		
		colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
		
		UIView.animateWithDuration(duration, delay: 0.0, options: (.CurveEaseOut | .AllowUserInteraction), animations: { [unowned self] in
				self.contentView.frame = frame
				self.slidingView.alpha = 0.0
				self.slideViewWith(percentage: self.percentageWith(offset: origin, relativeToWidth: CGRectGetWidth(self.bounds)), view: self.viewWith(percentage: percentage), andDragBehavior: self.viewBehaviorWith(percentage: percentage))
			}, completion: { [unowned self] (completed: Bool) -> Void in
				self.executeCompletionBlockWith(percentage: percentage)
			})
	}
	
	private func swipeToOriginWith(#percentage: Double) {
		executeCompletionBlockWith(percentage: percentage)
		
		let offset = offsetWith(percentage: percentage, relativeToWidth: CGRectGetWidth(bounds))
		
		UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: offset / 100.0, options: (.CurveEaseOut | .AllowUserInteraction), animations: { [unowned self] in
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
	
	private func executeCompletionBlockWith(#percentage: Double) {
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
	
	public override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
		if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
			let point = panGestureRecognizer.velocityInView(self)
			if abs(point.x) > abs(point.y) {
				
				if (point.x < 0.0) && !(stateOptions & .RightToLeft) {
					return false
				}
				
				if (point.x > 0.0) && !(stateOptions & .LeftToRight) {
					return false
				}
				
				delegate?.tableViewCellDidStartSwiping?(self)
				return true
			} else {
				return false
			}
		}
		return !editing
	}
	
	internal func _pan(gesture: UIPanGestureRecognizer) {
		if let shouldSwipe = delegate?.tableViewCellShouldSwipe?(self) {
			if !shouldSwipe { return }
		}
		pan(gestureState: gesture.state, translation: gesture.translationInView(self), velocity: gesture.velocityInView(self))
	}
	
	public func pan(#gestureState: UIGestureRecognizerState, translation: CGPoint) {
		pan(gestureState: gestureState, translation: translation, velocity: CGPointZero)
	}
	
	public func pan(#gestureState: UIGestureRecognizerState, translation: CGPoint, velocity: CGPoint) {
		let actualTranslation = actualizeTranslation(translation)
		var percentage = percentageWith(offset: actualTranslation.x, relativeToWidth: CGRectGetWidth(bounds))
		direction = directionWith(percentage: percentage)
		
		if (gestureState == .Began) || (gestureState == .Changed) {
			setupSwipingView()
			
			contentView.frame = CGRectOffset(contentView.bounds, actualTranslation.x, 0.0)
			colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
			slidingView.alpha = alphaWith(percentage: percentage)
			
			if let view = viewWith(percentage: percentage) {
				addSubviewToSlidingView(view)
			}
			slideViewWith(percentage: percentage)
			
			delegate?.tableViewCellIsSwiping?(self, withPercentage: percentage)
		} else if (gestureState == .Ended) || (gestureState == .Cancelled) {
			let cellState = stateWith(percentage: percentage)
			var cellMode: PTATableViewCellMode = .None
			
			if (cellState == .LeftToRight) && (leftToRightAttr.mode != .None) {
				cellMode = leftToRightAttr.mode
			} else if (cellState == .RightToLeft) && (rightToLeftAttr.mode != .None) {
				cellMode = rightToLeftAttr.mode
			}
			
			if (cellMode == .Exit) && !(direction & .None) {
				moveWith(percentage: percentage, duration: animationDurationWith(velocity: velocity), direction: cellState)
			} else {
				swipeToOriginWith(percentage: percentage)
			}
			
			delegate?.tableViewCellDidEndSwiping?(self)
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

public extension PTATableViewCell {
	
	/** Sets a pan gesture for the specified state and mode. Don’t forget to implement the delegate method `tableViewCell(cell:didTriggerState:withMode:)` to perform an action when the cell’s state is triggered. */
	public func setPanGesture(state: PTATableViewCellState, mode: PTATableViewCellMode, color: UIColor?, view: UIView?) {
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
