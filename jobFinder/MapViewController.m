//
//  MapViewController.m
//  jobFinder
//
//  Created by mario greco on 15/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIDevice+IdentifierAddition.h"
#import "MapViewController.h"
#import "InfoJobViewController.h"
#import "FavouriteAnnotation.h"
#import "DatabaseAccess.h"
#import "FilterViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MKMapView+Utils.h"
#import "Utilities.h"
#import "HelpViewController.h"

#define DEFAULT_COORDINATE -180
#define DEFAUlT_COORDINATE_0 0
#define scaleFactorLatitude   18.0    
#define scaleFactorLongitude  21.0
#define ZOOM_THRESHOLD 10 //=760567.187974
#define ZOOM_MAX 18
#define EPS 0.0000001

#pragma mark - Metodi e ivar private

/*Dichiaro property e metodi privati per il MapViewController
 */
@interface MapViewController()
@property(nonatomic, retain) NSString *filterBtnImgActive;
@property(nonatomic, retain) NSString *filterBtnImgNoactive;
@property(nonatomic,retain) NSArray *newJobs;
@property(nonatomic,retain) NSString *oldFieldsString;
@property(nonatomic,retain) NSString *oldKindOffer;
@property(nonatomic, assign) BOOL oldSwitch;
@property(nonatomic,retain) NSTimer *timer;
@property(nonatomic, assign) int oldZoom;
@property(nonatomic,retain) NSMutableArray *zoomBuffer;
@property(nonatomic,retain) NSMutableArray *annotationsBuffer;
-(void)filterOverThreshold:(NSArray *)newAnnotations;
-(void)filterUnderThreshold:(NSArray*)newAnnotations;
-(void)removeDuplicateAnnotations:(NSMutableArray*)newAnnotations;
-(void) dismissPublishView;
@end
//end

#pragma mark - Start Implementation

@implementation MapViewController 
//ivar pubbliche
@synthesize map, publishBtn,toolBar, refreshBtn, bookmarkButtonItem, filterButton, saveJobInPositionBtn, backBtn, jobToPublish;
//ivar private
@synthesize annotationsBuffer, zoomBuffer,oldZoom, timer, oldSwitch, oldFieldsString, newJobs, oldKindOffer;
@synthesize leftPanel, rightPanel, filterBtnImgActive,filterBtnImgNoactive;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
	    
	if (oldState == MKAnnotationViewDragStateDragging) {
        NSLog(@"DRAG PIN movmento");
    }
    else if(oldState == MKAnnotationViewDragStateEnding){
        NSLog(@"DRAG PIN FERMO");
        jobToPublish.address = NSLocalizedString(@"WAIT ADDR", @"");

        [geoDec searchAddressForCoordinate:[annotationView.annotation coordinate]];
    }
}


- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    /*attivo il pulsante refresh in base alla user location. Se la localizzazione è disabilitata dopo un po la userLocation assume i valori di default, quindi disattivo il pulsante.
     */
    if((userLocation.coordinate.latitude == DEFAULT_COORDINATE &&
       userLocation.coordinate.longitude == DEFAULT_COORDINATE) || 
        (userLocation.coordinate.latitude == DEFAUlT_COORDINATE_0 &&
         userLocation.coordinate.longitude == DEFAUlT_COORDINATE_0))
    {
        refreshBtn.enabled = NO;
    }
    else{
        refreshBtn.enabled = YES;
    }
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    
    // permette di zoomare sulla posizione dell'utente se gps attivo
    for (MKAnnotationView *annotationView in views) {
//        if (annotationView.annotation == mapView.userLocation) {
//            MKCoordinateSpan span = MKCoordinateSpanMake(0.215664, 0.227966);
//            MKCoordinateRegion region = MKCoordinateRegionMake(mapView.userLocation.coordinate, span);
//            [mapView setRegion:region animated:YES];
//        }
        //se il pin è draggabile --> viene mostrato con il callout già aperto
        if([annotationView.annotation isKindOfClass:[Job class]]){
            if(((Job*)annotationView.annotation).isDraggable){
                [mapView selectAnnotation:annotationView.annotation animated:YES];
            }
            else if(newJobs && [newJobs count] != 0 && 
                    [[newJobs objectAtIndex:0] intValue] == ((Job*)(annotationView.annotation)).idDb){
                
                [mapView selectAnnotation:annotationView.annotation animated:YES];
            }
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id )annotation
{    
    //se la annotation è la nostra posizione, ritorna annotationView standard
    if (annotation == mapView.userLocation) {
        [mapView.userLocation setTitle:NSLocalizedString(@"USER POSITION", @"")];
        return nil;
    }
    
    //se la annotatione è di tipo FavouriteAnnotation la creo e salvo 
    if([annotation isKindOfClass:[FavouriteAnnotation class]]){
                
        MKAnnotationView *favouritePinView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"favouritePin" ];
        if(favouritePinView == nil){
            favouritePinView = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"favouritePin"] autorelease];
        }
        
        favouritePinView.annotation = annotation;
        favouritePinView.tag = 122;
        favouritePinView.canShowCallout = YES;
        favouritePinView.image=[UIImage imageNamed:@"favPin.png"];

        return favouritePinView;
    }
    
    NSInteger annotationIndexInNewJobs = [self.newJobs indexOfObject:[NSNumber numberWithInt:((Job*)annotation).idDb]];
    
    NSString *identifier = ((Job*)annotation).kind;
    //NSLog(@"IDENTIFIER = %@",identifier);
    
    //se invece la annotation riguarda un lavoro creo e ritorno la annotationView dedicata
    MKPinAnnotationView* pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier ];
    
    //se non sono riuscito a riciclare un pin, lo creo
    if(pinView == nil){     
        
        pinView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier]autorelease];
        //setto colore, disclosure button ed animazione     
        pinView.canShowCallout = YES;
        pinView.animatesDrop = YES;
        
        //se annuncio è di tipo cerco associo una view persnalizzata
        if([identifier isEqualToString:@"Cerco"]){
            UIImage * image = [UIImage imageNamed:@"pinOrange.png"];
            UIImageView *imageView = [[[UIImageView alloc] initWithImage:image] autorelease];
            [pinView addSubview:imageView];
        }
        else{
            //altrimenti colore classico
            pinView.pinColor = MKPinAnnotationColorGreen;
        }
        
    }
    else{ 
        pinView.annotation = annotation;
    }
    
    //setto la proprietà draggable
    if(((Job*)annotation).isDraggable){
        
        //NSLog(@" IS DRAGGABLE");
        pinView.rightCalloutAccessoryView = nil;
        [pinView setDraggable:YES];
        pinView.pinColor = MKPinAnnotationColorRed;
    }
    else if(newJobs && annotationIndexInNewJobs != NSNotFound && [identifier isEqualToString:@"Offro"] ){
        pinView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [pinView setDraggable:NO];
        pinView.pinColor = MKPinAnnotationColorPurple;
    }
    else {
        //NSLog(@"IS NOT DRAGGABLE");
        pinView.pinColor = MKPinAnnotationColorGreen;
        pinView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [pinView setDraggable:NO];
    }
    
    return pinView;
}

