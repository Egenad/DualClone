//
//  BLEManager.swift
//  DualClone
//
//  Created by Angel Terol on 13/5/24.
//

import Foundation
import CoreBluetooth

class ConnectionManager: NSObject{
    
    static let instance = ConnectionManager()
    
    var centralManager: CBCentralManager?
    var peripheralManager = CBPeripheralManager()
    var peripheralFound: CBPeripheral!
    
    let GAME_SERVICE_UUID = CBUUID(string: "9D26CC8E-156D-40B0-8A9E-A70183F6DF6F") // Service UUID
    let CHRC_BULLETS_UUID = CBUUID(string: "F8427195-4852-4696-93E2-52D4B298B3A0") // Bullets Characteristic UUID
    let CHARACTERISTIC_PROPERTIES: CBCharacteristicProperties = .read
    let CHARACTERISTIC_PERMISSIONS: CBAttributePermissions = .readable
    
    var bulletsValue: [Bullet] = []
    //let bulletsData = NSKeyedArchiver.archivedData(withRootObject: bulletsValue)
    /*let bulletsCharacteristic = CBMutableCharacteristic(type: gameBulletsUUID,
                                                        properties: .notify, // Habilitar notificaciones
                                                        value: bulletsData,
                                                        permissions: .readable)*/
    
    let peripheralName = "DualClonePeripheral"
    
    // Switch manager to BLE connection
    func switchToBluetooth(){
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager?.scanForPeripherals(withServices: [GAME_SERVICE_UUID], options: nil)
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // Switch manager to WIFI connection
    func switchToWifi(){
        centralManager?.stopScan()
        centralManager = nil
    }
    
}

// ---- CENTRAL - MANAGER ----

extension ConnectionManager: CBCentralManagerDelegate {
    
    // Scan peripherals
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            centralManager?.scanForPeripherals(withServices: [GAME_SERVICE_UUID], options: nil)
        }
    }
    
    // Peripherial found --> Connect to peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let advertisementName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            if advertisementName == peripheralName{
                peripheralFound = peripheral
                peripheralFound?.delegate = self
                centralManager?.stopScan()
                centralManager?.connect(peripheralFound!)
                print ("Central - Connecting with peripheral: " + advertisementName)
            }
        }
    }
    
    // Peripheral connected --> Discover Services
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        peripheral.discoverServices([GAME_SERVICE_UUID])
        print ("Central - Connected with peripheral:" + peripheral.name!)
    }
}

// ---- CENTRAL - PERIPHERAL ----
extension ConnectionManager: CBPeripheralDelegate{
    
    // Did Discover Service --> Discover Characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            if service.uuid == GAME_SERVICE_UUID {
                peripheral.discoverCharacteristics([CHRC_BULLETS_UUID], for: service)
                print("Central - Found the service \(service) and looking for characteristics")
            }
        }
    }
    
    // Did Discover Characteristics --> Look for bullet characteristic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            if characteristic.uuid == CHRC_BULLETS_UUID {
                if (characteristic.properties.contains(.read)){
                    peripheral.readValue(for: characteristic)
                    print("Central - Found characteristic and requesting its reading")
                }
            }
        }
    }
    
    // Found asked characteristic
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if characteristic.uuid == CHRC_BULLETS_UUID {
            guard let data = characteristic.value else {
                print("Error: No se pudo obtener el valor de la característica.")
                return
            }
            
            if let bullet = deserializeBullet(data) {
                // Procesar la bala recibida
            } else {
                print("Error: No se pudo deserializar la bala recibida.")
            }
        }
    }
}

extension ConnectionManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if (peripheralManager.isAdvertising) {
            peripheralManager.stopAdvertising()
        }
        
        let myService = CBMutableService(type: GAME_SERVICE_UUID, primary: true)
        let myCharacteristic = CBMutableCharacteristic(type: CHRC_BULLETS_UUID, properties: CHARACTERISTIC_PROPERTIES, value: serializeBullet(Bullet(position: CGPoint(x: 10, y: 10), playerID: peripheralName)), permissions: CHARACTERISTIC_PERMISSIONS)
        myService.characteristics = [myCharacteristic]
        
        peripheralManager.add(myService)
        print("Peripheral - Init service tree and characteristic")
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[GAME_SERVICE_UUID], CBAdvertisementDataLocalNameKey: peripheralName])
                    
        print("Peripheral - start advertising with name: " + peripheralName)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let myError = error {
            print( "Peripheral - Error posting a service:" + myError.localizedDescription)
        }
        
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let myError = error {
            print( "Periférico: Error posting a service:" + myError.localizedDescription)
        }
    }
}
