//
//  Spaceshift.swift
//  DualClone
//
//  Created by Angel Terol on 8/5/24.
//

import Foundation
import SpriteKit

class Spaceship : SKSpriteNode {
    
    var spTexture : SKTexture?
    let connectionManager = ConnectionManager.instance
    
    var bulletColor = UIColor.green
    var enemyBulletColor = UIColor.systemPink
    
    var health: Int = 100
    
    init(){
        
        var spriteToUse = "spaceship"
        
        if(connectionManager.playerType == TransferService.CENTRAL_PL){
            spriteToUse = "greenSquare"
        }else{
            spriteToUse = "pinkTriangle"
            bulletColor = UIColor.systemPink
            enemyBulletColor = UIColor.green
        }
        
        spTexture = SKTexture(imageNamed: spriteToUse)
        super.init(texture: spTexture, color: .clear, size: spTexture?.size() ?? CGSize(width: 0, height: 0))
        
        self.name = "spaceship"
        self.setScale(0.07)
        self.zPosition = 1
        
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.categoryBitMask = PhysicsCategory.spaceship
        self.physicsBody?.contactTestBitMask = PhysicsCategory.bullet
        self.physicsBody?.collisionBitMask = PhysicsCategory.none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fireEnemyBullet(_ newBullet : Bullet) -> SKSpriteNode {
        let bullet = BulletObject(color: enemyBulletColor, physics: true, position: newBullet.position, name: "enemyBullet")
        
        let bullecAction = SKAction.moveBy(x: 0, y: -1000, duration: 1)
        bullet.run(SKAction.repeatForever(bullecAction))
        
        return bullet
    }
    
    func fireBullet() -> SKSpriteNode {
        let bullet = BulletObject(color: bulletColor, physics: false, position: self.position, name: "bullet")
        
        let bullecAction = SKAction.moveBy(x: 0, y: 1000, duration: 1)
        bullet.run(SKAction.repeatForever(bullecAction))
        
        return bullet
    }
    
}
