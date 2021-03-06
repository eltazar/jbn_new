//
//  Job.m
//  jobFinder
//
//  Created by mario greco on 17/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Job.h"
#import "Utilities.h"

@implementation Job

@synthesize field, date, address, description, phone, url, email, coordinate, title, subtitle, idDb, code, time, phone2, user, kind;
@synthesize isAnimated, isMultiple, isDraggable;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        idDb = 0;
        kind = @"";
        isMultiple = FALSE;
        isAnimated = TRUE;
        isEmailValid = TRUE;
        isURLvalid = TRUE;
        isDraggable = NO;
    }
    
    return self;
}

-(id) initWithCoordinate:(CLLocationCoordinate2D)coord
{
    self = [super init];
    if (self) {
        coordinate = coord; 
        isMultiple = FALSE;
        isAnimated = TRUE;
        isEmailValid = TRUE;
        isURLvalid = TRUE;
    }
    
    return self;
}


- (NSString *)title {
//    if(employee != nil)
//        return employee;
    
    if(isDraggable)
        return NSLocalizedString(@"CHANGE POSITION",@"");
    if([Utilities sectorFromCode:code] != nil)
        return [Utilities sectorFromCode:code];
    
    return @"";

}

- (NSString *)subtitle {
    
    if(isDraggable)
        return address;
    
    if(date != nil){
        //ritorna data formattata secondo la localizzazione dell'utente
        return [NSString stringWithFormat:@"Inserito: %@",[Utilities createLocalizedStringDate:date]];
    }
    else return @"";
}

-(NSString*)stringFromDate
{
    if(date != nil){
        //ritorna data formattata secondo la localizzazione dell'utente
        return [Utilities createLocalizedStringDate:date];
    }
    else return @"Non disponibile";
}

-(void) setTime:(NSString *)newTime
{
    if([newTime isKindOfClass:[NSNull class]] || [newTime isEqualToString:@""] || newTime == nil){
        [time release];
        time = @"";
        return;
    }
    [newTime retain];
    [time release];
    time = newTime;
}

-(void) setEmail:(NSString*)newEmail
{
    NSString* emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
    NSPredicate* emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    if(newEmail == nil)
        isEmailValid = TRUE;
    else if([newEmail isKindOfClass:[NSNull class]] || [newEmail isEqualToString:@""]){
        isEmailValid = TRUE;
        [newEmail release];
        newEmail = nil;
    }
    else isEmailValid = [emailTest evaluateWithObject:newEmail];
  
    
//    if(isEmailValid){
        [newEmail retain];
        [email release];
        email = newEmail;
//    }
//    else NSLog(@"EMAIL NO VALIDA");
}

-(void)_setPhone:(NSString *)_phone kind:(NSString*)kind
{
    if(_phone == nil || [_phone isEqualToString:@""]){
        
        if([kind isEqualToString:@"phone"])
            [self setPhone:@""];
        else [self setPhone2:@""]; 
        
        return;
    }

    BOOL isPlus = FALSE;
    
    //NSLog(@"_PHONE = %@",_phone);
   
    //se il numero di telefono ha il prefisso internazionale che comincia con +
    if([[_phone substringWithRange:NSMakeRange(0,1)] isEqualToString:@"+"])
        isPlus = TRUE;
    
    NSMutableString *strippedString = [NSMutableString 
                                       stringWithCapacity:_phone.length+1];
    
    NSScanner *scanner = [NSScanner scannerWithString:_phone];
    NSCharacterSet *numbers = [NSCharacterSet 
                               characterSetWithCharactersInString:@"0123456789"];
    
    while ([scanner isAtEnd] == NO) {
        NSString *buffer;
        if ([scanner scanCharactersFromSet:numbers intoString:&buffer]) {
            
            //reinserisco il + ad inizio stringa
            if(isPlus){
                strippedString = [NSMutableString stringWithFormat:@"%@",@"+"];
                isPlus = FALSE;
            }
            
            [strippedString appendString:buffer];
            
        } else {
            [scanner setScanLocation:([scanner scanLocation] + 1)];
        }
    }
    
    NSLog(@"STRIPPED STRING = %@",strippedString);
    
    if([kind isEqualToString:@"phone"])    
        [self setPhone:strippedString];
    else [self setPhone2:strippedString];

}

