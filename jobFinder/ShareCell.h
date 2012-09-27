//
//  ShareCell.h
//  jobFinder
//
//  Created by mario greco on 26/09/12.
//
//

#import <UIKit/UIKit.h>
#import "BaseCell.h"

@interface ShareCell : BaseCell

@property(nonatomic, retain) IBOutlet UIButton *fbButton;
@property(nonatomic, retain) IBOutlet UIButton *mailButton;
@property(nonatomic, retain) UIViewController *executor;
@end
