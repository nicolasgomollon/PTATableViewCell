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
	@objc optional func tableViewShouldSwipe(headerFooterView: PTATableViewHeaderFooterView) -> Bool
	
	/** Tells the delegate that the specified header/footer view is being swiped with the offset and percentage. */
	@objc optional func tableViewIsSwiping(headerFooterView: PTATableViewHeaderFooterView, with offset: CGFloat, percentage: Double)
	
	/** Tells the delegate that the specified header/footer view started swiping. */
	@objc optional func tableViewDidStartSwiping(headerFooterView: PTATableViewHeaderFooterView)
	
	/** Tells the delegate that the specified header/footer view ended swiping. */
	@objc optional func tableViewDidEndSwiping(headerFooterView: PTATableViewHeaderFooterView)
	
}

/** The delegate of a PTATableViewHeaderFooterView object must adopt the PTATableViewHeaderFooterViewDelegate protocol in order to perform an action when triggered. Optional methods of the protocol allow the delegate to be notified of a header/footer view’s swipe state, and determine whether a header/footer view should be swiped. */
public protocol PTATableViewHeaderFooterViewDelegate: ObjC_PTATableViewHeaderFooterViewDelegate {
	
	/** Tells the delegate that the specified cell’s state was triggered. */
	func tableView(headerFooterView: PTATableViewHeaderFooterView, didTrigger state: PTATableViewItemState, with mode: PTATableViewItemMode)
	
}


open class PTATableViewHeaderFooterView: UITableViewHeaderFooterView {
	
	/** The object that acts as the delegate of the receiving table view header/footer view. */
	open weak var delegate: PTATableViewHeaderFooterViewDelegate!
	
	fileprivate var initialized: Bool = false
	
	fileprivate var panGestureRecognizer: UIPanGestureRecognizer!
	
	fileprivate var direction: PTATableViewItemState = .none
	
	fileprivate var stateOptions: PTATableViewItemState = .none
	
	
	/** The color that’s revealed before an action is triggered. Defaults to a light gray color. */
	open var defaultColor: UIColor = UIColor(red: 227.0/255.0, green: 227.0/255.0, blue: 227.0/255.0, alpha: 1.0)
	
	/** The attributes used when swiping the header/footer view from left to right. */
	open var leftToRightAttr: PTATableViewItemStateAttributes = .init()
	
