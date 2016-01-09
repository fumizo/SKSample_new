//
//  TitleScene.m
//  SKSample
//
//  Created by FumikoYamamoto on 2016/01/09.
//  Copyright © 2016年 FumikoYamamoto. All rights reserved.
//

#import "TitleScene.h"
#import "PlayScene.h"

@implementation TitleScene

- (id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        SKLabelNode *titleLabel = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue"];
        titleLabel.text = @"BREAKOUT!";
        titleLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        titleLabel.fontSize = 50.0f;
        [self addChild:titleLabel];
    }
    return self;
}

//タップしたらPlayのsceneにいく
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    SKScene *scene = [PlayScene sceneWithSize:self.size];
    SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionUp duration:1.0f];
    [self.view presentScene:scene transition:transition];
}

@end
