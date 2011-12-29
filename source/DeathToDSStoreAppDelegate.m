#import "DeathToDSStoreAppDelegate.h"

@implementation DeathToDSStoreAppDelegate

@synthesize window, needNMLabel, needCPPFiltLabel, cliInvokeLabel, patchButton, installButton;

- (IBAction) hitPatchFinder:(id)sender
{
	AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
	AuthorizationRef myAuthorizationRef;
 
	OSStatus myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
	if( myStatus != errAuthorizationSuccess ){ return; }
 
	AuthorizationItem myItems = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights myRights = {1, &myItems};

	myFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
	myStatus = AuthorizationCopyRights( myAuthorizationRef, &myRights, NULL, myFlags, NULL );

	int s = 0;
	if( myStatus == errAuthorizationSuccess)
	{
		char* myArguments[] = { "", "", NULL };
		myArguments[0] = (char*)[[[NSBundle mainBundle] pathForResource:@"FinderOverride" ofType:@"bundle"] UTF8String];
		myArguments[1] = (char*)[[[NSBundle mainBundle] pathForResource:@"mach_inject_bundle_stub" ofType:@"bundle"] UTF8String];
		
		myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, [[[NSBundle mainBundle] pathForResource:@"injector" ofType:@""] UTF8String], kAuthorizationFlagDefaults, myArguments, NULL);
		wait(&s);
		
		NSRunAlertPanel( @"Injection/Overidde", @"Attempted injection and override. If things worked correctly (check the console) then the Finder will not write any more .DS_Store files until it is relaunched.", @"Quit", nil, nil );
		[NSApp terminate:self];
	}
	else
	{
		NSRunAlertPanel( @"Authorization Failed", @"You need admin authorization to patch the Finder.", @"Ok", nil, nil );
	}
	
	AuthorizationFree( myAuthorizationRef, kAuthorizationFlagDefaults );
}

- (IBAction) hitInstall:(NSButton*)sender
{
	AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
	AuthorizationRef myAuthorizationRef;
 
	OSStatus myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
	if( myStatus != errAuthorizationSuccess ){ return; }
 
	AuthorizationItem myItems = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights myRights = {1, &myItems};

	myFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
	myStatus = AuthorizationCopyRights( myAuthorizationRef, &myRights, NULL, myFlags, NULL );

	int s = 0;
	if( myStatus == errAuthorizationSuccess)
	{
		if( [sender state] == 1 )
		{
			char* myArguments[] = { "", NULL };
			myArguments[0] = (char*)[[[NSBundle mainBundle] bundlePath] UTF8String];
			
			myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, [[[NSBundle mainBundle] pathForResource:@"installLaunchAgent" ofType:@""] UTF8String], kAuthorizationFlagDefaults, myArguments, NULL);
			wait(&s);
			sleep(2); // Looks like there is a bit of a race somewhere for the file system to catch up
			
			if( [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/LaunchAgents/com.aoren.DeathToDSStore.plist"] &&
				[[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Application Support/Aoren/DeathToDSStore.app"] )
			{
				[installButton setState:1]; NSRunAlertPanel( @"Install Successful", @"Installation appears to have succeeded. The Finder should get auto-patched every time a user logs in now.", @"Ok", nil, nil );			
			}
			else
			{
				[installButton setState:0]; NSRunAlertPanel( @"Install Failed", @"Installation appears to have failed.", @"Ok", nil, nil );
			}
		}
		else
		{
			char* myArguments[] = { NULL };
			
			myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, [[[NSBundle mainBundle] pathForResource:@"removeLaunchAgent" ofType:@""] UTF8String], kAuthorizationFlagDefaults, myArguments, NULL);
			wait(&s);
			sleep(2); // Looks like there is a bit of a race somewhere for the file system to catch up
			
			if( ![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/LaunchAgents/com.aoren.DeathToDSStore.plist"] )
			{
				[installButton setState:0]; NSRunAlertPanel( @"Removal Successful", @"Successfully removed the DeathToDSStore Launch Agent.", @"Ok", nil, nil );			
			}
			else
			{
				[installButton setState:1]; NSRunAlertPanel( @"Removal Failed", @"Failed to remove the DeathToDSStore Launch Agent.", @"Ok", nil, nil );
			}			
		}
	}
	else
	{
		NSRunAlertPanel( @"Authorization Failed", @"You need admin authorization to install the Launch Agent.", @"Ok", nil, nil );
	}
	
	AuthorizationFree( myAuthorizationRef, kAuthorizationFlagDefaults );
}

- (void) applicationDidFinishLaunching:(NSNotification*)aNotification
{
	BOOL goodToGo = YES;
	
	if( [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/nm"]      ){      [needNMLabel setHidden:YES]; }else{      [needNMLabel setHidden:NO]; goodToGo = NO; }
	if( [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/c++filt"] ){ [needCPPFiltLabel setHidden:YES]; }else{ [needCPPFiltLabel setHidden:NO]; goodToGo = NO; }
	
	if( goodToGo )
	{
		[cliInvokeLabel setHidden:NO];
		[patchButton setEnabled:YES];
		
		if( !([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/LaunchAgents/com.aoren.DeathToDSStore.plist"] &&
	          [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Application Support/Aoren/DeathToDSStore.app"]) )
		{
			[installButton setState:0];
		}
		else
		{
			[installButton setState:1];
		}
		
		[installButton setEnabled:YES];
	}
	else
	{
		[cliInvokeLabel setHidden:YES];
		[patchButton setEnabled:NO];
		
		[installButton setEnabled:NO];
	}	
}

@end
