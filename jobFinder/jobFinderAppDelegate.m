//
//  jobFinderAppDelegate.m
//  jobFinder
//
//  Created by mario greco on 15/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "jobFinderAppDelegate.h"
#import "CoreLocation/CoreLocation.h"
#import "DatabaseAccess.h"
#import "Utilities.h"
#import "Reachability.h"
#import "MapViewController.h"
#import "InfoJobViewController.h"
#import "FBConnect.h"
#import "Flurry.h"

@implementation jobFinderAppDelegate

@synthesize window = _window;
@synthesize navController, mapController, facebook,typeRequest;

-(void) redirectNSLogToDocuments {
    NSArray *allPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDIR = [allPaths objectAtIndex:0];
    NSString *pathForLog = [documentsDIR stringByAppendingPathComponent:@"LOG.txt"];
    freopen([pathForLog cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Flurry startSession:@"428W4PRBV7F3THWRBNM8"];
    
    self.window.rootViewController = self.navController;
    
    // Override point for customization after application launch.
    [self.window makeKeyAndVisible];
    
    tokenSended = NO;
    typeRequest = @"flush";
    
    //############# controlla se i servizi di localizzazione sono attivi #################
    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"GPS non attivo" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil,nil];
    
    if([CLLocationManager locationServicesEnabled]){
        
        if ([CLLocationManager respondsToSelector:@selector(authorizationStatus)]){
            if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
                //NSLog(@"PRIMO");
                //[alert show];
            }
        }
    }  
    else{
        //NSLog(@"SECONDO");
        //[alert show];
    }
        
    //[alert release];
    
    
    //################ controlla presenza rete al primo avvio dell'app ###################
    
//    if(![Utilities networkReachable]){
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Per favore controlla le impostazioni di rete e riprova" message:@"Impossibile collegarsi ad internet" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
//        [alert show];
//        [alert release];
//    }
    
    
    //per controllare quando cambia stato connessione
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
    reachability = [[Reachability reachabilityForInternetConnection] retain];         
    [reachability startNotifier];       
    
    
    //FACEBOOK
    // Set i permessi di accesso
    permissions = [[NSArray arrayWithObjects:@"publish_stream", nil] retain];
    
    // Set the Facebook object we declared. We’ll use the declared object from the application
    // delegate.
    facebook = [[Facebook alloc] initWithAppId:@"175161829247160" andDelegate:self];
    
    //redirect console output su file di log
    //[self redirectNSLogToDocuments];

    
    //per gestire arrivo notifica push quando app è not running
    
    if (launchOptions != nil)
	{
		NSDictionary* dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
		if (dictionary != nil)
		{
            //per dire al server che la zona pref e il fields sono gli stessi di prima
            typeRequest = @"same";
			//NSLog(@"Launched from push notification in didFinishLaunching: %@", dictionary);
			[self.mapController setNewPins:[dictionary objectForKey:@"jobs"]];
            [self.mapController refreshViewMap];
		}
	}
    
    //spostato qui sotto perchè quando ci sono notifiche push e l'app non è in mem, veniva fatto il flush sul server, e quindi venivano ricaricati in job_for_user i lavori già notificati? 
    //###############   registrazione device a notifiche push #######################
