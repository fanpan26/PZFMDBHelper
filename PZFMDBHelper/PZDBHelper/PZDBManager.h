//
//  PZLocalDBManager.h
//  FMDBDemo
//
//  Created by FanYuepan on 16/3/3.
//  Copyright © 2016年 fyp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

@interface PZDBManager : NSObject

@property(nonatomic,retain,readonly) FMDatabaseQueue *dbQueue;

+(instancetype) manager;

+(NSString *)dbPath;


@end
