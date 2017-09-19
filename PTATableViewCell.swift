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
	@objc optional func tableViewShouldSwipe(cell: PTATableViewCell) -> Bool
	
	/** Tells the delegate that the specified cell is being swiped with the offset and percentage. */
	@objc optional func tableViewIsSwiping(cell: PTATableViewCell, with offset: CGFloat, percentage: Double)
	
	/** Tells the delegate that the specified cell started swiping. */
	@objc optional func tableViewDidStartSwiping(cell: PTATableViewCell)
	
	/** Tells the delegate that the specified cell ended swiping. */
	@objc optional func tableViewDidEndSwiping(cell: PTATableViewCell)
	
}

/** The delegate of a PTATableViewCell object must adopt the PTATableViewCellDelegate protocol in order to perform an action when triggered. Optional methods of the protocol allow the delegate to be notified of a cell’s swipe state, and determine whether a cell should be swiped. */
public protocol PTATableViewCellDelegate: ObjC_PTATableViewCellDelegate {
	
	/** Tells the delegate that the specified cell’s state was triggered. */
	func tableView(cell: PTATableViewCell, didTrigger state: PTATableViewItemState, with mode: PTATableViewItemMode)
	
}


open class PTATableViewCell: UITableViewCell {
	
	/** The object that acts as the delegate of the receiving table view cell. */
	open weak var delegate: PTATableViewCellDelegate!
	
	fileprivate var panGestureRecognizer: UIPanGestureRecognizer!
	
	fileprivate var direction: PTATableViewItemState = .none
	
	fileprivate var stateOptions: PTATableViewItemState = .none
	
	fileprivate var previousState: PTATableViewItemState = .none
	fileprivate var feedbackGenerator: AnyObject?
	fileprivate var impactGenerator: AnyObject?
	
	
	/** The color that’s revealed before an action is triggered. Defaults to a light gray color. */
	open var defaultColor = UIColor(red: 227.0/255.0, green: 227.0/255.0, blue: 227.0/255.0, alpha: 1.0)
	
	/** The attributes used when swiping the cell from left to right. */
	open var leftToRightAttr = PTATableViewItemStateAttributes()
	
	/** The attributes used when swiping the cell from right to left. */
	open var rightToLeftAttr = PTATableViewItemStateAttributes()
	
	
	fileprivate var _slidingView: UIView?
	fileprivate var slidingView: UIView! {
		get {
			if let slidingView = _slidingView {
				return slidingView
			}
			
			_slidingView = UIView()
			_slidingView!.contentMode = .center
			
			return _slidingView
		}
		set {
			_slidingView = newValue
		}
	}
	
	fileprivate var _colorIndicatorView: UIView?
	fileprivate var colorIndicatorView: UIView! {
		get {
			if let colorIndicatorView = _colorIndicatorView {
				return colorIndicatorView
			}
			
			_colorIndicatorView = UIView(frame: bounds)
			_colorIndicatorView!.autoresizingMask = ([.flexibleHeight, .flexibleWidth])
			_colorIndicatorView!.backgroundColor = defaultColor
			
			return _colorIndicatorView
		}
		set {
			_colorIndicatorView = newValue
		}
	}
	
	fileprivate func addSubviewToSlidingView(_ view: UIView) {
		for subview in slidingView.subviews {
			subview.removeFromSuperview()
		}
		slidingView.addSubview(view)
	}
	
	
	public override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		initialize()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}
	
	fileprivate func initialize() {
		contentView.backgroundColor = .white
		panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(PTATableViewCell._pan(_:)))
		panGestureRecognizer.delegate = self
		addGestureRecognizer(panGestureRecognizer)
	}
	
	open override func prepareForReuse() {
		super.prepareForReuse()
		
		removeSwipingView()
		stateOptions = .none
		leftToRightAttr = PTATableViewItemStateAttributes()
		rightToLeftAttr = PTATableViewItemStateAttributes()
	}
	
}

private extension PTATableViewCell {
	
	func setupSwipingView() {
		if _colorIndicatorView != nil { return }
		colorIndicatorView.addSubview(slidingView)
		insertSubview(colorIndicatorView, at: 0)
	}
	
	func removeSwipingView() {
		if _colorIndicatorView == nil { return }
		
		slidingView?.removeFromSuperview()
		slidingView = nil
		
		colorIndicatorView?.removeFromSuperview()
		colorIndicatorView = nil
	}
	
}

