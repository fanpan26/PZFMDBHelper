//
//  PZClassCache.h
//  PZFMDBHelper
//
//  Created by FanYuepan on 16/3/6.
//  Copyright © 2016年 fyp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PZClassCache : NSObject

+(instancetype)shareCache;

//获取更新SQL语句
-(NSString *)getUpdateSQL:(NSString *)tableName;
//获取插入SQL语句
-(NSString *)getInsertSQL:(NSString *)tableName;

@end
