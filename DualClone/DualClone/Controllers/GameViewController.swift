//
//  GameViewController.swift
//  DualClone
//
//  Created by Angel Terol on 8/5/24.
//

import UIKit
import SpriteKit
import GameplayKit

protocol GameSceneDelegate: AnyObject {
    func playerDidDie()
}

class GameViewController: UIViewController, GameSceneDelegate {
    
    var playerType = TransferService.CENTRAL_PL
    var gameScene : SKScene?
    
    var connectionManager = ConnectionManager.instance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") as? GameScene {
                gameScene = scene
                scene.scaleMode = .aspectFill
                scene.gameDelegate = self
                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = false
            view.showsNodeCount = false
        }
        
        connectionManager.receiveBullet = { param in
            DispatchQueue.main.async {
                if let scene = self.gameScene as? GameScene {
                    scene.spawnEnemyBullet(param)
                }
            }
        }
        
        connectionManager.endGameReceived = {
            DispatchQueue.main.async {
                self.playerDidDie()
            }
        }
        
        connectionManager.playerNameReceived = {
            DispatchQueue.main.async {
                if let scene = self.gameScene as? GameScene {
                    scene.updateEnemyName()
                }
            }
        }
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func playerDidDie() {
        
        if(connectionManager.connectionType == TransferService.BLE_OPTION){
            // Send game over via bluetooth
            connectionManager.sendDataBLE(data: "Game Over".data(using: .utf8)!, characteristicUUID: TransferService.endGameCharacteristicUUID)
        }else if(connectionManager.connectionType == TransferService.WIFI_OPTION){
            let goMSG = PTPMessage(type: .gameOver, content: "Game Over".data(using: .utf8)!)
            connectionManager.sendPTPData(goMSG)
        }
        
        connectionManager.terminateConnection()
        self.dismiss(animated: true, completion: nil)
    }
}
