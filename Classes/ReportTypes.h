#import <Foundation/Foundation.h>

typedef enum { 
	ReportTypeDay = 0, 
	ReportTypeWeek = 1, 
	ReportTypeFinancial = 2, 
	ReportTypeFree = 3, 
	ReportTypeUnknown = 99 } ReportType;

typedef enum { 
	ReportRegionUnknown = 0, 
	ReportRegionUSA = 1, 
	ReportRegionEurope = 2, 
	ReportRegionCanada = 3, 
	ReportRegionAustralia = 4, 
	ReportRegionUK = 5, 
	ReportRegionJapan = 6, 
	ReportRegionRestOfWorld = 7} ReportRegion;

typedef enum { TransactionTypeSale = 1, TransactionTypeFreeUpdate = 7, TransactionTypeIAP = 101 } TransactionType;




