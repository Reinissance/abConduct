//
//  ViewController.m
//  abConduct
//
//  Created by Reinhard Sasse on 01.09.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController {
    NSURL *filepath;
//    NSArray *voiceArray;
    int page;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    filepath = [NSURL fileURLWithPath:[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Hallelujah"] stringByAppendingPathExtension:@"abc"]];

    [self openABCFile];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (IBAction)loadFile:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO]; // yes if more than one dir is allowed
    
    NSInteger clicked = [panel runModal];
    
    if (clicked == NSModalResponseOK) {
        filepath = [panel URL];
        [self openABCFile];
    }
}

- (void) openABCFile {
    if (![[filepath pathExtension] isEqualToString:@"abc"]) {
        return;
    }
    else {
        [self deleteFilesWithFormat:@"self ENDSWITH '.pdf'" andFormat:@"self ENDSWITH '.jpg'"];
        NSError *error;
        NSString *path = [filepath path];
        NSString *content = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:&error];
        if (!error) {
            [_abcView setString:content];
            [self createVoices];
        }
    }
}

-(void) createVoices {
    int index = (int) [_selectVoice indexOfSelectedItem];
    [_selectVoice removeAllItems];
    //remove old ps files
    [self deleteFilesWithFormat:@"self ENDSWITH '.ps'" andFormat:@"self ENDSWITH '.abc'"];
    //create new
    NSMutableArray *Voices = [self getVoicesWithHeader];
    NSArray *currentVoice = Voices[index];
    [self createPostScriptWithName:currentVoice[0] andData:currentVoice[1]];
    for (int i = 0; i < Voices.count; i++) {
        if (i != index) {
            NSArray *Voice = Voices[i];
            [self createPostScriptWithName:Voice[0] andData:Voice[1]];
        }
    }
    [_selectVoice selectItemAtIndex:index];
    [self displayVoice:nil];
}

- (void) deleteFilesWithFormat:(NSString*) format1 andFormat: (NSString*) format2 {
    NSFileManager  *manager = [NSFileManager defaultManager];
    NSString *resourceDirectory = [[NSBundle mainBundle] resourcePath];
    NSArray *allFiles = [manager contentsOfDirectoryAtPath:resourceDirectory error:nil];
    NSPredicate *fltr1 = [NSPredicate predicateWithFormat:format1];
    NSPredicate *fltr2 = [NSPredicate predicateWithFormat:format2];
    NSPredicate *fltr = [NSCompoundPredicate orPredicateWithSubpredicates:@[fltr1, fltr2]];
    NSArray *oldFiles = [allFiles filteredArrayUsingPredicate:fltr];
    for (NSString *psFile in oldFiles)
    {
        NSError *error = nil;
        [manager removeItemAtPath:[resourceDirectory stringByAppendingPathComponent:psFile] error:&error];
    }
    
}

- (IBAction)displayVoice:(id)sender {
    NSFileManager  *manager = [NSFileManager defaultManager];
    NSString *resourceDirectory = [[NSBundle mainBundle] resourcePath];
    if (![manager fileExistsAtPath:[[resourceDirectory stringByAppendingPathComponent:[_selectVoice titleOfSelectedItem]] stringByAppendingPathExtension:@"jpg"]]) {
        NSTask *toPdf =[[NSTask alloc] init];
        [toPdf setLaunchPath:@"/usr/local/bin/ps2pdf"];
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        [toPdf setCurrentDirectoryPath:resourcePath];
        NSString *name = [_selectVoice titleOfSelectedItem];
        [toPdf setArguments:[NSArray arrayWithObjects:[resourcePath stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"ps"]], nil]];
        toPdf.terminationHandler = ^(NSTask *task) {
            NSTask *toJpg =[[NSTask alloc] init];
            [toJpg setLaunchPath:[[NSBundle mainBundle]pathForResource:@"gs" ofType:nil]];
            [toJpg setCurrentDirectoryPath:resourcePath];
            [toJpg setArguments:[NSArray arrayWithObjects:@"-dNOPAUSE", @"-sDEVICE=jpeg", @"-r512", [NSString stringWithFormat:@"-sOutputFile=%@_%@.jpg", name, @"%02d"],     [resourcePath stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"ps"]], nil]];
            [toJpg launch];
            self->page = 1;
            [self performSelectorOnMainThread:@selector(loadDisplayfromFile:) withObject:[resourcePath stringByAppendingPathComponent:[[name stringByAppendingString:@"_01"] stringByAppendingPathExtension:@"jpg"]] waitUntilDone:NO];
        };
        [toPdf launch];
    }
}

- (void) loadDisplayfromFile: (NSString *) file {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSImage *image = [[NSImage alloc]initWithContentsOfFile:file];
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, self->_scrollView.frame.size.width, self->_scrollView.frame.size.height)];
        [imageView setImage:image];
        for (NSView *view in [self->_scrollView.documentView subviews]) {
            [view removeFromSuperview];
        }
        [self->_scrollView.documentView addSubview:imageView];
        self->_pageLabel.stringValue = [NSString stringWithFormat:@"page: %d", self->page];
    });
}

