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
    static let BLE_OPTION = 0
    static let WIFI_OPTION = 1
    static let CENTRAL_PL = 0
    static let PERIPHERAL_PL = 1
}
