//
//  PZClassAnalysis.m
//  PZFMDBHelper
//
//  Created by FanYuepan on 16/3/6.
//  Copyright © 2016年 fyp. All rights reserved.
//

#import "PZClassAnalysis.h"
#import <objc/runtime.h>
#import "PZDBManager.h"

#define SQLTEXT @"TEXT"
#define SQLINTEGER @"INTEGER"
#define SQLREAL @"REAL"
#define SQLBLOB @"BLOB"
#define SQLNULL @"NULL"
#define PRIMARY_KEY @"primary key"

#define PRIMARY_ID @"unionId"

#define GlobalDBManager [PZDBManager manager]

static NSString *const propertyNameKey = @"PROPERTY_NAME";
static NSString *const propertyTypeKey = @"PROPERTY_TYPE";

@interface PZClassAnalysis(){
    NSCache *_cache;
}

@end

@implementation PZClassAnalysis

-(instancetype)init
{
    if (self = [super init]) {
        _cloumnsNotInDB = [NSArray array];
        _cache = [[NSCache alloc] init];
    }
    return self;
}

/*单例*/
+ (instancetype)sharedAnalysis
{
    static PZClassAnalysis *_instance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _instance = [[PZClassAnalysis alloc] init];
    });
    return _instance;
}

- (NSDictionary *)pz_getClassPropertyWithClass:(Class)c
{
    //存储列名和列类型的可变数组
    NSMutableArray *propertyNames = [NSMutableArray array];
    NSMutableArray *propertyTypes = [NSMutableArray array];
    
    unsigned int outCount,i;
    
    objc_property_t *properties = class_copyPropertyList(c, &outCount);
    
    //属性名称
    NSString *propertyName;
    NSString *propertyType;
    for (i = 0; i < outCount; i ++) {
        objc_property_t property = properties[i];
        propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        //将不需要的排除
        if ([_cloumnsNotInDB containsObject:propertyName]) {
            continue;
        }
        [propertyNames addObject:propertyName];
        //获取属性类型
        propertyType = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        
        if ([propertyType hasPrefix:@"T@"]) {
            [propertyTypes addObject:SQLTEXT];
        }else if ([propertyType hasPrefix:@"Ti"]||[propertyType hasPrefix:@"TI"]||[propertyType hasPrefix:@"Ts"]||[propertyType hasPrefix:@"TS"]||[propertyType hasPrefix:@"TB"]) {
            [propertyTypes addObject:SQLINTEGER];
        } else {
            [propertyTypes addObject:SQLREAL];
        }
    }
    free(properties);
    
    return  [NSDictionary dictionaryWithObjectsAndKeys:propertyNames,propertyNameKey,propertyTypes,propertyTypeKey, nil];
}

-(NSDictionary *)pz_getClassPropertyWithModel:(id)model
{
    if (model == nil) {
        return nil;
    }
    return [self pz_getClassPropertyWithClass:[model class]];
}

-(BOOL)addDataWithModel:(id)model
{
    NSString *insertSQL = [self pz_getInsertSQL:model];
    __block BOOL result = NO;
    
    //组成数值类型array
    NSDictionary *dict = [self pz_getClassPropertyWithModel:model];
    NSArray *columnNames = [dict objectForKey:propertyNameKey];
    NSMutableArray *valueArray = [NSMutableArray array];
    [columnNames enumerateObjectsUsingBlock:^(NSString *_cname, NSUInteger idx, BOOL * _Nonnull stop) {
        [valueArray addObject:[model valueForKey:_cname]];
    }];
    
    [GlobalDBManager.dbQueue inDatabase:^(FMDatabase *db) {
       result = [db executeUpdate:insertSQL withArgumentsInArray:valueArray];
    }];
    return  result;
}
#pragma mark 私有方法
-(NSString *)pz_getTableNameWithModel:(id)model
{
    NSString *tableName = NSStringFromClass([model class]);
//     NSString *tableNameCreateCacheKey = [NSString stringWithFormat:@"PZ_CACHE_CREATE_TABLE_%@",tableName];
    
    return tableName;
}

//获取插入的SQL语句，用NSCache缓存
-(NSString *)pz_getInsertSQL:(id)model
{
    NSString *tableName = [self pz_getTableNameWithModel:model];
    NSString *insertCacheKey =  [NSString stringWithFormat:@"PZ_CACHE_INSERTSQL_%@;",tableName];
    
    NSString *_insertSQL = [_cache objectForKey:insertCacheKey];
    if (_insertSQL) {
        NSLog(@"从缓存里获取insertSQL");
        return _insertSQL;
    }
    
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    
    NSDictionary *dict = [self pz_getClassPropertyWithModel:model];
    NSArray *columnNames = [dict objectForKey:propertyNameKey];
    
    //拼接字符串  insert into tablename (unionid,text1,text2) values (1,2,3);
    [columnNames enumerateObjectsUsingBlock:^(NSString *_cname, NSUInteger idx, BOOL * _Nonnull stop) {
        [keyString appendFormat:@"%@",_cname];
        [valueString appendString:@"?"];
        
        if (idx < columnNames.count - 1) {
            [keyString appendString:@","];
            [valueString appendString:@","];
        }
    }];
    _insertSQL = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)",tableName,keyString,valueString];
    
    [_cache setObject:_insertSQL forKey:insertCacheKey];
    
    return _insertSQL;
}

//获取更新的SQL语句，用NSCache缓存
-(NSString *)pz_getUpdateSQL:(id)model
{
    NSString *tableName = [self pz_getTableNameWithModel:model];
    NSString *updateCacheKey = [NSString stringWithFormat:@"PZ_CACHE_UPDATESQL_%@;",tableName];
    
    NSString *_updateSQL = [_cache objectForKey:updateCacheKey];
    if (_updateSQL) {
        NSLog(@"从缓存里获取updateSQL");
        return _updateSQL;
    }
    NSDictionary *dict = [self pz_getClassPropertyWithModel:model];
    NSArray *columnNames = [dict objectForKey:propertyNameKey];
    
    
    NSMutableString *keyString = [NSMutableString string];
    //拼接字符串  update tablename set a = 1,b=2,c=3,v=4 where unionid = 1
    [columnNames enumerateObjectsUsingBlock:^(NSString *_cname, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [keyString appendFormat:@"%@=?",_cname];
        
        if (idx < columnNames.count - 1) {
            [keyString appendString:@","];
        }
    }];
    _updateSQL = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ =?",tableName,keyString,PRIMARY_ID];
    
    [_cache setObject:_updateSQL forKey:updateCacheKey];
    
    return _updateSQL;

}

@end
