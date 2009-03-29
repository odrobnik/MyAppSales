//
//  This class was created by Nonnus,
//  who graciously decided to share it with the CocoaHTTPServer community.
//

#import "iPhoneHTTPServerAppDelegate.h"
#import "HTTPServer.h"
#import "MyHTTPConnection.h"
#import "localhostAdresses.h"


@implementation iPhoneHTTPServerAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application 
{
	[window makeKeyAndVisible];
	
	NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
	
	httpServer = [HTTPServer new];
	[httpServer setType:@"_http._tcp."];
	[httpServer setConnectionClass:[MyHTTPConnection class]];
	[httpServer setDocumentRoot:[NSURL fileURLWithPath:root]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayInfoUpdate:) name:@"LocalhostAdressesResolved" object:nil];
	[localhostAdresses performSelectorInBackground:@selector(list) withObject:nil];
}

- (void)displayInfoUpdate:(NSNotification *) notification
{
	NSLog(@"displayInfoUpdate:");

	if(notification)
	{
		[addresses release];
		addresses = [[notification object] copy];
		NSLog(@"addresses: %@", addresses);
	}
	if(addresses == nil)
	{
		return;
	}
	
	NSString *info;
	UInt16 port = [httpServer port];
	
	NSString *localIP = [addresses objectForKey:@"en0"];
	if (!localIP)
		info = @"Wifi: No Connection !\n";
	else
		info = [NSString stringWithFormat:@"http://iphone.local:%d		http://%@:%d\n", port, localIP, port];
	NSString *wwwIP = [addresses objectForKey:@"www"];
	if (wwwIP)
		info = [info stringByAppendingFormat:@"Web: %@:%d\n", wwwIP, port];
	else
		info = [info stringByAppendingString:@"Web: No Connection\n"];
	
	displayInfo.text = info;
}

- (IBAction)startStopServer:(id)sender
{
	if ([sender isOn])
	{
		NSError *error;
		if(![httpServer start:&error])
		{
			NSLog(@"Error starting HTTP Server: %@", error);
		}
		[self displayInfoUpdate:nil];
	}
	else
	{
		[httpServer stop];
	}
}

- (void)dealloc 
{
	[httpServer release];
    [window release];
    [super dealloc];
}


@end