//per gestire il tap sul disclosure
- (void)mapView:(MKMapView *)_mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    
    //carico la vista relativa al job
    
    if([((Job*)view.annotation).user isEqualToString:[[UIDevice currentDevice] uniqueDeviceIdentifier]]){
        PublishViewController *publishViewCtrl = [[PublishViewController alloc] initWithJob: view.annotation];
        publishViewCtrl.pwDelegate = self;
        
        [self presentModalViewController:publishViewCtrl animated:YES];
        [publishViewCtrl release];
    }
    else{
        InfoJobViewController *infoJobView = [[InfoJobViewController alloc] initWithJob: view.annotation];
        [self.navigationController pushViewController:infoJobView animated: YES];
        [infoJobView release];
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    //se c'è un pin draggabile sulla mappa non faccio fare letture dal db, risparmio un po di query
    if(!isDragPinOnMap){
        
        static int count = 0;        
        
        if(count == 0)
            ++count;
        else if(count == 1){
            //NSLog(@"QUERY");
            [timer invalidate];
            timer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(regionDidChange) userInfo:nil repeats:NO];
        }
    }
}

//gestisce le chiamate al db in base al cambio di region
- (void)regionDidChange
{   
    timer = nil;
          
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    //se c'è internet posso fare le query
    if([Utilities networkReachable]){
        
        //calcolo i rect delle regioni
        MKMapRect oldRect = [MKMapView mapRectForCoordinateRegion:oldRegion];
        MKMapRect newRect = [MKMapView mapRectForCoordinateRegion:map.region];
        MKMapRect newExtendedRect = [MKMapView mapRectForCoordinateRegion:map.region];  
        
        //ricalcolo il rect dell'attuale region per aumentarne le dimensioni e fare la query
        newExtendedRect.origin.x -= newExtendedRect.size.width / 2;
        newExtendedRect.origin.y -= newExtendedRect.size.height / 2;
        newExtendedRect.size.width *= 2;
        newExtendedRect.size.height *= 2;
        MKCoordinateRegion regionQuery = MKCoordinateRegionForMapRect(newExtendedRect);
        
        //in base a come effettuo lo zoom cambia il tipo di query
        
//        NSLog(@"CURRENT ZOOM LIVEL: %d", [map currentZoomLevel]);
//        NSLog(@"FABS %ef",fabs(newRect.size.width - oldRect.size.width));
        
    
        if([map currentZoomLevel] < ZOOM_THRESHOLD){
            //NSLog(@"PHP 1B");
            [dbAccess jobReadRequest:regionQuery field: [Utilities createFieldsString] kind: [prefs objectForKey:@"kindOfOffer"]?[prefs objectForKey:@"kindOfOffer"]:@"Offro"];
        }
        else
        {
            if(fabs((newRect.size.width - oldRect.size.width)) > EPS){
                //NSLog(@"PHP 1A");
                [dbAccess jobReadRequest:map.region field: [Utilities createFieldsString] kind: [prefs objectForKey:@"kindOfOffer"]?[prefs objectForKey:@"kindOfOffer"]:@"Offro"];
            }
            else{
               // NSLog(@"PHP 2");
                [dbAccess jobReadRequestOldRegion:oldRegion newRegion:map.region field:[Utilities createFieldsString] kind: [prefs objectForKey:@"kindOfOffer"]?[prefs objectForKey:@"kindOfOffer"]:@"Offro"];
            }
        }
    
    }
    else{
           //se non c'è internet mostro alert
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"NO NETWORK TITLE", @"") message: NSLocalizedString(@"NO NETWORK MEX", @"") delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
                [alert release];
    }
    
    if([map currentZoomLevel] < ZOOM_THRESHOLD)
        self.oldZoom = ZOOM_THRESHOLD-1;


    //aggiorno oldRegion con la region attuale
    oldRegion = map.region;

}


#pragma mark - Metodi per filtraggio e fitting delle Annotations

/*rimuove da newAnnotations le annotazioni già presenti sulla mappa
 */
