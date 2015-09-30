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
	case None
	
	/** The item bounces back to its original position after it’s released. */
	case Switch
	
	/** The item slides off screen in the direction it’s being dragged ONLY if it’s released after `triggerPercentage` is reached. If `triggerPercentage` is NOT reached when the item is released, the item bounces back to its original position. */
	case Exit
}


/** Describes the slide behaviors that the sliding view can use when the item is dragged. */
public enum PTATableViewItemSlidingViewBehavior {
	
	/** The view remains still as the item is dragged. */
	case None
	
	/** The view is dragged with the item until `triggerPercentage` is reached, at which point the view remains still. */
	case DragWithPanThenStick
	
	/** The view remains still until `triggerPercentage` is reached, at which point the view is dragged with the item. */
	case StickThenDragWithPan
	
	/** The view is dragged with the item. */
	case DragWithPan
}


/** Describes the state that has been triggered by the user. */
public struct PTATableViewItemState: OptionSetType, BooleanType {
	private var value: UInt = 0
	
	public init(_ rawValue: UInt) { self.value = rawValue }
	
	// MARK: RawOptionSetType
	public init(rawValue: UInt) { self.value = rawValue }
	
	// MARK: NilLiteralConvertible
	public init(nilLiteral: ()) { self.value = 0}
	public static func convertFromNilLiteral() -> PTATableViewItemState { return self.init(0) }
	
	// MARK: RawRepresentable
	public var rawValue: UInt { return self.value }
	public func toRaw() -> UInt { return self.value }
	public static func fromRaw(raw: UInt) -> PTATableViewItemState? { return self.init(raw) }
	
	// MARK: BooleanType
	public var boolValue: Bool { return self.value != 0 }
	
	// MARK: BitwiseOperationsType
	public static var allZeros: PTATableViewItemState { return self.init(0) }
	public static func fromMask(raw: UInt) -> PTATableViewItemState { return self.init(raw) }
	
	/** No state has been triggered. */
	public static var None: PTATableViewItemState			{ return self.init(0) }
	
	/** The state triggered during a left-to-right swipe. */
	public static var LeftToRight: PTATableViewItemState	{ return self.init(1 << 0) }
	
	/** The state triggered during a right-to-left swipe. */
	public static var RightToLeft: PTATableViewItemState	{ return self.init(1 << 1) }
}

public func == (left: PTATableViewItemState, right: PTATableViewItemState) -> Bool { return left.value == right.value }


/** The attributes used when swiping the item in a specific state. */
public class PTATableViewItemStateAttributes {
	
	/** The mode to use with the item state. Defaults to `.None`. */
	public var mode: PTATableViewItemMode
	
	/** The percent of the width of the item required to be panned before the action is triggered. Defaults to 20%. */
	public var triggerPercentage: Double
	
	/** The rubberband effect applied the farther the item is dragged. Defaults to `true`. */
	public var rubberbandBounce: Bool
	
	/** The color that’s revealed when an action is triggered. Defaults to `nil`. */
	public var color: UIColor?
	
	/** The view below the item that’s revealed when an action is triggered. Defaults to `nil`. */
	var view: UIView?
	
	/** The slide behavior that `view` should use when the item is panned. Defaults to `.StickThenDragWithPan`. */
	public var viewBehavior: PTATableViewItemSlidingViewBehavior
	
	public convenience init() {
		self.init(mode: .None, color: nil, view: nil)
	}
	
	public init(mode: PTATableViewItemMode, color: UIColor?, view: UIView?) {
		self.mode = mode
		triggerPercentage = 0.2
		rubberbandBounce = true
		self.color = color
		self.view = view
		viewBehavior = .StickThenDragWithPan
	}
	
}


public class PTATableViewItemHelper: NSObject {
	
	public class func offsetWith(percentage percentage: Double, relativeToWidth w: CGFloat) -> CGFloat {
		let width = Double(w)
		var offset = percentage * width
		
		if offset < -width {
			offset = -width
		} else if offset > width {
			offset = width
		}
		
		return CGFloat(offset)
	}
	
	public class func percentageWith(offset offset: Double, relativeToWidth width: Double) -> Double {
		var percentage = offset / width
		
		if percentage < -1.0 {
			percentage = -1.0
		} else if percentage > 1.0 {
			percentage = 1.0
		}
		
		return percentage
	}
	
	public class func directionWith(percentage percentage: Double) -> PTATableViewItemState {
		if percentage < 0.0 {
			return .RightToLeft
		} else if percentage > 0.0 {
			return .LeftToRight
		}
		return .None
	}
	
}
