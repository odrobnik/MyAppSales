//
//  This class was created by Nonnus,
//  who graciously decided to share it with the CocoaHTTPServer community.
//

#import "MyHTTPConnection.h"
#import "HTTPServer.h"
#import "HTTPResponse.h"

// these two necessary to get report texts
#import "ASiSTAppDelegate.h"
#import "BirneConnect.h"
#import "Report.h"


@implementation MyHTTPConnection

/**
 * Returns whether or not the requested resource is browseable.
**/
- (BOOL)isBrowseable:(NSString *)path
{
	// Override me to provide custom configuration...
	// You can configure it for the entire server, or based on the current request
	
	return YES;
}

/**
 * This method creates a html browseable page.
 * Customize to fit your needs
**/
- (NSString *) createBrowseableIndex:(NSString *)path
{
    NSArray *array = [[NSFileManager defaultManager] directoryContentsAtPath:path];
    
    NSMutableString *outdata = [NSMutableString new];
	[outdata appendString:@"<html><head>"];
	[outdata appendFormat:@"<title>Files from %@</title>", server.name];
    [outdata appendString:@"<style>html {background-color:#eeeeee} body { background-color:#FFFFFF; font-family:Tahoma,Arial,Helvetica,sans-serif; font-size:18x; margin-left:15%; margin-right:15%; border:3px groove #006600; padding:15px; } </style>"];
    [outdata appendString:@"</head><body>"];
	[outdata appendFormat:@"<h1>Files from %@</h1>", server.name];
    [outdata appendString:@"<bq>The following files are hosted live from the iPhone's Docs folder.</bq>"];
    [outdata appendString:@"<p>"];
	[outdata appendFormat:@"<a href=\"..\">..</a><br />\n"];
    for (NSString *fname in array)
    {
        NSDictionary *fileDict = [[NSFileManager defaultManager] fileAttributesAtPath:[path stringByAppendingPathComponent:fname] traverseLink:NO];
		//NSLog(@"fileDict: %@", fileDict);
        NSString *modDate = [[fileDict objectForKey:NSFileModificationDate] description];
		if ([[fileDict objectForKey:NSFileType] isEqualToString: @"NSFileTypeDirectory"]) fname = [fname stringByAppendingString:@"/"];
		[outdata appendFormat:@"<a href=\"%@\">%@</a>		(%8.1f Kb, %@)<br />\n", fname, fname, [[fileDict objectForKey:NSFileSize] floatValue] / 1024, modDate];
    }
    [outdata appendString:@"</p>"];
	
	if ([self supportsPOST:path withSize:0])
	{
		[outdata appendString:@"<form action=\"\" method=\"post\" enctype=\"multipart/form-data\" name=\"form1\" id=\"form1\">"];
		[outdata appendString:@"<label>upload file"];
		[outdata appendString:@"<input type=\"file\" name=\"file\" id=\"file\" />"];
		[outdata appendString:@"</label>"];
		[outdata appendString:@"<label>"];
		[outdata appendString:@"<input type=\"submit\" name=\"button\" id=\"button\" value=\"Submit\" />"];
		[outdata appendString:@"</label>"];
		[outdata appendString:@"</form>"];
	}
	
	[outdata appendString:@"</body></html>"];
    
	//NSLog(@"outData: %@", outdata);
    return [outdata autorelease];
}

- (NSString *) htmlEncodeUmlaute:(NSString *)string
{
	NSString *ret = [string stringByReplacingOccurrencesOfString:@"ä" withString:@"&auml;"];
	
	return ret;
}


/*
NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
NSString *documentsDirectory = [paths objectAtIndex:0];
NSString *path1 = [documentsDirectory stringByAppendingPathComponent:@"test.zip"];
NSString *path2 = [documentsDirectory stringByAppendingPathComponent:@"292436602.png"];
NSString *path3 = [documentsDirectory stringByAppendingPathComponent:@"292809726.png"];

ZipArchive *zip = [[ZipArchive alloc] init];

BOOL ret = [zip CreateZipFile2:path1]; 
ret = [zip addFileToZip:path2 newname:@"reports/292436602.png"];
ret = [zip addFileToZip:path3 newname:@"reports/292809726.png"];
[zip CloseZipFile2];
[zip release];
*/



