//
//  AdvancedExpandableTextCell.m
//  formKeyboard
//
//  Created by chen xiaosong on 16/4/12.
//  Copyright © 2016年 chen xiaosong. All rights reserved.
//

#import "AdvancedExpandableTextCell.h"
#import "UIScrollView+KeyboardAvoiding.h"

#define kFontSize  15.0
#define kMinHeigth 50.0

@interface AdvancedExpandableTextCell()<UITextViewDelegate>

@end

@implementation AdvancedExpandableTextCell

 - (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (SZTextView*) textView
{
    if (_textView == NULL) {
        CGRect cellFrame = self.contentView.frame;
        
        _textView = [[SZTextView alloc] initWithFrame:cellFrame];
        _textView.delegate = self;
        
        _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _textView.placeholderTextColor = [UIColor colorWithRed:(float)0xcc/0xff green:(float)0xcc/0xff blue:(float)0xcc/0xff alpha:1];
        _textView.backgroundColor = [UIColor clearColor];
        _textView.font = [UIFont systemFontOfSize:kFontSize];
        
        _textView.scrollEnabled = NO;
        _textView.showsVerticalScrollIndicator = NO;
        _textView.showsHorizontalScrollIndicator = NO;
        
    }
    
    return _textView;
}

- (void)setText:(NSString*)text
{
    self.textView.text = text;
}

- (void)setPlaceholder:(NSString*)placeholder
{
    self.textView.placeholder = placeholder;
}

- (CGFloat)cellHeight
{
    CGFloat height = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, FLT_MAX)].height;

    return MAX(kMinHeigth, height + 1.0);
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self != NULL) {
        [self.contentView addSubview:self.textView];
    }
    
    return self;
}

#pragma mark - Text View Delegate

-(void)textViewDidEndEditing:(UITextView *)textView{
    if ([self.expandableTableView.delegate respondsToSelector:@selector(tableView:textViewDidEndEditing:)]) {
        [(id<AdvancedExpandableTableViewDelegate>)self.expandableTableView.delegate tableView:self.expandableTableView textViewDidEndEditing:self.textView];
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    if ([self.expandableTableView.delegate respondsToSelector:@selector(tableView:textViewDidChangeSelection:)]) {
        [(id<AdvancedExpandableTableViewDelegate>)self.expandableTableView.delegate tableView:self.expandableTableView textViewDidChangeSelection:self.textView];
    }
    
    //
    [self performSelector:@selector(caretPostionChanged)
               withObject:self.textView
               afterDelay:0.1];
}

- (void) caretPostionChanged
{
    [self.expandableTableView KeyboardAvoiding_caretPostionChanged];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([self.expandableTableView.delegate respondsToSelector:@selector(tableView:textView:shouldChangeTextInRange:replacementText:)]) {
        id<AdvancedExpandableTableViewDelegate> delegate = (id<AdvancedExpandableTableViewDelegate>)self.expandableTableView.delegate;
        return [delegate tableView:self.expandableTableView
                          textView:textView
           shouldChangeTextInRange:range
                   replacementText:text];
    }
    return YES;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    // make sure the cell is at the top
    [self.expandableTableView scrollToRowAtIndexPath:[self.expandableTableView indexPathForCell:self]
                                    atScrollPosition:UITableViewScrollPositionTop
                                            animated:YES];
    
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([self.expandableTableView.delegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [(id<AdvancedExpandableTableViewDelegate>)self.expandableTableView.delegate textViewDidBeginEditing:textView];
    }
}

- (void)textViewDidChange:(UITextView *)theTextView
{
    if ([self.expandableTableView.delegate conformsToProtocol:@protocol(AdvancedExpandableTableViewDelegate)]) {
        
        id<AdvancedExpandableTableViewDelegate> delegate = (id<AdvancedExpandableTableViewDelegate>)self.expandableTableView.delegate;
        NSIndexPath *indexPath = [self.expandableTableView indexPathForCell:self];
        
        // update the text
        if (_maxCharacter > 0 && self.textView.text.length > _maxCharacter) {
            self.textView.text = [self.textView.text substringToIndex:_maxCharacter];
        }

        _text = self.textView.text;
        
        [delegate tableView:self.expandableTableView
                updatedText:_text
                atIndexPath:indexPath];
        
        //高度有变化
        CGFloat newHeight = [self cellHeight];
        CGFloat oldHeight = [delegate tableView:self.expandableTableView heightForRowAtIndexPath:indexPath];
        
        if (fabs(newHeight - oldHeight) > 0.01) {
            
            // update the height
            if ([delegate respondsToSelector:@selector(tableView:updatedHeight:atIndexPath:)]) {
                [delegate tableView:self.expandableTableView
                      updatedHeight:newHeight
                        atIndexPath:indexPath];
            }
            
            [self.expandableTableView beginUpdates];
            [self.expandableTableView endUpdates];
        }
        
    }
}


@end


@implementation UITableView (AdvancedExpandableTextCell)

- (AdvancedExpandableTextCell *)advancedExpandableTextCellWithId:(NSString*)cellId
{
    AdvancedExpandableTextCell *cell = [self dequeueReusableCellWithIdentifier:cellId];
    
    if (cell == NULL) {
        cell = [[AdvancedExpandableTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        
        cell.expandableTableView = self;
        
        //键盘消失的手势
        [self tapToDismissKeyboard];
        self.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        
        //检测键盘事件
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KeyboardAvoiding_keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KeyboardAvoiding_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
        cell.maxCharacter = -1;
    }
    
    return cell;
}

- (void)tapToDismissKeyboard
{
    UITapGestureRecognizer *tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    [self addGestureRecognizer:tapGr];
}

- (void)viewTapped:(id)sender
{
    [self endEditing:YES];
}

@end
