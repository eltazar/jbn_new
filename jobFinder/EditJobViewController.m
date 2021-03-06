//
//  EditJobViewController.m
//  jobFinder
//
//  Created by mario greco on 03/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.


#import "EditJobViewController.h"
#import "SectorTableViewController.h"
#import "ActionCell.h"
#import "TextFieldCell.h"
#import "TextAreaCell.h"

@implementation EditJobViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        contractSegmentedCtrl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Part-time",@"Full-time", nil]];       
        contractSegmentedCtrl.frame = CGRectMake(27, 7, 180, 30);
        [contractSegmentedCtrl addTarget:self
                             action:@selector(selectedTime:)
                   forControlEvents:UIControlEventValueChanged];
        contractSegmentedCtrl.segmentedControlStyle = UISegmentedControlStyleBar;
        
        kindSegmentedCtrl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"JOB OFFER", @""),NSLocalizedString(@"FIND A JOB", @""), nil]];
        kindSegmentedCtrl.frame = CGRectMake(27, 7, 140, 30);
        [kindSegmentedCtrl addTarget:self
                                  action:@selector(chooseKind:)
                        forControlEvents:UIControlEventValueChanged];
        kindSegmentedCtrl.segmentedControlStyle = UISegmentedControlStyleBar;
    }
    return self;
}


#pragma mark - DataSourceProtocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *sec = [sectionData objectAtIndex:indexPath.section];
    NSDictionary *rowDesc = [sec objectAtIndex:indexPath.row]; 
    
    BaseCell *cell = (BaseCell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if(indexPath.section == 0 && indexPath.row == 0){
        cell.accessoryView = kindSegmentedCtrl;
        //[cell.contentView addSubview:segmentedCtrl];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if(indexPath.section == 0 && indexPath.row == 1){
        
        cell.accessoryView = contractSegmentedCtrl;
        //[cell.contentView addSubview:segmentedCtrl]; 
        cell.selectionStyle = UITableViewCellSelectionStyleNone;        
    }
    
    [self fillCell:cell rowDesc:rowDesc];
    
    [cell setDelegate:self];
    
    return cell;    
}


#pragma mark - TableViewDelegate

//azioni per le celle selezionate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    int section = indexPath.section;
    int row = indexPath.row;
    
    if(section == 0 && row == 2){

        NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
        
        SectorTableViewController *sectorTable = nil;
        
        if([language isEqualToString:@"it"])        
            sectorTable = [[SectorTableViewController alloc] initWithPlist:@"it-sectors-table"];
        else sectorTable = [[SectorTableViewController alloc] initWithPlist:@"en-sectors-table"];
        
        sectorTable.secDelegate = self;
        [self.navigationController pushViewController:sectorTable animated:YES];
        [sectorTable release];
    }
    else if(section == 2){
        TextFieldCell *cell = (TextFieldCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell.textField becomeFirstResponder];
    }
}


#pragma mark - TextField and TextView Delegate

- (void)textFieldDidEndEditing:(UITextField *)txtField
{   
    //recupera la cella relativa al texfield
    TextFieldCell *cell = (TextFieldCell *) [[txtField superview] superview];

    if([cell.dataKey isEqualToString:@"phone"])
        [job _setPhone:txtField.text  kind:@"phone"];
    else if([cell.dataKey isEqualToString:@"phone2"])
        [job _setPhone:txtField.text kind:@"phone2"];
    else if([cell.dataKey isEqualToString:@"email"])
        job.email = txtField.text;    
    else if([cell.dataKey isEqualToString:@"url"])
        [job setUrlWithString:txtField.text];    
}

-(void) textViewDidEndEditing:(UITextView *)textView
{    
    TextAreaCell *cell = (TextAreaCell *) [textView superview] ;
    //     NSLog(@"2) dataKey %@, textArea %@ ", cell.dataKey, cell.textView.text);
    if ([cell.dataKey isEqualToString:@"description"])
        job.description = textView.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{ 
	[textField resignFirstResponder];
	return YES;
}

#pragma mark - SectorTableDelegate

//prende i dati dalla tabella settori ed aggiorna la cella con il nuovo dato
-(void) didReceiveSectorFromTable:(NSString*) jobSector andCode:(NSString*)code
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:2 inSection:0];
    NSString *placeholder;
    
    if(jobSector != nil){
        job.field = jobSector;
        placeholder = jobSector;
        job.code = code;
    }    
    else{
        job.field = @"";
        placeholder = NSLocalizedString(@"CHOOSE...", @"");
        job.code = @"";
    } 
    
    //aggiorno il model della tabella
    [[[sectionData objectAtIndex:0] objectAtIndex:0] setObject:placeholder forKey:@"placeholder"];
    [self.tableView reloadRowsAtIndexPaths: [[[NSArray alloc] initWithObjects:indexPath,nil] autorelease] withRowAnimation:UITableViewRowAnimationNone];
    
    [self.navigationController popViewControllerAnimated:YES];
}

