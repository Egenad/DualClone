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
        connectionManager.switchToBluetooth()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let nickname = nickNameField.text, !nickname.isEmpty else {
            return false
        }
        
        return true
    }

}
