//
//  ASiSTAppDelegate.m
//  ASiST
//
//  Created by Oliver Drobnik on 18.12.08.
//  Copyright drobnik.com. 2008. All rights reserved.
//

#import "ASiSTAppDelegate.h"
#import "RootViewController.h"
#import "AppViewController.h"
#import "ReportViewController.h"
#import "StatusInfoController.h"
#import	"PinLockController.h"

#import "Database.h"

// for the HTTP server
#import "HTTPServer.h"
#import "MyHTTPConnection.h"
#import "localhostAdresses.h"

#import "Report.h"
#import "YahooFinance.h"

#import "Query.h"

#import "ZipArchive.h"

#import "AccountManager.h"
#import "Account.h"
#import "Country.h"
#import "App.h"


//#import "TurboReviewScraper.h"
#import "SynchingManager.h"
#import "NSDate+Helpers.h"


@implementation ASiSTAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize tabBarController;
@synthesize appViewController, reportRootController, settingsViewController, statusViewController;
@synthesize /*itts, keychainWrapper,*/ serverIsRunning, convertSalesToMainCurrency;
@synthesize addresses, httpServer;
@synthesize appBadgeItem, reportBadgeItem, refreshButton;



- (void) scrapeReviews
{
	NSDate *today = [NSDate date];
	
	[[NSUserDefaults standardUserDefaults] setObject:today forKey:@"ReviewsLastDownloaded"];
	
	// get apps sorted
	NSArray *allApps = [[Database sharedInstance] appsSortedBySales];
	NSMutableDictionary *countries = [[Database sharedInstance] countries];
	NSArray *allKeys = [countries allKeys];

	for (App *oneApp in allApps)
	{
		for (NSString *oneKey in allKeys)
		{
			Country *oneCountry = [countries objectForKey:oneKey];
			if (oneCountry.appStoreID)
			{
				[[SynchingManager sharedInstance] scrapeForApp:oneApp country:oneCountry delegate:oneApp];
			}
		}
	}
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSURL *launchURL;
	BOOL forceSynch;
	
	if (launchOptions)
	{
		 launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
		//NSString *openingApp = [launchOptions objectForKey:UIApplicationLaunchOptionsSourceApplicationKey];
		
		NSString *host = [launchURL host];
		
		if ([host isEqualToString:@"reports"])
		{
			tabBarController.selectedIndex = 1;
			forceSynch = YES;
		}
	}
	

	// Configure and show the window
	[window addSubview:[tabBarController view]];
	[window addSubview:statusViewController.view];
	[window makeKeyAndVisible];
	
	
	BOOL locked = NO;
	NSString *pin =  [[NSUserDefaults standardUserDefaults] objectForKey:@"PIN"];
	if (pin)
	{	
		PinLockController *controller = [[PinLockController alloc] initWithMode:PinLockControllerModeUnlock];
		controller.delegate = self;
		controller.pin = pin;
	
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.navigationBar.barStyle = UIBarStyleBlack;
		[controller release];
	
		[tabBarController presentModalViewController:navController animated:NO];
		[navController release];
		locked = YES;
	}
	
	
	
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
	
	
	//NSString *user = [keychainWrapper objectForKey:(id)kSecAttrAccount];
	//NSString *pass = [keychainWrapper objectForKey:(id)kSecValueData];
	
	AccountManager *acc = [AccountManager sharedAccountManager];
	
	if ([acc.accounts count]>0)
	{
		//itts = [[iTunesConnect alloc] initWithAccount:[acc.accounts objectAtIndex:0]];
		
		// only auto-sync if we did not already download a daily report today
		Report *lastDailyReport = [[Database sharedInstance] latestReportOfType:ReportTypeDay];
		if (forceSynch || ![lastDailyReport.downloadedDate sameDateAs:[NSDate date]])
		{
			[[SynchingManager sharedInstance] downloadForAccount:[acc.accounts objectAtIndex:0] reportsToIgnore:nil];
		}
	}
	else 
	{
		//itts = [[iTunesConnect alloc] init];

		// don't show alert on lock
		
		if (!locked)
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Welcome to My App Sales" message:@"To start downloading your reports please enter your login information.\nSales/Trend reports are for directional purposes only, do not use for financial statement purpose. Money amounts may vary due to changes in exchange rates." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alert show];
			[alert release];
			[tabBarController setSelectedIndex:3];
		}
		return YES;
	}

	
	// load settings
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *mainCurrency = [defaults objectForKey:@"MainCurrency"];
	if (mainCurrency)
	{
		[[YahooFinance sharedInstance] setMainCurrency:mainCurrency];
	}
	
	convertSalesToMainCurrency = [defaults boolForKey:@"AlwaysUseMainCurrency"];
	
	
	// set default
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"ReviewFrequency"])
	{
		[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"ReviewFrequency"];
	}
	
	
	
	// Review Downloading
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DownloadReviews"])
	{
		NSDate *lastScraped = [[NSUserDefaults standardUserDefaults] objectForKey:@"ReviewsLastDownloaded"];
		NSInteger scrapeFrequency = [[NSUserDefaults standardUserDefaults] integerForKey:@"ReviewFrequency"]; 
		
		if (!lastScraped||!scrapeFrequency)
		{
			
			// scrape now
			[self scrapeReviews];
		}
		else
		{
			// check interval
			NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
			NSDateComponents *comps = [gregorian components:NSDayCalendarUnit fromDate:[lastScraped dateAtBeginningOfDay] toDate:[[NSDate date] dateAtBeginningOfDay] options:0];
			
			if ([comps day]>scrapeFrequency)
			{
				// scrape now
				[self scrapeReviews];
				
			}
		}
	}
	
	return YES;
}


