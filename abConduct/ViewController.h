//
//  ViewController.h
//  abConduct
//
//  Created by Reinhard Sasse on 01.09.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <Quartz/Quartz.h>

@interface ViewController : NSViewController <CALayerDelegate>

@property (weak) IBOutlet NSPopUpButton *selectVoice;
@property (unsafe_unretained) IBOutlet NSTextView *abcView;
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet NSTextField *pageLabel;

- (IBAction)loadFile:(id)sender;
- (IBAction)displayVoice:(id)sender;
- (IBAction)saveFile:(id)sender;
- (IBAction)changePage:(NSSegmentedControl *)sender;
- (IBAction)refresh:(id)sender;
- (IBAction)export:(id)sender;

@end

