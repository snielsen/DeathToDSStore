#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>

#import <dlfcn.h>
#import <mach-o/dyld.h>

#import "mach_override.h"

__uint64_t getAddressOfLibrary( char* libraryPath )
{
	const struct mach_header* mh;

	int n = _dyld_image_count();
	
	int i = 0;
	for( i = 0; i < n; i++ )
	{
	    mh = _dyld_get_image_header(i);
	    if( mh->filetype != MH_DYLIB ){ continue; }

		const char* imageName = _dyld_get_image_name(i);
		if( strcmp(imageName, libraryPath) == 0 )
		{
			struct segment_command_64* seg;
			struct load_command* cmd;
			cmd = (struct load_command*)((char*)mh + sizeof(struct mach_header_64));

			int j = 0;
			for( j = 0; j < mh->ncmds; j++ )
			{
				if( cmd->cmd == LC_SEGMENT_64 )
				{
					seg = (struct segment_command_64*)cmd;
					if( strcmp(seg->segname, SEG_TEXT) == 0 )
					{
						return seg->vmaddr + (__uint64_t)_dyld_get_image_vmaddr_slide(i);
					}
				}

				cmd = (struct load_command*)((char*)cmd + cmd->cmdsize);
			}
		
			return _dyld_get_image_vmaddr_slide(i);
		}
	}
	
	return 0;
}

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

	NSString*  offset = [[runScript([NSString stringWithFormat:@"%@/Contents/Resources/getOffset", [[NSBundle bundleWithIdentifier:@"com.aoren.FinderOverride"] bundlePath]]) componentsSeparatedByString:@" "] objectAtIndex:0];

	unsigned long long a = getAddressOfLibrary("/System/Library/PrivateFrameworks/DesktopServicesPriv.framework/Versions/A/DesktopServicesPriv");
	unsigned long long o = 0; sscanf([offset UTF8String], "%qx", &o);

	NSLog(@"FinderOverride: HFSPlusPropertyStore::FlushChanges address %qx offset %qx", a, o);

	if( a && o )
	{
//		void* thePtr = dlsym(RTLD_NEXT, "__ZN21THFSPlusPropertyStore12FlushChangesEv");
//		if( !thePtr ){ thePtr = dlsym(RTLD_DEFAULT, "__ZN21THFSPlusPropertyStore12FlushChangesEv"); }
				
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