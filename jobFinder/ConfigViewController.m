//
//  ConfigViewController.m
//  jobFinder
//
//  Created by mario greco on 29/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ConfigViewController.h"
#import "BaseCell.h"
#import "SearchZoneViewController.h"
#import "DatabaseAccess.h"
#import "jobFinderAppDelegate.h"
#import "Utilities.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@implementation ConfigViewController
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization 
    }
    return self;
}

#pragma mark - UITableViewDataSource delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return sectionDescripition.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger) section
{   
    if(sectionData){
        return [[sectionData objectAtIndex: section] count];
    } 

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *sec = [sectionData objectAtIndex:indexPath.section];
    NSDictionary *rowDesc = [sec objectAtIndex:indexPath.row]; 
    NSString *dataKey = [rowDesc objectForKey:@"DataKey"];
    NSString *kind = [rowDesc objectForKey:@"kind"];
    int cellStyle = UITableViewCellStyleDefault;
    
    BaseCell *cell = (BaseCell *)[tableView dequeueReusableCellWithIdentifier: dataKey];
    
    //se non è recuperata creo una nuova cella
	if (cell == nil) {
        cell = [[[NSClassFromString(kind) alloc] initWithStyle: cellStyle reuseIdentifier:kind withDictionary:rowDesc] autorelease];
    }


    cell.textLabel.numberOfLines = 2;
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;

    
    return cell;
}

//setta gli header delle sezioni
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{  
     return [sectionDescripition objectAtIndex:section];
}

//setta i footer della sezione
//non so se è una soluzione zozza per aggiungere il footer :|, da verificare
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return NSLocalizedString(@"SEARCH ZONE MEX",@"");
            break;
        case 1:
            return @"";
            break;
        
        default:
            return nil;
            break;
    }
}

#pragma mark - TableViewDelegate


//azioni per le celle selezionate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    int section = indexPath.section;
    int row = indexPath.row;
    
    if(section == 0){
        switch (row) {
            case 1:
                searchZone = [[[SearchZoneViewController alloc] initWithNibName: @"SearchZoneViewController" bundle: nil] autorelease];
                [searchZone setDelegate:self];
                [self.navigationController pushViewController:searchZone animated:YES];
                break;
                
            default:
                break;
        }
    }
    
    //deseleziona la cella
    [tableView deselectRowAtIndexPath:indexPath animated:YES];  
    
}

#pragma mark - azioni dei bottoni

-(void) doneButtonClicked: (id) sender
{
    //rimuove vista
    [UIView 
     transitionWithView:self.navigationController.view
     duration:0.8
     options:UIViewAnimationOptionTransitionFlipFromLeft
     animations:^{ 
         [self.navigationController 
          popViewControllerAnimated:NO];
     }
     completion:NULL];
}

#pragma mark - SearchZoneDelegate

-(void) didSelectedPreferredAddress:(NSString *)address withLatitude:(CLLocationDegrees)latitude andLongitude:(CLLocationDegrees) longitude
{    
    //una volta selezionata la zona preferita viene salvata nelle impostazioni personali dell'utente
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
   [prefs setObject:address forKey:@"address"];
   [prefs setObject: [NSNumber numberWithDouble:latitude] forKey: @"lat"];
   [prefs setObject: [NSNumber numberWithDouble:longitude] forKey: @"long"];
    
    //    NSLog(@"dato nel prefs: %@",[prefs objectForKey:cell.dataKey]);
    [prefs synchronize];
    
    //aggiorno il model per mostrare i cambiamenti fatti alla tabella
    [[[sectionData objectAtIndex:0] objectAtIndex:0] setObject:address forKey:@"label"];
    [self.tableView reloadData];    
    //avviso il delegato che ho scelto la zona preferita e gli passo le coordinate
    if(delegate && [delegate respondsToSelector:@selector(didSelectedFavouriteZone:)])
        [delegate didSelectedFavouriteZone:CLLocationCoordinate2DMake(latitude,longitude)]; 
    
    [self.navigationController popViewControllerAnimated:YES];
    
    //scrivo sul db il cambiamento della zona preferita per il relativo token
    ((jobFinderAppDelegate*)[[UIApplication sharedApplication] delegate]).typeRequest = @"zoneChanged";        
    
#if !TARGET_IPHONE_SIMULATOR
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge];
#endif
    
}

#pragma mark - DatabaseAccessDelegate

- (void) didReceiveResponsFromServer:(NSString *)receivedData {
    //NSLog(@"%s", [receivedData UTF8String]);
}

#pragma mark - View life cycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorColor = UIColorFromRGB(0xf3f3f3);
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        if(result.height == 480)
        {
            // iPhone Classic
            self.tableView.backgroundView = [[UIImageView alloc] initWithImage:
                                             [UIImage imageNamed:@"tableBackground.png"]];
        }
        if(result.height == 568)
        {
            self.tableView.backgroundView = [[UIImageView alloc] initWithImage:
                                             [UIImage imageNamed:@"tableBackgroundiP5.png"]];
        }
    }
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if([prefs objectForKey:@"address"] == nil || [[prefs objectForKey:@"address"] isEqualToString:@""]){
        [prefs setObject:@"" forKey:@"address"];
    }

    //setta titolo vista
    [self setTitle:NSLocalizedString(@"CONFIG", @"")];
    self.navigationItem.hidesBackButton = TRUE;
    //aggiungo bottone "fatto" alla barra e setto azione
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"DONE", @"")   style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonClicked:)];
    self.navigationItem.rightBarButtonItem = anotherButton;
    [anotherButton release];
    
    //creo le sezioni
    NSMutableArray *secA = [[NSMutableArray alloc] init];
    
    [secA insertObject:[[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                         @"bookmarks",              @"DataKey",
                         @"InfoCell",               @"kind",
                         [prefs objectForKey:@"address"], @"label",
                         @"",                       @"detailLabel",
                         @"star.png",               @"img",
                         [NSString stringWithFormat:@"%d", UITableViewCellStyleDefault], @"style",
                         nil] autorelease] atIndex: 0];

    [secA insertObject:[[[NSDictionary alloc] initWithObjectsAndKeys:
                         @"search",           @"DataKey",
                         @"ActionCell",       @"kind",
                         NSLocalizedString(@"SEARCH ADDR", @""),       @"label",
                         @"search.png",       @"img",
                         [NSString stringWithFormat:@"%d", UITableViewCellStyleDefault], @"style",
                         nil] autorelease] atIndex: 1];
    
        
    sectionData = [[NSArray alloc] initWithObjects: secA, nil];
    sectionDescripition = [[NSArray alloc] initWithObjects:NSLocalizedString(@"PREF ZONE",@""),nil];
    
    [secA autorelease];
}


- (void)viewDidUnload
{
    [sectionData release];
    sectionData = nil;
    [sectionDescripition release];
    sectionDescripition = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


#pragma mark - memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc 
{    [sectionDescripition release];
    [sectionData release];  
//    [searchZone release];
    [super dealloc];
}

@end
