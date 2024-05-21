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
    
    init(){
        spTexture = SKTexture(imageNamed: "spaceship")
        super.init(texture: spTexture, color: .clear, size: spTexture?.size() ?? CGSize(width: 0, height: 0))
        
        self.name = "spaceship"
        self.setScale(0.1)
        self.zPosition = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fireBullet() -> SKSpriteNode {
        let bullet = SKSpriteNode(color: .blue, size: CGSize(width: 5, height: 20))
        bullet.name = "bullet"
        bullet.position = self.position
        bullet.zPosition = 1
        bullet.speed = 1000
        
        let bullecAction = SKAction.moveBy(x: 0, y: bullet.speed, duration: 1)
        bullet.run(SKAction.repeatForever(bullecAction))
        
        return bullet
    }
    
}
