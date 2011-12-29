#import <Cocoa/Cocoa.h>

@interface DeathToDSStoreAppDelegate : NSObject <NSApplicationDelegate>
{
    NSWindow*								window;
	
	NSTextField*							needNMLabel;
	NSTextField*							needCPPFiltLabel;
	NSTextField*							cliInvokeLabel;
	NSButton*								patchButton;
	NSButton*								installButton;
}

@property (assign) IBOutlet NSWindow*		window;

@property (assign) IBOutlet NSTextField*	needNMLabel;
@property (assign) IBOutlet NSTextField*	needCPPFiltLabel;
@property (assign) IBOutlet NSTextField*	cliInvokeLabel;
@property (assign) IBOutlet NSButton*		patchButton;
@property (assign) IBOutlet NSButton*		installButton;

- (IBAction) hitPatchFinder:(id)sender;
- (IBAction) hitInstall:(NSButton*)sender;

@end
