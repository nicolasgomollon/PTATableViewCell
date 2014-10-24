# PTATableViewCell

PTATableViewCell (PTA is short for “Pan to Trigger Action”) is a convenient UITableViewCell subclass that supports pan gestures to trigger actions (as seen in apps such as Clear, Mailbox, Tweetbot, and more). PTATableViewCell is written completely in Swift (adapted from Objective-C, original code by: [alikaragoz/MCSwipeTableViewCell](https://github.com/alikaragoz/MCSwipeTableViewCell)).

<img alt="Sample Screenshot" width="320" height="568" src="http://f.cl.ly/items/2X0n0d1M2e0f0a2C390R/SampleScreenshot.png" />


## Usage

Here’s an example usage, with various attributes modified to show a few of the cell’s properties.

```swift
override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
	let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as PTATableViewCell
	
	cell.textLabel.text = objects[indexPath.row]
	

	cell.delegate = self

	cell.setPanGesture(.LeftToRight, mode: .Switch, color: view.tintColor, view: viewWithImage(named: "check"))
	cell.leftToRightAttr.viewBehavior = .DragWithPanThenStick
	
	let redColor = UIColor(red: 232.0/255.0, green: 61.0/255.0, blue: 14.0/255.0, alpha: 1.0)
	cell.setPanGesture(.RightToLeft, mode: .Exit, color: redColor, view: viewWithImage(named: "cross"))
	
	cell.rightToLeftAttr.triggerPercentage = 0.4
	cell.rightToLeftAttr.rubberbandBounce = false
	cell.rightToLeftAttr.viewBehavior = .DragWithPan
	

	return cell
}
```

It’s **important** that you implement the following delegate method to perform an action when the cell’s state is triggered:

```swift
func tableViewCell(cell: PTATableViewCell, didTriggerState state: PTATableViewCellState, withMode mode: PTATableViewCellMode) {
	if let indexPath = tableView.indexPathForCell(cell) {
		switch mode {
		case .Switch:
			println("row \(indexPath.row)'s switch was triggered")
			// Do something interesting here.
		case .Exit:
			println("row \(indexPath.row)'s exit was triggered")
			// Do something interesting here.
			objects.removeAtIndex(indexPath.row)
			tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
		default:
			break
		}
	}
}
```

There are also a few _optional_ delegate methods you may implement:

```swift
// Asks the delegate whether a given cell should be swiped. Defaults to `true` if not implemented.
func tableViewCellShouldSwipe(cell: PTATableViewCell) -> Bool

// Tells the delegate that the specified cell is being swiped with a percentage.
func tableViewCellIsSwiping(cell: PTATableViewCell, withPercentage percentage: Double)

// Tells the delegate that the specified cell started swiping.
func tableViewCellDidStartSwiping(cell: PTATableViewCell)

// Tells the delegate that the specified cell ended swiping.
func tableViewCellDidEndSwiping(cell: PTATableViewCell)
```

See the ActionTest demo project included in this repository for a working example of the project, including the code above.


## Requirements

Since PTATableViewCell is written in Swift, it requires Xcode 6 or above and works on iOS 7 and above.


## License

PTATableViewCell is released under the MIT License.
