//
//  FilterOfferView.h
//  jobFinder
//
//  Created by mario greco on 19/12/12.
//
//

#import "PullableView.h"
@protocol FilterOfferViewDelegate;
@interface FilterOfferView : PullableView
{
    @private
    UIImageView *filterImg;
    UISegmentedControl *segCtrlFilter;
}
@property(nonatomic, retain) UIImageView *filterImg;
@property(nonatomic, retain) UISegmentedControl *segCtrlFilter;
@property(nonatomic, assign) id<FilterOfferViewDelegate> fDelegate;

-(void)setDelegate:(id<PullableViewDelegate>)delegate;

@end

@protocol FilterOfferViewDelegate <NSObject>

-(void)didChangeFilter:(NSInteger)value;
@end