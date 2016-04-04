//
//  InterfaceController.m
//  TheTicker Extension
//
//  Created by Pete Shanahan on 02/04/2016.
//  Copyright © 2016 Pete Shanahan. All rights reserved.
//

#import "InterfaceController.h"
#import <HealthKit/HealthKit.h>

@interface InterfaceController()

@property (weak) IBOutlet WKInterfaceLabel *theLabel;

@property HKHealthStore *healthStore;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (NSSet *)typesToWrite {
    return [[NSSet alloc] init];
}
- (NSSet *)typesToRead {
    return [NSSet setWithObjects:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate], nil];
}

- (void)updateResult:(NSArray *)results {
    //HKQuantityType *heartbeat = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    if (!results) {
        NSLog(@"Failed to read results");
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (HKQuantitySample *result in results) {
                double d = [result.quantity doubleValueForUnit:[HKUnit unitFromString:@"count/s"]];
                [self.theLabel setText:[NSString stringWithFormat:@"%f", d * 60]];
            }
        });
    }
}

- (void)updateHeartBeat {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
//    NSDateComponents *components = [calendar
//                                    components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
//                                    fromDate:now];
    NSDate *startDate = [calendar dateByAddingUnit:NSCalendarUnitDay
                                             value:-1 toDate:now
                                           options:0];
    NSPredicate *pred = [HKQuery predicateForSamplesWithStartDate:startDate
                                                          endDate:now
                                                          options:HKQueryOptionNone];
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                           predicate:pred
                                                               limit:1
                                                     sortDescriptors:nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                          [self updateResult:results];
                                                      }];
    [self.healthStore executeQuery:query];
}

- (IBAction)buttonPressed:(id)sender {
    if ([HKHealthStore isHealthDataAvailable] && !self.healthStore) {
        self.healthStore = [[HKHealthStore alloc] init];
    }
    if (self.healthStore != nil) {
        [self.healthStore requestAuthorizationToShareTypes:[self typesToWrite]
                                                 readTypes:[self typesToRead]
         completion:^(BOOL success, NSError * _Nullable error) {
             if (!success) {
                 NSLog(@"Failed to get permission");
             } else {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self updateHeartBeat];
                 });
             }
         }];
    }
}

@end



