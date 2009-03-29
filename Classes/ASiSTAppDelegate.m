//
//  ASiSTAppDelegate.m
//  ASiST
//
//  Created by Oliver Drobnik on 18.12.08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "ASiSTAppDelegate.h"
#import "RootViewController.h"
#import "AppViewController.h"
#import "ReportViewController.h"
#import "StatusInfoController.h"

//#import "NSDataCompression.h"
#import "BirneConnect.h"

// for the HTTP server
#import "HTTPServer.h"
#import "MyHTTPConnection.h"
#import "localhostAdresses.h"

#import "Report.h"
#import "YahooFinance.h"
#import "BirneConnect.h"
#import "KeychainWrapper.h"

#import "Query.h"

#import "ZipArchive.h"


@implementation ASiSTAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize tabBarController;
@synthesize appViewController, reportRootController, settingsViewController, statusViewController;
@synthesize itts, keychainWrapper, serverIsRunning, convertSalesToMainCurrency;
@synthesize addresses, httpServer;
@synthesize appBadgeItem, reportBadgeItem;


- (void)applicationDidFinishLaunching:(UIApplication *)application 
{
	// The database is stored in the application bundle. 
	// The settings is stored in the application bundle. 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
	
	KeychainWrapper *wrapper= [[KeychainWrapper alloc] init];
    self.keychainWrapper = wrapper;
    [wrapper release];

	// Configure and show the window
	[window addSubview:[tabBarController view]];
	[window addSubview:statusViewController.view];

	
	[window makeKeyAndVisible];
	
	[statusViewController showStatus:NO];
	
	// configure the http server
	NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
	
	httpServer = [HTTPServer new];
	[httpServer setType:@"_http._tcp."];
	[httpServer setConnectionClass:[MyHTTPConnection class]];
	[httpServer setDocumentRoot:[NSURL fileURLWithPath:root]];

	/*
#if TARGET_IPHONE_SIMULATOR
	[httpServer setPort:8080];
#else
	[httpServer setPort:80];
#endif
*/	

	[httpServer setPort:8080];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayInfoUpdate:) name:@"LocalhostAdressesResolved" object:nil];
	[localhostAdresses performSelectorInBackground:@selector(list) withObject:nil];
	
	/*
	NSError *error;
	if(![httpServer start:&error])
	{
		NSLog(@"Error starting HTTP Server: %@", error);
	} */
	
	serverIsRunning = NO;
	convertSalesToMainCurrency = YES;
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newFileInDocuments:) name:@"NewFileUploaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newAppNotification:) name:@"NewAppAdded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newReportNotification:) name:@"NewReportAdded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newReportRead:) name:@"NewReportRead" object:nil];

	
	NSString *user = [keychainWrapper objectForKey:(id)kSecAttrAccount];
	NSString *pass = [keychainWrapper objectForKey:(id)kSecValueData];
	
	itts = [[BirneConnect alloc] initWithLogin:user password:pass];
//	NSArray *currencies = [itts salesCurrencies];
//	myYahoo = [[YahooFinance alloc] initWithCurrencyList:currencies];
	
	// load settings
	
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"settings.plist"];
	
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
	
	if (settings)
	{
		NSString *mainCurrency = [settings objectForKey:@"MainCurrency"];
		if (mainCurrency)
		{
			itts.myYahoo.mainCurrency = mainCurrency;
		}
		
		NSNumber *alwaysMainCurrency = [settings objectForKey:@"AlwaysUseMainCurrency"];
		if (alwaysMainCurrency)
		{
			convertSalesToMainCurrency = [alwaysMainCurrency boolValue];
		}
	}
}


- (void)dealloc {
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[keychainWrapper release];
	[itts release];
	[navigationController release];
	[window release];
	[super dealloc];
}