- (void)dealloc {
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	//[keychainWrapper release];
	//[itts release];
	[navigationController release];
	[window release];
	[super dealloc];
}


- (void)applicationWillTerminate:(UIApplication *)application 
{
	// Save settings
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setObject:[[YahooFinance sharedInstance] mainCurrency] forKey:@"MainCurrency"];
	[defaults setObject:[NSNumber numberWithBool:convertSalesToMainCurrency] forKey:@"AlwaysUseMainCurrency"];
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
			//NSLog(@"Error starting HTTP Server: %@", error);
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
			//NSLog(@"Error starting HTTP Server: %@", error);
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
	//itts.username = [keychainWrapper objectForKey:(id)kSecAttrAccount];
	//itts.password = [keychainWrapper objectForKey:(id)kSecValueData];
	
	
	// currently we always set the first account to be used
	
	AccountManager *acc = [AccountManager sharedAccountManager];
	
	if ([acc.accounts count]>0)
	{
		//itts.account = [acc.accounts objectAtIndex:0];
		//[itts sync];
		[[SynchingManager sharedInstance] downloadForAccount:[acc.accounts objectAtIndex:0] reportsToIgnore:[[Database sharedInstance] allReports]];
	}
	
}


#pragma mark Notifications
- (void)newFileInDocuments:(NSNotification *) notification
{
	[DB importReportsFromDocumentsFolder];
}


- (void)newReportNotification:(NSNotification *) notification
{
	
	
	if(notification)
	{
		NSDictionary *tmpDict = [notification userInfo];
		
		int newReports = [[tmpDict objectForKey:@"NewReports"] intValue];
		
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
		
		int newReports = [[tmpDict objectForKey:@"NewReports"] intValue];
		
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
		
		int newApps = [[tmpDict objectForKey:@"NewApps"] intValue];
		
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



#pragma mark Internal Server
- (void)displayInfoUpdate:(NSNotification *) notification
{
	
	if(notification)
	{
		[addresses release];
		addresses = [[notification object] copy];
		//NSLog(@"addresses: %@", addresses);
	}
	if(addresses == nil)
	{
		return;
	}
	
	/*
	 // not used according to Analyze
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
	 */
}

#pragma mark Misc

- (void) emptyCache
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	// NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
	
	// get list of all files in document directory
	NSArray *docs = [fileManager directoryContentsAtPath:documentsDirectory];
	NSEnumerator *enu = [docs objectEnumerator];
	NSString *aString;
	
	NSError *error;
	
	while (aString = [enu nextObject])
	{
		NSString *pathOfFile = [documentsDirectory stringByAppendingPathComponent:aString];
		
		if ([aString isEqualToString:@"apps.db"]
			||[aString isEqualToString:@"Currencies.plist"]||[aString isEqualToString:@"simkeychain.plist"])
		{
			// excepted
		}
		else
		{
			NSLog(@"removed %@", pathOfFile);
			// all others removed
			[fileManager removeItemAtPath:pathOfFile error:&error];
		}
	}
	
	// notify all objects
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EmptyCache" object:nil userInfo:nil];
	
	
	// reload app icons
	[DB reloadAllAppIcons];
	
}


#pragma mark PinLock Delegate
- (void) didFinishUnlocking
{
	[tabBarController dismissModalViewControllerAnimated:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	NSString *pin =  [[NSUserDefaults standardUserDefaults] objectForKey:@"PIN"];
	if (pin)
	{	
		PinLockController *controller = [[PinLockController alloc] initWithMode:PinLockControllerModeUnlock];
		controller.delegate = self;
		controller.pin = pin;
		
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.navigationBar.barStyle = UIBarStyleBlack;
		[controller release];
		
		[tabBarController presentModalViewController:navController animated:NO];
		[navController release];
	}
}

@end
