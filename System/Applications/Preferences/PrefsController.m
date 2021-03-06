/*
	PrefsController.m

	Preferences window controller class

	Copyright (C) 2001 Dusk to Dawn Computing, Inc.

	Author: Jeff Teunissen <deek@d2dc.net>
	Date:	11 Nov 2001

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License as
	published by the Free Software Foundation; either version 2 of
	the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public
	License along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA
*/
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <Foundation/NSDebug.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSObjCRuntime.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSNibLoading.h>

#include <PrefsModule/PrefsModule.h>

#include "PrefsController.h"

@implementation PrefsController

static PrefsController	*sharedInstance = nil;
static NSMutableArray	*prefsViews = nil;
static id				currentModule = nil;

+ (PrefsController *) sharedPrefsController
{
	return (sharedInstance ? sharedInstance : [[self alloc] init]);
}

- (id) init
{
	if (sharedInstance) {
		[self dealloc];
	} else {
		self = [super init];
		prefsViews = [[[NSMutableArray alloc] initWithCapacity: 5] retain];
	}
	return sharedInstance = self;	
}

/*
	awakeFromNib

	Initialize stuff that can't be set in the nib/gorm file.
*/
- (void) awakeFromNib
{
	// Let the system keep track of where it belongs
	[window setFrameAutosaveName: @"PreferencesMainWindow"];
	[window setFrameUsingName: @"PreferencesMainWindow"];

	if (iconList)	// stop processing if we already have an icon list
		return;

	/* What is the matrix? :) */
	iconList = [[NSMatrix alloc] initWithFrame: NSMakeRect (0, 0, 64*30, 64)];
	[iconList setCellClass: [NSButtonCell class]];
	[iconList setCellSize: NSMakeSize (64, 64)];
	[iconList setMode: NSRadioModeMatrix];
	[iconList setIntercellSpacing: NSZeroSize];
	[iconList setAllowsEmptySelection: YES];

	[iconScrollView setDocumentView: iconList];
	[iconScrollView setHasHorizontalScroller: YES];
	[iconScrollView setHasVerticalScroller: NO];
	[iconScrollView setBorderType: NSBezelBorder];
}

/*
	Since we manage a single instance of the class, we override the -retain
	and -release methods to do nothing.
*/
- (id) retain
{
	return self;
}

- (oneway void) release
{
	return;
}

/*
	dealloc

	Do some special handling so that instances created with +alloc can be
	deleted, while still not allowing the shared instance to be deallocated.
*/
- (void) dealloc
{
	if (sharedInstance && self != sharedInstance) {
		[super dealloc];
	}
	return;
}

/*
	windowWillClose:

	TODO: Tell the loaded modules about this so that they can clean up after
	themselves
*/
#if 0
- (void) windowWillClose: (NSNotification *) aNotification
{
}
#endif

- (BOOL) registerPrefsModule: (id) aPrefsModule;
{
	NSButtonCell	*button = [[NSButtonCell alloc] init];

	if (!aPrefsModule
		|| ![aPrefsModule conformsToProtocol: @protocol(PrefsModule)])
		return NO;

	if (![prefsViews containsObject: aPrefsModule]) {
		[prefsViews addObject: aPrefsModule];
	}

	[button setTitle: [aPrefsModule buttonCaption]];
	[button setFont: [NSFont systemFontOfSize: 9]];
	[button setImage: [aPrefsModule buttonImage]];
	[button setImagePosition: NSImageOnly];
	[button setHighlightsBy: NSChangeBackgroundCellMask];
	[button setShowsStateBy: NSChangeBackgroundCellMask];
	[button setRefusesFirstResponder: YES];
	[button setTarget: aPrefsModule];
	[button setAction: [aPrefsModule buttonAction]];

	[iconList addColumnWithCells: [NSArray arrayWithObject: button]];
	[iconList sizeToCells];

	return YES;
}

- (BOOL) setCurrentModule: (id) aPrefsModule;
{
	if (!aPrefsModule || ![prefsViews containsObject: aPrefsModule]
		|| ![aPrefsModule view])
		return NO;

	currentModule = aPrefsModule;
	[[currentModule view] setBounds: [[prefsViewBox contentView] bounds]];
	[prefsViewBox setContentView: [currentModule view]];
	[window setTitle: [currentModule buttonCaption]];
	return YES;
}

- (NSWindow*) window;
{
	return window;
}

- (id) currentModule;
{
	return currentModule;
}

- (BOOL) respondsToSelector: (SEL) aSelector
{
	if (!aSelector)
		return NO;

	if ([super respondsToSelector: aSelector])
		return YES;

	if (currentModule)
		return [currentModule respondsToSelector: aSelector];

	return NO;
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL) aSelector
{
	NSMethodSignature	*sig = [super methodSignatureForSelector: aSelector];

	if (!sig && currentModule) {
		sig = [(NSObject *)currentModule methodSignatureForSelector: aSelector];
	}

	return sig;
}

- (void) forwardInvocation: (NSInvocation *)invocation
{
	[invocation invokeWithTarget: currentModule];
}

@end
