//
//  PZClassAnalysis.m
//  PZFMDBHelper
//
//  Created by FanYuepan on 16/3/6.
//  Copyright © 2016年 fyp. All rights reserved.
//

#import "PZFMDBUtil.h"
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

@interface PZFMDBUtil(){
    NSCache *_cache;
}

@end

@implementation PZFMDBUtil

-(instancetype)init
{
    if (self = [super init]) {
        _cloumnsNotInDB = [NSArray array];
        _cache = [[NSCache alloc] init];
    }
    return self;
}

/*单例*/
+ (instancetype)sharedUtil
{
    static PZFMDBUtil *_instance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _instance = [[PZFMDBUtil alloc] init];
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

-(BOOL)pz_addDataWithModel:(id)model
{
    NSString *insertSQL = [self pz_getInsertSQL:model];
    __block BOOL result = NO;
    
    //组成数值类型array
    NSDictionary *dict = [self pz_getClassPropertyWithModel:model];
    NSArray *columnNames = [dict objectForKey:propertyNameKey];
    NSMutableArray *valueArray = [NSMutableArray array];
    [columnNames enumerateObjectsUsingBlock:^(NSString *_cname, NSUInteger idx, BOOL * _Nonnull stop) {
        id val = [model valueForKey:_cname];
        if (!val) {
            val  = @"";
        }
        [valueArray addObject:val];
    }];
    
    [GlobalDBManager.dbQueue inDatabase:^(FMDatabase *db) {
       result = [db executeUpdate:insertSQL withArgumentsInArray:valueArray];
    }];
    if(result){
        NSLog(@"插入成功");
    }else{
        NSLog(@"插入失败");
    }
    return  result;
}
#pragma mark 私有方法
-(NSString *)pz_getTableNameWithModel:(id)model
{
    return [self pz_getTableNameWithClass:[model class]];
}

-(NSString *)pz_getTableNameWithClass:(Class)c
{
    return NSStringFromClass(c);
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

/*获取键值对  unionid  text */
-(NSString *)getTypeAndColumnStringWithClass:(Class)c orName:(NSString *)name
{
    NSMutableString *typeColumnString = [NSMutableString string];
    if (name) {
        if (!c) {
            c = NSClassFromString(name);
        }
    }
    NSDictionary *nameAndTypes = [self pz_getClassPropertyWithClass:c];
    
    NSArray *names = [nameAndTypes objectForKey:propertyNameKey];
    NSArray *types = [nameAndTypes objectForKey:propertyTypeKey];
    [names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *type = [types objectAtIndex:idx];
        
        [typeColumnString appendFormat:@"%@ %@",name,type];
        if (idx < names.count - 1) {
            [typeColumnString appendString:@","];
        }
    }];
    
    NSLog(@"typeColumnString 为：%@",typeColumnString);
    
    return typeColumnString;
}


-(BOOL)createTableWithClasses:(NSArray *)classes
{
    
    NSMutableArray *nameArrary = [NSMutableArray array];
    [classes enumerateObjectsUsingBlock:^(Class obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [nameArrary addObject:NSStringFromClass(obj)];
    }];
    return  [self createTableWithNames:[nameArrary copy]];
}

-(BOOL)createTableWithNames:(NSArray *)names recreate:(BOOL)recreate
{
    return [self createTableWithNames:names];
}

-(BOOL)createTableWithNames:(NSArray *)names
{
    if (names.count == 0 ||names == nil) {
        return  NO;
    }
    __block BOOL result = YES;
    [GlobalDBManager.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        [names enumerateObjectsUsingBlock:^(NSString *n, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSString *columnAndType = [self getTypeAndColumnStringWithClass:nil orName:n];
            NSString *createTableSQL = [NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@ (%@);",n,columnAndType];
            NSLog(@"创建Table的语句：%@",createTableSQL);
            if (![db executeUpdate:createTableSQL]) {
                result  = NO;
                *rollback = YES;
                return ;
            }

        }];
    }];
    return result;
}

//更新Model
- (BOOL)pz_updateDataWithModel:(id)model andCondition:(NSString *)condition{
    NSString *updateSQL = [self pz_getUpdateSQL:model];
    
    NSMutableArray *arguments = [NSMutableArray array];
    
    NSArray *columns = [[self pz_getClassPropertyWithModel:model] objectForKey:propertyNameKey];
    [columns enumerateObjectsUsingBlock:^(NSString *_name, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *val = [model valueForKey:_name];
        if (val == nil) {
            val  = @"";
        }
        [arguments addObject:val];
    }];
    
    __block BOOL result = NO;
    [GlobalDBManager.dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:updateSQL withArgumentsInArray:arguments];
    }];
    return  result;
}


- (BOOL)pz_updateDataWithModel:(id)model andPrimaryKey:(NSString *)primaryKey{
    id val = [model objectForKey:primaryKey];
    if (val == nil) {
        return NO;
    }
    NSString *condition = [NSString stringWithFormat:@"%@=%@",primaryKey,val];
    return [self pz_updateDataWithModel:model andCondition:condition];
}
//删除model
- (BOOL)pz_deleteDataWithModel:(id)model andCondition:(NSString *)condition{
    
    NSString *tableName = [self pz_getTableNameWithModel:model];
    NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@",tableName,condition];
    __block BOOL result = NO;
    [GlobalDBManager.dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:deleteSQL];
    }];
    return  result;
}

- (BOOL)pz_deleteDataWithModel:(id)model andPrimaryKey:(NSString *)primaryKey{
    id val = [model objectForKey:primaryKey];
    if (val == nil) {
        return NO;
    }
    NSString *condition = [NSString stringWithFormat:@"%@=%@",primaryKey,val];
    return [self pz_deleteDataWithModel:model andCondition:condition];
}
//查询
-(NSArray *)pz_queryDataWithClass:(Class)c andCondition:(NSString *)condition{return  nil;}

-(id)pz_queryDataWithClass:(Class)c
             andPrimaryKey:(NSString *)primaryKey
           andPrimaryValue:(NSString *)primaryValue{return  nil;}
//查询
-(NSArray *)pz_queryAllWithClass:(Class)c{
    NSString *tableName = [self pz_getTableNameWithClass:c];
    NSString *querySQL = [NSString stringWithFormat: @"SELECT * FROM %@ ",tableName];
    NSDictionary *dict = [self pz_getClassPropertyWithClass:c];
    NSArray *columns = [dict objectForKey:propertyNameKey];
    NSArray *types = [dict objectForKey:propertyTypeKey];
    
    NSMutableArray *results = [NSMutableArray array];
    [GlobalDBManager.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *result = [db executeQuery:querySQL];
        while ([result next]) {
            id model = [[c alloc] init];
            [columns enumerateObjectsUsingBlock:^(NSString *_name, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *t = [types objectAtIndex:idx];
                if ([t isEqualToString:SQLTEXT]) {
                    [model setValue:[result stringForColumn:_name] forKey:_name];
                }else
                if ([t isEqualToString:SQLREAL]) {
                    [model setValue:@([result doubleForColumn:_name]) forKey:_name];
                }else
                if ([t isEqualToString:SQLINTEGER]) {
                    [model setValue:@([result intForColumn:_name]) forKey:_name];
                }else
                if ([t isEqualToString:SQLNULL]) {
                    //[model setValue:@"" forKey:_name];
                }
            }];
            [results addObject:model];
        }
    }];
    return [results copy];
}



@end
