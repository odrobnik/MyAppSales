#import <UIKit/UIKit.h>


@interface ReviewCell : UITableViewCell
{
	UILabel *reviewTitle;
	UILabel *reviewTitleBackground;
	UILabel *reviewText;
	UILabel *reviewAuthor;
	UILabel *reviewVersion;
	UILabel *reviewDate;
	UIImageView *ratingImage;
	UIImageView *countryImage;
	
}

@property (nonatomic, retain) UILabel *reviewTitle;
@property (nonatomic, retain) UILabel *reviewText;
@property (nonatomic, retain) UILabel *reviewAuthor;
@property (nonatomic, retain) UILabel *reviewVersion;
@property (nonatomic, retain) UILabel *reviewDate;
@property (nonatomic, retain) UIImageView *ratingImage;
@property (nonatomic, retain) UIImageView *countryImage;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
