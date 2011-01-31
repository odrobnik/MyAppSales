//
//  NSDataCompression.h
//  ObjGit
//
//  thankfully borrowed from the Etoile framework
//

#include <Foundation/Foundation.h>

@interface NSData (DDData)

// gzip compression utilities
- (NSData *)gzipInflate;
- (NSData *)gzipDeflate;

@end