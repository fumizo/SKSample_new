//
//  ViewController.m
//  SKSample
//
//  Created by FumikoYamamoto on 2016/01/09.
//  Copyright © 2016年 FumikoYamamoto. All rights reserved.
//

#import "ViewController.h"
#import "TitleScene.h"
@import SpriteKit;

@interface ViewController ()

@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

//loadViewで、self.viewをSKViewに差し替える
- (void)loadView {
    SKView *skView = [[SKView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = skView;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //情報表示の設定をした後、SKSceneをインスタンス化して表示
    SKView *skView = (SKView *)self.view;
    skView.showsDrawCount = YES;
    skView.showsNodeCount = YES;
    skView.showsFPS = YES;
    
//    SKScene *scene = [SKScene sceneWithSize:self.view.bounds.size];
    SKScene *scene = [TitleScene sceneWithSize:self.view.bounds.size];
    [skView presentScene:scene];
    
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose ofany resources that can be recreated.

}


@end
