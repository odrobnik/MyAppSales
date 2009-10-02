#import "ReviewCell.h"

@implementation ReviewCell

@synthesize reviewTitle;
@synthesize reviewText;
@synthesize reviewAuthor;
@synthesize reviewVersion;
@synthesize reviewDate;
@synthesize ratingImage;
@synthesize countryImage;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
	if(self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier])
	{
		self.reviewTitle = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
		self.reviewTitle.font = [UIFont boldSystemFontOfSize:14];
		self.reviewTitle.textColor = [UIColor whiteColor];
		self.reviewTitle.backgroundColor = [UIColor clearColor];
		self.reviewTitle.numberOfLines = 0;
		self.reviewTitle.shadowColor = [UIColor blackColor];
		self.reviewTitle.shadowOffset = CGSizeMake(0, 1);
		
		reviewTitleBackground = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
		reviewTitleBackground.backgroundColor = [UIColor lightGrayColor];
		
		self.reviewAuthor = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
		self.reviewAuthor.font = [UIFont boldSystemFontOfSize:12];
		self.reviewAuthor.numberOfLines = 0;
		
		self.reviewText = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
		self.reviewText.font = [UIFont systemFontOfSize:12];
		self.reviewText.numberOfLines = 0;
		
		self.reviewVersion = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
		self.reviewVersion.font = [UIFont systemFontOfSize:12];
		self.reviewVersion.numberOfLines = 0;
		self.reviewVersion.textColor = [UIColor darkGrayColor];
		self.reviewVersion.textAlignment = UITextAlignmentRight;
		
		self.reviewDate = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
		self.reviewDate.font = [UIFont systemFontOfSize:12];
		self.reviewDate.numberOfLines = 0;
		self.reviewDate.textColor = [UIColor darkGrayColor];
		self.reviewDate.textAlignment = UITextAlignmentRight;
		
		
		self.ratingImage = [[[UIImageView alloc] initWithFrame:CGRectMake(10, 0, 85, 16)] autorelease];
		self.countryImage = [[[UIImageView alloc] initWithFrame:CGRectMake(285, 0, 32, 32)] autorelease];
		
		
		
		[self.contentView addSubview:reviewTitleBackground];
		[self.contentView addSubview:self.reviewTitle];
		[self.contentView addSubview:self.reviewAuthor];
		[self.contentView addSubview:self.reviewText];
		[self.contentView addSubview:self.ratingImage];
		[self.contentView addSubview:self.reviewVersion];
		[self.contentView addSubview:self.reviewDate];
		[self.contentView addSubview:self.countryImage];
		
		
	}
	
	return self;
}


- (void)layoutSubviews
{	
	[super layoutSubviews];
	
	CGRect contentRect = self.contentView.bounds;
	
	if(!self.editing)
	{
		CGFloat boundsX = contentRect.origin.x;
		CGRect frame;
		
		NSString *text = self.reviewTitle.text;
		UIFont *font = self.reviewTitle.font;
		CGSize constraint = CGSizeMake(contentRect.size.width - 50, 500);
		CGSize size = [text sizeWithFont:font constrainedToSize:constraint];
		
		frame = CGRectMake(boundsX + 10, 0, contentRect.size.width - 50, size.height + 10);
		
		self.reviewTitle.frame = frame;
		
		self.countryImage.frame = CGRectMake(280, 2.0+(frame.size.height-self.countryImage.image.size.height)/2.0, self.countryImage.image.size.height, self.countryImage.image.size.height);
		
		
		reviewTitleBackground.frame = CGRectMake(boundsX, 0, contentRect.size.width, size.height + 10);
		
		text = self.reviewAuthor.text;
		font = self.reviewAuthor.font;
		constraint = CGSizeMake(contentRect.size.width - 20, 500);
		size = [text sizeWithFont:font constrainedToSize:constraint];
		
		frame = CGRectMake(boundsX + 10, self.reviewTitle.frame.size.height + 3, contentRect.size.width - 20, size.height + 5);
		self.reviewAuthor.frame = frame;
		
		text = self.reviewText.text;
		font = self.reviewText.font;
		constraint = CGSizeMake(contentRect.size.width - 20, 500);
		size = [text sizeWithFont:font constrainedToSize:constraint];
		
		frame = CGRectMake(boundsX + 10, self.reviewTitle.frame.size.height + self.reviewAuthor.frame.size.height, contentRect.size.width - 20, size.height + 10);
		self.reviewText.frame = frame;
		
		frame = CGRectMake(boundsX + 10, self.reviewText.frame.size.height + self.reviewAuthor.frame.size.height + self.reviewTitle.frame.size.height, 85, 16);
		self.ratingImage.frame = frame;
		
		frame = CGRectMake(boundsX + 100, self.reviewText.frame.size.height + self.reviewAuthor.frame.size.height + self.reviewTitle.frame.size.height + 2, contentRect.size.width - 115, 16);
		self.reviewVersion.frame = frame;
		
		frame = CGRectMake(boundsX + 150, self.reviewTitle.frame.size.height + 3, contentRect.size.width - 165, 16);
		self.reviewDate.frame = frame;
	}
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	
}

- (void)dealloc
{
    [reviewText release];
	[ratingImage release];
	[reviewTitle release];
	[reviewAuthor release];
	[reviewVersion release];
	reviewTitleBackground = nil;
	
	[super dealloc];
}


@end