//riempe le celle in base ai dati del job creato
-(void)fillCell: (UITableViewCell *)cell rowDesc:(NSDictionary *)rowDesc
{
    NSString *datakey= [rowDesc objectForKey:@"DataKey"];
    
    if([datakey isEqualToString:@"employee"]){
         cell.detailTextLabel.text = job.field;
        if(job.field == nil || [job.field isEqualToString:@""])
            ((ActionCell *)cell).detailTextLabel.text = [rowDesc objectForKey:@"placeholder"];
        else ((ActionCell *)cell).detailTextLabel.text = job.field;
    }
    else if([datakey isEqualToString:@"description"])
        ((TextAreaCell*)cell).textView.text = job.description;
    else if([datakey isEqualToString:@"phone"])
         ((TextFieldCell *)cell).textField.text = job.phone;
    else if([datakey isEqualToString:@"phone2"])
        ((TextFieldCell *)cell).textField.text = job.phone2;
    else if([datakey isEqualToString:@"email"])
         ((TextFieldCell *)cell).textField.text = job.email;
    else if([datakey isEqualToString:@"url"])
         ((TextFieldCell *)cell).textField.text = [job.url absoluteString]; 
}

- (void)hideKeyboard 
{ 
    //nasconde tastiera se ho selezionato la cella contentente la textView
    if([self.tableView viewWithTag:1111] != nil)
        [[self.tableView viewWithTag:1111] resignFirstResponder];
}

- (void) selectedTime:(id)sender{
    NSLog(@"SELECTOR time");
    switch(contractSegmentedCtrl.selectedSegmentIndex)
    {
        case 0:
            job.time = @"Part-time";
            break;
        case 1:
            job.time = @"Full-time";
            break;
        default: job.time = @"";
            break;
    }
    
    //NSLog(@"job.time = %@",job.time);
}

- (void) chooseKind:(id)sender{
    NSLog(@"SELECTOR kind");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"employeeDidSet" object:self userInfo:nil];
    switch(kindSegmentedCtrl.selectedSegmentIndex)
    {
        case 0:
            job.kind = @"Offro";
            break;
        case 1:
            job.kind = @"Cerco";
            break;
        default: job.kind = @"";
            break;
    }
    
    //NSLog(@"job.time = %@",job.time);

    
}
    

#pragma mark - View lifecycle

