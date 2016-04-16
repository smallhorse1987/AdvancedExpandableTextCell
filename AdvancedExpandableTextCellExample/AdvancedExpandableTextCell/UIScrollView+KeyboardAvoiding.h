//
//  UIScrollView+KeyboardAvoiding.h
//  formKeyboard
//
//  Created by chen xiaosong on 16/4/12.
//  Copyright © 2016年 chen xiaosong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScrollView(KeyboardAvoiding)

- (void)KeyboardAvoiding_keyboardWillShow:(NSNotification*)notification;
- (void)KeyboardAvoiding_keyboardWillHide:(NSNotification*)notification;

- (void)KeyboardAvoiding_caretPostionChanged;

@end