- (NSString *) createBrowseableReportIndex
{
	
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	
	// get two items from the dictionary
	NSString *version = [info objectForKey:@"CFBundleVersion"];
	NSString *title = [info objectForKey:@"CFBundleDisplayName"];
	
	
    NSMutableString *outdata = [NSMutableString new];
	[outdata appendString:@"<html><head>"];
	[outdata appendFormat:@"<title>ASiST</title>", server.name];
    [outdata appendString:@"<style>html {background-color:#eeeeee} body { background-color:#FFFFFF; font-family:Tahoma,Arial,Helvetica,sans-serif; font-size:18x; margin-left:15%; margin-right:15%; border:3px groove #006600; padding:15px; } </style>"];
	[outdata appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"/>"];
    [outdata appendString:@"</head><body>"];
	[outdata appendString:@"<img src=\"/app/ASiST.jpg\" style=\"float:right;\"/>"];
	[outdata appendFormat:@"<h1>%@</h1>", title];
	
	[outdata appendString:@"<h2>Database Tools</h2>"];
	[outdata appendString:@"<p><a href=\"/apps.db\">Download the SQLite Database</a> to your PC for safe-keeping or to analyze it yourself. If you upload an apps.db via the file upload tool you replace the current database. You have to restart the application for the new DB to take effect.</p>"];
	
	[outdata appendString:@"<p>You can <b>import</b> daily or weekly reports into ASiST with this upload tool. Reports must be in the original format, their type is automatically detected. Duplicate reports will be ignored. You can also upload a single ZIP archive containing multiple text reports for importing multiple reports at once.</p>"];
	
	//if ([self supportsPOST:path withSize:0])
	{
		[outdata appendString:@"<form action=\"\" method=\"post\" enctype=\"multipart/form-data\" name=\"form1\" id=\"form1\">"];
		[outdata appendString:@"<label>Upload File:"];
		[outdata appendString:@"<input type=\"file\" name=\"file\" id=\"file\" />"];
		[outdata appendString:@"</label>"];
		[outdata appendString:@"<label>"];
		[outdata appendString:@"<input type=\"submit\" name=\"button\" id=\"button\" value=\"Submit\" />"];
		[outdata appendString:@"</label>"];
		[outdata appendString:@"</form>"];
	}
	
   // [outdata appendString:@"<bq>The following reports are in your ASiST database.</bq>"];
	//[outdata appendString:@"<img src=\"/app/Report_Icon.png\" style=\"float:left; margin-right:10px;\"/>"];
    [outdata appendString:@"<h2>Daily Reports</h2>"];
	
    [outdata appendString:@"<ul>"];
	

	// Daily Reports
	ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	NSMutableArray *tmpArray = [[appDelegate.itts reportsByType] objectAtIndex:0];
	
	NSSortDescriptor *dateDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"fromDate" ascending:NO] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
	NSArray *sortedArray = [tmpArray sortedArrayUsingDescriptors:sortDescriptors];

	NSEnumerator *enu = [sortedArray objectEnumerator];
	Report *tmpReport;
	
	while (tmpReport = [enu nextObject]) {
		[outdata appendFormat:@"<li><a href=\"/report?id=%d\">%@</a></li>\n", tmpReport.primaryKey, [self htmlEncodeUmlaute:[tmpReport listDescription]]];
	}
    [outdata appendString:@"</ul>"];
	[outdata appendString:@"<p>Download all <a href=\"/export?type=0\">daily reports</a> as ZIP archive.</p>"];
//	[outdata appendString:@"<img src=\"/app/Report_Icon.png\" style=\"float:left; margin-right:10px;\"/>"];
    [outdata appendString:@"<h2>Weekly Reports</h2>"];

    [outdata appendString:@"<ul>"];

	// Weekly Reports
	tmpArray = [[appDelegate.itts reportsByType] objectAtIndex:1];
	
	sortedArray = [tmpArray sortedArrayUsingDescriptors:sortDescriptors];
	
	enu = [sortedArray objectEnumerator];
	
	while (tmpReport = [enu nextObject]) {
		[outdata appendFormat:@"<li><a href=\"/report?id=%d\">%@</a></li>", tmpReport.primaryKey, [tmpReport listDescription]];
	}
    [outdata appendString:@"</ul>"];
	
	[outdata appendString:@"<p>Download all <a href=\"/export?type=1\">weekly reports</a> as ZIP archive.</p>"];
	

	[outdata appendFormat:@"<p style=\"text-align:right;\"><small>%@ %@<br />&copy;2009 Drobnik.com</small></p>", title, version];
	
	
	
	[outdata appendString:@"</body></html>"];
	
    return [outdata autorelease];
}


/**
 * Returns whether or not the server will accept POSTs.
 * That is, whether the server will accept uploaded data for the given URI.
**/
- (BOOL)supportsPOST:(NSString *)path withSize:(UInt64)contentLength
{
//	NSLog(@"POST:%@", path);
	
	dataStartIndex = 0;
	multipartData = [[NSMutableArray alloc] init];
	postHeaderOK = FALSE;
	
	return YES;
}