private extension PTATableViewCell {
	
	func animationDurationWith(velocity: CGPoint) -> TimeInterval {
		let DurationHighLimit = 0.1
		let DurationLowLimit = 0.25
		
		let width = bounds.width
		let animationDurationDiff = DurationHighLimit - DurationLowLimit
		var horizontalVelocity = velocity.x
		
		if horizontalVelocity < -width {
			horizontalVelocity = -width
		} else if horizontalVelocity > width {
			horizontalVelocity = width
		}
		
		return (DurationHighLimit + DurationLowLimit) - abs(Double(horizontalVelocity / width) * animationDurationDiff)
	}
	
	func viewWith(percentage: Double) -> UIView? {
		if percentage < 0.0 {
			return rightToLeftAttr.view
		} else if percentage > 0.0 {
			return leftToRightAttr.view
		}
		return nil
	}
	
	func viewBehaviorWith(percentage: Double) -> PTATableViewItemSlidingViewBehavior {
		if (PTATableViewItemHelper.directionWith(percentage: percentage) == .leftToRight) && (leftToRightAttr.mode != .none) {
			return leftToRightAttr.viewBehavior
		} else if (PTATableViewItemHelper.directionWith(percentage: percentage) == .rightToLeft) && (rightToLeftAttr.mode != .none) {
			return rightToLeftAttr.viewBehavior
		}
		return .none
	}
	
	func alphaWith(percentage: Double) -> CGFloat {
		let ltrTrigger = leftToRightAttr.trigger
		let rtlTrigger = rightToLeftAttr.trigger
		let offset = PTATableViewItemHelper.offsetWith(percentage: abs(percentage), relativeToWidth: bounds.width)
		if percentage > 0.0 {
			switch ltrTrigger.kind {
			case .percentage:
				if percentage < ltrTrigger.value {
					return CGFloat(percentage / ltrTrigger.value)
				}
			case .offset:
				let triggerValue = CGFloat(ltrTrigger.value)
				if offset < triggerValue {
					return offset / triggerValue
				}
			}
		} else if percentage < 0.0 {
			switch rtlTrigger.kind {
			case .percentage:
				if percentage > -rtlTrigger.value {
					return CGFloat(abs(percentage / rtlTrigger.value))
				}
			case .offset:
				let triggerValue = CGFloat(rtlTrigger.value)
				if offset < triggerValue {
					return offset / triggerValue
				}
			}
		}
		return 1.0
	}
	
	func colorWith(percentage: Double) -> UIColor {
		let ltrTrigger = leftToRightAttr.trigger
		let rtlTrigger = rightToLeftAttr.trigger
		let offset = PTATableViewItemHelper.offsetWith(percentage: abs(percentage), relativeToWidth: bounds.width)
		if (percentage > 0.0) && (leftToRightAttr.mode != .none) && (leftToRightAttr.color != nil) {
			switch ltrTrigger.kind {
			case .percentage:
				if percentage >= ltrTrigger.value {
					return leftToRightAttr.color!
				}
			case .offset:
				let triggerValue = CGFloat(ltrTrigger.value)
				if offset >= triggerValue {
					return leftToRightAttr.color!
				}
			}
		} else if (percentage < 0.0) && (rightToLeftAttr.mode != .none) && (rightToLeftAttr.color != nil) {
			switch rtlTrigger.kind {
			case .percentage:
				if percentage <= -rtlTrigger.value {
					return rightToLeftAttr.color!
				}
			case .offset:
				let triggerValue = CGFloat(rtlTrigger.value)
				if offset >= triggerValue {
					return rightToLeftAttr.color!
				}
			}
		}
		return defaultColor
	}
	
	func stateWith(percentage: Double) -> PTATableViewItemState {
		let ltrTrigger = leftToRightAttr.trigger
		let rtlTrigger = rightToLeftAttr.trigger
		let offset = PTATableViewItemHelper.offsetWith(percentage: abs(percentage), relativeToWidth: bounds.width)
		if (percentage > 0.0) && (leftToRightAttr.mode != .none) {
			switch ltrTrigger.kind {
			case .percentage:
				if percentage >= ltrTrigger.value {
					return .leftToRight
				}
			case .offset:
				let triggerValue = CGFloat(ltrTrigger.value)
				if offset >= triggerValue {
					return .leftToRight
				}
			}
		} else if (percentage < 0.0) && (rightToLeftAttr.mode != .none) {
			switch rtlTrigger.kind {
			case .percentage:
				if percentage <= -rtlTrigger.value {
					return .rightToLeft
				}
			case .offset:
				let triggerValue = CGFloat(rtlTrigger.value)
				if offset >= triggerValue {
					return .rightToLeft
				}
			}
		}
		return .none
	}
	
}