-(void)removeDuplicateAnnotations:(NSMutableArray*)newAnnotations
{
    
    NSMutableArray * mapAnnotations = [map orderedMutableAnnotations];
    
    //elenco indici da eliminare da array
    NSInteger indexToDelete;
    NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc]init];
    
    
    //cerca tra le annotazioni della mappa quali annotationi di newAnnotations sono già presenti
    for(int i=0; i<newAnnotations.count;i++){
        indexToDelete = [Job jobBinarySearch:mapAnnotations withID: ((Job*)[newAnnotations objectAtIndex:i]).idDb];
        
        if(indexToDelete != -1)
            [indexes addIndex:i];               
    }
    
    [newAnnotations removeObjectsAtIndexes:indexes];
    [indexes release];
}


//filtro attivato se sto sotto il threshold
-(void)filterUnderThreshold:(NSMutableArray*)newAnnotations
{
    //le annotazioni della mappa ordinate
    NSMutableArray *mapAnn = [map orderedMutableAnnotations];
    
    /* annotationsBuffer contiene le annotazioni calcolate quando si va sotto lo zoom threshold.
     */
    
    //pulisco lo zoomBuffer se lo zoom scende sotto threshold
    if(self.oldZoom >= ZOOM_THRESHOLD){
        for(NSObject *array in zoomBuffer)
            [(NSMutableArray*)array removeAllObjects];
    }
        
    //rimuovo duplicati che sono tra newAnnotations e mapAnn
    NSMutableArray *newAnnotationNotInMap = [newAnnotations mutableCopy];
    [self removeDuplicateAnnotations:newAnnotationNotInMap];
    //aggiungo alla mappa 
    [map addAnnotations:newAnnotationNotInMap];
    // e li aggiungo al buffer
    [annotationsBuffer addObjectsFromArray:newAnnotationNotInMap];
    
    
    /*fa si che sulla mappa rimangano tutte e sole le annotazioni ritornate dal db (che sono più aggiornate). Di conseguenza se viene superata la soglia di zoom vengono tolte tutte quelle aggiunte dall'altra funzione di filtro
     */
            
    //fa si che sulla mappa siano presenti sempre le annotazioni nuove appena scaricate
    for(Job* an in mapAnn){
        //se an non trovato tra le nuove annotazioni lo rimuovo dalla mappa
        if([Job jobBinarySearch:newAnnotations withID:((Job*)an).idDb] == -1){
            [map removeAnnotation:an];
            [annotationsBuffer removeObject:an];
        }        
    }
        
    [newAnnotationNotInMap release];
}


/* filtro attivato se sto sopra il livello di threshold.
 * effettua il fitting delle annotations in base al livello di zoom e a dei fattori di scala
 */
-(void)filterOverThreshold:(NSMutableArray *)newAnnotations{
        
    NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc]init];
    float latDelta;
    float longDelta; 
    MKMapPoint center = [MKMapView centerPointForMapRect: [map visibleMapRect]];
    MKCoordinateRegion region;
    MKMapRect rect;    
    
    NSMutableArray *jobToShow=[[NSMutableArray alloc] initWithCapacity:0];
    
    
    //############# ZOOM OUT ################
    
    
    //se sto facendo zoom out
    if([map currentZoomLevel] > self.oldZoom){
        
        
        //controlla se si è superato il threshold ed elimina tutti i pin inseriti quando si stava sotto il livello threshold dalla mappa e dal buffer
        if(self.oldZoom < ZOOM_THRESHOLD){
            if(annotationsBuffer != nil){
                [map removeAnnotations:annotationsBuffer];
                [annotationsBuffer removeAllObjects];
            }
        }         
        
        //rimuovo per ogni livello di zoom tra 10 e 18 tutti i pin inseriti quando feci zoom in
        for(int i=MAX(ZOOM_THRESHOLD,self.oldZoom); i < [map currentZoomLevel]; i++){
            [map removeAnnotations: [zoomBuffer objectAtIndex:(i - ZOOM_THRESHOLD)]];
            [[zoomBuffer objectAtIndex:(i - ZOOM_THRESHOLD)] removeAllObjects];
        }
    }
    
    //############# ZOOM IN ################
    
    //se sto facendo zoom in o nn cambio livello di zoom.
    //calcola quali sono tra le newAnnotations quelle che non sono già sulla mappa
    [self removeDuplicateAnnotations:newAnnotations];
        
    
    //calcola per ogni livello di zoom ed in base al fattore di scala quante annotazioni vanno inserite sulla mappa (fitting)
    for(int j=ZOOM_MAX; j>= [map currentZoomLevel];j--){
        rect.size = [MKMapView mapRectSizeForZoom:j];
        rect.origin = [MKMapView rectOriginForCenter:center andSize:rect.size];
        region = MKCoordinateRegionForMapRect(rect);
        
        latDelta = region.span.latitudeDelta / scaleFactorLatitude;
        longDelta = region.span.longitudeDelta / scaleFactorLongitude;
        
        for (int i=0; i<[newAnnotations count]; i++) {
            Job *checkingAnnotation=[newAnnotations objectAtIndex:i];
            CLLocationDegrees latitude = [checkingAnnotation coordinate].latitude;
            CLLocationDegrees longitude = [checkingAnnotation coordinate].longitude;
            
            
            //se una nuova annotazione è troppo vicina a quelle da mostrare o a quelle presenti già sulla mappa la scarto
            bool found=FALSE;
            for (Job *tempPlacemark in jobToShow) {
                if(fabs([tempPlacemark coordinate].latitude-latitude) < latDelta &&
                   fabs([tempPlacemark coordinate].longitude-longitude) <longDelta ){
                    //[map removeAnnotation:checkingLocation];
                    found=TRUE;
                    break;
                }
            }
            if(!found){
                for (Job *tempPlacemark in [map annotations]) {
                    if (![tempPlacemark isKindOfClass:[Job class]] || tempPlacemark.isDraggable)
                        continue;
                    if(fabs([tempPlacemark coordinate].latitude-latitude) < latDelta &&
                       fabs([tempPlacemark coordinate].longitude-longitude) <longDelta ){
                        //[map removeAnnotation:checkingLocation];
                        found=TRUE;
                        break;
                    }
                }
            }
            
            //solo se non trovo un'annotazione troppo vicina ad un altra la aggiungo alla mappa e al buffer
            if (!found) {
                [jobToShow addObject:checkingAnnotation];
                //[map addAnnotation:checkingAnnotation];
                [[zoomBuffer objectAtIndex:(j - ZOOM_THRESHOLD)] addObject:checkingAnnotation];
                [indexes addIndex:i];
            }
            
        }
        
        //rimuovo annotazioni già processate
        [newAnnotations removeObjectsAtIndexes:indexes];
        [indexes removeAllIndexes];
    }
    //}
    
    
    [map addAnnotations:jobToShow];
    
    self.oldZoom = [map currentZoomLevel];
        
    [indexes release];
    [jobToShow release];
}

