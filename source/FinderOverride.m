#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>

#import <dlfcn.h>

#import "mach_override.h"

typedef	void (*FlushChangesProc)( void );
FlushChangesProc gFlushChanges;

void flushChanges( void );

NSString* runScript( NSString* path )
{
	NSTask* task = [[NSTask alloc] init]; [task setLaunchPath:@"/bin/sh"]; [task setArguments:[NSArray arrayWithObject:path]];
	NSPipe* pipe = [NSPipe pipe]; [task setStandardOutput:pipe];
	NSFileHandle* file = [pipe fileHandleForReading];
	[task launch];
	NSString* string = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
	[string autorelease];
	[task release];
	return string;
}

void load( void ) __attribute__ ((constructor));
void load( void )
{
	NSLog(@"FinderOverride: Executing load()\n");

	NSString* address = [[[[runScript([NSString stringWithFormat:@"%@/Contents/Resources/getAddress", [[NSBundle bundleWithIdentifier:@"com.aoren.FinderOverride"] bundlePath]]) componentsSeparatedByString:@"-"] objectAtIndex:0] componentsSeparatedByString:@" "] lastObject];
	NSString*  offset = [[runScript([NSString stringWithFormat:@"%@/Contents/Resources/getOffset", [[NSBundle bundleWithIdentifier:@"com.aoren.FinderOverride"] bundlePath]]) componentsSeparatedByString:@" "] objectAtIndex:0];

	NSLog(@"FinderOverride: HFSPlusPropertyStore::FlushChanges address %@ offset %@", address, offset);

	unsigned long long a = 0;
	unsigned long long o = 0;

	sscanf([address UTF8String], "%qx", &a);
	sscanf([offset UTF8String], "%qx", &o);

	if( a && o )
	{
//		void* thePtr = dlsym(RTLD_NEXT, "__ZN21THFSPlusPropertyStore12FlushChangesEv");
//		if( !thePtr ){ thePtr = dlsym(RTLD_DEFAULT, "__ZN21THFSPlusPropertyStore12FlushChangesEv"); }
//		fprintf(stderr, "Got here 2! %X\n", thePtr);
				
		if( mach_override_ptr((void*)(a + o), flushChanges, (void**) &gFlushChanges ) == 0)
		{
			NSLog(@"FinderOverride: Override succeeded! No more .DS_Store generation until relaunch.");
			return;
		}
	}

	NSLog(@"FinderOverride: Override failed!");
}

void flushChanges( void )
{
//	NSLog(@"HFSPlusPropertyStore::FlushChanges attempted."); fflush(0);
//	AudioServicesPlayAlertSound(kSystemSoundID_UserPreferredAlert);
}