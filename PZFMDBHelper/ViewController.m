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
    
    NSDictionary *dictionary = [[PZClassAnalysis sharedAnalysis] pz_getClassPropertyWithClass:[UITableView class]];
    /*
     "PROPERTY_NAME" =     (
     name,
     age,
     number,
     address
     );
     "PROPERTY_TYPE" =     (
     TEXT,
     REAL,
     REAL,
     TEXT
     );
     */
    NSLog(@"%@",dictionary);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
