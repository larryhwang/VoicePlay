//
//  InterfaceController.m
//  Steps Extension
//
//  Created by Larry on 17/3/11.
//  Copyright © 2017年 Larry. All rights reserved.
//

#import "InterfaceController.h"
#import "TableCell.h"

#define kCellType @"cell"
#import <WatchConnectivity/WatchConnectivity.h>

@interface InterfaceController()<WCSessionDelegate>{
      WCSession * session;
}

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *table;
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    session = [WCSession defaultSession];
    session.delegate = self;
    [session activateSession];

}
- (IBAction)CLICK {
    
    //1,32342|2,24223|3,12323|

    NSLog(@"WATCH_DATA:%@",session.receivedApplicationContext[@"name"]);
    //分离数据成为数组
    
    NSString *tempALl = session.receivedApplicationContext[@"name"];
    
    NSArray *arr = [tempALl componentsSeparatedByString:@"|"];
    
    [_table setNumberOfRows:arr.count withRowType:kCellType];
    
    for (int  i =0; arr.count>i; i++) {
        NSString *tmp = arr[i];
        NSArray  *arr = [tmp componentsSeparatedByString:@","];
        TableCell *row = [_table rowControllerAtIndex:i];
        [row.NoLable setText:arr[0]];
        [row.DDLable setText:arr[1]];
    }

    
    
    
    
   

}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



