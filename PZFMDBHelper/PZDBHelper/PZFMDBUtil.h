//
//  PZClassAnalysis.h
//  PZFMDBHelper
//
//  Created by FanYuepan on 16/3/6.
//  Copyright © 2016年 fyp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PZFMDBUtil : NSObject

@property(nonatomic,strong) NSArray *cloumnsNotInDB;

+ (instancetype)sharedUtil;

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

//添加一条Model
- (BOOL)pz_addDataWithModel:(id)model;
//更新Model
- (BOOL)pz_updateDataWithModel:(id)model andCondition:(NSString *)condition;

- (BOOL)pz_updateDataWithModel:(id)model andPrimaryKey:(NSString *)primaryKey;
//删除model
- (BOOL)pz_deleteDataWithModel:(id)model andCondition:(NSString *)condition;

- (BOOL)pz_deleteDataWithModel:(id)model andPrimaryKey:(NSString *)primaryKey;
//查询
-(NSArray *)pz_queryDataWithClass:(Class)c andCondition:(NSString *)condition;

-(id)pz_queryDataWithClass:(Class)c
                     andPrimaryKey:(NSString *)primaryKey
                     andPrimaryValue:(NSString *)primaryValue;

-(NSArray *)pz_queryAllWithClass:(Class)c;
@end
