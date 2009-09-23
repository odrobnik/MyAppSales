//
//  LKGoogleTranslator.h
//  GoogleTranslator
//

#import <Foundation/Foundation.h>
#import "LKConstants.h"

@interface LKGoogleTranslator : NSObject
{

}

- (NSString *)urlencode:(NSString *)url;
- (NSString*)translateText:(NSString*)sourceText fromLanguage:(NSString*)sourceLanguage toLanguage:(NSString*)targetLanguage;
- (NSString*)translateCharacters:(NSString*)text;

@end