-(void)setPhone:(NSString *)newPhone
{    
    if([newPhone isKindOfClass:[NSNull class]] || [newPhone isEqualToString:@""]){

        [phone release];
        phone = @"";
        return;
    }
   
    //TODO: CREARE REGEX PER CONTROLLO DATI INSERITI
    
//    NSString *_newPhone = [[newPhone stringByReplacingOccurrencesOfString:@" " withString:@""] retain];
    [newPhone retain];
    [phone release];
    phone = newPhone;    
}

-(void)setPhone2:(NSString *)newPhone
{    
    
    if([newPhone isKindOfClass:[NSNull class]] || [newPhone isEqualToString:@""]){
        
        [phone2 release];
        phone2 = @"";
        return;
    }
    
    //TODO: CREARE REGEX PER CONTROLLO DATI INSERITI
    
    //    NSString *_newPhone = [[newPhone stringByReplacingOccurrencesOfString:@" " withString:@""] retain];
    [newPhone retain];
    [phone2 release];
    phone2 = newPhone;
}

-(void)setUser:(NSString *)newUser
{
    if([newUser isKindOfClass:[NSNull class]] || [newUser isEqualToString:@""]){
        
        [user release];
        user = @"";
        return;        
    }
    
    [newUser retain];
    [user release];
    user = newUser;
}

//problemi con questo metodo, vedere commit 7 novembre --> risolti
-(void)setDescription:(NSString *)newDescription
{
    //NSLog(@"NEW DESCR: %@",newDescription);
        
    if([newDescription isKindOfClass:[NSNull class]] || [newDescription isEqualToString:@""]){ //
        [description release];
        //description = nil;
        description = @"";
        return;
    }
    
   [newDescription retain];
   [description release];
   description = newDescription;
}

-(void) setUrlWithString:(NSString *) newUrlString
{
    if(newUrlString == nil || [newUrlString isKindOfClass:[NSNull class]] || [newUrlString isEqualToString:@""]){
        
       isURLvalid = YES;
       self.url = [NSURL URLWithString:@""];
       return;
    }        
    
    NSURL *tmpURL = [NSURL URLWithString:newUrlString];
    NSURL *urlFromString;
    
    //NSLog(@"SCHEME = %@, TMPURL = %@, HOST = %@",tmpURL.scheme,tmpURL,tmpURL.host);
    
    if (tmpURL && tmpURL.scheme){
        
        isURLvalid = YES;
        self.url = tmpURL;
        return;        
    }    
    
    if(tmpURL && tmpURL.scheme == nil){
            
        NSString *stringModified = [NSString stringWithFormat:@"http://%@",newUrlString];
        urlFromString = [[NSURL alloc]initWithString:stringModified];
        isURLvalid = YES;
        self.url = urlFromString;
        [urlFromString release];
        return;
    }
    
    isURLvalid = NO;
    //se la stringa non è valida e si scrolla la tabella la cella viene cancellata :S
    self.url = tmpURL;
    
}

/*
 - (BOOL) validateUrl: (NSString *) url {
 NSString *theURL =
 @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
 NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", theURL]; 
 return [urlTest evaluateWithObject:url];
 }
 */

-(BOOL) isValid
{
    return isURLvalid && isEmailValid;
}

-(NSString*) invalidReason
{
    if(!isURLvalid)
        return @"URL";
    else if(!isEmailValid)
        return @"E-mail";
    else return nil;    
}


- (NSString *)getLocalizedKind
{
    NSLog(@"tipo di lavoro = %@",kind);
    if([self.kind isEqualToString:@"Offro"])
        return NSLocalizedString(@"JOB OFFER", @"");
    else return NSLocalizedString(@"FIND A JOB", @"");
}

- (NSString *)description
{
    NSString *tmpDescription;
    if(description == nil){
        tmpDescription = @"";
    }
    else{
        tmpDescription = description;
    }

    return [[tmpDescription  retain] autorelease];
}

- (NSString *)email
{    
    NSString *tempEmail;
    if(email == nil){
        tempEmail = @"";
    }
    else{
        tempEmail = email;
    }
    return [[ tempEmail retain] autorelease];
}

- (NSString *)phone
{    
    NSString *tempPhone;
    
    if(phone == nil){
        tempPhone = @"";
    }
    else{
        tempPhone = phone;
        //NSLog(@"INFO PHONE = %@",phone);
    }
    return [[ tempPhone retain] autorelease];
}

- (NSString *)phone2
{    
    NSString *tempPhone;
    
    if(phone2 == nil){
        tempPhone = @"";
    }
    else{
        tempPhone = phone2;
        //NSLog(@"INFO PHONE = %@",phone2);
    }

    return [[ tempPhone retain] autorelease];
}