- (void) createPostScriptWithName: (NSString*) name andData: (NSString*) data {
    
    NSBundle *myBundle = [NSBundle mainBundle];
    NSError *error;
    NSString *tmpFile = [[myBundle resourcePath] stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"abc"]];
    [data writeToFile:tmpFile atomically:YES encoding:NSASCIIStringEncoding error:&error];
    if (error) {
        NSLog(@"could not write file: %@", error.localizedDescription);
    }
    else NSLog(@"wrote to tempFolder:%@", tmpFile);
    NSTask *abcViewer = [[NSTask alloc] init];
    NSString *absPath= [myBundle pathForResource:@"abcm2ps" ofType:nil];
    [abcViewer setLaunchPath:absPath];
    [abcViewer setCurrentDirectoryPath:[myBundle resourcePath]];
    [abcViewer setArguments:[NSArray arrayWithObjects:[NSString stringWithFormat:@"-O%@", [name stringByAppendingPathExtension:@"ps"]], tmpFile, nil]];
    [abcViewer launch];
}

- (IBAction)saveFile:(id)sender {
    NSError *error;
    [_abcView.string writeToFile:[filepath path] atomically:YES encoding:NSASCIIStringEncoding error:&error];
    if (error) {
        NSLog(@"could not write file: %@", error.localizedDescription);
    }
}

- (IBAction)changePage:(NSSegmentedControl *)sender {
    NSString *fileString;
    if (sender.selectedSegment == 0) {
        if (page == 1)
            return;
        else {
            page = page-1;
            fileString = [[[_selectVoice titleOfSelectedItem] stringByAppendingString:[NSString stringWithFormat: @"_%@", (page < 10) ? [NSString stringWithFormat:@"0%d", page] : [NSString stringWithFormat:@"%d", page]]] stringByAppendingPathExtension:@"jpg"];
        }
    }
    else {
        page = page+1;
        NSFileManager  *manager = [NSFileManager defaultManager];
        NSString *resourceDirectory = [[NSBundle mainBundle] resourcePath];
        NSArray *allFiles = [manager contentsOfDirectoryAtPath:resourceDirectory error:nil];
        NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.jpg'"];
        NSArray *pageFiles = [allFiles filteredArrayUsingPredicate:fltr];
        fileString = [[[_selectVoice titleOfSelectedItem] stringByAppendingString:[NSString stringWithFormat: @"_%@", (page < 10) ? [NSString stringWithFormat:@"0%d", page] : [NSString stringWithFormat:@"%d", page]]] stringByAppendingPathExtension:@"jpg"];
        if (![pageFiles containsObject:fileString]) {
            page = page-1;
            return;
        }
    }
    [self loadDisplayfromFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fileString]];
}

- (IBAction)refresh:(id)sender {
    [self createVoices];
}

- (IBAction)export:(id)sender {
    
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO]; // yes if more than one dir is allowed
    
    NSInteger clicked = [panel runModal];
    
    if (clicked == NSModalResponseOK) {
        NSString *folderpath = [[panel URL] path];;
        
        NSFileManager  *manager = [NSFileManager defaultManager];
        NSString *resourceDirectory = [[NSBundle mainBundle] resourcePath];
        for (NSString *voice in [_selectVoice itemTitles]) {
            if (![manager fileExistsAtPath:[[resourceDirectory stringByAppendingPathComponent:voice] stringByAppendingPathExtension:@"pdf"]]) {
                NSTask *toPdf =[[NSTask alloc] init];
                [toPdf setLaunchPath:@"/usr/local/bin/ps2pdf"];
                NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
                [toPdf setCurrentDirectoryPath:resourcePath];
                [toPdf setArguments:[NSArray arrayWithObjects:[resourcePath stringByAppendingPathComponent:[voice stringByAppendingPathExtension:@"ps"]], nil]];
                toPdf.terminationHandler = ^(NSTask *task) {
                    [self exportVoiceWithPath:[[resourceDirectory stringByAppendingPathComponent:voice] stringByAppendingPathExtension:@"pdf"] toPath:[[folderpath stringByAppendingPathComponent:voice] stringByAppendingPathExtension:@"pdf"]];
                };
                [toPdf launch];
            }
            else [self exportVoiceWithPath:[[resourceDirectory stringByAppendingPathComponent:voice] stringByAppendingPathExtension:@"pdf"] toPath:[[folderpath stringByAppendingPathComponent:voice] stringByAppendingPathExtension:@"pdf"]];
        }
    }
}

- (void) exportVoiceWithPath: (NSString *) path toPath: (NSString *) toPath {
    
    NSFileManager  *manager = [NSFileManager defaultManager];
    NSError *error;
    if ([manager fileExistsAtPath:toPath]) {
        [manager removeItemAtPath:toPath error:&error];
    }
    if (!error)
        [manager moveItemAtPath:path toPath:toPath error:&error];
    if (error) {
        NSLog(@"error copying files: %@", error.localizedDescription);
    }
}

