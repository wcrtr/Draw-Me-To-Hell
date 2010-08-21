//
//  DriveMeToHellViewController.h
//  DriveMeToHell
//
//  Created by William Carter on 8/20/10.
//  Copyright Nodesnoop LLC 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "ASIHTTPRequest.h"

@interface DriveMeToHellViewController : UIViewController <MKMapViewDelegate, ASIHTTPRequestDelegate> {

	IBOutlet MKMapView *_mapView;
	int state;
	NSMutableArray *points;

	
}

@property (nonatomic,retain) IBOutlet MKMapView *mapView;
-(NSMutableArray *)decodePolyLine: (NSMutableString *)encoded;

@end

