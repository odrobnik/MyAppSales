//
//  Sale.m
//  ASiST
//
//  Created by Oliver Drobnik on 24.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import "Sale.h"
#import "App.h"
#import "Product_v1.h"
#import "Database.h"
#import "Country.h"
#import "Report.h"

@interface Sale ()
@end


@implementation Sale

@synthesize country, unitsSold, product, report, royaltyPrice, royaltyCurrency,customerPrice, customerCurrency, transactionType;

static sqlite3_stmt *insert_statement_sale = nil;


- (id) initWithCountry:(Country *)acountry report:(Report *)areport product:(Product_v1 *)saleProduct units:(NSInteger)aunits royaltyPrice:(double)aprice royaltyCurrency:(NSString *)acurrency customerPrice:(double)c_price customerCurrency:(NSString *)c_currency transactionType:(TransactionType)ttype
{
	if (self = [super init]) 
	{
		self.country = acountry;
		NSAssert(country, @"Country must not be null");
		self.report = areport;
		self.unitsSold = aunits;
		self.product = saleProduct;
		self.royaltyPrice = aprice;
		self.royaltyCurrency = acurrency;
		self.customerPrice = c_price;
		self.customerCurrency = c_currency;
		self.transactionType = ttype;
	}
	
	return self;
}

- (void) dealloc
{
	[customerCurrency release];
	[royaltyCurrency release];
	[product release];
	[country release];
	[super dealloc];
}

- (void)insertIntoDatabase:(sqlite3 *)db {
    database = db;
	//NSUInteger primaryKey = 0;
	// This query may be performed many times during the run of the application. As an optimization, a static
    // variable is used to store the SQLite compiled byte-code for the query, which is generated one time - the first
    // time the method is executed by any Book object.
    if (insert_statement_sale == nil) {
        static char *sql = "INSERT INTO sale(app_id, type_id, units, royalty_price, royalty_currency, customer_price , customer_currency , country_code, report_id) VALUES(?, ?, ?, ?, ?, ?, ?,?,?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insert_statement_sale, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
	
	sqlite3_bind_int(insert_statement_sale, 1, product.apple_identifier);
	sqlite3_bind_int(insert_statement_sale, 2, transactionType);
	sqlite3_bind_int(insert_statement_sale, 3, unitsSold);
	sqlite3_bind_double(insert_statement_sale, 4, royaltyPrice);
	sqlite3_bind_text(insert_statement_sale, 5, [royaltyCurrency UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_double(insert_statement_sale, 6, customerPrice);
	sqlite3_bind_text(insert_statement_sale, 7, [customerCurrency UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_statement_sale, 8, [country.iso2 UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(insert_statement_sale, 9, report.primaryKey);
	
    int success = sqlite3_step(insert_statement_sale);
	
    // Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(insert_statement_sale);
    if (success == SQLITE_ERROR) {
        NSAssert1(0, @"Error: failed to insert into the database with message '%s'.", sqlite3_errmsg(database));
    } else {
        // SQLite provides a method which retrieves the value of the most recently auto-generated primary key sequence
        // in the database. To access this functionality, the table should have a column declared of type 
        // "INTEGER PRIMARY KEY"
        //primaryKey = sqlite3_last_insert_rowid(database);
    }
    // All data for the book is already in memory, but has not be written to the database
    // Mark as hydrated to prevent empty/default values from overwriting what is in memory
    //hydrated = YES;
	
	//return primaryKey;
}



@end
