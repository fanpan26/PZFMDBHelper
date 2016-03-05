//
//  PZClassCache.m
//  PZFMDBHelper
//
//  Created by FanYuepan on 16/3/6.
//  Copyright © 2016年 fyp. All rights reserved.
//

#import "PZClassCache.h"

@implementation PZClassCache

+(instancetype)shareCache
{
    static PZClassCache *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance =  [[PZClassCache alloc] init];
    });
    return _instance;
}

-(NSString *)getInsertSQL:(NSString *)tableName
{
    return nil;
}

-(NSString *)getUpdateSQL:(NSString *)tableName
{
    return nil;
}

@end
