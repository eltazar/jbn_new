//
//  PopoverView.m
//  jobFinder
//
//  Created by mario greco on 15/12/12.
//
//

#import "PopoverView.h"

@implementation PopoverView
@synthesize text;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
       
    }
    return self;
}

- (id) init
{
    self = [super initWithFrame:CGRectMake(0, 0, 150, 100)];
    
    if(self){
        // Initialization code
        UIImage *image = [UIImage imageNamed:@"popover2"];
        //image.size = CGSizeMake(self.frame.size.width, self.frame.size.height);
        UIImageView *imageView = [[UIImageView alloc]initWithImage:image];
        
        imageView.frame = CGRectMake(0, 0, 150, 100);
        
       // self.backgroundColor = [UIColor greenColor];
        self.text = [[[UILabel alloc] initWithFrame:CGRectMake(10,13, 130, 70)]
                     autorelease];
        //text.center = self.center;
        text.backgroundColor = [UIColor clearColor];
        text.textColor = [UIColor whiteColor];
        text.text = NSLocalizedString(@"NOTIFICATION", @"");
        text.lineBreakMode = UILineBreakModeWordWrap;
        text.numberOfLines = 0;
        text.textAlignment = UITextAlignmentCenter;
        [text setFont:[UIFont fontWithName:@"Arial-BoldMT" size:13]];
        
        [imageView addSubview:text];
        [self addSubview:imageView];
        [imageView release];
        
        UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissPopover)];
        [self addGestureRecognizer:tapRec];
        [tapRec release];
        
        self.alpha = 0;
    }
    
    return self;
    
}

-(void)dismissPopover{
    NSLog(@"dismiss");

    self.alpha = 1;
    [UIView animateWithDuration:0.6
                     animations:^{
                         self.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [self removeFromSuperview];
                     }
     ];
}

-(void)showPopover:(UIView*)parentView{
    
    [parentView addSubview:self];
    [UIView animateWithDuration:0.6
                     animations:^{
                         self.alpha = 1;
                     }
     ];
    
}

-(void)setOrigin:(CGPoint)point{
    
    self.frame = CGRectMake(point.x,point.y,self.frame.size.width,self.frame.size.height);
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)dealloc{
    self.text = nil;
    [super dealloc];
}
@end
