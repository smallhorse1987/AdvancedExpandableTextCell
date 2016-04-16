//
//  UIScrollView+KeyboardAvoiding.m
//  formKeyboard
//
//  Created by chen xiaosong on 16/4/12.
//  Copyright © 2016年 chen xiaosong. All rights reserved.
//

#import "UIScrollView+KeyboardAvoiding.h"

#import "SZTextView.h"

#import <objc/runtime.h>

static const int kStateKey;

@interface KeyboardAvoidingState : NSObject
@property (nonatomic, assign) UIEdgeInsets priorInset;
@property (nonatomic, assign) BOOL         keyboardVisible;
@property (nonatomic, assign) CGRect       keyboardRect;
@property (nonatomic, assign) BOOL         keyboardAnimationInProgress;
@end

@implementation KeyboardAvoidingState
@end

@implementation UIScrollView(KeyboardAvoiding)

- (KeyboardAvoidingState*)keyboardAvoidingState {
    KeyboardAvoidingState *state = objc_getAssociatedObject(self, &kStateKey);
    if ( !state ) {
        state = [[KeyboardAvoidingState alloc] init];
        objc_setAssociatedObject(self, &kStateKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
#if !__has_feature(objc_arc)
        [state release];
#endif
    }
    return state;
}

- (void)KeyboardAvoiding_keyboardWillShow:(NSNotification*)notification
{
    CGRect keyboardEndRect = [[notification.userInfo objectForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    CGRect keyboardBeginRect = [[notification.userInfo objectForKey:@"UIKeyboardFrameBeginUserInfoKey"] CGRectValue];
    
    if (keyboardEndRect.origin.y >= keyboardBeginRect.origin.y) {
        return;
    }
 
    KeyboardAvoidingState *state = [self keyboardAvoidingState];
    
    if (state.keyboardVisible)
        return;
 
    state.priorInset = self.contentInset;

    state.keyboardVisible = YES;
    
    state.keyboardRect = keyboardEndRect;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [UIView beginAnimations:nil context:NULL];
        
        [UIView setAnimationDelegate:self];
        [UIView setAnimationWillStartSelector:@selector(keyboardViewAppear:context:)];
        [UIView setAnimationDidStopSelector:@selector(keyboardViewDisappear:finished:context:)];
        
        [UIView setAnimationCurve:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
        [UIView setAnimationDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];

        self.contentInset = [self KeyboardAvoiding_contentInsetForKeyboard];
        
        [self setContentOffset:CGPointMake(self.contentOffset.x,[self KeyboardAvoiding_idealOffsetForView])
                      animated:NO];

        
        [self layoutIfNeeded];
        
        [UIView commitAnimations];
    });

}

- (void)KeyboardAvoiding_keyboardWillHide:(NSNotification*)notification
{
    CGRect keyboardEndRect = [[notification.userInfo objectForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    CGRect keyboardBeginRect = [[notification.userInfo objectForKey:@"UIKeyboardFrameBeginUserInfoKey"] CGRectValue];
    
    if (keyboardEndRect.origin.y <= keyboardBeginRect.origin.y) {
        return;
    }

    if (self.keyboardAvoidingState.keyboardAnimationInProgress) {
        return;
    }
    
    KeyboardAvoidingState *state = [self keyboardAvoidingState];
    
    if (!state.keyboardVisible)
        return;

    state.keyboardVisible = NO;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [UIView beginAnimations:nil context:NULL];

        [UIView setAnimationCurve:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
        [UIView setAnimationDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];

        self.contentInset = state.priorInset;
        
        [self layoutIfNeeded];

        [UIView commitAnimations];
    });

}

- (void)KeyboardAvoiding_caretPostionChanged
{
    
    CGFloat desiredOffsetY = [self KeyboardAvoiding_adjustOffsetForView];
    
    if(desiredOffsetY != self.contentOffset.y)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [UIView beginAnimations:nil context:NULL];
            
            [self setContentOffset:CGPointMake(self.contentOffset.x, desiredOffsetY) animated:NO];
            
            [self layoutIfNeeded];
            
            [UIView commitAnimations];
        });
        
    } else {

    }

}

- (void)keyboardViewAppear:(NSString *)animationID context:(void *)context {
    self.keyboardAvoidingState.keyboardAnimationInProgress = true;
}

- (void)keyboardViewDisappear:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
    if (finished) {
        self.keyboardAvoidingState.keyboardAnimationInProgress = false;
    }
}

- (UIEdgeInsets)KeyboardAvoiding_contentInsetForKeyboard {
    KeyboardAvoidingState *state = self.keyboardAvoidingState;
    UIEdgeInsets newInset = self.contentInset;
    CGRect keyboardRect = state.keyboardRect;
    newInset.bottom = keyboardRect.size.height;// - MAX((CGRectGetMaxY(keyboardRect) - CGRectGetMaxY(self.bounds)), 0);
    return newInset;
}

