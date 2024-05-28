//
//  Bullet.swift
//  DualClone
//
//  Created by Angel Terol on 13/5/24.
//

import Foundation
import SpriteKit

class BulletObject : SKSpriteNode {
    
    let bulletWidth = 10
    let bulletHeight = 10
    
    init(color: UIColor, physics: Bool, position: CGPoint, name: String, yVelocity: CGFloat, angle: CGFloat) {
        let size = CGSize(width: bulletWidth, height: bulletHeight) // Tamaño del cubo
        super.init(texture: nil, color: color, size: size)
        
        self.name = name
        self.position = position
        self.zPosition = 1
        
        if(physics){
            self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
            self.physicsBody?.isDynamic = true
            self.physicsBody?.affectedByGravity = false
            self.physicsBody?.categoryBitMask = PhysicsCategory.bullet
            self.physicsBody?.contactTestBitMask = PhysicsCategory.spaceship
            self.physicsBody?.collisionBitMask = PhysicsCategory.none
        }
        
        let dy = cos(angle)
        let dx = -sin(angle)
        
        print("angle: \(angle), cos_x: \(dx), sin_y: \(dy)")
        
        let bullecAction = SKAction.moveBy(x: dx * 1000, y: dy * yVelocity, duration: 1)
        self.run(SKAction.repeatForever(bullecAction))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct Bullet : Codable {
    var position: CGPoint
    var angle: CGFloat
    
    mutating func mirrorBullet(for screenHeight: CGFloat) {
        position.y = screenHeight - position.y
        position.x = -position.x
        angle = -angle
    }
}

func deserializeBullet(_ data: Data) -> Bullet? {
    do {
        let decoder = JSONDecoder()
        let bullet = try decoder.decode(Bullet.self, from: data)
        return bullet
    } catch {
        print("Error on deserialize: \(error)")
        return nil
    }
}

func serializeBullet(_ bullet: Bullet) -> Data? {
    do {
        let encoder = JSONEncoder()
        let data = try encoder.encode(bullet)
        return data
    } catch {
        print("Error on serialize: \(error)")
        return nil
    }
}
