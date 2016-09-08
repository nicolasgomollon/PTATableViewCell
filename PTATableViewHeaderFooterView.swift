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
	
	/** Tells the delegate that the specified header/footer view is being swiped with a percentage. */
	@objc optional func tableViewIsSwiping(headerFooterView: PTATableViewHeaderFooterView, with percentage: Double)
	
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
	open var defaultColor = UIColor(red: 227.0/255.0, green: 227.0/255.0, blue: 227.0/255.0, alpha: 1.0)
	
	/** The attributes used when swiping the header/footer view from left to right. */
	open var leftToRightAttr = PTATableViewItemStateAttributes()
	
	/** The attributes used when swiping the header/footer view from right to left. */
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
		if initialized { return }
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
		if _colorIndicatorView != nil { return }
		colorIndicatorView.addSubview(slidingView)
		// TODO: Check this out on iOS 7.
		insertSubview(colorIndicatorView, belowSubview: contentView)
	}
	
	func removeSwipingView() {
		if _colorIndicatorView == nil { return }
		
		slidingView?.removeFromSuperview()
		slidingView = nil
		
		colorIndicatorView?.removeFromSuperview()
		colorIndicatorView = nil
	}
	
}

private extension PTATableViewHeaderFooterView {
	
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
		if (percentage > 0.0) && (percentage < leftToRightAttr.triggerPercentage) {
			return CGFloat(percentage / leftToRightAttr.triggerPercentage)
		} else if (percentage < 0.0) && (percentage > -rightToLeftAttr.triggerPercentage) {
			return CGFloat(abs(percentage / rightToLeftAttr.triggerPercentage))
		}
		return 1.0
	}
	
	func colorWith(percentage: Double) -> UIColor {
		if (percentage >= leftToRightAttr.triggerPercentage) && (leftToRightAttr.mode != .none) && (leftToRightAttr.color != nil) {
			return leftToRightAttr.color!
		} else if (percentage <= -rightToLeftAttr.triggerPercentage) && (rightToLeftAttr.mode != .none) && (rightToLeftAttr.color != nil) {
			return rightToLeftAttr.color!
		}
		return defaultColor
	}
	
	func stateWith(percentage: Double) -> PTATableViewItemState {
		if (percentage >= leftToRightAttr.triggerPercentage) && (leftToRightAttr.mode != .none) {
			return .leftToRight
		} else if (percentage <= -rightToLeftAttr.triggerPercentage) && (rightToLeftAttr.mode != .none) {
			return .rightToLeft
		}
		return .none
	}
	
}

private extension PTATableViewHeaderFooterView {
	
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
		let halfLeftToRightTriggerPercentage = leftToRightAttr.triggerPercentage / 2.0
		let halfRightToLeftTriggerPercentage = rightToLeftAttr.triggerPercentage / 2.0
		
