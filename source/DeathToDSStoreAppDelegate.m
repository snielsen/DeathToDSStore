#import "DeathToDSStoreAppDelegate.h"

@implementation DeathToDSStoreAppDelegate

@synthesize window, needNMLabel, needCPPFiltLabel, cliInvokeLabel, patchButton;

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
		
		NSString* injectorPath = [[NSBundle mainBundle] pathForResource:@"injector" ofType:@""];
		myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, [injectorPath UTF8String], kAuthorizationFlagDefaults, myArguments, NULL);
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

- (void) applicationDidFinishLaunching:(NSNotification*)aNotification
{
	BOOL goodToGo = YES;
	
	if( [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/nm"]      ){      [needNMLabel setHidden:YES]; }else{      [needNMLabel setHidden:NO]; goodToGo = NO; }
	if( [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/c++filt"] ){ [needCPPFiltLabel setHidden:YES]; }else{ [needCPPFiltLabel setHidden:NO]; goodToGo = NO; }
	
	if( goodToGo ){ [cliInvokeLabel setHidden:NO]; [patchButton setEnabled:YES]; }else{ [cliInvokeLabel setHidden:YES]; [patchButton setEnabled:NO]; }

//	[NSApp terminate:self];
}

@end