- (CGFloat)KeyboardAvoiding_adjustOffsetForView
{
    //有几种情况
    //1，尽量保证有上边距，但又不能显示上面的单元
    //2，尽量保证有下边距，但又不能显示下面的单元
    CGFloat insetTop = self.contentInset.top;
    CGFloat offsetY = self.contentOffset.y;
    
    UITextView *textInput = (UITextView*)[self KeyboardAvoiding_findFirstResponderBeneathView:self];
    CGRect textInputRect = [textInput convertRect:textInput.bounds toView:self];
    
    CGFloat viewableHeight = self.bounds.size.height - self.contentInset.top - self.contentInset.bottom;
    
    //获取caret在scrollview中的位置
    UITextPosition *caretPosition = [textInput selectedTextRange].start;
    CGRect caretTextInputRect = [textInput caretRectForPosition:caretPosition];
    CGRect caretRect = [self convertRect:caretTextInputRect fromView:textInput];
    
    if (textInputRect.size.height <= viewableHeight) {
        offsetY = textInputRect.origin.y - insetTop;
    }else{
        //尽量在上下空出一行字
        CGFloat verticalMargin = textInput.font.lineHeight;
        
        CGFloat viewableTopY     = offsetY;
        CGFloat viewableBottomY  = offsetY + viewableHeight;
        
        CGFloat caretTopY     = caretRect.origin.y - insetTop;
        CGFloat caretBottomY  = caretRect.origin.y + caretRect.size.height - insetTop;
        
        CGFloat textInputTopY    = textInputRect.origin.y - insetTop;
        CGFloat textInputBottomY = textInputRect.origin.y + textInputRect.size.height - insetTop;
        
        if(caretTopY - verticalMargin < viewableTopY){
            offsetY = caretTopY - verticalMargin;
            
            //保证textinput至少对齐顶部
            offsetY = MAX(textInputTopY, offsetY);
            
        } else if (caretBottomY + verticalMargin > viewableBottomY){
            offsetY = offsetY + (caretBottomY + verticalMargin) - viewableBottomY;
            
            //保证textinput至少对齐底部
            offsetY = textInputBottomY < offsetY + viewableHeight ? textInputBottomY - viewableHeight : offsetY;
        } else {
            //do nothing
        }
    }
    
    return offsetY;
}

-(CGFloat)KeyboardAvoiding_idealOffsetForView
{
    CGFloat insetTop = self.contentInset.top;
    CGFloat offsetY  = self.contentOffset.y;
   
    UITextView *textInput = (UITextView*)[self KeyboardAvoiding_findFirstResponderBeneathView:self];
    CGRect textInputRect = [textInput convertRect:textInput.bounds toView:self];
    
    CGFloat viewableHeight = self.bounds.size.height - self.contentInset.top - self.contentInset.bottom;
    
    //获取caret在scrollview中的位置
    UITextPosition *caretPosition = [textInput selectedTextRange].start;
    CGRect caretTextInputRect = [textInput caretRectForPosition:caretPosition];
    CGRect caretRect = [self convertRect:caretTextInputRect fromView:textInput];
    
    if (textInputRect.size.height <= viewableHeight) {
        offsetY = textInputRect.origin.y - insetTop;
    }else{
        //保证textinput至少对顶对齐
        offsetY = textInputRect.origin.y - insetTop> offsetY ? textInputRect.origin.y - insetTop: offsetY;

        //尽量在上下空出一行字
        CGFloat verticalMargin = textInput.font.lineHeight;

        CGFloat viewableTopY     = offsetY;
        CGFloat viewableBottomY  = offsetY + viewableHeight;

        CGFloat caretTopY     = caretRect.origin.y - insetTop;
        CGFloat caretBottomY  = caretRect.origin.y + caretRect.size.height- insetTop;
        
        CGFloat textInputTopY    = textInputRect.origin.y- insetTop;
        CGFloat textInputBottomY = textInputRect.origin.y + textInputRect.size.height- insetTop;

        if(caretTopY - verticalMargin < viewableTopY){
            offsetY = caretTopY - verticalMargin;
            
            //保证textinput至少对齐顶部
            offsetY = MAX(textInputTopY, offsetY);
            
        } else if (caretBottomY + verticalMargin > viewableBottomY){
            offsetY = offsetY + (caretBottomY + verticalMargin) - viewableBottomY;

            //保证textinput至少对齐底部
            offsetY = textInputBottomY < offsetY + viewableHeight ? textInputBottomY - viewableHeight : offsetY;
        } else {
            //do nothing
        }
    }

    return offsetY;
}

- (UIView*)KeyboardAvoiding_findFirstResponderBeneathView:(UIView*)view {
    // Search recursively for first responder
    for ( UIView *childView in view.subviews ) {
        if ( [childView respondsToSelector:@selector(isFirstResponder)] && [childView isFirstResponder] ) return childView;
        UIView *result = [self KeyboardAvoiding_findFirstResponderBeneathView:childView];
        if ( result ) return result;
    }
    return nil;
}
@end