-(NSString*)user
{
    NSString *tempUser;
    if(user == nil){
        tempUser = @"";
    }
    else{
        tempUser = user;
    }
    return [[ tempUser retain] autorelease];
    
}

//- (NSURL *)url
//{    
//    if(url == nil){
//        url = [[[NSURL alloc] initWithString:@""]autorelease];
//        NSLog(@"URL é : %@",[url absoluteString]);
//    }
//    return [[ url retain] autorelease];
//}

-(NSString*)urlAsString
{
    //NSLog(@"URL = %@", [url absoluteString]);
    
    if(url == nil)
        return @"";
    else{
        return [url absoluteString];
    }
}

//effettua la ricerca binaria su un array di un dato un idDb di un'annotation
+(NSInteger)jobBinarySearch:(NSArray*)array withID:(NSInteger) x
{   
    //    NSLog(@"RICERCA BINARIA; ARRAY COUNT = %d",array.count);
    //NSLog(@"X = %d",x);
    NSInteger p;
    NSInteger u;
    NSInteger m;
    p = 0;
    u = [array count] - 1;
    //    NSLog(@"U = %d",u);
    NSObject *element = nil;
    
    while(p <= u) {
        m = (p+u)/2;
        element = [array objectAtIndex:m];
        //NSLog(@"M = %d",m);
        
        //NSLog(@"M.IDDB = %d",((Job*)[array objectAtIndex:m]).idDb);
        
        if(((Job*)element).idDb == x){ 
            //NSLog(@"TROVATO");
            return m; // valore x trovato alla posizione m
        }
        else if(((Job*)element).idDb > x)
            p = m+1;
        else{
            u = m-1;
        }
        
        //NSLog(@"P = %d ##### U = %d",p,u);
        
        
    }
    
    //NSLog(@"NON TROVATO");
    return -1;
}

//ordina array di job in base ad idDb
+(void)orderJobsByID:(NSMutableArray*)jobs
{
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"idDb"
                                                  ascending:NO] autorelease];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    [jobs sortUsingDescriptors:sortDescriptors]; 
}

//fonde due array ordinati di job
+(void)mergeArray:(NSMutableArray*)totalArray withArray:(NSArray*)jobs
{
    
    NSMutableArray *tempArray = [[NSMutableArray alloc]initWithCapacity:([totalArray count]+[jobs count])];
    
    int i = 0;
    
    int a = 0;
    int b = [totalArray count];
    int c = 0;
    int d = [jobs count];
    
    while(a<b && c<d){
        
        if(((Job*)[totalArray objectAtIndex:a]).idDb >= ((Job*)[jobs objectAtIndex:c]).idDb){
            if((i-1 < 0) || ((Job*)[totalArray objectAtIndex:a]).idDb != ((Job*)[tempArray objectAtIndex:i-1]).idDb){
                [tempArray insertObject:[totalArray objectAtIndex:a] atIndex:i];
                ++i;
            }
            ++a;
        }
        else{
            if((i-1 < 0) || ((Job*)[jobs objectAtIndex:c]).idDb != ((Job*)[tempArray objectAtIndex:i-1]).idDb){
                [tempArray insertObject:[jobs objectAtIndex:c] atIndex:i];
                ++i;
            }
            ++c;
        }
    }
    
    if(a < b) {
        for (int p = a; p < b; p++) {
            if((i-1 <0) || ((Job*)[totalArray objectAtIndex:p]).idDb != ((Job*)[tempArray objectAtIndex:i-1]).idDb){
                [tempArray insertObject: [totalArray objectAtIndex:p] atIndex:i];
                i++;
            }
        }
    } else {
        for (int p = c; p < d; p++) {
            if((i-1 <0) || ((Job*)[jobs objectAtIndex:p]).idDb != ((Job*)[tempArray objectAtIndex:i-1]).idDb){
                [tempArray insertObject: [jobs objectAtIndex:p] atIndex:i];
                i++;
            }
        }
    }
    
    
//    for(Job *j in tempArray)
//        NSLog(@"JOB ID = %d",j.idDb);
    
    [totalArray removeAllObjects];
    [totalArray addObjectsFromArray:tempArray];    
    [tempArray release];
}



-(void)dealloc{
    [kind release];
    [user release];
    [time release];
    [code release];
    [subtitle release];
    [title release];
    [field release];
    [date release];
    [address release];
    //[city release];
    [phone release];
    [phone2 release];
    [email release];
    [description release];
    [url release];
    url = nil;
    [super dealloc];
}

@end
