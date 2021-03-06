//
//  MapViewController.h
//  jobFinder
//
//  Created by mario greco on 15/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MapKit/MKAnnotation.h>
#import "PublishViewController.h"
#import "Job.h"
#import "FavouriteAnnotation.h"
#import "DatabaseAccess.h"
#import "InformationSectionViewController.h"
#import "GeoDecoder.h"
#import "FilterOfferView.h"
#import "PullableView.h"

@interface MapViewController : UIViewController <PublishViewControllerDelegate,  MKMapViewDelegate, DatabaseAccessDelegate,InformationSectionViewControllerDelegate,GeoDecoderDelegate, FilterOfferViewDelegate, PullableViewDelegate>{
    
    MKMapView *map;
    UIToolbar *toolBar;  
    UIButton *publishBtn;
    UIButton *refreshBtn;
    UIBarButtonItem *infoBarButtonItem;
    UIBarButtonItem *filterButton;
    UIButton *bookmarkButtonItem;
    Job *jobToPublish;
    UIButton *saveJobInPositionBtn;
    UIButton *backBtn;
    
    FavouriteAnnotation *favouriteAnnotation;
        
    BOOL isDragPinOnMap;

    DatabaseAccess *dbAccess;
      
    MKCoordinateRegion oldRegion;
    
    GeoDecoder *geoDec;
    
}
@property(nonatomic, retain)Job *jobToPublish;
@property(nonatomic, retain) IBOutlet UIButton *backBtn;
@property(nonatomic, retain) IBOutlet UIButton *saveJobInPositionBtn;
@property(nonatomic, retain) IBOutlet MKMapView *map;
@property(nonatomic, retain) IBOutlet UIToolbar *toolBar;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *filterButton;
@property(nonatomic, retain) IBOutlet UIButton *publishBtn;
@property(nonatomic, retain) IBOutlet UIButton *refreshBtn;
@property(nonatomic, retain) IBOutlet UIButton *bookmarkButtonItem;
@property(nonatomic, retain) IBOutlet UIView *leftPanel;
@property(nonatomic, retain) IBOutlet UIView *rightPanel;

-(void)setNewPins:(NSArray*)pins;
-(void)onConnectionRestored;
-(IBAction)publishBtnClicked:(id)sender;
-(IBAction)saveNewJobInPositionBtnClicked:(id)sender;
-(IBAction)bookmarkBtnClicked:(id)sender;
-(IBAction)configBtnClicked:(id)sender;
-(IBAction)showUserLocationButtonClicked:(id)sender;
-(IBAction)backBtnClicked:(id)sender;
-(IBAction)filterBtnClicked:(id)sender;
-(IBAction) refreshViewMap;
//-(void)launchTourMessage:(id)sender;

@end