- (NSDictionary *)dictFromUrlParams:(NSString *)path
{
	NSMutableDictionary *retMut = [[NSMutableDictionary alloc] init];
	
	NSURL *url = [NSURL URLWithString:path];
	
	NSArray *queryParts = [[url query] componentsSeparatedByString:@"&"];
	NSEnumerator *enu = [queryParts objectEnumerator];
	NSString *oneVar;
	
	while (oneVar = [enu nextObject])
	{
		NSArray *varParts = [oneVar componentsSeparatedByString:@"="];
		
		if ([varParts count]==2)
		{
			NSString *paramName = [varParts objectAtIndex:0];
			NSString *paramValue = [varParts objectAtIndex:1];
			
			[retMut setObject:paramValue forKey:paramName];
		}
	}
	
	NSDictionary *ret = [NSDictionary dictionaryWithDictionary:retMut];
	[retMut release];
	
	return ret;
}


/**
 * This method is called to get a response for a request.
 * You may return any object that adopts the HTTPResponse protocol.
 * The HTTPServer comes with two such classes: HTTPFileResponse and HTTPDataResponse.
 * HTTPFileResponse is a wrapper for an NSFileHandle object, and is the preferred way to send a file response.
 * HTTPDataResopnse is a wrapper for an NSData object, and may be used to send a custom response.
**/
- (NSObject<HTTPResponse> *)httpResponseForURI:(NSString *)path
{
//	NSLog(@"httpResponseForURI: %@", path);
	
	if (postContentLength > 0)		//process POST data
	{
		//NSLog(@"processing post data: %i", postContentLength);
		
		NSString* postInfo = [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:1] bytes] length:[[multipartData objectAtIndex:1] length] encoding:NSUTF8StringEncoding];
		NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
		postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
		postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
		NSString* filename = [postInfoComponents lastObject];
		
		if (![filename isEqualToString:@""]) //this makes sure we did not submitted upload form without selecting file
		{
			UInt16 separatorBytes = 0x0A0D;
			NSMutableData* separatorData = [NSMutableData dataWithBytes:&separatorBytes length:2];
			[separatorData appendData:[multipartData objectAtIndex:0]];
			int l = [separatorData length];
			int count = 2;	//number of times the separator shows up at the end of file data
			
			NSFileHandle* dataToTrim = [multipartData lastObject];
			
			for (unsigned long long i = [dataToTrim offsetInFile] - l; i > 0; i--)
			{
				[dataToTrim seekToFileOffset:i];
				if ([[dataToTrim readDataOfLength:l] isEqualToData:separatorData])
				{
					[dataToTrim truncateFileAtOffset:i];
					i -= l;
					if (--count == 0) break;
				}
			}
			
			//NSLog(@"NewFileUploaded");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NewFileUploaded" object:nil];
		}
		
	/*	for (int n = 1; n < [multipartData count] - 1; n++)
			NSLog(@"%@", [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:n] bytes] length:[[multipartData objectAtIndex:n] length] encoding:NSUTF8StringEncoding]);
	*/	
		[postInfo release];
		[multipartData release];
		postContentLength = 0;
		
	}
	
	NSString *filePath = [self filePathForURI:path];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
	{
		return [[[HTTPFileResponse alloc] initWithFilePath:filePath] autorelease];
	}
	else
	{
		if ([path hasPrefix:@"/report"])
		{
			NSURL *url = [NSURL URLWithString:path];
			
			NSUInteger report_id=0;
			ReportType report_type=ReportTypeDay;
			NSString *from_date = nil;
			
			NSArray *queryParts = [[url query] componentsSeparatedByString:@"&"];
			NSEnumerator *enu = [queryParts objectEnumerator];
			NSString *oneVar;
			
			while (oneVar = [enu nextObject])
			{
				NSArray *varParts = [oneVar componentsSeparatedByString:@"="];
				
				if ([varParts count]==2)
				{
					NSString *paramName = [varParts objectAtIndex:0];
					NSString *paramValue = [varParts objectAtIndex:1];
					
					if ([paramName isEqualToString:@"id"])
					{
						report_id = [paramValue intValue];
					}
					else if([paramName isEqualToString:@"type"])
					{
						if ([paramValue isEqualToString:@"day"])
						{
							report_type = ReportTypeDay;
						}
						else if ([paramValue isEqualToString:@"week"]) {
							report_type = ReportTypeWeek;
						}
					}
					else if([paramName isEqualToString:@"from_date"])
					{
						//NSDateFormatter dateFormatterToRead = [[NSDateFormatter alloc] init];
						//[dateFormatterToRead setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZ"]; /* Unicode Locale Data Markup Language */
						//from_date = [dateFormatterToRead dateFromString:paramValue];
						//[dateFormatterToRead release];
						
						from_date = paramValue;
					}
				}
			}

			ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
			
			if (!report_id && from_date)
			{
				report_id = [appDelegate.itts reportIDForDate:from_date type:report_type];
			}
			
			NSString *reportText;
			if (report_id)
			{
				reportText = [appDelegate.itts reportTextForID:report_id];
			}
			else
			{
				//reportText = @"Illegal parameter for report function";
				NSData *browseData = [[self createBrowseableReportIndex] dataUsingEncoding:NSUTF8StringEncoding];
				return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];

			}
			
			NSData *browseData = [reportText dataUsingEncoding:NSUTF8StringEncoding];
			HTTPDataResponse *myResponse = [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
	
			return myResponse;
			
		}
		else if ([path hasPrefix:@"/export"])
		{
			NSDictionary *paramDict = [self dictFromUrlParams:path];
			NSString *type = [paramDict objectForKey:@"type"];
			
			
			if (type)
			{
				ReportType rt = (ReportType)[type intValue];
				ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];

				NSString *zipFilePath = [appDelegate.itts createZipFromReportsOfType:rt];
				
				return [[[HTTPFileResponse alloc] initWithFilePath:zipFilePath] autorelease];
	
			}
		}
		else if ([path hasPrefix:@"/app"])
		{
			NSString *basename = [path lastPathComponent];
			NSString *appPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:basename];
			
			return [[[HTTPFileResponse alloc] initWithFilePath:appPath] autorelease];
		}
		

		NSData *browseData = [[self createBrowseableReportIndex] dataUsingEncoding:NSUTF8StringEncoding];
		return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
			
		
		/*
		NSString *folder = [path isEqualToString:@"/"] ? [[server documentRoot] path] : [NSString stringWithFormat: @"%@%@", [[server documentRoot] path], path];
		if ([self isBrowseable:folder])
		{
			//NSLog(@"folder: %@", folder);
			NSData *browseData = [[self createBrowseableIndex:folder] dataUsingEncoding:NSUTF8StringEncoding];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
		} */
	}
	
	return nil;
}

