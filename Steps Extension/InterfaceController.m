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

@interface InterfaceController()
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *table;
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    
    [_table setNumberOfRows:12 withRowType:kCellType];
    
    for (int i = 0; i < 12; i++) {
        
        TableCell *row = [_table rowControllerAtIndex:i];
        //  [row.DDLable setText:[_counties objectAtIndex:i]];
        [row.DDLable setText:@"13,22314"];
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



