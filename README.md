# PTATableViewCell

PTATableViewCell (PTA is short for “Pan to Trigger Action”) is a convenient UITableViewCell subclass that supports pan gestures to trigger actions (as seen in apps such as Clear, Mailbox, Tweetbot, and more). PTATableViewCell is based on: [alikaragoz/MCSwipeTableViewCell](https://github.com/alikaragoz/MCSwipeTableViewCell), and ported from the Swift version of this repo.

<img alt="Sample Screenshot" width="320" height="568" src="http://f.cl.ly/items/2X0n0d1M2e0f0a2C390R/SampleScreenshot.png" />


## Usage

Here’s an example usage, with various attributes modified to show a few of the cell’s properties.

```objective-c
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	PTATableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	cell.textLabel.text = _objects[indexPath.row];


	cell.delegate = self;

	[cell setPanGestureState:PTATableViewCellStateLeftToRight
						mode:PTATableViewCellModeSwitch
					   color:self.view.tintColor
						view:[self viewWithImageNamed:@"check"]];
	cell.leftToRightAttr.viewBehavior = PTATableViewCellSlidingViewBehaviorDragWithPanThenStick;
	
	UIColor *redColor = [UIColor colorWithRed:232.0f/255.0f green:61.0f/255.0f blue:14.0f/255.0f alpha:1.0f];
	[cell setPanGestureState:PTATableViewCellStateRightToLeft
						mode:PTATableViewCellModeExit
					   color:redColor
						view:[self viewWithImageNamed:@"cross"]];
	
	cell.rightToLeftAttr.triggerPercentage = 0.4f;
	cell.rightToLeftAttr.rubberbandBounce = NO;
	cell.rightToLeftAttr.viewBehavior = PTATableViewCellSlidingViewBehaviorDragWithPan;
	
	return cell;
}
```

It’s **important** that you implement the following delegate method to perform an action when the cell’s state is triggered:

```objective-c
- (void)tableViewCell:(PTATableViewCell *)cell didTriggerState:(PTATableViewCellState)state withMode:(PTATableViewCellMode)mode {
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	
	switch (mode) {
		case PTATableViewCellModeSwitch:
			NSLog(@"row %li's switch was triggered", (long)indexPath.row);
			break;
			
		case PTATableViewCellModeExit:
			NSLog(@"row %li's exit was triggered", (long)indexPath.row);
			[_objects removeObjectAtIndex:indexPath.row];
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		default:
			break;
	}
}
```

There are also a few _optional_ delegate methods you may implement:

```objective-c
// Asks the delegate whether a given cell should be swiped. Defaults to `true` if not implemented.
- (BOOL)tableViewCellShouldSwipe:(PTATableViewCell *)cell;

// Tells the delegate that the specified cell is being swiped with a percentage.
- (void)tableViewCellIsSwiping:(PTATableViewCell *)cell withPercentage:(CGFloat)percentage;

// Tells the delegate that the specified cell started swiping.
- (void)tableViewCellDidStartSwiping:(PTATableViewCell *)cell;

// Tells the delegate that the specified cell ended swiping.
- (void)tableViewCellDidEndSwiping:(PTATableViewCell *)cell;
```

See the ActionTest demo project included in this repository for a working example of the project, including the code above.


## Requirements

PTATableViewCell has been tested with Xcode 6 and works on iOS 7 and above.


## License

PTATableViewCell is released under the MIT License.
