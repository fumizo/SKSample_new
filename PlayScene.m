//
//  PlayScene.m
//  SKSample
//
//  Created by FumikoYamamoto on 2016/01/09.
//  Copyright © 2016年 FumikoYamamoto. All rights reserved.
//

#import "PlayScene.h"

@implementation PlayScene

/*
 本来はSKNodeでblockNodeを作るべきだけど、簡略化のため、ここに。[SKNode...alphaとかをできるやつ]
*/

- (id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        [self addBlocks];
    }
    return self;
}

static NSDictionary *config = nil;
+ (void)initialize {
    //設定を読み込んで、static変数configに保持
    NSString *path = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!config) {
        config = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    }
}

# pragma mark - Block

- (void)addBlocks {
    //幅・高さ・マージン・rowsなどから表示できるブロック数を計算、表示
    int rows = [config[@"block"][@"rows"] intValue];
    CGFloat margin = [config[@"block"][@"margin"] floatValue];
    CGFloat width = [config[@"block"][@"width"] floatValue];
    CGFloat height = [config[@"block"][@"height"] floatValue];
    
    int cols = floor(CGRectGetWidth(self.frame) - margin) / (width + margin);
    
    CGFloat y = CGRectGetHeight(self.frame) - margin - height / 2;
    
    for (int i = 0; i < rows; i++) {
        CGFloat x = margin + width / 2;
        for (int j = 0; j < cols; j++) {
            SKNode *block = [self newBlock];
            block.position = CGPointMake(x, y);
            x += width + margin;
        }
        y -= height + margin;
    }
}

- (SKNode *)newBlock {
    CGFloat width = [config[@"block"][@"width"] floatValue];
    CGFloat height = [config[@"block"][@"height"] floatValue];
    int maxLife = [config[@"block"][@"max_life"] floatValue];
    
    SKSpriteNode *block = [SKSpriteNode spriteNodeWithColor:[SKColor cyanColor] size:CGSizeMake(width, height)];
    //画像じゃなくて色にしてる。通常はspriteNodeWithImageNamedやspriteNodeWithTextureでテクスチャ画像を指定して使う。
    block.name = @"block";
    
    //ブロックの耐久力（life）をランダムに設定しuserDataに持たせて、それに応じてupdateBlockAplha:で透明度を変化

    int life = (arc4random() % maxLife) + 1;
    block.userData = @{ @"life" : @(life) }.mutableCopy;
    [self updateBlockAlpha:block];
    
    [self addChild:block];
    
    return block;
}

- (void)updateBlockAlpha:(SKNode *)block {
    int life = [block.userData[@"life"] intValue];
    block.alpha = life * 0.2f;
}

@end