#pragma mark - GeodecoderDelegate

//date le coordinate del job cerca il relativo indirizzo e lo mostra nella tabella
-(void)didReceivedGeoDecoderData:(NSDictionary *)geoData
{
    NSString *address;
    
    NSLog(@"ricevuti dati geolog");
    
    if([[geoData objectForKey:@"status"] isEqualToString:@"OK"]){
        
        NSArray *resultsArray = [geoData objectForKey:@"results"];
        
        NSDictionary *data = [resultsArray objectAtIndex:0];
        //NSLog(@"DICTIONARY ESTRATTO \n :%@",[data objectForKey:@"address_components"]); //array
        //NSLog(@"CLASSE: %s", class_getName([[data objectForKey:@"address_components"] class]));
        
        NSArray *dataArray = [data objectForKey:@"address_components"];
        
        //    NSLog(@"CLASSE: %s", class_getName([[dataArray objectAtIndex:0] class]));
        //NSLog(@"DATA ARRAY: %@", [[dataArray objectAtIndex:0] objectForKey:@"long_name"]);// 0 = dizionario street number
        
        address = @""; //dove mettere "non disponibile" ?
        NSString *street;
        NSString *number;
        if(dataArray != nil && dataArray.count != 0){
            street = [[dataArray objectAtIndex:1] objectForKey:@"long_name"];
            number = [[dataArray objectAtIndex:0] objectForKey:@"long_name"];
        }
        //formatto la stringa address
        if(street != nil && !([street isEqualToString:@""])){
            address = [NSString stringWithFormat:@"%@", street];
            if( number != nil && !([number isEqualToString:@""]))
                address = [NSString stringWithFormat:@"%@, %@", address, number];
            
        }
        NSLog(@"ADDRESS = %@",address);
    }
    else{
        address = NSLocalizedString(@"NO ADDRESS", @"");
    }
    //aggiorno il callout
    //NSLog(@"INDIRIZZO CALCOLATO = %@",address);
    jobToPublish.address = address;
    [self.map deselectAnnotation:jobToPublish animated:NO];
    [self.map selectAnnotation:jobToPublish animated:NO];
    
    
    
}

#pragma mark - DatabaseAccessDelegate

/*riceve una lista dinuove annotazioni dal server
 */
-(void)didReceiveJobList:(NSArray *)jobList
{
    //NSLog(@"JOBLIST: %d",[jobList count]);
    if([jobList count] != 0){
        if([map currentZoomLevel] >= ZOOM_THRESHOLD) {
            [self filterOverThreshold:jobList];
        }
        else [self filterUnderThreshold:jobList];
    }    
}