//questa view può esser ruotata
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}


 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad
 {   
     [super viewDidLoad];
     
//     job = [[Job alloc]initWithCoordinate:CLLocationCoordinate2DMake(0,0)];
     //NSLog(@"job in EDTI_VIEW: %p",job);
     
     [self.navigationItem setTitle:NSLocalizedString(@"NEW JOB",@"")];
     
     //creo il model della tabella
     NSMutableArray *secA = [[NSMutableArray alloc] init];
     NSMutableArray *secB = [[NSMutableArray alloc] init];
     NSMutableArray *secC = [[NSMutableArray alloc] init];
     
     [secA insertObject:[[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                          @"kind",             @"DataKey",
                          @"BaseCell",         @"kind",
                          NSLocalizedString(@"KIND OF OFFER",@""),    @"label",
                          @"",                 @"placeholder",
                          @"",                 @"img",
                          [NSString stringWithFormat:@"%d", UITableViewCellStyleDefault], @"style",
                          nil] autorelease] atIndex: 0];
     
     [secA insertObject:[[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                          @"time",             @"DataKey",
                          @"BaseCell",         @"kind",
                          NSLocalizedString(@"CONTRACT",@""),                 @"label",
                          @"",                 @"placeholder",
                          @"",                 @"img",
                          [NSString stringWithFormat:@"%d", UITableViewCellStyleDefault], @"style",
                          nil] autorelease] atIndex: 1];
     
     [secA insertObject:[[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                          @"employee",         @"DataKey",
                          @"ActionCell",       @"kind", 
                          NSLocalizedString(@"SECTOR",@""),          @"label",
                          NSLocalizedString(@"CHOOSE...", @""),        @"placeholder",
                          @"",                 @"img",
                          [NSString stringWithFormat:@"%d", UITableViewCellStyleValue1], @"style",
                          nil] autorelease] atIndex: 2];
     
     [secB insertObject:[[[NSDictionary alloc] initWithObjectsAndKeys:
                          @"description",      @"DataKey",
                          @"TextAreaCell",     @"kind",
                          NSLocalizedString(@"DESCRIPTION",@""),      @"label",
                          @"",                 @"placeholder",
                          @"",                 @"img",
                          [NSString stringWithFormat:@"%d", UITableViewCellStyleValue1], @"style",
                          [NSString stringWithFormat:@"%d", UIKeyboardTypeDefault], @"keyboardType",
                          nil] autorelease]  atIndex: 0];
     
     [secC insertObject:[[[NSDictionary alloc] initWithObjectsAndKeys:
                          @"phone",            @"DataKey",
                          @"TextFieldCell",    @"kind",
                          NSLocalizedString(@"PHONE",@""),         @"label",
                          @"44112233",         @"placeholder",
                          @"",                 @"img",
                          [NSString stringWithFormat:@"%d", UITableViewCellStyleValue1], @"style",
                          [NSString stringWithFormat:@"%d", UIKeyboardTypeNumbersAndPunctuation], @"keyboardType",
                          nil] autorelease ]  atIndex: 0];
     
     [secC insertObject:[[[NSDictionary alloc] initWithObjectsAndKeys:
                          @"phone2",            @"DataKey",
                          @"TextFieldCell",    @"kind",
                          NSLocalizedString(@"PHONE",@""),         @"label",
                          @"44112233",         @"placeholder",
                          @"",                 @"img",
                          [NSString stringWithFormat:@"%d", UITableViewCellStyleValue1], @"style",
                          [NSString stringWithFormat:@"%d", UIKeyboardTypeNumbersAndPunctuation], @"keyboardType",
                          nil] autorelease ]  atIndex: 1];
     
     [secC insertObject:[[[NSDictionary alloc] initWithObjectsAndKeys:
                          @"email",            @"DataKey",
                          @"TextFieldCell",    @"kind",
                          @"E-mail",           @"label",
                          [NSString stringWithFormat:@"%@%@",NSLocalizedString(@"EXAMPLE", @""),@"@mail.com"], @"placeholder",
                          @"",                 @"img",
                          [NSString stringWithFormat:@"%d", UITableViewCellStyleValue1], @"style",
                          [NSString stringWithFormat:@"%d", UIKeyboardTypeEmailAddress], @"keyboardType",
                          nil] autorelease] atIndex: 2];
     
     [secC insertObject:[[[NSDictionary alloc] initWithObjectsAndKeys:
                          @"url",              @"DataKey",
                          @"TextFieldCell",    @"kind", 
                          @"URL",              @"label", 
                          [NSString stringWithFormat:@"http://www.%@.com",NSLocalizedString(@"EXAMPLE", @"")],  @"placeholder",
                          @"",                 @"img", 
                          [NSString stringWithFormat:@"%d", UITableViewCellStyleValue1], @"style",
                          [NSString stringWithFormat:@"%d", UIKeyboardTypeURL], @"keyboardType", 
                          nil] autorelease] atIndex: 3];
     
     
     //il release è lasciato alla classe madre
     sectionData = [[NSArray alloc] initWithObjects: secA, secB, secC, nil];
     sectionDescripition = [[NSArray alloc] initWithObjects:NSLocalizedString(@"GENERAL INFORMATION",@""), NSLocalizedString(@"DESCRIPTION",@"") , NSLocalizedString(@"CONTACTS",@""), nil];   
     
     [secA autorelease]; 
     [secB autorelease];
     [secC autorelease];
     
     UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
     [self.tableView addGestureRecognizer:gestureRecognizer];
     gestureRecognizer.cancelsTouchesInView = NO;  // this prevents the gesture recognizers to 'block' touches
     [gestureRecognizer release];


 }

//- (void) viewWillDisappear:(BOOL) animated
//{
//    //invio al delegato il job
////    [[self delegate] setJobCollected:job];
//}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    //    NSLog(@"UIPIKER UNLOAD count = %d", pickerView.view.retainCount);
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void) dealloc
{
    [kindSegmentedCtrl release];
    [contractSegmentedCtrl release];
    [job release]; //aggiunti 19 novembre
    job = nil; 
    [super dealloc];

//    NSLog(@"dea job = %p, count = %d",job, job.retainCount);
}


@end
