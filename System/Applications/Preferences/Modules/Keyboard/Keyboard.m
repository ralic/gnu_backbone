/*
	Keyboard.m

	Controller class for this bundle

	Copyright (C) 2001 Dusk to Dawn Computing, Inc.
	Additional copyrights here

	Author: Jeff Teunissen <deek@d2dc.net>
	Date:	24 Nov 2001

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
static const char rcsid[] = 
	"$Id$";

#ifdef HAVE_CONFIG_H
# include "Config.h"
#endif

#import <AppKit/NSButton.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSOpenPanel.h>

#import "Keyboard.h"
#import "KeyboardView.h"

@interface Keyboard (Private)

- (void) updateUI;
- (void) preferencesFromDefaults;

@end

@implementation Keyboard (Private)

static id <PrefsController>	controller;
static NSUserDefaults		*defaults = nil;
static NSMutableDictionary	*domain = nil;

#define setStringDefault(string,name) \
	[domain setObject: (string) forKey: (name)]; \
	[defaults setPersistentDomain: domain forName: NSGlobalDomain]; \
	[defaults synchronize];

static NSMutableDictionary *
defaultValues (void) {
    static NSMutableDictionary *dict = nil;

    if (!dict) {
        dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
				@"Alt_L", @"GSFirstCommandKey",
				@"No Symbol", @"GSSecondCommandKey",
				@"Control_L", @"GSFirstControlKey",
				@"Control_R", @"GSSecondControlKey",
				@"Alt_R", @"GSFirstAlternateKey",
				@"No Symbol", @"GSSecondAlternateKey",
				nil];
    }
    return dict;
}

static NSArray *
commonMenu (void) {
    static NSArray *arr = nil;

    if (!arr) {
        arr = [[NSArray alloc] initWithObjects:
				@"Left Alt",
				@"Right Alt",
				@"Left Meta/Windows",
				@"Right Meta/Windows",
				@"Left Control",
				@"Right Control",
				@"Mode Switch",
				@"None",
				nil];
    }
    return arr;
}

static NSDictionary *
menuItemNames (void) {
    static NSDictionary *dict = nil;

    if (!dict) {
        dict = [[NSDictionary alloc] initWithObjectsAndKeys:
				@"Alt_L", @"Left Alt",
				@"Alt_R", @"Right Alt",
				@"Control_L", @"Left Control",
				@"Control_R", @"Right Control",
				@"Meta_L", @"Left Meta/Windows",
				@"Meta_R", @"Right Meta/Windows",
				@"Mode_switch", @"Mode Switch",
				@"No Symbol", @"None",
				nil];
    }
    return dict;
}

#if 0
static BOOL
getBoolDefault (NSMutableDictionary *dict, NSString *name)
{
	NSString	*str = [[NSUserDefaults standardUserDefaults] stringForKey: name];
	NSNumber	*num;

	if (!str)
		str = [[defaultValues() objectForKey: name] stringValue];

	num = [NSNumber numberWithBool: [str hasPrefix: @"Y"]];
	[dict setObject: num forKey: name];

	return [num boolValue];
}
#endif

static NSString *
getStringDefault (NSMutableDictionary *dict, NSString *name)
{
	NSString	*str = [domain objectForKey: name];

	if (!str)
		str = [defaultValues() objectForKey: name];

	[dict setObject: str forKey: name];
	
	return str;
}

- (void) preferencesFromDefaults
{
	getStringDefault (domain, @"GSFirstAlternateKey");
	getStringDefault (domain, @"GSFirstCommandKey");
	getStringDefault (domain, @"GSFirstControlKey");
	getStringDefault (domain, @"GSSecondAlternateKey");
	getStringDefault (domain, @"GSSecondCommandKey");
	getStringDefault (domain, @"GSSecondControlKey");
	return;
}

- (void) updateUI
{
	[firstAlternatePopUp selectItemWithTitle: [[menuItemNames() allKeysForObject: [domain objectForKey: @"GSFirstAlternateKey"]] objectAtIndex: 0]];
	[firstCommandPopUp selectItemWithTitle: [[menuItemNames() allKeysForObject: [domain objectForKey: @"GSFirstCommandKey"]] objectAtIndex: 0]];
	[firstControlPopUp selectItemWithTitle: [[menuItemNames() allKeysForObject: [domain objectForKey: @"GSFirstControlKey"]] objectAtIndex: 0]];
	[secondAlternatePopUp selectItemWithTitle: [[menuItemNames() allKeysForObject: [domain objectForKey: @"GSSecondAlternateKey"]] objectAtIndex: 0]];
	[secondCommandPopUp selectItemWithTitle: [[menuItemNames() allKeysForObject: [domain objectForKey: @"GSSecondCommandKey"]] objectAtIndex: 0]];
	[secondControlPopUp selectItemWithTitle: [[menuItemNames() allKeysForObject: [domain objectForKey: @"GSSecondControlKey"]] objectAtIndex: 0]];
	[view setNeedsDisplay: YES];
}

@end	// Keyboard (Private)

@implementation Keyboard

static Keyboard			*sharedInstance = nil;
static id <PrefsApplication>	owner = nil;

- (id) initWithOwner: (id <PrefsApplication>) anOwner
{
	NSMutableArray	*popups = [NSMutableArray arrayWithCapacity: 6];

	if (sharedInstance) {
		[self dealloc];
	} else {
		self = [super init];
		owner = anOwner;
		controller = [owner prefsController];
		defaults = [NSUserDefaults standardUserDefaults];
		domain = [[defaults persistentDomainForName: NSGlobalDomain] mutableCopy];
		[self preferencesFromDefaults];

		[controller registerPrefsModule: self];
		if (![NSBundle loadNibNamed: @"Keyboard" owner: self]) {
			NSLog (@"Keyboard: Could not load nib \"Keyboard\", using compiled-in version");
			view = [[KeyboardView alloc] initWithOwner: self andFrame: PrefsRect];

			// hook up to our outlet(s)
			firstAlternatePopUp = [view firstAlternatePopUp];
			firstCommandPopUp = [view firstCommandPopUp];
			firstControlPopUp = [view firstControlPopUp];
			secondAlternatePopUp = [view secondAlternatePopUp];
			secondCommandPopUp = [view secondCommandPopUp];
			secondControlPopUp = [view secondControlPopUp];
		} else {
			// window can be any size, as long as it's 486x228 :)
			view = [window contentView];
			[view removeFromSuperview];
			[window setContentView: NULL];
			[window dealloc];
			window = nil;
		}
		[view retain];

		[popups addObject: firstAlternatePopUp];
		[popups addObject: firstCommandPopUp];
		[popups addObject: firstControlPopUp];
		[popups addObject: secondAlternatePopUp];
		[popups addObject: secondCommandPopUp];
		[popups addObject: secondControlPopUp];
		{
			id	myEnum = [popups objectEnumerator];
			id	obj;
		
			while ((obj = [myEnum nextObject])) {
				[obj removeAllItems];
				[obj addItemsWithTitles: commonMenu()];
			}
		}
//		[popups autorelease];
		[self updateUI];

		sharedInstance = self;
	}
	return sharedInstance;
}

- (void) showView: (id) sender;
{
	[controller setCurrentModule: self];
	[view setNeedsDisplay: YES];
}

- (NSView *) view
{
	return view;
}

- (NSString *) buttonCaption
{
	return @"Modifier Key Preferences";
}

- (NSImage *) buttonImage
{
	return [NSImage imageNamed: @"PrefsIcon_Keyboard"];
}

- (SEL) buttonAction
{
	return @selector(showView:);
}

/*
	Action methods
*/
- (IBAction) firstAlternateChanged: (id) sender
{
	setStringDefault ([menuItemNames() objectForKey: [firstAlternatePopUp titleOfSelectedItem]], @"GSFirstAlternateKey");
}

- (IBAction) firstCommandChanged: (id) sender
{
	setStringDefault ([menuItemNames() objectForKey: [firstCommandPopUp titleOfSelectedItem]], @"GSFirstCommandKey");
}

- (IBAction) firstControlChanged: (id) sender
{
	setStringDefault ([menuItemNames() objectForKey: [firstControlPopUp titleOfSelectedItem]], @"GSFirstControlKey");
}

- (IBAction) secondAlternateChanged: (id) sender
{
	setStringDefault ([menuItemNames() objectForKey: [secondAlternatePopUp titleOfSelectedItem]], @"GSSecondAlternateKey");
}

- (IBAction) secondCommandChanged: (id) sender
{
	setStringDefault ([menuItemNames() objectForKey: [secondCommandPopUp titleOfSelectedItem]], @"GSSecondCommandKey");
}

- (IBAction) secondControlChanged: (id) sender
{
	setStringDefault ([menuItemNames() objectForKey: [secondControlPopUp titleOfSelectedItem]], @"GSSecondControlKey");
}

@end	// Keyboard
