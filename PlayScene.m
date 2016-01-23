//
//  PlayScene.m
//  SKSample
//
//  Created by FumikoYamamoto on 2016/01/09.
//  Copyright © 2016年 FumikoYamamoto. All rights reserved.
//

#import "PlayScene.h"
#import "YMCPhysicsDebugger.h"

//<<...2でかけます
//static const は定数(変数じゃないやつ)/そのクラス内で使われる
//uint32_tは4バイト消費する
static const uint32_t blockCategory = 0x1 << 0; //*1の意味
static const uint32_t ballCategory = 0x1 << 1; //*2だよ

@interface PlayScene () <SKPhysicsContactDelegate>
@end
@implementation PlayScene

/*
 本来はSKNodeでblockNodeを作るべきだけど、簡略化のため、ここに。[SKNode...alphaとかをできるやつ]
*/


- (id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        [YMCPhysicsDebugger init];
        /* Create scene contens */
        [self addBlocks];
        [self addPaddle];
        [self drawPhysicsBodies];
        //physicsBodyを設定する/重力が使えるようになる
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        self.physicsWorld.contactDelegate = self;  //物理演算をselfの中でやるよ。これがないと
    }
    return self;
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
    
    block.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:block.size];
    block.physicsBody.dynamic = NO; //ブロックは重力で落ちちゃダメだからNOにする。これによって固定。
    block.physicsBody.categoryBitMask = blockCategory;  //categoryBitMaskは、クラスを判別できる。マスクに番地をあげた
    
    [self addChild:block];  //ブロックを追加
    return block;
}

- (void)updateBlockAlpha:(SKNode *)block {
    int life = [block.userData[@"life"] intValue];
    block.alpha = life * 0.2f;
}


static NSDictionary *config = nil;
+ (void)initialize {
    //設定を読み込んで、static変数configに保持
    //main bundle = SKSampleのバンドル config.jsonの内容を文字列で持ってきて、pathにしますよ
    NSString *path = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!config) {
        config = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    }
}

- (void)decreaseBlockLife:(SKNode *)block {
    int life = [block.userData[@"life"] intValue] - 1;
    block.userData[@"life"] = @(life);
    
    if (life < 1) {
        [self removeNodeWithSpark:block];
        //lifeが0になったらパーティクル呼ぶ(消滅と同時に爆発)
    }
    
    [self updateBlockAlpha:block];
}


# pragma mark - Paddle

//設定を元にパドルを表示
- (void)addPaddle {
    CGFloat width = [config[@"paddle"][@"width"] floatValue];
    CGFloat height = [config[@"paddle"][@"height"] floatValue];
    CGFloat y = [config[@"paddle"][@"y"] floatValue];
    
    SKSpriteNode *paddle = [SKSpriteNode spriteNodeWithColor:[SKColor brownColor] size:CGSizeMake(width, height)];
    //ここで名前を設定
    paddle.name = @"paddle";
    paddle.position = CGPointMake(CGRectGetMidX(self.frame), y);
    
    paddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:paddle.size];
    paddle.physicsBody.dynamic = NO; //パドルは重力で落ちちゃダメだからNOにする。固定
    
    [self addChild:paddle]; //パドルを追加
}

- (SKNode *)paddleNode {
    return [self childNodeWithName:@"paddle"]; //nameに設定した値を元にするということ
}

# pragma mark - Ball
- (void)addBall {
    CGFloat radius = [config[@"ball"][@"radius"] floatValue];
    
    CGFloat velocityX = [config[@"ball"][@"velocity"][@"x"] floatValue];
    CGFloat velocityY = [config[@"ball"][@"velocity"][@"y"] floatValue];
    
    SKShapeNode *ball = [SKShapeNode node];
    //ここで名前を設定
    ball.name = @"ball";
    ball.position = CGPointMake(CGRectGetMidX([self paddleNode].frame), CGRectGetMaxY([self paddleNode].frame) + radius);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddArc(path, NULL, 0,     0, radius, 0, M_PI * 2, YES);
    ball.path = path;
    ball.fillColor = [SKColor yellowColor];
    ball.strokeColor = [SKColor clearColor];
    
    //physicsBodyを使うことで重力環境になり、衝突が可能になる
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:radius]; //丸さ
    ball.physicsBody.affectedByGravity = NO;  //ボールは固定はしないけど、重力を無視するため
    ball.physicsBody.velocity = CGVectorMake(velocityX, velocityY);  //velocityで力を加えてる
    ball.physicsBody.restitution = 1.0f; //a反発係数を1に
    ball.physicsBody.linearDamping = 0;  //b空気抵抗を0
    ball.physicsBody.friction = 0;       //c摩擦を0...b.cによって跳ね返り(a)を一定に保つ
    ball.physicsBody.usesPreciseCollisionDetection = YES;  //yesで衝突判定が可能に
    ball.physicsBody.categoryBitMask = ballCategory;       //categoryBitMaskはそれが何のクラスか判別する。contactTestBitMaskに設定したものとcontact(接触)した場合didBeginContact:が呼ばれる
    ball.physicsBody.contactTestBitMask = blockCategory;  //contactTestBitMaskにblockCategoryを設定してる
    
    CGPathRelease(path);
    
    [self addChild:ball];  //ボールを追加
}

- (SKNode *)ballNode {
    return [self childNodeWithName:@"ball"];  //nameのballに設定した値を元にするということ
}

# pragma mark - Touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //画面がタップされたときにボールがなければ、addBallを呼び出してボールを追加
    if (![self ballNode]) {
        [self addBall];
        return;
    }
    //ボールがあればゲーム中だから、パドルを等速で動かす
    UITouch *touch = [touches anyObject];
    CGPoint locaiton = [touch locationInNode:self];
    
    CGFloat speed = [config[@"paddle"][@"speed"] floatValue];
    
    CGFloat x = locaiton.x;
    CGFloat diff = abs(x - [self paddleNode].position.x);
    CGFloat duration = speed * diff;
    SKAction *move = [SKAction moveToX:x duration:duration];
    [[self paddleNode] runAction:move];
}

# pragma mark - SKPhysicsContactDelegate

- (void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if (firstBody.categoryBitMask & blockCategory) {
        if (secondBody.categoryBitMask & ballCategory) {
            [self decreaseBlockLife:firstBody.node];
        }
    }
}

//ここから下パーティクル
# pragma mark - Utilities

- (void)removeNodeWithSpark:(SKNode *)node {
    NSString *sparkPath = [[NSBundle mainBundle] pathForResource:@"spark" ofType:@"sks"]; //パーティクルのやつから
    SKEmitterNode *spark = [NSKeyedUnarchiver unarchiveObjectWithFile:sparkPath];
    spark.position = node.position;  //ブロックの破壊時にブロックの座標
    spark.xScale = spark.yScale = 0.3f;
    [self addChild:spark];  //パーティクルを表示
    
    SKAction *fadeOut = [SKAction fadeOutWithDuration:0.3f];  //0.3秒でフェードアウト
    SKAction *remove = [SKAction removeFromParent];
    SKAction *sequence = [SKAction sequence:@[fadeOut, remove]];  //シーケンスを使えばアニメーションを連続して行う設定をできる
    [spark runAction:sequence];
    
    [node removeFromParent];  //シーンからnodeを削除する
}

//ブロックの耐久力が0になると、爆発と共に消滅

@end