/**
 * This method is called to handle data read from a POST.
 * The given data is part of the POST body.
**/
- (void)processPostDataChunk:(NSData *)postDataChunk
{
	// Override me to do something useful with a POST.
	// If the post is small, such as a simple form, you may want to simply append the data to the request.
	// If the post is big, such as a file upload, you may want to store the file to disk.
	// 
	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.
	
	//NSLog(@"processPostDataChunk");
	
	if (!postHeaderOK)
	{
		UInt16 separatorBytes = 0x0A0D;
		NSData* separatorData = [NSData dataWithBytes:&separatorBytes length:2];
		
		int l = [separatorData length];
		for (int i = 0; i < [postDataChunk length] - l; i++)
		{
			NSRange searchRange = {i, l};
			if ([[postDataChunk subdataWithRange:searchRange] isEqualToData:separatorData])
			{
				NSRange newDataRange = {dataStartIndex, i - dataStartIndex};
				dataStartIndex = i + l;
				i += l - 1;
				NSData *newData = [postDataChunk subdataWithRange:newDataRange];
				if ([newData length])
				{
					[multipartData addObject:newData];
					
				}
				else
				{
					postHeaderOK = TRUE;
					
					NSString* postInfo = [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:1] bytes] length:[[multipartData objectAtIndex:1] length] encoding:NSUTF8StringEncoding];
					NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
					postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
					postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
					NSString* filename = [[[server documentRoot] path] stringByAppendingPathComponent:[postInfoComponents lastObject]];
					NSRange fileDataRange = {dataStartIndex, [postDataChunk length] - dataStartIndex};
					
					[[NSFileManager defaultManager] createFileAtPath:filename contents:[postDataChunk subdataWithRange:fileDataRange] attributes:nil];
					NSFileHandle *file = [[NSFileHandle fileHandleForUpdatingAtPath:filename] retain];
					if (file)
					{
						[file seekToEndOfFile];
						[multipartData addObject:file];
					}
					
					[postInfo release];
					
					break;
				}
			}
		}
	}
	else
	{
		[(NSFileHandle*)[multipartData lastObject] writeData:postDataChunk];
	}
}

@end
