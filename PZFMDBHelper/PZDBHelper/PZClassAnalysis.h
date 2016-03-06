//
//  PZClassAnalysis.h
//  PZFMDBHelper
//
//  Created by FanYuepan on 16/3/6.
//  Copyright © 2016年 fyp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PZClassAnalysis : NSObject

@property(nonatomic,strong) NSArray *cloumnsNotInDB;

+ (instancetype)sharedAnalysis;

//是否覆盖原有的表，会删除以前的数据
-(BOOL)createTableWithNames:(NSArray *)names recreate:(BOOL)recreate;
//创建table
-(BOOL)createTableWithClasses:(NSArray *)classes;
//创建table 只执行一次
-(BOOL)createTableWithNames:(NSArray *)names;

/*分析类名列名和列类型*/
- (NSDictionary *)pz_getClassPropertyWithClass:(Class)c;
/*根据model分析列名和类型*/
- (NSDictionary *)pz_getClassPropertyWithModel:(id)model;
//
- (BOOL)pz_addDataWithModel:(id)model;
@end
