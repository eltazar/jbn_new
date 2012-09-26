//
//  ShareCell.m
//  jobFinder
//
//  Created by mario greco on 26/09/12.
//
//

#import "ShareCell.h"

@implementation ShareCell
@synthesize fbButton,mailButton, executor;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withDictionary:(NSDictionary *)dictionary {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier withDictionary:dictionary]){
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        fbButton = [[UIButton alloc] init];
        [fbButton setBackgroundImage:[UIImage imageNamed:@"fbButton.png"] forState:UIControlStateNormal];
        [fbButton addTarget:executor action:@selector(shareWithFB:) forControlEvents:UIControlEventTouchUpInside];
        [fbButton setFrame:CGRectMake(self.frame.size.width-125, 5, 40, 40)];
        [self addSubview:fbButton];
        self.fbButton = nil;
        
        
        mailButton = [[UIButton alloc] init];
        [mailButton setBackgroundImage:[UIImage imageNamed:@"mailButton.png"] forState:UIControlStateNormal];
        [mailButton addTarget:executor action:@selector(shareWithMail:) forControlEvents:UIControlEventTouchUpInside];
        [mailButton setFrame:CGRectMake(self.frame.size.width-70, 5, 40, 40)];
        [self addSubview:mailButton];
        self.mailButton = nil;

        [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height+5)];
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)dealloc{
    self.executor = nil;
    self.fbButton = nil;
    self.mailButton = nil;
    [super dealloc];
}

@end
