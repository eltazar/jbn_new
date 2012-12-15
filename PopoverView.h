//
//  PopoverView.h
//  jobFinder
//
//  Created by mario greco on 15/12/12.
//
//

#import <UIKit/UIKit.h>

@interface PopoverView : UIView


@property(nonatomic, retain) UILabel *text;
-(void)setOrigin:(CGPoint)point;
-(void)showPopover:(UIView*)parentView;
@end
