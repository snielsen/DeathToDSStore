#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	if( (argc == 2) && (strncmp(argv[1], "-silent", strlen("-silent")) == 0) )
	{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			system([[NSString stringWithFormat:@"%@ %@ %@", [[NSBundle mainBundle] pathForResource:@"injector" ofType:@""], [[NSBundle mainBundle] pathForResource:@"FinderOverride" ofType:@"bundle"], [[NSBundle mainBundle] pathForResource:@"mach_inject_bundle_stub" ofType:@"bundle"]] UTF8String]);
		[pool release];
		
		return 0;
	}

    return NSApplicationMain(argc,  (const char **) argv);
}
