//
//  ViewController.m
//  PZFMDBHelper
//
//  Created by FanYuepan on 16/3/6.
//  Copyright © 2016年 fyp. All rights reserved.
//

#import "ViewController.h"
#import "PZDBModel.h"
#import "PZDBHelper.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *dict = [[PZFMDBUtil sharedUtil] pz_getClassPropertyWithClass:[PZDBModel class]];
    
    NSLog(@"%@",dict);
    
    NSArray *array  = [[PZFMDBUtil sharedUtil] pz_queryAllWithClass:[PZDBModel class]];
    NSLog(@"%@",array);
    PZDBModel *model = [[PZDBModel alloc] init];
    model.name = @"panzi";
    model.number = 12;
    [[PZFMDBUtil sharedUtil] pz_addDataWithModel:model];
//
//    PZDBModel *model1 = [[PZDBModel alloc] init];
//    model1.name = @"panzi";
//    model1.number = 13;
//    [[PZFMDBUtil sharedUtil] pz_addDataWithModel:model1];


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