	/** The attributes used when swiping the header/footer view from right to left. */
	open var rightToLeftAttr: PTATableViewItemStateAttributes = .init()
	
	
	fileprivate var _slidingView: UIView?
	fileprivate var slidingView: UIView! {
		get {
			if let slidingView: UIView = _slidingView {
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
			if let colorIndicatorView: UIView = _colorIndicatorView {
				return colorIndicatorView
			}
			_colorIndicatorView = UIView(frame: bounds)
			_colorIndicatorView!.autoresizingMask = [.flexibleHeight, .flexibleWidth]
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
	
	
	public override init(reuseIdentifier: String?) {
		super.init(reuseIdentifier: reuseIdentifier)
		initialize()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}
	
	fileprivate func initialize() {
		guard !initialized else { return }
		initialized = true
		contentView.backgroundColor = .white
		panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(PTATableViewHeaderFooterView._pan(_:)))
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

private extension PTATableViewHeaderFooterView {
	
	func setupSwipingView() {
		guard _colorIndicatorView == nil else { return }
		colorIndicatorView.addSubview(slidingView)
		// TODO: Check this out on iOS 7.
		insertSubview(colorIndicatorView, belowSubview: contentView)
	}
	
	func removeSwipingView() {
		guard _colorIndicatorView != nil else { return }
		slidingView?.removeFromSuperview()
		slidingView = nil
		colorIndicatorView?.removeFromSuperview()
		colorIndicatorView = nil
	}
	
}

private extension PTATableViewHeaderFooterView {
	
	func animationDurationWith(velocity: CGPoint) -> TimeInterval {
		let DurationHighLimit: Double = 0.1
		let DurationLowLimit: Double = 0.25
		
		let width: CGFloat = bounds.width
		let animationDurationDiff: TimeInterval = DurationHighLimit - DurationLowLimit
		var horizontalVelocity: CGFloat = velocity.x
		
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
		let ltrTrigger: PTATableViewItemTrigger = leftToRightAttr.trigger
		let rtlTrigger: PTATableViewItemTrigger = rightToLeftAttr.trigger
		let offset: CGFloat = PTATableViewItemHelper.offsetWith(percentage: abs(percentage), relativeToWidth: bounds.width)
		if percentage > 0.0 {
			switch ltrTrigger.kind {
			case .percentage:
				if percentage < ltrTrigger.value {
					return CGFloat(percentage / ltrTrigger.value)
				}
			case .offset:
				let triggerValue: CGFloat = CGFloat(ltrTrigger.value)
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
				let triggerValue: CGFloat = CGFloat(rtlTrigger.value)
				if offset < triggerValue {
					return offset / triggerValue
				}
			}
		}
		return 1.0
	}
	
	func colorWith(percentage: Double) -> UIColor {
		let ltrTrigger: PTATableViewItemTrigger = leftToRightAttr.trigger
		let rtlTrigger: PTATableViewItemTrigger = rightToLeftAttr.trigger
		let offset: CGFloat = PTATableViewItemHelper.offsetWith(percentage: abs(percentage), relativeToWidth: bounds.width)
		if (percentage > 0.0) && (leftToRightAttr.mode != .none) && (leftToRightAttr.color != nil) {
			switch ltrTrigger.kind {
			case .percentage:
				if percentage >= ltrTrigger.value {
					return leftToRightAttr.color!
				}
			case .offset:
				let triggerValue: CGFloat = CGFloat(ltrTrigger.value)
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
				let triggerValue: CGFloat = CGFloat(rtlTrigger.value)
				if offset >= triggerValue {
					return rightToLeftAttr.color!
				}
			}
		}
		return defaultColor
	}
	
	func stateWith(percentage: Double) -> PTATableViewItemState {
		let ltrTrigger: PTATableViewItemTrigger = leftToRightAttr.trigger
		let rtlTrigger: PTATableViewItemTrigger = rightToLeftAttr.trigger
		let offset: CGFloat = PTATableViewItemHelper.offsetWith(percentage: abs(percentage), relativeToWidth: bounds.width)
		if (percentage > 0.0) && (leftToRightAttr.mode != .none) {
			switch ltrTrigger.kind {
			case .percentage:
				if percentage >= ltrTrigger.value {
					return .leftToRight
				}
			case .offset:
				let triggerValue: CGFloat = CGFloat(ltrTrigger.value)
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
				let triggerValue: CGFloat = CGFloat(rtlTrigger.value)
				if offset >= triggerValue {
					return .rightToLeft
				}
			}
		}
		return .none
	}
	
}

private extension PTATableViewHeaderFooterView {
	
	func animateWith(offset: Double) {
		let percentage: Double = PTATableViewItemHelper.percentageWith(offset: offset, relativeToWidth: Double(bounds.width))
		if let view: UIView = viewWith(percentage: percentage) {
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
		var position: CGPoint = .zero
		position.y = bounds.height / 2.0
		
		let width: CGFloat = bounds.width
		let offset: CGFloat = PTATableViewItemHelper.offsetWith(percentage: percentage, relativeToWidth: width)
		
		let ltrTriggerPercentage: Double = leftToRightAttr.trigger.percentage(relativeToWidth: width)
		let rtlTriggerPercentage: Double = rightToLeftAttr.trigger.percentage(relativeToWidth: width)
		
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
		
		guard let activeView: UIView = view else { return }
		var activeViewFrame: CGRect = activeView.bounds
		activeViewFrame.origin.x = position.x - (activeViewFrame.size.width / 2.0)
		activeViewFrame.origin.y = position.y - (activeViewFrame.size.height / 2.0)
		slidingView.frame = activeViewFrame
	}
	
	func moveWith(percentage: Double, duration: TimeInterval, direction: PTATableViewItemState) {
		var origin: CGFloat = 0.0
		
		if direction == .rightToLeft {
			origin -= bounds.width
		} else if direction == .leftToRight {
			origin += bounds.width
		}
		
		var frame: CGRect = contentView.frame
		frame.origin.x = origin
		
		colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
		
		UIView.animate(withDuration: duration, delay: 0.0, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.contentView.frame = frame
			self.slidingView.alpha = 0.0
			self.slideViewWith(percentage: PTATableViewItemHelper.percentageWith(offset: Double(origin), relativeToWidth: Double(self.bounds.width)), view: self.viewWith(percentage: percentage), andDragBehavior: self.viewBehaviorWith(percentage: percentage))
		}, completion: { (finished: Bool) in
			self.executeCompletionBlockWith(percentage: percentage)
		})
	}
	
	func swipeToOriginWith(percentage: Double) {
		executeCompletionBlockWith(percentage: percentage)
		
		let offset: CGFloat = PTATableViewItemHelper.offsetWith(percentage: percentage, relativeToWidth: bounds.width)
		
		UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: offset / 100.0, options: [.curveEaseOut, .allowUserInteraction], animations: {
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
		}, completion: { (finished: Bool) in
			self.removeSwipingView()
		})
	}
	
	func executeCompletionBlockWith(percentage: Double) {
		let state: PTATableViewItemState = stateWith(percentage: percentage)
		let mode: PTATableViewItemMode
		switch state {
		case PTATableViewItemState.leftToRight:
			mode = leftToRightAttr.mode
		case PTATableViewItemState.rightToLeft:
			mode = rightToLeftAttr.mode
		default:
			mode = .none
		}
		delegate?.tableView(headerFooterView: self, didTrigger: state, with: mode)
	}
	
}

extension PTATableViewHeaderFooterView: UIGestureRecognizerDelegate {
	
	open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		guard let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return true }
		let point: CGPoint = panGestureRecognizer.velocity(in: self)
		if abs(point.x) > abs(point.y) {
			if (point.x < 0.0) && !stateOptions.contains(.rightToLeft) {
				return false
			}
			if (point.x > 0.0) && !stateOptions.contains(.leftToRight) {
				return false
			}
			delegate?.tableViewDidStartSwiping?(headerFooterView: self)
			return true
		} else {
			return false
		}
	}
	
	@objc internal func _pan(_ gesture: UIPanGestureRecognizer) {
		if let shouldSwipe: Bool = delegate?.tableViewShouldSwipe?(headerFooterView: self) {
			guard shouldSwipe else { return }
		}
		pan(gestureState: gesture.state, translation: gesture.translation(in: self), velocity: gesture.velocity(in: self))
	}
	
	public func pan(gestureState: UIGestureRecognizer.State, translation: CGPoint) {
		pan(gestureState: gestureState, translation: translation, velocity: CGPoint.zero)
	}
	
	public func pan(gestureState: UIGestureRecognizer.State, translation: CGPoint, velocity: CGPoint) {
		let actualTranslation: CGPoint = actualizeTranslation(translation)
		let percentage: Double = PTATableViewItemHelper.percentageWith(offset: Double(actualTranslation.x), relativeToWidth: Double(bounds.width))
		direction = PTATableViewItemHelper.directionWith(percentage: percentage)
		
		switch gestureState {
			
		case .began,
			 .changed:
			setupSwipingView()
			
			contentView.frame = contentView.bounds.offsetBy(dx: actualTranslation.x, dy: 0.0)
			colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
			slidingView.alpha = alphaWith(percentage: percentage)
			
			if let view: UIView = viewWith(percentage: percentage) {
				addSubviewToSlidingView(view)
			}
			slideViewWith(percentage: percentage)
			
			delegate?.tableViewIsSwiping?(headerFooterView: self, with: actualTranslation.x, percentage: percentage)
			
		case .ended,
			 .cancelled:
			let cellState: PTATableViewItemState = stateWith(percentage: percentage)
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
			
			delegate?.tableViewDidEndSwiping?(headerFooterView: self)
			
		default:
			break
		}
	}
	
	public func actualizeTranslation(_ translation: CGPoint) -> CGPoint {
		let width: CGFloat = bounds.width
		var panOffset: CGFloat = translation.x
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

extension PTATableViewHeaderFooterView {
	
	/** Sets a pan gesture for the specified state and mode. Don’t forget to implement the delegate method `tableViewHeaderFooterView(view:didTriggerState:withMode:)` to perform an action when the header/footer view’s state is triggered. */
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
