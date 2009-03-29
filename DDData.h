#import <Foundation/Foundation.h>

@interface NSData (DDData)

- (NSData *)md5Digest;

- (NSData *)sha1Digest;

- (NSString *)hexStringValue;

- (NSString *)base64Encoded;
- (NSData *)base64Decoded;

// gzip compression utilities
- (NSData *)gzipInflate;
- (NSData *)gzipDeflate;

@end