- (void)newFileInDocuments:(NSNotification *) notification
{
	NSLog(@"New File");
	[self.itts importReportsFromDocumentsFolder];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
	//[itts.myYahoo save];
	
	NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
	
	[settings setObject:itts.myYahoo.mainCurrency forKey:@"MainCurrency"];
	[settings setObject:[NSNumber numberWithBool:convertSalesToMainCurrency] forKey:@"AlwaysUseMainCurrency"];
	
	// The settings is stored in the application bundle. 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"settings.plist"];
	
	[settings writeToFile:path atomically:YES];
}






- (void) toggleNetworkIndicator:(BOOL)isON
{
	UIApplication *application = [UIApplication sharedApplication];
	application.networkActivityIndicatorVisible = isON;
}

// HTTP Server
- (IBAction)startStopServer:(id)sender
{
	if ([sender isOn])
	{
		NSError *error;
		if(![httpServer start:&error])
		{
			NSLog(@"Error starting HTTP Server: %@", error);
			serverIsRunning = NO;
		}
		else
		{
			//[self displayInfoUpdate:nil];
			serverIsRunning = YES;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerStatusChanged" object:nil userInfo:(id)[NSNumber numberWithBool:YES]];

		}
	}
	else
	{
		[httpServer stop];
		serverIsRunning = NO;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerStatusChanged" object:nil userInfo:(id)[NSNumber numberWithBool:NO]];

	}
}

- (void) toggleServer:(BOOL)status
{
	if (serverIsRunning == status)
	{
		return;
	}
	
	if (status)
	{
		NSError *error;
		if(![httpServer start:&error])
		{
			NSLog(@"Error starting HTTP Server: %@", error);
			serverIsRunning = NO;
		}
		else
		{
			//[self displayInfoUpdate:nil];
			serverIsRunning = YES;
		}
	}
	else
	{
		[httpServer stop];
		serverIsRunning = NO;
	}
}




- (void) refreshButton:(id)sender
{
	itts.username = [keychainWrapper objectForKey:(id)kSecAttrAccount];
	itts.password = [keychainWrapper objectForKey:(id)kSecValueData];
	
	[itts sync];
}

- (void)newReportNotification:(NSNotification *) notification
{
	
	
	if(notification)
	{
		NSDictionary *tmpDict = [notification userInfo];

		newReports = [[tmpDict objectForKey:@"NewReports"] intValue];
			
		if (newReports)
		{
			[reportBadgeItem setBadgeValue:[NSString stringWithFormat:@"%d", newReports]];
		}
		else
		{
			[reportBadgeItem setBadgeValue:nil];
		}
		
	} 

	[appViewController.tableView reloadData];  // royalites could have changed
	
	// also remove cached chart data
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
	
	int i;
	for (i=0;i<2; i++)
	{
		NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"cache_data_%d.plist",i]];
	
		NSFileManager *fileManager = [NSFileManager defaultManager];
		[fileManager removeItemAtPath:path error:NULL];
	}
}

- (void)newReportRead:(NSNotification *) notification
{
	if(notification)
	{
		NSDictionary *tmpDict = [notification userInfo];
		
		newReports = [[tmpDict objectForKey:@"NewReports"] intValue];
		
		if (newReports)
		{
			[reportBadgeItem setBadgeValue:[NSString stringWithFormat:@"%d", newReports]];
		}
		else
		{
			[reportBadgeItem setBadgeValue:nil];
		}
		
	} 
	
	[appViewController.tableView reloadData];  // royalites could have changed
}




- (void)newAppNotification:(NSNotification *) notification
{
	
	
	if(notification)
	{
		NSDictionary *tmpDict = [notification userInfo];
		
		newApps = [[tmpDict objectForKey:@"NewApps"] intValue];
		
		if (newApps)
		{
			[appBadgeItem setBadgeValue:[NSString stringWithFormat:@"%d", newApps]];
		}
		else
		{
			[appBadgeItem setBadgeValue:nil];
		}
	} 
}

- (void)displayInfoUpdate:(NSNotification *) notification
{
	
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
	
	NSLog(info);
}

@end
