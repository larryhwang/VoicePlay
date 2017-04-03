//
//  TableCell.h
//  WatchDemo
//
//  Created by AbooJan on 15/8/14.
//  Copyright © 2015年 AbooJan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface TableCell : NSObject

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *DDLable;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *NoLable;

@end