-(void)didReceiveResponsFromServer:(NSString *)receivedData
{
    NSLog(@"RECEIVED DATA ORA: %@",receivedData);
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    UIAlertView *alert;
    alert = [[UIAlertView alloc]initWithTitle:nil message:nil delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    
    if([receivedData isEqualToString:@"Deleted"]){
        
        [alert setTitle:NSLocalizedString(@"OFFER DELETED TITLE", @"")];
        [alert setMessage:NSLocalizedString(@"OFFER DELETED MEX", @"")];

        [alert show];
    }
    else if([receivedData isEqualToString:@"Modified"]){
    
        [alert setTitle:NSLocalizedString(@"OFFER MODIFIED TITLE", @"")];
        [alert setMessage:NSLocalizedString(@"OFFER MODIFIED MEX", @"")];
        [alert show];
        [dbAccess jobReadRequest:map.region field:[Utilities createFieldsString] kind: [prefs objectForKey:@"kindOfOffer"]?[prefs objectForKey:@"kindOfOffer"]:@"Offro"];

    }
    else if([[receivedData substringWithRange:NSMakeRange(0,2)] isEqualToString:@"OK"]){
        if(jobToPublish != nil){
            jobToPublish.idDb = [[receivedData substringFromIndex:2] intValue];
            jobToPublish.isDraggable = NO;
            [map addAnnotation:jobToPublish];
        }

    }
    else{
        [alert setTitle:NSLocalizedString(@"NETWORK ERROR TITLE", @"")];
        [alert setMessage:NSLocalizedString(@"NETWORK ERROR MEX", @"")];
        [alert show];
    }

    [alert release];
}

#pragma mark - gestione click bottoni e view

-(void)setNewPins:(NSArray *)pins{
    
    if(pins == nil && newJobs != nil){
                
        NSMutableArray * mapJobAnn = [map orderedMutableAnnotations];
        
        for(int i = 0; i < [self.newJobs count]; i++){
            int index = [Job jobBinarySearch:mapJobAnn withID:[[self.newJobs objectAtIndex:i] intValue]];
            
            if(index != -1 ){
                [map removeAnnotation: [mapJobAnn objectAtIndex:index]];
            }
        }
        self.newJobs = nil;    
        
        return;
    }
    
    
    
    NSMutableArray *temp =[[NSMutableArray alloc] initWithCapacity:[pins count]];

    for(int i = 0; i < [pins count]; i++){
        [temp insertObject: [NSNumber numberWithInt:[[pins objectAtIndex:i] intValue]] atIndex:i];
    }
    self.newJobs = temp;
    
    NSMutableArray * mapJobAnn = [map orderedMutableAnnotations];
    for(int i = 0; i < [pins count]; i++){
        int index = [Job jobBinarySearch:mapJobAnn withID:[[pins objectAtIndex:i] intValue]];
        
        if(index != -1 ){
            [map removeAnnotation: [mapJobAnn objectAtIndex:index]];
        }
    }
    
    [temp release];
}

//mostra la barra con i pulsanti per inserimento di un nuovo job
-(IBAction)publishBtnClicked:(id)sender 
{    
    if([Utilities networkReachable]){
        CLLocationCoordinate2D coordinate;
        
        //controllo se gps spento
        if((map.userLocation.coordinate.latitude == DEFAULT_COORDINATE && map.userLocation.coordinate.longitude == DEFAULT_COORDINATE) ||
           (map.userLocation.coordinate.latitude == DEFAUlT_COORDINATE_0 && map.userLocation.coordinate.longitude == DEFAUlT_COORDINATE_0))
        {
            
            //TODO: mostrare avviso che gps spento 
            //setta le coordinate del punto draggabile come quelle del centro della region attuale
            coordinate = CLLocationCoordinate2DMake(map.region.center.latitude,map.region.center.longitude);
        }
        else{
            //setta coordinate del punto draggabile come quelle della user location
            coordinate = CLLocationCoordinate2DMake(map.userLocation.coordinate.latitude,map.userLocation.coordinate.longitude);
        }
        
        //alloco il job da pubblicare
        self.jobToPublish = [[[Job alloc] initWithCoordinate:coordinate] autorelease];
        [geoDec searchAddressForCoordinate:coordinate];
        
        if(jobToPublish != nil){
            
            //così il pin sarà draggabile
            jobToPublish.isDraggable = YES;
            jobToPublish.address = NSLocalizedString(@"WAIT ADDR", @"");
            //aggiungo annotazione alla mappa
            [map addAnnotation:jobToPublish];
            //segnalo che c'è un pin draggabile sulla mappa
            isDragPinOnMap = YES;
            
            //sposta la vista nella region in cui è stato inserito il pin
            MKCoordinateSpan span = MKCoordinateSpanMake(0.017731, 0.01820);
            MKCoordinateRegion region = MKCoordinateRegionMake(coordinate,span);
            [map setRegion:region animated:YES];
            
            
            /*se è stato inserito un pin draggabile disattivo il tasto segnala ed attivo quello per il salvataggio del job nella posizione scelta
             */
            if(isDragPinOnMap){
                publishBtn.enabled = NO;
                //publishBtn.userInteractionEnabled = NO;
                saveJobInPositionBtn.enabled = YES;
            }
            
            //mostro il left panel
            
            leftPanel.frame = CGRectMake(0-leftPanel.frame.size.width, map.frame.size.height - leftPanel.frame.size.height,self.leftPanel.frame.size.width,leftPanel.frame.size.height);
            [self.map addSubview:leftPanel];
            rightPanel.frame = CGRectMake(self.map.frame.size.width, map.frame.size.height - rightPanel.frame.size.height,self.rightPanel.frame.size.width,rightPanel.frame.size.height);
            [self.map addSubview:rightPanel];
            
            //NSLog(@"LEFT PANEL x=%f, y=%f, w=%f,h=%f",leftPanel.frame.origin.x,leftPanel.frame.origin.y,leftPanel.frame.size.width,leftPanel.frame.size.height);
            [UIView animateWithDuration:.5
                            animations:^{
                                    rightPanel.frame = CGRectMake(self.map.frame.size.width - rightPanel.frame.size.width,map.frame.size.height - rightPanel.frame.size.height , self.rightPanel.frame.size.width, rightPanel.frame.size.height);
                                    leftPanel.frame = CGRectMake(leftPanel.frame.origin.x+leftPanel.frame.size.width,map.frame.size.height - leftPanel.frame.size.height , self.leftPanel.frame.size.width, leftPanel.frame.size.height);
                            }
             ];
            
        }
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NO NETWORK TITLE", @"") message:NSLocalizedString(@"NO NETWORK MEX", @"") delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        [alert release];
        
    }
}

//carica la view per inserimento dati del job in maniera modale
-(IBAction)saveNewJobInPositionBtnClicked:(id)sender
{
    PublishViewController *publishViewCtrl = [[PublishViewController alloc]initWithStandardRootViewController];
    publishViewCtrl.pwDelegate = self;
    //passo in avanti il puntatore a jobToPublish
    publishViewCtrl.theNewJob = jobToPublish;
    [self presentModalViewController:publishViewCtrl animated:YES];
    [publishViewCtrl release];
}

//carica la view per la configurazione dell'app
-(IBAction)configBtnClicked:(id)sender
{
    
    InformationSectionViewController *infoView = [[InformationSectionViewController alloc] initWithNibName:@"InformationSectionViewController" bundle:nil];
    [infoView setDelegate:self];
    //animazione e push della view
    [self.navigationController pushViewController:infoView animated:YES];  
    
    [infoView release];
    
}

//mostra la posizione attuale dell'utente
-(IBAction) showUserLocationButtonClicked:(id)sender
{ 
    if(refreshBtn.enabled){
        //riposiziona la region alla userLocation
        MKCoordinateSpan span = MKCoordinateSpanMake(0.017731, 0.01820);
        MKCoordinateRegion region = MKCoordinateRegionMake(map.userLocation.coordinate, span);
        [map setRegion:region animated:YES];
    }
}

//mostra la regione in cui si trova la zona preferita scelta dall'utente
-(IBAction)bookmarkBtnClicked:(id)sender
{
    if(favouriteAnnotation == nil){
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PREF ZONE AD", @"") message:nil delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
    }
    
    else if(favouriteAnnotation != nil &&
       favouriteAnnotation.coordinate.latitude != 0 &&
       favouriteAnnotation.coordinate.longitude != 0){
        
        MKCoordinateSpan span = MKCoordinateSpanMake(0.215664, 0.227966);
        MKCoordinateRegion region = MKCoordinateRegionMake(favouriteAnnotation.coordinate, span);
        [map setRegion:region animated:YES];
    }
}


-(IBAction)backBtnClicked:(id)sender
{      
    [UIView animateWithDuration:.5
                     animations:^{
                         //nascondo rightPanel con animazione
                         rightPanel.frame = CGRectMake(self.rightPanel.frame.origin.x + rightPanel.frame.size.width,map.frame.size.height - rightPanel.frame.size.height , self.rightPanel.frame.size.width, rightPanel.frame.size.height);
                         leftPanel.frame = CGRectMake(self.leftPanel.frame.origin.x-leftPanel.frame.size.width,map.frame.size.height - leftPanel.frame.size.height , self.leftPanel.frame.size.width, leftPanel.frame.size.height);
                     }
     ];
    
    //rimuovo il pin draggabile dalla mappa
    if(jobToPublish != nil && jobToPublish.isDraggable == YES)
        [map removeAnnotation:jobToPublish];
    
    //segnalo che non ci sono pin draggabili sulla mappa
    isDragPinOnMap = NO;
    
    [map removeAnnotations:[map jobAnnotations]];
    [dbAccess jobReadRequest:map.region field:[Utilities createFieldsString] kind: [[NSUserDefaults standardUserDefaults] objectForKey:@"kindOfOffer"]?[[NSUserDefaults standardUserDefaults] objectForKey:@"kindOfOffer"]:@"Offro"];
    
    //riabilito il pulsante segnala
    publishBtn.enabled = YES;

}

//mostra la vista per filtrare i settori di lavoro
-(IBAction)filterBtnClicked:(id)sender
{
    FilterViewController *filterTable = [[FilterViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:filterTable animated:YES];
    [filterTable release];
}

-(void)onConnectionRestored{
    [dbAccess jobReadRequest:map.region field:[Utilities createFieldsString] kind: [[NSUserDefaults standardUserDefaults] objectForKey:@"kindOfOffer"]?[[NSUserDefaults standardUserDefaults] objectForKey:@"kindOfOffer"]:@"Offro"];
}

#pragma mark - PublishViewControllerDelegate

-(void)didDelJob:(Job *)theNewJob{
    
    //NSLog(@"MAP THE NEW JOB ID %d", theNewJob.idDb);
    
    [dbAccess jobDelRequest:theNewJob];
    
    if(theNewJob)
        [map removeAnnotation:theNewJob];
    
    [self dismissPublishView];
}

-(void)didModifiedJob:(Job *)theNewJob
{    
    //richiedo scrittura su db dei dati
    [dbAccess jobModRequest:theNewJob];
    if(theNewJob)
        [map removeAnnotation:theNewJob];
    [self dismissPublishView];
}

/*richiamato dalla view modale dopo il click su inserisci. spedisce i dati sul db
 */
-(void)didInsertNewJob:(Job *)theNewJob
{    
    //segnala che non ci sono pin draggabili sulla mappa
    isDragPinOnMap = NO; 
    //disabilita pulsante per salvare la posizione del job
    saveJobInPositionBtn.enabled = NO;
    //il pin del job segnalato non deve essere più draggabile
    jobToPublish.isDraggable = NO;
    
    

    //richiedo scrittura su db dei dati
    [dbAccess jobWriteRequest:jobToPublish];
    
    //rimuovo il pin rosso e metto quello verde (da drag a noDrag)
    if(jobToPublish != nil){
        [map removeAnnotation:jobToPublish];
        //[map addAnnotation:jobToPublish];
        //faccio partire una query per far caricare il nuovo job sulla mappa
        //[dbAccess jobReadRequest:map.region field:[Utilities createFieldsString]];
    }
    
    //rimuovo left e rightPanel
    [UIView animateWithDuration:.5
                     animations:^{
                         //nascondo rightPanel con animazione
                         rightPanel.frame = CGRectMake(self.rightPanel.frame.origin.x + rightPanel.frame.size.width,map.frame.size.height - rightPanel.frame.size.height , self.rightPanel.frame.size.width, rightPanel.frame.size.height);
                         leftPanel.frame = CGRectMake(self.leftPanel.frame.origin.x-leftPanel.frame.size.width,map.frame.size.height - leftPanel.frame.size.height , self.leftPanel.frame.size.width, leftPanel.frame.size.height);
                     }
     
     ];
    
    //riattivo pulsante segnalazione
    publishBtn.enabled = YES;
    
    [self dismissPublishView]; 
     
}

//rimuove il pin rosso dalla mappa se si è scelto di annullare la creazione
-(void) didCancelNewJob:(PublishViewController *)viewController
{
    //se l'operazione di inserimento è annullata il pin draggabile sarà eliminato dalla mappa
    [self backBtnClicked:self];
    
    [self dismissPublishView];
}


//dismette la modal view
-(void) dismissPublishView
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - InformationSectionViewControllerDelegate

//gestisce il pin relativo all'annotation favourite
-(void)didSelectedFavouriteZone:(CLLocationCoordinate2D)coordinate
{
    //rimuovo la vecchia annotation preferita
    if(favouriteAnnotation != nil){
        [map removeAnnotation:favouriteAnnotation];
    }
    //aggiungo la nuova
    favouriteAnnotation = [[[FavouriteAnnotation alloc]initWithCoordinate:coordinate] autorelease];
    [map addAnnotation:favouriteAnnotation];
}

#pragma  mark - View lyfe cicle

-(void) refreshViewMap
{
    NSLog(@"REFRESH MAP view");
    [self bookmarkBtnClicked:self];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //serve per riabilitare il tasto refreshBtn dopo un memory warning
    if((map.userLocation.coordinate.latitude == DEFAULT_COORDINATE &&
        map.userLocation.coordinate.longitude == DEFAULT_COORDINATE) || 
       (map.userLocation.coordinate.latitude == DEFAUlT_COORDINATE_0 &&
        map.userLocation.coordinate.longitude == DEFAUlT_COORDINATE_0))
    {
        refreshBtn.enabled = NO;
    }
    else{
        refreshBtn.enabled = YES;
    }

     
    //setto il colore del tasto di filtro per segnalare se l'utente ha il filtro su on od off
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSLog(@"OLD KIND OFFER = %@", oldKindOffer);
    //se cambio il tipo di filtro sul tipo di annuncio cancello i pin
    if(([[prefs objectForKey:@"kindOfOffer"] isEqualToString:@"Offro"] && [oldKindOffer isEqualToString:@"Cerco"]) ||
       ([[prefs objectForKey:@"kindOfOffer"] isEqualToString:@"Cerco"] && ([oldKindOffer isEqualToString:@"Offro"] || oldKindOffer == nil))){
        [map removeAnnotations:[map jobAnnotations]];
        [dbAccess jobReadRequest:map.region field:[Utilities createFieldsString] kind: [prefs objectForKey:@"kindOfOffer"]?[prefs objectForKey:@"kindOfOffer"]:@"Offro"];
    }
    
    //gestisco alla comparsa della view come settare il tasto per il filtro e come effettuare le query
        
    if(  [prefs boolForKey:@"switch"]){
        [filterButton setImage:[UIImage imageNamed:filterBtnImgActive]];
        if(oldSwitch == FALSE){
            [map removeAnnotations:[map jobAnnotations]];
            [dbAccess jobReadRequest:map.region field:[Utilities createFieldsString] kind: [prefs objectForKey:@"kindOfOffer"]?[prefs objectForKey:@"kindOfOffer"]:@"Offro"];
        }
        else if(![oldFieldsString isEqualToString:[Utilities createFieldsString]]){
            [map removeAnnotations:[map jobAnnotations]];
            [dbAccess jobReadRequest:map.region field:[Utilities createFieldsString] kind: [prefs objectForKey:@"kindOfOffer"]?[prefs objectForKey:@"kindOfOffer"]:@"Offro"];
        }
    }
    else{
        if(oldSwitch == TRUE){
            [filterButton setImage:[UIImage imageNamed:filterBtnImgNoactive]];
            [dbAccess jobReadRequest:map.region field:[Utilities createFieldsString] kind: [prefs objectForKey:@"kindOfOffer"]?[prefs objectForKey:@"kindOfOffer"]:@"Offro"];
        }
    }
    
    
    //sono cambiate le impostazioni del filtro lancio query per cambiare dati sul db
    //le lancio sia quando cambio settori per "cerca" sia per "offro"
    if(! [oldFieldsString isEqualToString:[Utilities createFieldsString]]){
        
        //NSLog(@"CAMBIATE LE PREFERENZE NEL FILTRO: %@ -> settori = %@",[prefs objectForKey:@"kindOfOffer"], [Utilities createFieldsString]);
                                                        
         ((jobFinderAppDelegate*)[[UIApplication sharedApplication] delegate]).typeRequest = @"fieldsChanged";
        #if !TARGET_IPHONE_SIMULATOR
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge];
        #endif    
    }
    
    oldKindOffer = [prefs objectForKey:@"kindOfOffer"];
    oldSwitch = [prefs boolForKey:@"switch"];
    self.oldFieldsString = [Utilities createFieldsString];
    //NSLog(@"selected cells = %@",[prefs objectForKey:@"selectedCells"]);
}

- (void)viewDidLoad
{
    // Do any additional setup after loading the view from its nib.
    [super viewDidLoad];
    
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
        
    if([language isEqualToString:@"it"]){
        filterBtnImgActive = @"filtroAttivo.png";
        filterBtnImgNoactive = @"filtroDisattivato.png";
    }
    else{
        filterBtnImgActive = @"filterActive.png";
        filterBtnImgNoactive = @"filterDeactive.png";
    }
    
    //per il geocodinge e revers geocoding
    geoDec = [[GeoDecoder alloc] init];
    [geoDec setDelegate:self];
    
    /*Inizializzazione proprietà mapView
     */
    self.oldZoom = 18; //max zoom
    
    /*Aggiungo le subViews alla mappa
     */
//    leftPanel.frame = CGRectMake(0-leftPanel.frame.size.width, map.frame.size.height - leftPanel.frame.size.height,self.leftPanel.frame.size.width,leftPanel.frame.size.height);
//    [self.map addSubview:leftPanel];
//    rightPanel.frame = CGRectMake(self.map.frame.size.width, map.frame.size.height - rightPanel.frame.size.height,self.rightPanel.frame.size.width,rightPanel.frame.size.height);
//    [self.map addSubview:rightPanel];
    
    
    /*inizializzo i buffer per lo zoom e per le annotazioni
     */
    //buffer di annotazioni aggiunte sotto la soglia di zoom 10
    annotationsBuffer = [[NSMutableArray alloc] init];
    
    //buffer composto da nove sotto array che contengono le annotazioni aggiunte ad ogni livello di zoom sopra la soglia 10
    zoomBuffer = [[NSMutableArray alloc] initWithCapacity:11];
    for(int i=0;i<11;i++)
        [zoomBuffer insertObject:[[[NSMutableArray alloc]init]autorelease] atIndex:i];  
   
    /*inizializzazione pulsanti view
     */
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        if(result.height == 480)
        {
            // iPhone Classic
        }
        if(result.height == 568)
        {
            [publishBtn setFrame:CGRectMake(112,self.view.frame.size.height - 55, 97, 53)];
        }
    }
    
    //aggiungo bottone Info alla navigation bar
    UIButton *tempInfoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[tempInfoButton addTarget:self action:@selector(configBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    infoBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:tempInfoButton];
	self.navigationItem.leftBarButtonItem = infoBarButtonItem;
      
    //tasto refresh è disabilitato di default
    refreshBtn.enabled = NO;
    //tasto publishAlternativeBtn è disabilitato di default
    saveJobInPositionBtn.enabled = NO;
    
    /* configurazione pulsanti della view
     */
        
    [publishBtn setTitle:NSLocalizedString(@"PUBLISH BTN TITLE",@"") forState:UIControlStateNormal];
    [publishBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [publishBtn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [publishBtn setTitleEdgeInsets:UIEdgeInsetsMake(28.0, 0.0, 0.0, 0.0 )];
    publishBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    
    //[filterButton setImage:[UIImage imageNamed:@"filtroDisattivato.png"]];


    //[publishBtn setBackgroundImage:[UIImage imageNamed:@"insertJobButtonDisabled.png"] forState:UIControlStateDisabled];
    //[bookmarkButtonItem setImage:[UIImage imageNamed:@"starBookmark.png"]];
    
    /* Gestione delle configurazioni preferite dell'utente
     */
    //recupero le coordinate preferite all'avvio dell'app ed aggiungo la relativa annotation
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if([prefs objectForKey: @"lat"] != nil && [prefs objectForKey: @"long"] != nil){
        CLLocationCoordinate2D favouriteCoord = CLLocationCoordinate2DMake([[prefs objectForKey:@"lat"] doubleValue], [[prefs objectForKey:@"long"] doubleValue]);
        //creo ed aggiungo l'annotatione alla mappa
        favouriteAnnotation = [[[FavouriteAnnotation alloc] initWithCoordinate:favouriteCoord] autorelease];
        //        if([prefs objectForKey:@"address"] != nil)
        //            favouriteAnnotation.address = [prefs objectForKey:@"address"];
        [map addAnnotation:favouriteAnnotation];   
        
    } 
    
    if(  [prefs boolForKey:@"switch"]){
        [filterButton setImage:[UIImage imageNamed:filterBtnImgActive]];
    }
    else{
        //NSLog(@"MAP LOAD SWITCH off = %p",[UIImage imageNamed:@"filtroDisattivato.png"]);
        [filterButton setImage:[UIImage imageNamed:filterBtnImgNoactive]];
    }
    
    /* Inizializzazione valori booleani per la classe
     */
    //di default i pin non possono esser "draggabili"
    isDragPinOnMap = NO;

    /*Inizializzazione proprietà filtro settori
     */
    oldSwitch = [prefs boolForKey:@"switch"];
    self.oldFieldsString = [Utilities createFieldsString];
    oldKindOffer = [prefs objectForKey:@"kindOfOffer"];
    
    /* inizializzazione classi ausiliarie necessarie al map view controller
     */
    //alloco l'istanza per accesso al database
    dbAccess = [[DatabaseAccess alloc] init];
    [dbAccess setDelegate:self];
   
}

- (void)viewDidUnload
{    
    NSLog(@"MAPCONTROLLER DID UNLOAD");
    
    self.backBtn = nil;
    self.saveJobInPositionBtn = nil;
    self.map = nil;
    self.toolBar = nil;
    //self.filterButton = nil;
    self.publishBtn = nil;
    self.refreshBtn = nil;
    self.bookmarkButtonItem = nil;
    [infoBarButtonItem release];
    infoBarButtonItem = nil;
    
    [zoomBuffer release];
    zoomBuffer = nil;
    [annotationsBuffer release];
    annotationsBuffer = nil;
//    [dbAccess release];
//    dbAccess = nil;
    
    newJobs = nil;
    
    self.rightPanel = nil;
    self.leftPanel = nil;
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


#pragma mark - memory management

- (void)dealloc
{
    self.filterBtnImgNoactive = nil;
    self.filterBtnImgActive = nil;
    [rightPanel release];
    [leftPanel release];
    [geoDec release];
    [oldKindOffer release];
    [newJobs release];
    [jobToPublish release], jobToPublish = nil;
    [filterButton release];
    [favouriteAnnotation release];
    [map release];
    [toolBar release];  
    [refreshBtn release]; 
    [infoBarButtonItem release];
    [publishBtn release];
    [dbAccess release];
    [annotationsBuffer release];
    [zoomBuffer release];
    [super dealloc];
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}



@end
