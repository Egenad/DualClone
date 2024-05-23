//
//  GameScene.swift
//  DualClone
//
//  Created by Angel Terol on 8/5/24.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    weak var gameDelegate: GameSceneDelegate?
    private var spinnyNode : SKShapeNode?
    private var spaceship : Spaceship!
    let motionManager = CMMotionManager()
    let connectionManager = ConnectionManager.instance
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        // Player
        spaceship = Spaceship()
        spaceship.position = CGPoint(x: 0, y: 0)
        addChild(spaceship)
        
        // Gyro movement
        startGyroMotion()
        
        // Shoot effect
        let w = (self.size.width + self.size.height) * 0.01
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
    }
    
    private func startGyroMotion(){
        
        motionManager.startGyroUpdates()
        
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (motion, error) in
            guard let motion = motion else { return }
            let rotationRate = motion.rotationRate
            
            let speed: CGFloat = 5.0

            self.spaceship.position.x += CGFloat(rotationRate.x) * speed
            self.spaceship.position.y += CGFloat(rotationRate.y) * speed
            
            self.spaceship.position.x = max(min(self.spaceship.position.x, self.size.width / 2), -self.size.width / 2)
            self.spaceship.position.y = max(min(self.spaceship.position.y, self.size.height / 2), -self.size.height / 2)
            
            let rotationAngle = CGFloat(rotationRate.z) * 0.01
            self.spaceship.zRotation += rotationAngle
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    func spawnEnemyBullet(_ newBullet: Bullet){
        let enemyBullet = self.spaceship?.fireEnemyBullet(newBullet)
        
        if(enemyBullet != nil){
            self.addChild(enemyBullet!)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Fire bullet on main device
        let bullet = spaceship.fireBullet()
        self.addChild(bullet)
        
        // Send the bullet to the other player
        var bulletStruct = Bullet(position: bullet.position)
        bulletStruct.mirrorBullet(for: UIScreen.main.bounds.height)
        
        if(connectionManager.connectionType == TransferService.BLE_OPTION){
            // Send bullet via bluetooth
            connectionManager.sendDataBLE(data: serializeBullet(bulletStruct), characteristicUUID: TransferService.characteristicUUID)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Eliminar balas que están fuera de los límites de la pantalla
        self.enumerateChildNodes(withName: "bullet") { (node, stop) in
            if !self.frame.contains(node.position) {
                node.removeFromParent()
                print("Bullet removed from scene")
            }
        }
        
        self.enumerateChildNodes(withName: "enemyBullet") { (node, stop) in
            if node.position.y < 0 - (UIScreen.main.bounds.height / 2) {
                node.removeFromParent()
                print("Enemy bullet removed from scene")
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        switch contactMask {
        case PhysicsCategory.spaceship | PhysicsCategory.bullet:
            if let spaceshipNode = contact.bodyA.node as? Spaceship {
                checkGameOver(spaceshipNode: spaceshipNode)
            } else if let spaceshipNode = contact.bodyB.node as? Spaceship {
                checkGameOver(spaceshipNode: spaceshipNode)
            }
            
            if let bulletNode = contact.bodyA.node as? BulletObject {
                bulletNode.removeFromParent()
            } else if let bulletNode = contact.bodyB.node as? BulletObject {
                bulletNode.removeFromParent()
            }
            
        default:
            return
        }
    }
    
    private func checkGameOver(spaceshipNode: Spaceship){
        spaceshipNode.health -= 10
        print("Spaceship hit! Health: \(spaceshipNode.health)")
        if(spaceshipNode.health <= 0){
            gameDelegate?.playerDidDie()
        }
    }
}
