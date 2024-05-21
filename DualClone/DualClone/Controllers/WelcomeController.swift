//
//  WelcomeController.swift
//  DualClone
//
//  Created by Angel Terol on 9/5/24.
//

import UIKit

class WelcomeController: UIViewController {

    @IBOutlet weak var connectionType: UISegmentedControl!
    @IBOutlet weak var nickNameField: UITextField!
    
    private let connectionManager = ConnectionManager.instance
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        ConnectionManager.instance.onSuccessfulConnection = {
            DispatchQueue.main.async {
                self.startGame()
            }
        }
        
        nickNameField.attributedPlaceholder = NSAttributedString(string: "Example: Neo, Mike, Klea...",
                                                                         attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
    }
    
    @IBAction func createRoom(_ sender: Any) {
        if(hasName()){
            switch connectionType.selectedSegmentIndex {
                case TransferService.BLE_OPTION:
                    connectionManager.startBLERoom()
                    break
                case TransferService.WIFI_OPTION:
                    
                    break
                default:
                    // Nothing
                    break
            }
        }
    }
    
    @IBAction func joinRoom(_ sender: Any) {
        if(hasName()){
            switch connectionType.selectedSegmentIndex {
                case TransferService.BLE_OPTION:
                    connectionManager.joinBLERoom()
                    break
                case TransferService.WIFI_OPTION:
                    
                    break
                default:
                    // Nothing
                    break
            }
        }
    }
    
    private func hasName() -> Bool {
        guard let nickname = nickNameField.text, !nickname.isEmpty else {
            return false
        }
        return true
    }
    
    private func startGame(){
        performSegue(withIdentifier: "GameScene", sender: self)
    }
}
