//
//  YahooFinance.m
//  ASiST
//
//  Created by Oliver Drobnik on 09.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import "YahooFinance.h"


@implementation YahooFinance

@synthesize mainCurrency, allCurrencies, nameIndex;

static YahooFinance *_sharedInstance = nil;


// default main currency
+ (void) initialize
{
	// called once before this class is used the first time
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:@"USD" forKey:@"MainCurrency"];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:defaultsDict];
}

+ (YahooFinance *)sharedInstance
{
	if (!_sharedInstance)
	{
		_sharedInstance = [[YahooFinance alloc] initWithAllCurrencies];
	}
	
	return _sharedInstance;
}


- (id) initWithAllCurrencies
{
	
	if ((self = [super init]))
	{
		// the latested finance data is cached in the documents directory 
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		NSString *path = [documentsDirectory stringByAppendingPathComponent:@"Currencies.plist"];
		self.allCurrencies = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
		
		// if that did not work, then get it from the default
		if (!self.allCurrencies)
		{
			path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Currencies.plist"];
			self.allCurrencies = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
		}
		
		// sort by names
		NSEnumerator *enu = [allCurrencies keyEnumerator];
		NSString *key;
		
		self.nameIndex = [[NSMutableDictionary alloc] init];
		
		while (key = [enu nextObject]) 
		{
			NSDictionary *tmpDict = [allCurrencies objectForKey:key];
			[nameIndex setObject:key forKey:[tmpDict objectForKey:@"Name"]];
		}
		

		// make query string
		NSMutableString *string = [NSMutableString string];
		
		NSArray *currencies = [self.allCurrencies allKeys];
		
		
		NSEnumerator *en = [currencies objectEnumerator];
		NSString *oneCurrency;
		
		[string appendString:@"http://quote.yahoo.com/d/quotes.csv?s="];
		
		while (oneCurrency = [en nextObject])
		{
			//[symbolDict setObject:[oneCurrency objectForKey:@"symbol"] forKey:[oneCurrency objectForKey:@"countryCode"]];
			
			if (oneCurrency == [currencies lastObject])
			{
				[string appendFormat:@"EUR%@=X", oneCurrency];
			}
			else
			{
				[string appendFormat:@"EUR%@=X+", oneCurrency];
			}
		}
		
		[string appendString:@"&f=nl1d1t1"];
		
		NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:string]
																cachePolicy:NSURLRequestUseProtocolCachePolicy
															timeoutInterval:60.0];
		theConnection=[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
		if (theConnection) 
		{
			
			// Create the NSMutableData that will hold
			// the received data
			// receivedData is declared as a method instance elsewhere
			if (!receivedData)
			{
				receivedData=[[NSMutableData data] retain];
			}
		}
		else
		{
			// inform the user that the download could not be made
		}
	}
	
	// set up standard currency formatter
	currencyFormatter = [[NSNumberFormatter alloc] init];
	[currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	
	return self;
}
 
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    // this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // append the new data to the receivedData
    // receivedData is declared as a method instance elsewhere
    [receivedData appendData:data];
	NSString *sourceSt = [[NSString alloc] initWithBytes:[receivedData bytes] length:[receivedData length] encoding:NSASCIIStringEncoding];
	[sourceSt release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    //[connection release]; is autoreleased
    // receivedData is declared as a method instance elsewhere
    [receivedData release];
	receivedData = nil;	
}

