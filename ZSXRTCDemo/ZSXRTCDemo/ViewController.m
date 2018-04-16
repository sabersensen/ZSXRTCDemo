//
//  ViewController.m
//  ZSXRTCDemo
//
//  Created by 邹时新 on 2018/4/16.
//  Copyright © 2018年 zoushixin. All rights reserved.
//

#import "ViewController.h"
#import "ZSXSocketManager.h"

@interface ViewController ()<UITextFieldDelegate>


@property (weak, nonatomic) IBOutlet UITextField *text;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (nonatomic,strong)ZSXSocketManager *socketManager;

@end

@implementation ViewController
- (IBAction)onConnectClick:(id)sender {
    [self.socketManager connect];

}

- (IBAction)onSendClick:(id)sender {
    [self.view endEditing:YES];
    [self.socketManager sendMsg:_text.text];

}

- (IBAction)onCloseClick:(id)sender {
    [self.socketManager disConnect];

}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    [self.view endEditing:YES];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    _text.delegate = self;
    self.socketManager = [ZSXSocketManager share];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
