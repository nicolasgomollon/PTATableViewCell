//
//  PTATableViewItem.swift
//  PTATableViewCell
//
//  Objective-C code Copyright (c) 2014 Ali Karagoz. All rights reserved.
//  Swift adaptation Copyright (c) 2014 Nicolas Gomollon. All rights reserved.
//

import Foundation
import UIKit


/** Describes the mode used during a pan. */
public enum PTATableViewItemMode {
	
	/** The pan to trigger action is effectively disabled. */
	case none
	
	/** The item bounces back to its original position after it’s released. */
	case `switch`
	
	/** The item slides off screen in the direction it’s being dragged ONLY if it’s released after `triggerPercentage` is reached. If `triggerPercentage` is NOT reached when the item is released, the item bounces back to its original position. */
	case exit
}


/** Describes the slide behaviors that the sliding view can use when the item is dragged. */
public enum PTATableViewItemSlidingViewBehavior {
	
	/** The view remains still as the item is dragged. */
	case none
	
	/** The view is dragged with the item until `triggerPercentage` is reached, at which point the view remains still. */
	case dragWithPanThenStick
	
	/** The view remains still until `triggerPercentage` is reached, at which point the view is dragged with the item. */
	case stickThenDragWithPan
	
	/** The view is dragged with the item. */
	case dragWithPan
}


/** Describes the state that has been triggered by the user. */
public struct PTATableViewItemState: OptionSet {
	fileprivate var value: UInt = 0
	
	public init(_ rawValue: UInt) { self.value = rawValue }
	
	// MARK: RawOptionSetType
	public init(rawValue: UInt) { self.value = rawValue }
	
	// MARK: NilLiteralConvertible
	public init(nilLiteral: ()) { self.value = 0}
	public static func convertFromNilLiteral() -> PTATableViewItemState { return self.init(0) }
	
	// MARK: RawRepresentable
	public var rawValue: UInt { return self.value }
	public func toRaw() -> UInt { return self.value }
	public static func fromRaw(_ raw: UInt) -> PTATableViewItemState? { return self.init(raw) }
	
	// MARK: BooleanType
	public var boolValue: Bool { return self.value != 0 }
	
	// MARK: BitwiseOperationsType
	public static var allZeros: PTATableViewItemState { return self.init(0) }
	public static func fromMask(_ raw: UInt) -> PTATableViewItemState { return self.init(raw) }
	
	/** No state has been triggered. */
	public static var none: PTATableViewItemState { return self.init(0) }
	
	/** The state triggered during a left-to-right swipe. */
	public static var leftToRight: PTATableViewItemState	 { return self.init(1 << 0) }
	
	/** The state triggered during a right-to-left swipe. */
	public static var rightToLeft: PTATableViewItemState	 { return self.init(1 << 1) }
}

public func == (left: PTATableViewItemState, right: PTATableViewItemState) -> Bool { return left.value == right.value }


/** Describes the trigger required to perform the action. */
public class PTATableViewItemTrigger {
	
	/** Describes what the value represents. */
	public enum Kind {
		
		/** The value represents a percentage of the width of the item to be panned before the action is triggered. */
		case percentage
		
		/** The value represents the number of points to be panned before the action is triggered. */
		case offset
	}
	
	/** The kind of number that `value` represents. */
	public var kind: Kind
	
	/** The value of the trigger `kind`. */
	public var value: Double
	
	init(kind: Kind, value: Double) {
		self.kind = kind
		self.value = value
	}
	
	/** Calculate the offset relative to the given width, if needed. */
	public func offset(relativeToWidth w: CGFloat) -> CGFloat {
		if kind == .offset {
			return CGFloat(value)
		}
		
		let width = Double(w)
		var offset = value * width
		
		if offset < -width {
			offset = -width
		} else if offset > width {
			offset = width
		}
		
		return CGFloat(offset)
	}
	
	/** Calculate the percentage relative to the given width, if needed. */
	public func percentage(relativeToWidth w: CGFloat) -> Double {
		if kind == .percentage {
			return value
		}
		
		let width = Double(w)
		var percentage = value / width
		
		if percentage < -1.0 {
			percentage = -1.0
		} else if percentage > 1.0 {
			percentage = 1.0
		}
		
		return percentage
	}
	
}


/** The attributes used when swiping the item in a specific state. */
open class PTATableViewItemStateAttributes {
	
	/** The mode to use with the item state. Defaults to `.None`. */
	open var mode: PTATableViewItemMode
	
	/** The trigger required to perform the action. Defaults to 20%. */
	open var trigger: PTATableViewItemTrigger
	
	/** The rubberband effect applied the farther the item is dragged. Defaults to `true`. */
	open var rubberbandBounce: Bool
	
	/** The color that’s revealed when an action is triggered. Defaults to `nil`. */
	open var color: UIColor?
	
	/** The view below the item that’s revealed when an action is triggered. Defaults to `nil`. */
	var view: UIView?
	
	/** The slide behavior that `view` should use when the item is panned. Defaults to `.StickThenDragWithPan`. */
	open var viewBehavior: PTATableViewItemSlidingViewBehavior
	
	public convenience init() {
		self.init(mode: .none, trigger: nil, color: nil, view: nil)
	}
	
	public init(mode: PTATableViewItemMode, trigger: PTATableViewItemTrigger?, color: UIColor?, view: UIView?) {
		self.mode = mode
		if let trigger = trigger {
			self.trigger = trigger
		} else {
			self.trigger = PTATableViewItemTrigger(kind: .percentage, value: 0.2)
		}
		rubberbandBounce = true
		self.color = color
		self.view = view
		viewBehavior = .stickThenDragWithPan
	}
	
}


open class PTATableViewItemHelper: NSObject {
	
	open class func offsetWith(percentage: Double, relativeToWidth w: CGFloat) -> CGFloat {
		let width = Double(w)
		var offset = percentage * width
		
		if offset < -width {
			offset = -width
		} else if offset > width {
			offset = width
		}
		
		return CGFloat(offset)
	}
	
	open class func percentageWith(offset: Double, relativeToWidth width: Double) -> Double {
		var percentage = offset / width
		
		if percentage < -1.0 {
			percentage = -1.0
		} else if percentage > 1.0 {
			percentage = 1.0
		}
		
		return percentage
	}
	
	open class func directionWith(percentage: Double) -> PTATableViewItemState {
		if percentage < 0.0 {
			return .rightToLeft
		} else if percentage > 0.0 {
			return .leftToRight
		}
		return .none
	}
	
}