private extension PTATableViewCell {
	
	func animateWith(offset: Double) {
		let percentage = PTATableViewItemHelper.percentageWith(offset: offset, relativeToWidth: Double(bounds.width))
		
		if let view = viewWith(percentage: percentage) {
			addSubviewToSlidingView(view)
			slidingView.alpha = alphaWith(percentage: percentage)
			slideViewWith(percentage: percentage)
		}
		
		colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
	}
	
	func slideViewWith(percentage: Double) {
		slideViewWith(percentage: percentage, view: viewWith(percentage: percentage), andDragBehavior: viewBehaviorWith(percentage: percentage))
	}
	
	func slideViewWith(percentage: Double, view: UIView?, andDragBehavior dragBehavior: PTATableViewItemSlidingViewBehavior) {
		var position = CGPoint.zero
		position.y = bounds.height / 2.0
		
		let width = bounds.width
		let offset = PTATableViewItemHelper.offsetWith(percentage: percentage, relativeToWidth: width)
		
		let ltrTriggerPercentage = leftToRightAttr.trigger.percentage(relativeToWidth: width)
		let rtlTriggerPercentage = rightToLeftAttr.trigger.percentage(relativeToWidth: width)
		
		switch dragBehavior {
			
		case .stickThenDragWithPan:
			if direction == .leftToRight {
				if (percentage >= 0.0) && (percentage < ltrTriggerPercentage) {
					position.x = leftToRightAttr.trigger.offset(relativeToWidth: width) / 2.0
				} else if percentage >= ltrTriggerPercentage {
					position.x = offset - (leftToRightAttr.trigger.offset(relativeToWidth: width) / 2.0)
				}
			} else if direction == .rightToLeft {
				if (percentage <= 0.0) && (percentage >= -rtlTriggerPercentage) {
					position.x = width - (rightToLeftAttr.trigger.offset(relativeToWidth: width) / 2.0)
				} else if percentage <= -rtlTriggerPercentage {
					position.x = width + offset + (rightToLeftAttr.trigger.offset(relativeToWidth: width) / 2.0)
				}
			}
			
		case .dragWithPanThenStick:
			if direction == .leftToRight {
				if (percentage >= 0.0) && (percentage < ltrTriggerPercentage) {
					position.x = offset - (leftToRightAttr.trigger.offset(relativeToWidth: width) / 2.0)
				} else if percentage >= ltrTriggerPercentage {
					position.x = leftToRightAttr.trigger.offset(relativeToWidth: width) / 2.0
				}
			} else if direction == .rightToLeft {
				if (percentage <= 0.0) && (percentage >= -rtlTriggerPercentage) {
					position.x = width + offset + (rightToLeftAttr.trigger.offset(relativeToWidth: width) / 2.0)
				} else if percentage <= -rtlTriggerPercentage {
					position.x = width - (rightToLeftAttr.trigger.offset(relativeToWidth: width) / 2.0)
				}
			}
			
		case .dragWithPan:
			if direction == .leftToRight {
				position.x = offset - (leftToRightAttr.trigger.offset(relativeToWidth: width) / 2.0)
			} else if direction == .rightToLeft {
				position.x = width + offset + (rightToLeftAttr.trigger.offset(relativeToWidth: width) / 2.0)
			}
			
		case .none:
			if direction == .leftToRight {
				position.x = leftToRightAttr.trigger.offset(relativeToWidth: width) / 2.0
			} else if direction == .rightToLeft {
				position.x = width - (rightToLeftAttr.trigger.offset(relativeToWidth: width) / 2.0)
			}
			
		}
		
		if let activeView = view {
			var activeViewFrame = activeView.bounds
			activeViewFrame.origin.x = position.x - (activeViewFrame.size.width / 2.0)
			activeViewFrame.origin.y = position.y - (activeViewFrame.size.height / 2.0)
			
			slidingView.frame = activeViewFrame
		}
	}
	
