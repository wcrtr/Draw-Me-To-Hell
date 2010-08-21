//
//  DriveMeToHellViewController.m
//  DriveMeToHell
//
//  Created by William Carter on 8/20/10.
//  Copyright Nodesnoop LLC 2010. All rights reserved.
//

#import "DriveMeToHellViewController.h"
#import "SBJSON.h"

#define kDirectionsRequested 0
#define kDirectionsProcessing 1
#define kDirectionsLoaded 2

@implementation DriveMeToHellViewController

@synthesize mapView = _mapView;


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {

	state = kDirectionsRequested;
	[_mapView setDelegate:self];
	[_mapView setMapType:MKMapTypeHybrid];
	[_mapView setShowsUserLocation:YES];
    [super viewDidLoad];
}


/*
 ASIHTTPRequest Delgates
*/

- (void)requestFinished:(ASIHTTPRequest *)request
{
	points = [[NSMutableArray alloc] init];
	SBJSON *json = [SBJSON new];
	NSString *responseString = [request responseString];
	NSLog(@"%@",responseString);
	
	NSDictionary *obj = [json objectWithString:responseString];
	
	NSLog(@"status: %@", [obj objectForKey:@"status"]);
	
	NSArray *routes = [obj objectForKey:@"routes"];
	NSDictionary *route = [routes objectAtIndex:0];
	NSArray *legs = [route objectForKey:@"legs"];
	for(NSDictionary *leg in legs) {
		NSArray *steps = [leg objectForKey:@"steps"];
		for(NSDictionary *step in steps) {
			NSDictionary *polyline = [step objectForKey:@"polyline"];
			//NSLog(@"%@",[polyline objectForKey:@"points"]);
			NSArray *pnts = [self decodePolyLine:[NSMutableString stringWithString:[polyline objectForKey:@"points"]]];
			[points addObject:pnts];
			[pnts release];
		}
	}
	
	NSMutableArray *allpoints = [[NSMutableArray alloc] init];
	
	for(NSArray *polyline in points) {
		
		for (int i=0; i<[polyline count]; i++) {
			CLLocation *l = (CLLocation*)[polyline objectAtIndex:i];
			[allpoints addObject:l];
		}
	}
	
	MKMapPoint northEastPoint;
	MKMapPoint southWestPoint;	
	
	CLLocationCoordinate2D* coordArr = malloc(sizeof(CLLocationCoordinate2D) * [allpoints count]);
	
	int i = 0;
	for(CLLocation *polyline in allpoints) {
		
		coordArr[i] = polyline.coordinate;
		MKMapPoint point = MKMapPointForCoordinate(polyline.coordinate);
		
		if (i == 0) {
			northEastPoint = point;
			southWestPoint = point;
		} else {
			if (point.x > northEastPoint.x)
				northEastPoint.x = point.x;
			if(point.y > northEastPoint.y)
				northEastPoint.y = point.y;
			if (point.x < southWestPoint.x)
				southWestPoint.x = point.x;
			if (point.y < southWestPoint.y)
				southWestPoint.y = point.y;
		}
		i++;
	}
	
	MKPolyline *line = [MKPolyline polylineWithCoordinates:coordArr count:[allpoints count]];
	[self.mapView addOverlay:line];
	free(coordArr);
	
	MKMapRect _routeRect = MKMapRectMake(southWestPoint.x, 
										 southWestPoint.y, 
										 northEastPoint.x - southWestPoint.x, 
										 northEastPoint.y - southWestPoint.y);
	
	[self.mapView setVisibleMapRect:_routeRect];
	
	state = kDirectionsLoaded;
	
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	NSLog(@"error: %@", [error localizedDescription]);
}

/*
 Mapview delegates
*/

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    CLLocation *location = userLocation.location;
    if (location) {
		
		if(state == kDirectionsRequested) {
			
			NSString *origin = [NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude];
			NSString *destination = @"Hell,CA";
			NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com/maps/api/directions/json?origin=%@&destination=%@&sensor=true",origin,destination];
			NSURL *url = [NSURL URLWithString:urlString];
			ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
			[request setDelegate:self];
			[request startAsynchronous];
			state = kDirectionsProcessing;
			
		}
    }
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
	NSLog(@"loaded");
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay
{
	
	MKOverlayView* overlayView = nil;

	MKPolylineView *routeLineView = [[[MKPolylineView alloc] initWithPolyline:overlay] autorelease];
	routeLineView.fillColor = [UIColor redColor];
	routeLineView.strokeColor = [UIColor redColor];
	routeLineView.lineWidth = 3;
	overlayView = routeLineView;

	
	return overlayView;
	
}



/*
Decoding the polyline
Courtesy fkn1337, who is TEH 1337. lol. http://fkn1337.com/
*/

-(NSMutableArray *)decodePolyLine: (NSMutableString *)encoded {
	[encoded replaceOccurrencesOfString:@"\\\\" withString:@"\\"
								options:NSLiteralSearch
								  range:NSMakeRange(0, [encoded length])];
	NSInteger len = [encoded length];
	NSInteger index = 0;
	NSMutableArray *array = [[NSMutableArray alloc] init];
	NSInteger lat=0;
	NSInteger lng=0;
	while (index < len) {
		NSInteger b;
		NSInteger shift = 0;
		NSInteger result = 0;
		do {
			b = [encoded characterAtIndex:index++] - 63;
			result |= (b & 0x1f) << shift;
			shift += 5;
		} while (b >= 0x20);
		NSInteger dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
		lat += dlat;
		shift = 0;
		result = 0;
		do {
			b = [encoded characterAtIndex:index++] - 63;
			result |= (b & 0x1f) << shift;
			shift += 5;
		} while (b >= 0x20);
		NSInteger dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
		lng += dlng;
		NSNumber *latitude = [[NSNumber alloc] initWithFloat:lat * 1e-5];
		NSNumber *longitude = [[NSNumber alloc] initWithFloat:lng * 1e-5];
		CLLocation *loc = [[CLLocation alloc] initWithLatitude:[latitude floatValue] longitude:[longitude floatValue]];
		[array addObject:loc];
		//NSLog(@"%f,%f",[latitude floatValue],[longitude floatValue]);
		[loc release];
		[latitude release];
		[longitude release];
	}
	return array;
}


/*
 Memory Management
*/


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
