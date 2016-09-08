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
		tableView.register(PTATableViewCell.self, forCellReuseIdentifier: "Cell")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view, typically from a nib.
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(MasterViewController.insertNewObject(_:)))
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func insertNewObject(_ sender: AnyObject) {
		objects += ["Swipe Me Left to Delete"]
		let indexPath = IndexPath(row: (objects.count - 1), section: 0)
		tableView.insertRows(at: [indexPath], with: .automatic)
	}
	
	func viewWithImage(named: String) -> UIView {
		let imageView = UIImageView(image: UIImage(named: named))
		imageView.contentMode = .center
		return imageView
	}
	
	// MARK: - Table View
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return objects.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PTATableViewCell
		
		cell.delegate = self
		cell.textLabel?.text = objects[indexPath.row]
		
		if indexPath.row == 0 {
			let greenColor = UIColor(red: 85.0/255.0, green: 213.0/255.0, blue: 80.0/255.0, alpha: 1.0)
			
			cell.setPanGesture([.leftToRight, .rightToLeft], mode: .switch, color: view.tintColor, view: viewWithImage(named: "check"))
			
			cell.leftToRightAttr.viewBehavior = .dragWithPanThenStick
			cell.leftToRightAttr.color = greenColor
			cell.rightToLeftAttr.rubberbandBounce = false
		} else {
			let redColor = UIColor(red: 232.0/255.0, green: 61.0/255.0, blue: 14.0/255.0, alpha: 1.0)
			
			cell.setPanGesture(.leftToRight, mode: .switch, color: view.tintColor, view: viewWithImage(named: "check"))
			cell.setPanGesture(.rightToLeft, mode: .exit, color: redColor, view: viewWithImage(named: "cross"))
			
			cell.rightToLeftAttr.triggerPercentage = 0.4
			cell.rightToLeftAttr.rubberbandBounce = false
			cell.rightToLeftAttr.viewBehavior = .dragWithPan
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		// Implement your own `tableView:didSelectRowAtIndexPath:` here.
	}
	
	// MARK: - Pan Trigger Action (Required)
	
	func tableView(cell: PTATableViewCell, didTrigger state: PTATableViewItemState, with mode: PTATableViewItemMode) {
		guard let indexPath = tableView.indexPath(for: cell) else { return }
		switch mode {
		case .switch:
			print("row \(indexPath.row)'s switch was triggered")
		case .exit:
			print("row \(indexPath.row)'s exit was triggered")
			objects.remove(at: indexPath.row)
			tableView.deleteRows(at: [indexPath], with: .fade)
		default:
			break
		}
	}
	
	// MARK: - Pan Trigger Action (Optional)
	
	func tableViewDidStartSwiping(cell: PTATableViewCell) {
		guard let indexPath = tableView.indexPath(for: cell) else { return }
		print("row \(indexPath.row) started swiping")
	}
	
	func tableViewIsSwiping(cell: PTATableViewCell, with percentage: Double) {
		guard let indexPath = tableView.indexPath(for: cell) else { return }
		print("row \(indexPath.row) is being swiped with percentage: \(percentage * 100.0)")
	}
	
	func tableViewDidEndSwiping(cell: PTATableViewCell) {
		guard let indexPath = tableView.indexPath(for: cell) else { return }
		print("row \(indexPath.row) ended swiping")
	}
	
}
