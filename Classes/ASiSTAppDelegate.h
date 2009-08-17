//
//  ASiSTAppDelegate.h
//  ASiST
//
//  Created by Oliver Drobnik on 18.12.08.
//  Copyright drobnik.com 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
// This includes the header for the SQLite library.
#import <sqlite3.h>

@class   HTTPServer, YahooFinance;

@class BirneConnect, AppViewController, ReportRootController, SettingsViewController, Report, KeychainWrapper, App, StatusInfoController;

@interface ASiSTAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
	UITabBarController *tabBarController;
	
	BirneConnect *itts;
	AppViewController *appViewController;
	ReportRootController *reportRootController;
	SettingsViewController *settingsViewController;
	IBOutlet StatusInfoController *statusViewController;
	
	// HTTP server
	HTTPServer *httpServer;
	NSDictionary *addresses;
	BOOL serverIsRunning;
	
	
	// keychain services
	KeychainWrapper *keychainWrapper;
	
	// preferences
	BOOL convertSalesToMainCurrency;
	
	NSUInteger newApps;
	NSUInteger newReports;
	
	IBOutlet UITabBarItem* appBadgeItem;
	IBOutlet UITabBarItem* reportBadgeItem;
	
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet UITabBarItem* appBadgeItem;
@property (nonatomic, retain) IBOutlet UITabBarItem* reportBadgeItem;
@property (nonatomic, retain) BirneConnect *itts;

@property (nonatomic, readonly, assign) BOOL serverIsRunning;
@property (nonatomic, assign) BOOL convertSalesToMainCurrency;

@property (nonatomic, retain) HTTPServer *httpServer;
@property (nonatomic, retain) NSDictionary *addresses;



@property (nonatomic, retain) IBOutlet ReportRootController *reportRootController;
@property (nonatomic, retain) IBOutlet AppViewController *appViewController;

@property (nonatomic, retain) IBOutlet SettingsViewController *settingsViewController;
@property (nonatomic, retain) IBOutlet StatusInfoController *statusViewController;

@property (nonatomic, retain) KeychainWrapper *keychainWrapper;


- (void) toggleNetworkIndicator:(BOOL)isON;


// Notification handlers
- (void)newFileInDocuments:(NSNotification *) notification;
- (void)newAppNotification:(NSNotification *) notification;
- (void)newReportNotification:(NSNotification *) notification;



- (void) refreshButton:(id)sender;


@end