- (NSMutableArray*) getVoicesWithHeader {
    NSArray* allLinedStrings = [_abcView.string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *header = [NSMutableArray array];
    BOOL headerRead = false;
    NSString *currentVoice;
    NSMutableArray *currentVoiceString = [NSMutableArray array];
    NSMutableArray *allVoices = [NSMutableArray array];
    NSMutableArray *userScoresAndStaves = [NSMutableArray array];
    for (NSString *line in allLinedStrings) {
        if (line.length > 2 && ![[line substringToIndex:2] isEqualToString:@"V:"] && !headerRead) {
                [header addObject: line];
            if ((line.length > 10) && ([[line substringToIndex:8] isEqualToString:@"%%staves"] || [[line substringToIndex:7] isEqualToString:@"%%score"]))
                [userScoresAndStaves addObject:line];
        }
        else {
            if (line.length > 2 && [[line substringToIndex:2] isEqualToString:@"V:"]){
                if (![line isEqualToString:currentVoice]) {
                    headerRead = true;
                    if (currentVoiceString.count > 0 && currentVoice != nil) {
                        NSArray *voice = [self voiceStringWithNameFromCleanedHeader:header withData:currentVoiceString];
                        [allVoices addObject:voice];
                    }
                    currentVoice = line;
                    [currentVoiceString removeAllObjects];
                }
            }
            [currentVoiceString addObject:line];
        }
    }
    NSArray *voice = [self voiceStringWithNameFromCleanedHeader:header withData:currentVoiceString];
    [allVoices addObject:voice];
    NSMutableArray *combinedVoicesWithName = [NSMutableArray array];
    for (int i = 0; i < userScoresAndStaves.count; i++) {
        NSString *string = userScoresAndStaves[i];
        NSArray *getStaveOrScoreName = [string componentsSeparatedByString:@"%"];
        NSString *staveOrScoreName = [getStaveOrScoreName lastObject];
        NSArray *stavesOrScoreOptions = [staveOrScoreName componentsSeparatedByString:@" "];
        if (stavesOrScoreOptions.count > 1) {
            staveOrScoreName = stavesOrScoreOptions[0];
        }
        NSString *combinedVoices;
        if (getStaveOrScoreName.count > 0) {
            for (int j = 0; j < allVoices.count; j++) {
                NSArray *array = allVoices[j];
                if (j == 0) {
                    NSString *headerToModify = array[1];
                    int incept = (int) [headerToModify rangeOfString:@"\n"].location;
                    combinedVoices = [[[headerToModify substringToIndex:incept] stringByAppendingString:[NSString stringWithFormat:@"\n%@", string]] stringByAppendingString:[headerToModify substringFromIndex:incept]];
                    if (stavesOrScoreOptions.count > 1) {
                        for (int k = 1; k < stavesOrScoreOptions.count; k++) {
                            NSString *option = stavesOrScoreOptions[k];
                            NSArray *optionSep = [option componentsSeparatedByString:@"="];
                            if (optionSep.count != 2) {
                                break;
                            }
                            else combinedVoices = [combinedVoices stringByAppendingString:[[@"\n%%" stringByAppendingString:optionSep[0]] stringByAppendingString:[NSString stringWithFormat:@" %@", optionSep[1]]]];
                        }
                    }
                }
                NSString *name = array[0];
                if ([string rangeOfString:name].location != NSNotFound) {
                    combinedVoices = [combinedVoices stringByAppendingString:[@"\n" stringByAppendingString: array[2]]];
                }
            }
        }
        [combinedVoicesWithName addObject:@[staveOrScoreName, combinedVoices]];
        [_selectVoice addItemWithTitle:staveOrScoreName];
    }
    return combinedVoicesWithName;
}

- (NSArray*) voiceStringWithNameFromCleanedHeader:(NSMutableArray*) header withData: (NSMutableArray*) currentVoiceString {
    
    NSString *cleanedHeader = header[0];
    NSArray *voiceInfo = [currentVoiceString[0] componentsSeparatedByString:@" "];
    NSString *name = [voiceInfo[0] substringFromIndex:2];
    for (int i = 1; i<header.count; i++) {
        NSString *line = header[i];
        if (line.length < 8) {
            cleanedHeader = [cleanedHeader stringByAppendingString:[NSString stringWithFormat:@"\n%@", line]];
        }
        else if (!([[line substringToIndex:8] isEqualToString:@"%%staves"]) && !([[line substringToIndex:7] isEqualToString:@"%%score"])) {
            cleanedHeader = [cleanedHeader stringByAppendingString:[NSString stringWithFormat:@"\n%@", line]];
        }
    }
    NSString *voice = currentVoiceString[0];
    for (int i = 1; i < currentVoiceString.count; i++) {
        NSString *voiceLine = currentVoiceString[i];
        voice = [voice stringByAppendingString:[NSString stringWithFormat:@"\n%@", voiceLine]];
    }
    return @[name, cleanedHeader, voice];
}
@end
