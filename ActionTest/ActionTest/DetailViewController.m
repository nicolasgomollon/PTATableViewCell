//
//  DetailViewController.m
//  ActionTest
//
//  Created by Nicolas Gomollon on 7/22/14.
//  Copyright (c) 2014 Techno-Magic. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
- (void)configureView;
@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)loadView {
	[super loadView];
	
	self.title = @"Detail";
	self.view.backgroundColor = [UIColor whiteColor];
	self.detailDescriptionLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
	self.detailDescriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.detailDescriptionLabel.backgroundColor = [UIColor clearColor];
	self.detailDescriptionLabel.textColor = [UIColor blackColor];
	self.detailDescriptionLabel.textAlignment = NSTextAlignmentCenter;
	[self.view addSubview:self.detailDescriptionLabel];
}

- (void)setDetailItem:(id)newDetailItem {
	if (_detailItem != newDetailItem) {
		_detailItem = newDetailItem;
		
		// Update the view.
		[self configureView];
	}
}

- (void)configureView {
	// Update the user interface for the detail item.

	if (self.detailItem) {
		self.detailDescriptionLabel.text = [self.detailItem description];
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	[self configureView];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
