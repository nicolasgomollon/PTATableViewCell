//
//  MasterViewController.swift
//  ActionTest
//
//  Created by Nicolas Gomollon on 6/18/14.
//  Copyright (c) 2014 Techno-Magic. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, PTATableViewCellDelegate {
	
	var objects = ["Swipe Me Left or Right", "Swipe Me Left to Delete"]
	
	
	override func awakeFromNib() {
		super.awakeFromNib()
		tableView.registerClass(PTATableViewCell.self, forCellReuseIdentifier: "Cell")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view, typically from a nib.
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(MasterViewController.insertNewObject(_:)))
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func insertNewObject(sender: AnyObject) {
		objects += ["Swipe Me Left to Delete"]
		let indexPath = NSIndexPath(forRow: (objects.count - 1), inSection: 0)
		tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
	}
	
	func viewWithImage(named named: String) -> UIView {
		let imageView = UIImageView(image: UIImage(named: named))
		imageView.contentMode = .Center
		return imageView
	}
	
	// MARK: - Table View
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return objects.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PTATableViewCell
		
		cell.delegate = self
		cell.textLabel?.text = objects[indexPath.row]
		
		if indexPath.row == 0 {
			let greenColor = UIColor(red: 85.0/255.0, green: 213.0/255.0, blue: 80.0/255.0, alpha: 1.0)
			
			cell.setPanGesture([.LeftToRight, .RightToLeft], mode: .Switch, color: view.tintColor, view: viewWithImage(named: "check"))
			
			cell.leftToRightAttr.viewBehavior = .DragWithPanThenStick
			cell.leftToRightAttr.color = greenColor
			cell.rightToLeftAttr.rubberbandBounce = false
		} else {
			let redColor = UIColor(red: 232.0/255.0, green: 61.0/255.0, blue: 14.0/255.0, alpha: 1.0)
			
			cell.setPanGesture(.LeftToRight, mode: .Switch, color: view.tintColor, view: viewWithImage(named: "check"))
			cell.setPanGesture(.RightToLeft, mode: .Exit, color: redColor, view: viewWithImage(named: "cross"))
			
			cell.rightToLeftAttr.triggerPercentage = 0.4
			cell.rightToLeftAttr.rubberbandBounce = false
			cell.rightToLeftAttr.viewBehavior = .DragWithPan
		}
		
		return cell
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		// Implement your own `tableView:didSelectRowAtIndexPath:` here.
	}
	
	// MARK: - Pan Trigger Action (Required)
	
	func tableViewCell(cell: PTATableViewCell, didTriggerState state: PTATableViewItemState, withMode mode: PTATableViewItemMode) {
		if let indexPath = tableView.indexPathForCell(cell) {
			switch mode {
			case .Switch:
				print("row \(indexPath.row)'s switch was triggered")
			case .Exit:
				print("row \(indexPath.row)'s exit was triggered")
				objects.removeAtIndex(indexPath.row)
				tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
			default:
				break
			}
		}
	}
	
	// MARK: - Pan Trigger Action (Optional)
	
	func tableViewCellDidStartSwiping(cell: PTATableViewCell) {
		if let indexPath = tableView.indexPathForCell(cell) {
			print("row \(indexPath.row) started swiping")
		}
	}
	
	func tableViewCellIsSwiping(cell: PTATableViewCell, withPercentage percentage: Double) {
		if let indexPath = tableView.indexPathForCell(cell) {
			print("row \(indexPath.row) is being swiped with percentage: \(percentage * 100.0)")
		}
	}
	
	func tableViewCellDidEndSwiping(cell: PTATableViewCell) {
		if let indexPath = tableView.indexPathForCell(cell) {
			print("row \(indexPath.row) ended swiping")
		}
	}
	
}
