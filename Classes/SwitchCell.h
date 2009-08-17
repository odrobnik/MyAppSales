//
//  SwitchCell.h
//  ASiST
//
//  Created by Oliver Drobnik on 15.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SwitchCell : UITableViewCell {
	UISwitch *switchCtl;
	UILabel *titleLabel;

}

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UISwitch *switchCtl;

@end
