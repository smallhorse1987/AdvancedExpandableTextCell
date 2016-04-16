//
//  ViewController.m
//  AdvancedExpandableTextCellExample
//
//  Created by chen xiaosong on 16/4/16.
//  Copyright © 2016年 chen xiaosong. All rights reserved.
//

#import "ViewController.h"

#import "AdvancedExpandableTextCell.h"

@interface ViewController ()<AdvancedExpandableTableViewDelegate, UITableViewDataSource>
{
    CGFloat textCellHeight;
    IBOutlet UITableView *tableV;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        //创建并设置可自撑开的文字输入框
        AdvancedExpandableTextCell *textCell = [tableView advancedExpandableTextCellWithId:@"kExpandableTextCell"];

        textCell.placeholder = @"请输入文字";
        textCell.maxCharacter = 1000;

        return textCell;
    } else if (indexPath.row == 1) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:@"kSimpleTable"];
        
        cell.textLabel.text = @"我就是来占一个单元行的";
        
        return cell;
    }

    return nil;
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return MAX(50.0, textCellHeight);
    }else {
        return 44.0;
    }
}

- (void)tableView:(UITableView *)tableView updatedHeight:(CGFloat)height atIndexPath:(NSIndexPath *)indexPath
{
    textCellHeight = height;
}

- (void)tableView:(UITableView *)tableView updatedText:(NSString *)text atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"debug : updatedText\n%@", text);
}


@end