#if !TARGET_IPHONE_SIMULATOR
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge];
#endif
    
    // Clear application badge when app launches
    application.applicationIconBadgeNumber = 0;
    
    //[self.mapController launchTourMessage:nil];

      
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{    
    
    //NSLog(@"DID ENTER BACK");
    [self.mapController setNewPins:nil];
    
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //query
    [mapController onConnectionRestored];
    
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{     
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    //We are unable to make a internet connection at this time. Some functionality will be limited until a connection is made.
    
    //controlla tra le impostazioni dell'iphone se l'app ha le notifiche attive
    UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    if (types == UIRemoteNotificationTypeNone) 
        NSLog(@"push disabilitate");
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

#pragma mark - Metodi per gestire le push notification

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken{
    
    //prima di inviare i dati sul server controlla la presenza della zona preferita
    
    NSString* newToken = [devToken description];
	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    //NSLog(@"DID REGISTER: \nIl token è %@, ed è lungo %d", newToken, [newToken length]);

    //se c'è connessione internet
    if([Utilities networkReachable]){
            
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];    
        //NSLog(@"pefs lat = %f, long = %f", [[pref objectForKey:@"lat"] doubleValue],[[pref objectForKey:@"long"] doubleValue]);
        
        //se coordinate sono settate e token è valido
        if([pref objectForKey: @"lat"] != nil &&
           [pref objectForKey: @"long"] != nil &&
           ![newToken isEqualToString:@""]){
            
            //NSLog(@" APP DELEGATE : preferito settato");
            DatabaseAccess *dbAccess = [[DatabaseAccess alloc] init];
            [dbAccess setDelegate:self];
            [dbAccess registerDevice:newToken typeRequest:typeRequest];
            [dbAccess release];
        }
        else{
            
            //NSLog(@" APP DELEGATE : nessun preferito");
            tokenSended = NO;
        }
    }
    else{
        //NSLog(@"INTERNET NN DISPONIBILE : TOKEN NN INVIATO");
        tokenSended = NO;
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)err{
    
    NSLog(@"%@, %@, %@", [err localizedDescription], [err localizedFailureReason], [err localizedRecoverySuggestion]);
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{    
    [self.mapController setNewPins:[userInfo objectForKey:@"jobs"]];
    //apre la mappa nella posizione preferita dopo la ricezione di una push
    [self.mapController refreshViewMap];
    
    //NSLog(@" é STATA RICEVUTA UNA PUSH NOTF = %@",[userInfo objectForKey:@"jobs"]);
    
}


//si accorge se cambia stato connessione, e se il token non è stato ancora inviato lo invia sul db
- (void) reachabilityChanged:(NSNotification *)notice
{  
//    NSLog(@"################");
//    NSLog(@"HANDLE NETWORK: CHANGE");
    
    NetworkStatus remoteStatus = [reachability currentReachabilityStatus];  
    
    //se internet è raggiungibile e il token non è stato ancora inviato
    if(remoteStatus != NotReachable){
        [mapController onConnectionRestored];
    }
    else if(remoteStatus != NotReachable && !tokenSended){
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
       
        if([pref objectForKey: @"lat"] != nil &&
           [pref objectForKey: @"long"] != nil) {
            
            //NSLog(@" APP DELEGATE : preferito settato");
        #if !TARGET_IPHONE_SIMULATOR
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge];
        #endif
        }
        else{
            //NSLog(@" APP DELEGATE : nessun preferito");        
            tokenSended = NO;
        }
    }

} 

#pragma mark - DatabaseAccessDelegate

- (void) didReceiveResponsFromServer:(NSString *)receivedData {
    //NSLog(@"%s", [receivedData UTF8String]);
    
    //se scrittura su db è andata a buon fine
    if([receivedData isEqualToString:@"OK"]){
        tokenSended = YES;
       // NSLog(@"token inviato");
    }
    else{
        tokenSended = NO;
        //NSLog(@"TOKEN NN INVIATO");
    }
}

#pragma mark - FacebookSessionDelegate

// Pre 4.2 support
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {

    return [facebook handleOpenURL:url]; 
}

// For 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    return [facebook handleOpenURL:url]; 
}

-(void)checkForPreviouslySavedAccessTokenInfo{
    // Initially set the isConnected value to NO.
    //isConnected = NO;
    
    // Check if there is a previous access token key in the user defaults file.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"] &&
        [defaults objectForKey:@"FBExpirationDateKey"]) {
        facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
//        NSLog(@"APP DELEGATE: expirationDate = %@",facebook.expirationDate);       
        // Check if the facebook session is valid.
        // If it’s not valid clear any authorization and mark the status as not connected.
        if (![facebook isSessionValid]) {
            //[facebook authorize:nil];
//            NSLog(@"APP DELEGATE: SESSIONE NN VALIDA");
            [facebook logout:self];
            //isConnected = NO;
        }
        else {
//            NSLog(@"APP DELEGATE: SESSIONE VALIDA");
            //isConnected = YES;
        }
    }
}

-(void)logIntoFacebook
{
    [facebook authorize:permissions];
}

#pragma mark - FBSessionDelegate
-(void)fbDidLogin{
    //salva valori di accesso e sessione
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
       
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FBdidLogin" object:nil];
}

-(void)fbDidNotLogin:(BOOL)cancelled{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FBerrLogin" object:nil];
}

-(void)fbDidLogout{
    // Keep this for testing purposes.
    
    //nascondo tasto logout
    
    // Remove saved authorization information if it exists
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"]) {
        [defaults removeObjectForKey:@"FBAccessTokenKey"];
        [defaults removeObjectForKey:@"FBExpirationDateKey"];
        [defaults synchronize];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FBdidLogout" object:nil];
    //[self.navigationItem setRightBarButtonItem:nil animated:YES];
}


#pragma mark - memory management

- (void)dealloc
{   
    [typeRequest release];
    [facebook release];
    [permissions release];
    [reachability release];
    [navController release];
    [_window release];
    [super dealloc];
}

@end
