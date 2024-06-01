//
//  TransferService.swift
//  DualClone
//
//  Created by Angel Terol on 16/5/24.
//

import Foundation
import CoreBluetooth

struct TransferService {
    static let serviceUUID = CBUUID(string: "9D26CC8E-156D-40B0-8A9E-A70183F6DF6F")
    static let characteristicUUID = CBUUID(string: "F8427195-4852-4696-93E2-52D4B298B3A0")
    static let endGameCharacteristicUUID = CBUUID(string: "59AD4954-DB43-430C-B322-CBAE4683BB71")
    static let nameCharacteristicUUID = CBUUID(string: "A2EB6CF6-7626-4613-96B3-A840FFC17ECD")
    static let BLE_OPTION = 0
    static let WIFI_OPTION = 1
    static let CENTRAL_PL = 0
    static let PERIPHERAL_PL = 1
    
    static let uuidList = [characteristicUUID, endGameCharacteristicUUID, nameCharacteristicUUID]
}
