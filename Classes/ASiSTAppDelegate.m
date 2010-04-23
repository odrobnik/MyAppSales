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
#import "ReportRootController.h"
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
#import "GenericAccount.h"
#import "GenericAccount+MyAppSales.h"
#import "Country.h"
#import "App.h"


//#import "TurboReviewScraper.h"
#import "SynchingManager.h"
#import "NSDate+Helpers.h"
#import "NSURL+Helpers.h"
#import "NSString+Helpers.h"

#import "GenericAccount.h"

@implementation ASiSTAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize tabBarController;
@synthesize appViewController, reportRootController, settingsViewController, statusViewController;
@synthesize serverIsRunning, convertSalesToMainCurrency;
@synthesize addresses, httpServer;
@synthesize appBadgeItem, reportBadgeItem;



- (void) scrapeReviews
{
	NSDate *today = [NSDate date];
	
	[[NSUserDefaults standardUserDefaults] setObject:today forKey:@"ReviewsLastDownloaded"];
	
	// get apps unsorted
	NSArray *allApps = [[Database sharedInstance] allApps];
	NSMutableDictionary *countries = [[Database sharedInstance] countries];
	NSArray *allKeys = [countries allKeys];

	for (App *oneApp in allApps)
	{
		// to prevent problems with staged loading, we load the app's reviews now
		[oneApp reviewsInStages:NO];
		
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
	BOOL forceSynch = NO;
	
	
	if (launchOptions)
	{
		 launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
		//NSString *openingApp = [launchOptions objectForKey:UIApplicationLaunchOptionsSourceApplicationKey];
		
		NSString *host = [launchURL host];
		
		if ([host isEqualToString:@"reports"])
		{
			tabBarController.selectedIndex = 1;

			NSDictionary *options = [launchURL parameterDictionary];
			
			NSDate *tmpDate = [[options objectForKey:@"report_date"] dateFromString];
			ReportType reportType = [[options objectForKey:@"type"] intValue];
			Report *oneReport = [[Database sharedInstance] reportForDate:tmpDate type:reportType region:[[options objectForKey:@"region"] intValue] appGrouping:nil];

			if (oneReport)
			{
				// no synch necessary because report is already there
				[reportRootController gotoReport:oneReport];
			}
			else
			{
				// go to the appropriate section and start synch
				[reportRootController gotToReportType:reportType];
				forceSynch = YES;
			}

		}
	}
	

	// Configure and show the window
	[navigationController.toolbar setTintColor:[UIColor blackColor]];

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
	
	
	
	
	//NSString *user = [keychainWrapper objectForKey:(id)kSecAttrAccount];
	//NSString *pass = [keychainWrapper objectForKey:(id)kSecValueData];
	
	AccountManager *acc = [AccountManager sharedAccountManager];
	
	
	// refresh notification
	NSArray *notificationsAccounts = [acc accountsOfType:@"Notifications"];
	
	if ([notificationsAccounts count]>0)
	{
		[[SynchingManager sharedInstance] subscribeToNotificationsWithAccount:[notificationsAccounts lastObject]];
	}
	
	NSArray *itunesAccounts = [acc accountsOfType:@"iTunes Connect"];
	
	if ([itunesAccounts count]>0)
	{
		//itts = [[iTunesConnect alloc] initWithAccount:[acc.accounts objectAtIndex:0]];
		
		// only auto-sync if we did not already download a daily report today
		Report *lastDailyReport = [[Database sharedInstance] latestReportOfType:ReportTypeDay];
		if (forceSynch || ![lastDailyReport.downloadedDate sameDateAs:[NSDate date]])
		{
			for (GenericAccount *oneAccount in itunesAccounts)
			{
				[[SynchingManager sharedInstance] downloadForAccount:oneAccount reportsToIgnore:[[Database sharedInstance] allReportsWithAppGrouping:[oneAccount appGrouping]]];
			}
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
		NSError *error=nil;
		if(![httpServer start:&error])
		{
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
		NSError *error=nil;
		if(![httpServer start:&error])
		{
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




- (void) startSync
{
	AccountManager *acc = [AccountManager sharedAccountManager];
	
	NSArray *itunesAccounts = [acc accountsOfType:@"iTunes Connect"];
	
	if ([itunesAccounts count]>0)
	{
		for (GenericAccount *oneAccount in itunesAccounts)
		{
			[[SynchingManager sharedInstance] downloadForAccount:oneAccount reportsToIgnore:[[Database sharedInstance] allReportsWithAppGrouping:[oneAccount appGrouping]]];
		}
	}
	
}


#pragma mark Notifications
- (void)newFileInDocuments:(NSNotification *) notification
{
	if (notification)
	{
		NSDictionary *userInfo = [notification userInfo];
		NSString *fileName = [userInfo objectForKey:@"FileName"];
		
		if ([fileName isEqualToString:@"apps.db"])
		{
			[[SynchingManager sharedInstance] cancelAllSynching];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"File uploaded" message:@"You replaced the SQLite Database. To avoid inconsistency you need to restart MyAppSales NOW." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Quit MyAppSales", nil];
			alert.tag = 99;
			[alert show];
			[alert release];
		}
		else
		{
			[DB importReportsFromDocumentsFolder];
		}

			
	}
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
	
	NSError *error=nil;
	
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
			// all others removed
			[fileManager removeItemAtPath:pathOfFile error:&error];
		}
	}
	
	// notify all objects
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EmptyCache" object:nil userInfo:nil];
	
	
	// reload app icons
	[DB unloadReports];
	[DB reloadAllAppIcons];
}


#pragma mark PinLock Delegate
- (void) didFinishUnlocking
{
	[tabBarController dismissModalViewControllerAnimated:YES];
}

- (void)applicationWillResignActive:(UIApplication *)application
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

#pragma mark Alert callback 
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (alertView.tag == 99)
	{
		[self emptyCache];
		exit(0);
	}
}
@end