	func moveWith(percentage: Double, duration: TimeInterval, direction: PTATableViewItemState) {
		var origin: CGFloat = 0.0
		
		if direction == .rightToLeft {
			origin -= bounds.width
		} else if direction == .leftToRight {
			origin += bounds.width
		}
		
		var frame = contentView.frame
		frame.origin.x = origin
		
		colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
		
		UIView.animate(withDuration: duration, delay: 0.0, options: [.curveEaseOut, .allowUserInteraction], animations: { [unowned self] () -> Void in
				self.contentView.frame = frame
				self.slidingView.alpha = 0.0
				self.slideViewWith(percentage: PTATableViewItemHelper.percentageWith(offset: Double(origin), relativeToWidth: Double(self.bounds.width)), view: self.viewWith(percentage: percentage), andDragBehavior: self.viewBehaviorWith(percentage: percentage))
			}, completion: { [unowned self] (Bool) -> Void in
				self.executeCompletionBlockWith(percentage: percentage)
			})
	}
	
	func swipeToOriginWith(percentage: Double) {
		executeCompletionBlockWith(percentage: percentage)
		
		let offset = PTATableViewItemHelper.offsetWith(percentage: percentage, relativeToWidth: bounds.width)
		
		UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: offset / 100.0, options: [.curveEaseOut, .allowUserInteraction], animations: { [unowned self] () -> Void in
				self.contentView.frame = self.contentView.bounds
				self.colorIndicatorView.backgroundColor = self.defaultColor
				self.slidingView.alpha = 0.0
				if ((self.stateWith(percentage: percentage) == .none) ||
					((self.direction == .leftToRight) && (self.leftToRightAttr.viewBehavior == .stickThenDragWithPan)) ||
					((self.direction == .rightToLeft) && (self.rightToLeftAttr.viewBehavior == .stickThenDragWithPan))) {
						self.slideViewWith(percentage: 0.0, view: self.viewWith(percentage: percentage), andDragBehavior: self.viewBehaviorWith(percentage: percentage))
				} else {
					self.slideViewWith(percentage: 0.0, view: self.viewWith(percentage: percentage), andDragBehavior: .none)
				}
			}, completion: { [unowned self] (Bool) -> Void in
				self.removeSwipingView()
			})
	}
	
	func executeCompletionBlockWith(percentage: Double) {
		let state = stateWith(percentage: percentage)
		var mode: PTATableViewItemMode = .none
		
		switch state {
		case PTATableViewItemState.leftToRight:
			mode = leftToRightAttr.mode
		case PTATableViewItemState.rightToLeft:
			mode = rightToLeftAttr.mode
		default:
			mode = .none
		}
		
		delegate?.tableView(cell: self, didTrigger: state, with: mode)
	}
	
}

extension PTATableViewCell {
	
	fileprivate func hapticFeedbackSetup() {
		if #available(iOS 10.0, *) {
			let feedbackGenerator = UISelectionFeedbackGenerator()
			feedbackGenerator.prepare()
			self.feedbackGenerator = feedbackGenerator
			self.impactGenerator = UIImpactFeedbackGenerator(style: .light)
		}
	}
	
	fileprivate func hapticFeedbackSelectionChanged() {
		if #available(iOS 10.0, *) {
			if let feedbackGenerator = self.feedbackGenerator as? UISelectionFeedbackGenerator {
				feedbackGenerator.selectionChanged()
				feedbackGenerator.prepare()
			}
		}
	}
	
	fileprivate func hapticFeedbackImpactOccurred() {
		if #available(iOS 10.0, *) {
			if let feedbackGenerator = self.impactGenerator as? UIImpactFeedbackGenerator {
				feedbackGenerator.impactOccurred()
			}
		}
	}
	
	fileprivate func hapticFeedbackFinalize() {
		if #available(iOS 10.0, *) {
			self.feedbackGenerator = nil
			self.impactGenerator = nil
		}
	}
	
}

extension PTATableViewCell {
	
