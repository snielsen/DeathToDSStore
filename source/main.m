#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>

#import "mach_inject_bundle.h"

static OSErr FindProcessBySignature( OSType type, OSType creator, ProcessSerialNumber* psn )
{
    ProcessSerialNumber tempPSN = { 0, kNoProcess };
    ProcessInfoRec procInfo;
    OSErr err = noErr;
    
	memset( &procInfo, 0, sizeof( ProcessInfoRec ));
    procInfo.processInfoLength = sizeof( ProcessInfoRec );
    procInfo.processName = nil;
    //procInfo.processAppSpec = nil;
    
    while( !err )
	{
        err = GetNextProcess( &tempPSN );
        if( !err ){ err = GetProcessInformation( &tempPSN, &procInfo ); }
        if( !err && procInfo.processType == type && procInfo.processSignature == creator )
		{
            *psn = tempPSN;
            return noErr;
        }
    }
    
    return err;
}

int main( int argc, char* argv[] )
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
		ProcessSerialNumber psn; FindProcessBySignature( 'FNDR', 'MACS', &psn );
		pid_t pid; GetProcessPID( &psn, &pid );
		
		NSString* bundlePath = [NSString stringWithCString:argv[1] encoding:NSASCIIStringEncoding];
		NSString* stubPath = [NSString stringWithCString:argv[2] encoding:NSASCIIStringEncoding];
		
		NSLog(@"bundlePath: %@", bundlePath);
		NSLog(@"stubPath: %@", stubPath);
		
		NSLog(@"pid %d", pid);
//		mach_error_t err = mach_inject_bundle_pid( [bundlePath fileSystemRepresentation], pid );
		mach_error_t err = mach_inject_bundle_pid( [bundlePath fileSystemRepresentation], (CFURLRef)[NSURL fileURLWithPath:stubPath], pid );
				
		NSLog(@"err %d", err);
		
	[pool release];

	return err;
}