- (void) parseYahooString:(NSString *)string
{
	NSArray *lines = [string componentsSeparatedByString:@"\r\n"];
	NSEnumerator *enu = [lines objectEnumerator];
	NSString *oneLine;
	
	while(oneLine = [enu nextObject])
	{
		NSArray *cols = [oneLine componentsSeparatedByString:@","];
		if ([cols count]==4)
		{
			NSNumber *tmpRate = [NSNumber numberWithDouble:[[cols objectAtIndex:1] doubleValue]];
			NSArray *colsCur = [[cols objectAtIndex:0] componentsSeparatedByString:@" "];
			if ([colsCur count]==3)
			{
				//NSString *fromCurrency = [[colsCur objectAtIndex:0] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
				NSString *toCurrency = [[colsCur objectAtIndex:2] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
				
				//NSArray *keys = [NSArray arrayWithObjects:@"Name", @"Rate", @"Symbol",nil];
				//NSArray *values = [NSArray arrayWithObjects:@"Name", @"Rate", @"Symbol",nil];
				
				[[self.allCurrencies objectForKey:toCurrency] setObject:tmpRate forKey:@"Rate"];
				
				//[curDict setObject:tmpRate forKey:toCurrency];
				
				
			}
		}
	}
	
	[self save];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ExchangeRatesChanged" object:nil userInfo:nil];
	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *sourceSt = [[NSString alloc] initWithBytes:[receivedData bytes] length:[receivedData length] encoding:NSASCIIStringEncoding];
	[self parseYahooString:sourceSt];
	[sourceSt release];
}	

- (void) save
{
	// the latested finance data is cached in the documents directory 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"Currencies.plist"];
	
	[self.allCurrencies writeToFile:path atomically:YES];	
}

- (double) convertToCurrency:(NSString *)toCurrency amount:(double)amount fromCurrency:(NSString *)fromCurrency
{
	if ([toCurrency isEqualToString:fromCurrency]) return amount;
	
	NSNumber *rate_1 = [[self.allCurrencies objectForKey:[fromCurrency uppercaseString]] objectForKey:@"Rate"];
	double inEuro=0;
	
	if (rate_1)
	{
		inEuro = amount/[rate_1 doubleValue];
	}
	else
	{
		return 0;
	}
	
	NSNumber *rate_2 = [[self.allCurrencies objectForKey:[toCurrency uppercaseString]] objectForKey:@"Rate"];
	
	if (rate_2)
	{
		return inEuro*[rate_2 doubleValue];
	}
	else
	{
		return 0;
	}
}

- (double) convertToMainCurrencyAmount:(double)amount fromCurrency:(NSString *)fromCurrency
{
	return [self convertToCurrency:self.mainCurrency amount:amount fromCurrency:fromCurrency];
}

- (double) convertToEuroFromDictionary:(NSDictionary *)amountDict
{
	if (!amountDict) return 0;
	
	double ret = 0;
	// root is a dictionary, we get the codes first
	for (NSString *currency_code in [amountDict allKeys])
	{
		id val = [amountDict objectForKey:currency_code];
		double original_amount = 0;
		
		if ([val isKindOfClass:[NSNumber class]])
		{
			 original_amount = [[amountDict objectForKey:currency_code] doubleValue];
		}
		else
		{
			 original_amount = [[[amountDict objectForKey:currency_code] objectForKey:@"Royalties"] doubleValue];
		}

		double converted_amount = [self convertToEuro:original_amount fromCurrency:currency_code];
		ret += converted_amount;
	}
	
	return ret;
}

- (double) convertToMainCurrencyFromDictionary:(NSDictionary *)amountDict
{
	double ret = 0;
	// root is a dictionary, we get the codes first
	for (NSString *currency_code in [amountDict allKeys])
	{
		double original_amount = [[amountDict objectForKey:currency_code] doubleValue];
		double converted_amount = [self convertToMainCurrencyAmount:original_amount fromCurrency:currency_code];
		ret += converted_amount;
	}
	
	return ret;
}

- (double) convertToEuro:(double)amount fromCurrency:(NSString *)fromCurrency
{
	
	NSNumber *rate = [[self.allCurrencies objectForKey:[fromCurrency uppercaseString]] objectForKey:@"Rate"];
	
	if (rate)
	{
		return amount/[rate doubleValue];
	}
	else
	{
		return 0;
	}
}

- (NSString *) formatAsCurrency:(NSString *)cur amount:(double)amount
{
	NSString *currencySymbol = [[self.allCurrencies objectForKey:[cur uppercaseString]] objectForKey:@"Symbol"];
	[currencyFormatter setCurrencySymbol:currencySymbol];
	
	return [currencyFormatter stringFromNumber:[NSNumber numberWithFloat:amount]];
}

- (NSString *)formatAsMainCurrencyAmount:(double)amount
{
	return [self formatAsCurrency:self.mainCurrency amount:amount];
}

- (NSArray *)currencyList
{
	NSArray *currencies = [allCurrencies allKeys];
	NSArray *ret = [currencies sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	return ret;
}


- (void) dealloc
{
	[mainCurrency release];
	[currencyFormatter release];
	[nameIndex release];
	[allCurrencies release];
	[self save];
	[super dealloc];
}

#pragma mark Custom Properties
- (NSString *)mainCurrency
{
	if (!mainCurrency)
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		mainCurrency = [[defaults objectForKey:@"MainCurrency"] retain];
	}
	
	return mainCurrency;
}


- (void) setMainCurrency:(NSString *)cur
{
	if (mainCurrency==cur)
	{
		return;
	}
	
	[mainCurrency release];
	mainCurrency = [cur retain];
	
	// save new currency in defaults
	[[NSUserDefaults standardUserDefaults] setObject:mainCurrency forKey:@"MainCurrency"];
	
	// we want all parts of the app to know if there is a new main currency, might be some table updating necessary
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MainCurrencyChanged" object:nil userInfo:(id)mainCurrency];
}



@end
