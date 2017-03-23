# PTATableViewCell

PTATableViewCell (PTA is short for “Pan to Trigger Action”) is a convenient UITableViewCell subclass that supports pan gestures to trigger actions (as seen in apps such as Clear, Mailbox, Tweetbot, and more). PTATableViewCell is written completely in Swift (adapted from Objective-C, original code by: [alikaragoz/MCSwipeTableViewCell](https://github.com/alikaragoz/MCSwipeTableViewCell)).

<img alt="Sample Screenshot" width="320" height="568" src="http://f.cl.ly/items/2X0n0d1M2e0f0a2C390R/SampleScreenshot.png" />


## Usage

Here’s an example usage, with various attributes modified to show a few of the cell’s properties.

```swift
override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
	let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PTATableViewCell
	
	cell.textLabel.text = objects[indexPath.row]
	
	
	cell.delegate = self
	
	cell.setPanGesture(.leftToRight, mode: .switch, trigger: PTATableViewItemTrigger(kind: .offset, value: 64.0), color: view.tintColor, view: viewWithImage(named: "check"))
	cell.leftToRightAttr.viewBehavior = .dragWithPanThenStick
	
	let redColor = UIColor(red: 232.0/255.0, green: 61.0/255.0, blue: 14.0/255.0, alpha: 1.0)
	cell.setPanGesture(.rightToLeft, mode: .exit, color: redColor, view: viewWithImage(named: "cross"))
	
	cell.rightToLeftAttr.trigger.value = 0.4
	cell.rightToLeftAttr.rubberbandBounce = false
	cell.rightToLeftAttr.viewBehavior = .dragWithPan
	
	
	return cell
}
```

It’s **important** that you implement the following delegate method to perform an action when the cell’s state is triggered:

```swift
func tableView(cell: PTATableViewCell, didTrigger state: PTATableViewItemState, with mode: PTATableViewItemMode) {
	guard let indexPath = tableView.indexPath(for: cell) else { return }
	switch mode {
	case .switch:
		print("row \(indexPath.row)'s switch was triggered")
		// Do something interesting here.
	case .exit:
		print("row \(indexPath.row)'s exit was triggered")
		// Do something interesting here.
		objects.remove(at: indexPath.row)
		tableView.deleteRows(at: [indexPath], with: .fade)
	default:
		break
	}
}
```

There are also a few _optional_ delegate methods you may implement:

```swift
// Asks the delegate whether a given cell should be swiped. Defaults to `true` if not implemented.
func tableViewShouldSwipe(cell: PTATableViewCell) -> Bool

// Tells the delegate that the specified cell is being swiped with the offset and percentage.
func tableViewIsSwiping(cell: PTATableViewCell, with offset: CGFloat, percentage: Double)

// Tells the delegate that the specified cell started swiping.
func tableViewDidStartSwiping(cell: PTATableViewCell)

// Tells the delegate that the specified cell ended swiping.
func tableViewDidEndSwiping(cell: PTATableViewCell)
```

See the ActionTest demo project included in this repository for a working example of the project, including the code above.


## Requirements

Since PTATableViewCell is written in Swift 3, it requires Xcode 8 or above and works on iOS 8 and above.


## License

PTATableViewCell is released under the MIT License.