	open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
			let point = panGestureRecognizer.velocity(in: self)
			if abs(point.x) > abs(point.y) {
				
				if (point.x < 0.0) && !stateOptions.contains(.rightToLeft) {
					return false
				}
				
				if (point.x > 0.0) && !stateOptions.contains(.leftToRight) {
					return false
				}
				
				previousState = .none
				hapticFeedbackSetup()
				delegate?.tableViewDidStartSwiping?(cell: self)
				return true
			} else {
				return false
			}
		}
		return !isEditing
	}
	
	public func redrawPanningView() {
		_pan(panGestureRecognizer)
	}
	
	@objc internal func _pan(_ gesture: UIPanGestureRecognizer) {
		if let shouldSwipe = delegate?.tableViewShouldSwipe?(cell: self) {
			if !shouldSwipe { return }
		}
		pan(gestureState: gesture.state, translation: gesture.translation(in: self), velocity: gesture.velocity(in: self))
	}
	
	public func pan(gestureState: UIGestureRecognizerState, translation: CGPoint) {
		pan(gestureState: gestureState, translation: translation, velocity: CGPoint.zero)
	}
	
	public func pan(gestureState: UIGestureRecognizerState, translation: CGPoint, velocity: CGPoint) {
		let actualTranslation = actualizeTranslation(translation)
		let percentage = PTATableViewItemHelper.percentageWith(offset: Double(actualTranslation.x), relativeToWidth: Double(bounds.width))
		direction = PTATableViewItemHelper.directionWith(percentage: percentage)
		let cellState = stateWith(percentage: percentage)
		
		if (gestureState == .began) || (gestureState == .changed) {
			setupSwipingView()
			
			contentView.frame = contentView.bounds.offsetBy(dx: actualTranslation.x, dy: 0.0)
			colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
			slidingView.alpha = alphaWith(percentage: percentage)
			
			if let view = viewWith(percentage: percentage) {
				addSubviewToSlidingView(view)
			}
			slideViewWith(percentage: percentage)
			
			if cellState != previousState {
				previousState = cellState
				hapticFeedbackSelectionChanged()
			}
			delegate?.tableViewIsSwiping?(cell: self, with: actualTranslation.x, percentage: percentage)
		} else if (gestureState == .ended) || (gestureState == .cancelled) {
			var cellMode: PTATableViewItemMode = .none
			
			if (cellState == .leftToRight) && (leftToRightAttr.mode != .none) {
				cellMode = leftToRightAttr.mode
			} else if (cellState == .rightToLeft) && (rightToLeftAttr.mode != .none) {
				cellMode = rightToLeftAttr.mode
			}
			
			if (cellMode == .exit) && (direction != .none) {
				moveWith(percentage: percentage, duration: animationDurationWith(velocity: velocity), direction: cellState)
			} else {
				swipeToOriginWith(percentage: percentage)
			}
			
			if cellState != .none {
				hapticFeedbackImpactOccurred()
			}
			hapticFeedbackFinalize()
			delegate?.tableViewDidEndSwiping?(cell: self)
		}
	}
	
	public func actualizeTranslation(_ translation: CGPoint) -> CGPoint {
		let width = bounds.width
		var panOffset = translation.x
		if ((panOffset > 0.0) && leftToRightAttr.rubberbandBounce ||
			(panOffset < 0.0) && rightToLeftAttr.rubberbandBounce) {
				let offset = abs(panOffset)
				panOffset = (offset * 0.55 * width) / (offset * 0.55 + width)
				panOffset *= (translation.x < 0) ? -1.0 : 1.0
		}
		return CGPoint(x: panOffset, y: translation.y)
	}
	
	public func reset() {
		contentView.frame = contentView.bounds
		colorIndicatorView.backgroundColor = defaultColor
		removeSwipingView()
	}
	
}

public extension PTATableViewCell {
	
	/** Sets a pan gesture for the specified state and mode. Don’t forget to implement the delegate method `tableViewCell(cell:didTriggerState:withMode:)` to perform an action when the cell’s state is triggered. */
	public func setPanGesture(_ state: PTATableViewItemState, mode: PTATableViewItemMode, trigger: PTATableViewItemTrigger? = nil, color: UIColor?, view: UIView?) {
			stateOptions.insert(state)
			
			if state.contains(.leftToRight) {
				leftToRightAttr = PTATableViewItemStateAttributes(mode: mode, trigger: trigger, color: color, view: view)
				
				if mode == .none {
					stateOptions.remove(.leftToRight)
				}
			}
			
			if state.contains(.rightToLeft) {
				rightToLeftAttr = PTATableViewItemStateAttributes(mode: mode, trigger: trigger, color: color, view: view)
				
				if mode == .none {
					stateOptions.remove(.rightToLeft)
				}
			}
	}
	
}
