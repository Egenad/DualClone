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
    
    @IBOutlet weak var createRoomButton: UIButton!
    @IBOutlet weak var joinRoomButton: UIButton!
    
    private let connectionManager = ConnectionManager.instance
    
    private var spinner = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        createRoomButton.setBackgroundImage(UIImage(ciImage: .gray), for: .highlighted)
        joinRoomButton.setBackgroundImage(UIImage(ciImage: .gray), for: .highlighted)
        
        connectionManager.onSuccessfulConnection = {
            DispatchQueue.main.async {
                self.startGame()
            }
        }
        
        connectionManager.initParameters()
        
        spinner.hidesWhenStopped = true
        spinner.color = UIColor.green
        spinner.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        self.view.addSubview(spinner)
        spinner.center.x = self.view.center.x
        spinner.center.y = self.view.center.y
        self.view.bringSubviewToFront(self.spinner)
        
        nickNameField.attributedPlaceholder = NSAttributedString(string: "Example: Neo, Mike, Klea...",
                                                                         attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        
        enableButtons(enabled: true)
    }
    
    @IBAction func createRoom(_ sender: Any) {
        
        guard hasName() else{
            showAlert(title: NSLocalizedString("empty_title", comment: ""), message: NSLocalizedString("empty", comment: ""))
            return
        }
        
        guard isValidName() else{
            showAlert(title: NSLocalizedString("title_not_valid", comment: ""), message: NSLocalizedString("not_valid", comment: ""))
            return
        }
            
        searchHUD()
        connectionManager.playerName = nickNameField!.text!
        
        switch connectionType.selectedSegmentIndex {
            case TransferService.BLE_OPTION:
                connectionManager.startBLERoom()
                break
            case TransferService.WIFI_OPTION:
                connectionManager.startWIFIRoom()
                break
            default:
                // Nothing
                break
        }
    }
    
    @IBAction func joinRoom(_ sender: Any) {
        
        guard hasName() else{
            showAlert(title: NSLocalizedString("empty_title", comment: ""), message: NSLocalizedString("empty", comment: ""))
            return
        }
        
        guard isValidName() else{
            showAlert(title: NSLocalizedString("title_not_valid", comment: ""), message: NSLocalizedString("not_valid", comment: ""))
            return
        }
            
        searchHUD()
        connectionManager.playerName = nickNameField!.text!
        
        switch connectionType.selectedSegmentIndex {
            case TransferService.BLE_OPTION:
                connectionManager.joinBLERoom()
                break
            case TransferService.WIFI_OPTION:
                connectionManager.joinWIFIRoom()
                break
            default:
                // Nothing
                break
        }
    }
    
    private func searchHUD(){
        spinner.startAnimating()
        enableButtons(enabled: false)
    }
    
    private func enableButtons(enabled: Bool){
        createRoomButton.isEnabled = enabled
        joinRoomButton.isEnabled = enabled
        nickNameField.isEnabled = enabled
        connectionType.isEnabled = enabled
    }
    
    private func hasName() -> Bool {
        guard let nickname = nickNameField.text, !nickname.isEmpty else {
            return false
        }
        return true
    }
    
    private func isValidName() -> Bool {
        
        let nickname = nickNameField.text
        
        let regex = "^[a-zA-Z0-9_]{1,20}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: nickname)
    }
    
    private func startGame(){
        connectionManager.gameFinished = false
        spinner.stopAnimating()
        enableButtons(enabled: true)
        performSegue(withIdentifier: "GameScene", sender: self)
    }
}
