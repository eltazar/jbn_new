//
//  FilterOfferView.m
//  jobFinder
//
//  Created by mario greco on 19/12/12.
//
//

#import "FilterOfferView.h"

#define PADDING_RIGHT 46



@implementation FilterOfferView
@synthesize segCtrlFilter, filterImg, fDelegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        //"JOB OFFER" = "Job offer";
        //"FIND A JOB" = "Job seeker";
        segCtrlFilter = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"JOB OFFER", @""),NSLocalizedString(@"FIND A JOB", @""), nil]];
        segCtrlFilter.selectedSegmentIndex = 0;
        [segCtrlFilter setFrame:CGRectMake(43, 4, 140, 26)];
        UIColor *newTintColor = [UIColor colorWithRed: 180/255.0 green:21/255.0 blue:7/255.0 alpha:1.0];
        //UIColor *newTintColor = [UIColor colorWithRed: 251/255.0 green:175/255.0 blue:93/255.0 alpha:1.0];
        segCtrlFilter.segmentedControlStyle = UISegmentedControlStyleBar;
        segCtrlFilter.tintColor = [UIColor grayColor];//newTintColor;
        
        [segCtrlFilter addTarget:self action:@selector(didChangeFilterSegCtrlState:) forControlEvents:UIControlEventValueChanged];

        self.openedCenter = CGPointMake(frame.size.width+PADDING_RIGHT, frame.origin.y);
        self.closedCenter = CGPointMake(frame.origin.x+PADDING_RIGHT, frame.origin.y);
        self.center = self.closedCenter;
        self.animate = YES;
        [self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"rightFilter"]]];
        [self setAlpha:0.95];
        
        filterImg = [[UIImageView alloc] initWithFrame:CGRectMake(segCtrlFilter.frame.origin.x-20, 8, 18, 20)];
        [filterImg setTag:697];
        filterImg.backgroundColor = [UIColor clearColor];

        [self addSubview:segCtrlFilter];
        
        //recupero precedente stato salvato per il filtro
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"kindOfOffer"] != nil){
            segCtrlFilter.selectedSegmentIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:@"kindOfOffer"] intValue];
            if([[[NSUserDefaults standardUserDefaults] objectForKey:@"kindOfOffer"] isEqualToString:@"Offro"]){
                segCtrlFilter.selectedSegmentIndex = 0;
                //pin verde
                filterImg.image = [UIImage imageNamed:@"pinGreen.png"];
            }
            else{
                segCtrlFilter.selectedSegmentIndex = 1;
                filterImg.image = [UIImage imageNamed:@"pinOrange.png"];
            }
        }
        else{
            //pin verde
            filterImg.image = [UIImage imageNamed:@"pinGreen.png"];
            segCtrlFilter.selectedSegmentIndex = 0;
        }
        
        [self addSubview:filterImg];
        [filterImg release];
        
    }
    return self;
}

-(void)setDelegate:(id<PullableViewDelegate>)aDelegate{
    super.delegate = aDelegate;
}

-(void)didChangeFilterSegCtrlState:(id)sender{
    
    //salvo stato filtro
    switch(segCtrlFilter.selectedSegmentIndex)
    {
        case 0:
            filterImg.image = [UIImage imageNamed:@"pinGreen.png"];
            [[NSUserDefaults standardUserDefaults] setObject:@"Offro" forKey:@"kindOfOffer"];
            break;
        case 1:
            filterImg.image = [UIImage imageNamed:@"pinOrange.png"];
            [[NSUserDefaults standardUserDefaults] setObject:@"Cerco" forKey:@"kindOfOffer"];
            break;
        default:
            filterImg.image = [UIImage imageNamed:@"pinGreen.png"];
            [[NSUserDefaults standardUserDefaults] setObject:@"Offro" forKey:@"kindOfOffer"];
            break;
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    //NSLog(@"job.time = %@",job.time);
    
    if(fDelegate && [fDelegate respondsToSelector:@selector(didChangeFilter:)])
       [fDelegate didChangeFilter:segCtrlFilter.selectedSegmentIndex];
}



-(void)dealloc{
    self.filterImg = nil;
    self.segCtrlFilter = nil;
    [super dealloc];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