		switch dragBehavior {
			
		case .stickThenDragWithPan:
			if direction == .leftToRight {
				if (percentage >= 0.0) && (percentage < leftToRightAttr.triggerPercentage) {
					position.x = PTATableViewItemHelper.offsetWith(percentage: halfLeftToRightTriggerPercentage, relativeToWidth: width)
				} else if percentage >= leftToRightAttr.triggerPercentage {
					position.x = PTATableViewItemHelper.offsetWith(percentage: percentage - halfLeftToRightTriggerPercentage, relativeToWidth: width)
				}
			} else if direction == .rightToLeft {
				if (percentage <= 0.0) && (percentage >= -rightToLeftAttr.triggerPercentage) {
					position.x = width - PTATableViewItemHelper.offsetWith(percentage: halfRightToLeftTriggerPercentage, relativeToWidth: width)
				} else if percentage <= -rightToLeftAttr.triggerPercentage {
					position.x = width + PTATableViewItemHelper.offsetWith(percentage: percentage + halfRightToLeftTriggerPercentage, relativeToWidth: width)
				}
			}
			
		case .dragWithPanThenStick:
			if direction == .leftToRight {
				if (percentage >= 0.0) && (percentage < leftToRightAttr.triggerPercentage) {
					position.x = PTATableViewItemHelper.offsetWith(percentage: percentage - halfLeftToRightTriggerPercentage, relativeToWidth: width)
				} else if percentage >= leftToRightAttr.triggerPercentage {
					position.x = PTATableViewItemHelper.offsetWith(percentage: halfLeftToRightTriggerPercentage, relativeToWidth: width)
				}
			} else if direction == .rightToLeft {
				if (percentage <= 0.0) && (percentage >= -rightToLeftAttr.triggerPercentage) {
					position.x = width + PTATableViewItemHelper.offsetWith(percentage: percentage + halfRightToLeftTriggerPercentage, relativeToWidth: width)
				} else if percentage <= -rightToLeftAttr.triggerPercentage {
					position.x = width - PTATableViewItemHelper.offsetWith(percentage: halfRightToLeftTriggerPercentage, relativeToWidth: width)
				}
			}
			
		case .dragWithPan:
			if direction == .leftToRight {
				position.x = PTATableViewItemHelper.offsetWith(percentage: percentage - halfLeftToRightTriggerPercentage, relativeToWidth: width)
			} else if direction == .rightToLeft {
				position.x = width + PTATableViewItemHelper.offsetWith(percentage: percentage + halfRightToLeftTriggerPercentage, relativeToWidth: width)
			}
			
		case .none:
			if direction == .leftToRight {
				position.x = PTATableViewItemHelper.offsetWith(percentage: halfLeftToRightTriggerPercentage, relativeToWidth: width)
			} else if direction == .rightToLeft {
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
		
		delegate?.tableView(headerFooterView: self, didTrigger: state, with: mode)
	}
	
}

extension PTATableViewHeaderFooterView: UIGestureRecognizerDelegate {
	
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
				
				delegate?.tableViewDidStartSwiping?(headerFooterView: self)
				return true
			} else {
				return false
			}
		}
		return true
	}
	
	internal func _pan(_ gesture: UIPanGestureRecognizer) {
		if let shouldSwipe = delegate?.tableViewShouldSwipe?(headerFooterView: self) {
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
		
		if (gestureState == .began) || (gestureState == .changed) {
			setupSwipingView()
			
			contentView.frame = contentView.bounds.offsetBy(dx: actualTranslation.x, dy: 0.0)
			colorIndicatorView.backgroundColor = colorWith(percentage: percentage)
			slidingView.alpha = alphaWith(percentage: percentage)
			
			if let view = viewWith(percentage: percentage) {
				addSubviewToSlidingView(view)
			}
			slideViewWith(percentage: percentage)
			
			delegate?.tableViewIsSwiping?(headerFooterView: self, with: percentage)
		} else if (gestureState == .ended) || (gestureState == .cancelled) {
			let cellState = stateWith(percentage: percentage)
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

public extension PTATableViewHeaderFooterView {
	
	/** Sets a pan gesture for the specified state and mode. Don’t forget to implement the delegate method `tableViewHeaderFooterView(view:didTriggerState:withMode:)` to perform an action when the header/footer view’s state is triggered. */
	public func setPanGesture(_ state: PTATableViewItemState, mode: PTATableViewItemMode, color: UIColor?, view: UIView?) {
		stateOptions.insert(state)
		
		if state.contains(.leftToRight) {
			leftToRightAttr = PTATableViewItemStateAttributes(mode: mode, color: color, view: view)
			
			if mode == .none {
				stateOptions.remove(.leftToRight)
			}
		}
		
		if state.contains(.rightToLeft) {
			rightToLeftAttr = PTATableViewItemStateAttributes(mode: mode, color: color, view: view)
			
			if mode == .none {
				stateOptions.remove(.rightToLeft)
			}
		}
	}
	
}
