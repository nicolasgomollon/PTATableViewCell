//
//  MasterViewController.m
//  ActionTest
//
//  Created by Nicolas Gomollon on 7/22/14.
//  Copyright (c) 2014 Techno-Magic. All rights reserved.
//

#import "MasterViewController.h"

@interface MasterViewController () {
	NSMutableArray *_objects;
}
@end

@implementation MasterViewController

- (void)loadView {
	[super loadView];
	self.title = @"Master";
	[self.tableView registerClass:[PTATableViewCell class] forCellReuseIdentifier:@"Cell"];
	_objects = [[NSMutableArray alloc] initWithArray:@[@"Swipe Me Left or Right", @"Swipe Me Left to Delete"]];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Do any additional setup after loading the view, typically from a nib.
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
	[_objects addObject:@"Swipe Me Left to Delete"];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(_objects.count - 1) inSection:0];
	[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (UIView *)viewWithImageNamed:(NSString *)named {
	UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:named]];
	imageView.contentMode = UIViewContentModeCenter;
	return imageView;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	PTATableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	cell.delegate = self;
	cell.textLabel.text = _objects[indexPath.row];
	
	if (indexPath.row == 0) {
		UIColor *greenColor = [UIColor colorWithRed:85.0f/255.0f green:213.0f/255.0f blue:80.0f/255.0f alpha:1.0f];
		
		[cell setPanGestureState:(PTATableViewCellStateLeftToRight | PTATableViewCellStateRightToLeft) mode:PTATableViewCellModeSwitch color:self.view.tintColor view:[self viewWithImageNamed:@"check"]];
		
		cell.leftToRightAttr.viewBehavior = PTATableViewCellSlidingViewBehaviorDragWithPanThenStick;
		cell.leftToRightAttr.color = greenColor;
		cell.rightToLeftAttr.rubberbandBounce = NO;
	} else {
		UIColor *redColor = [UIColor colorWithRed:232.0f/255.0f green:61.0f/255.0f blue:14.0f/255.0f alpha:1.0f];
		
		[cell setPanGestureState:PTATableViewCellStateLeftToRight mode:PTATableViewCellModeSwitch color:self.view.tintColor view:[self viewWithImageNamed:@"check"]];
		[cell setPanGestureState:PTATableViewCellStateRightToLeft mode:PTATableViewCellModeExit color:redColor view:[self viewWithImageNamed:@"cross"]];
		
		cell.rightToLeftAttr.triggerPercentage = 0.4f;
		cell.rightToLeftAttr.rubberbandBounce = NO;
		cell.rightToLeftAttr.viewBehavior = PTATableViewCellSlidingViewBehaviorDragWithPan;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	// Implement your own `tableView:didSelectRowAtIndexPath:` here.
}

#pragma mark - Pan Trigger Action (Required)

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

#pragma mark - Pan Trigger Action (Optional)

- (void)tableViewCellDidStartSwiping:(PTATableViewCell *)cell {
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	NSLog(@"row %li started swiping", (long)indexPath.row);
}

- (void)tableViewCellIsSwiping:(PTATableViewCell *)cell withPercentage:(CGFloat)percentage {
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	NSLog(@"row %li is being swiped with percentage: %0.1f", (long)indexPath.row, percentage * 100.0f);
}

- (void)tableViewCellDidEndSwiping:(PTATableViewCell *)cell {
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	NSLog(@"row %li ended swiping", (long)indexPath.row);
}

@end
