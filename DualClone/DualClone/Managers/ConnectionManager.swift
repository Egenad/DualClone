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
    
    var onSuccessfulConnection: (() -> Void)?
    
    var playerType = TransferService.CENTRAL_PL
    
    // --- CENTRAL ---
    var centralManager: CBCentralManager?
    var peripheralFound: CBPeripheral!
    var chrcSubscribed: CBCharacteristic!
    let peripheralName = "DualClonePeripheral"
    
    // --- PERIPHERAL ---
    var peripheralManager : CBPeripheralManager!
    var centralFound: CBCentral!
    
    var transferCharacteristic = CBMutableCharacteristic(type: TransferService.characteristicUUID,
                                                         properties: [.notify, .write, .read, .writeWithoutResponse],
                                                         value: nil,
                                                         permissions: [.readable, .writeable])
    
    // --- MAIN FUNCTIONS ---
    
    func startBLERoom(){
        playerType = TransferService.PERIPHERAL_PL
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    }
    
    func joinBLERoom(){
        playerType = TransferService.CENTRAL_PL
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager?.scanForPeripherals(withServices: [TransferService.serviceUUID], options: nil)
    }
    
    func sendDataBLE(data : Data?, characteristicUUID: CBUUID){
        
        guard data != nil else{
            return
        }
        
        if(playerType == TransferService.CENTRAL_PL){
            sendDataFromCentral(data: data!, characteristicUUID: characteristicUUID)
        }else{
            sendDataFromPeripheral(data: data!, characteristicUUID: characteristicUUID)
        }
    }

}

// ----------------------------------------------------------------------------------------------------------- //

// ---- CENTRAL - MANAGER ----

extension ConnectionManager: CBCentralManagerDelegate {
    
    // Scan peripherals
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            centralManager?.scanForPeripherals(withServices: [TransferService.serviceUUID], options: nil)
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
                
                // Starting game on central
                onSuccessfulConnection?()
            }
        }
    }
    
    // Peripheral connected --> Discover Services
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        peripheral.discoverServices([TransferService.serviceUUID])
        print ("Central - Connected with peripheral:" + peripheral.name!)
    }
}

// ---- CENTRAL - PERIPHERAL ----

extension ConnectionManager: CBPeripheralDelegate{
    
    // Did Discover Service --> Discover Characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            if service.uuid == TransferService.serviceUUID {
                peripheral.discoverCharacteristics([TransferService.characteristicUUID], for: service)
                print("Central - Found the service \(service) and looking for characteristics")
            }
        }
    }
    
    // Did Discover Characteristics --> Look for bullet characteristic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            if characteristic.uuid == TransferService.characteristicUUID {
                print("Central - Found characteristic and subscribing to it")
                peripheral.setNotifyValue(true, for: characteristic)
                chrcSubscribed = characteristic
                if (characteristic.properties.contains(.read)){
                    peripheral.readValue(for: characteristic)
                    print("Central - Found characteristic and requesting its reading")
                }
            }
        }
    }
    
    // Found asked characteristic
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if characteristic.uuid == TransferService.characteristicUUID {
            guard let data = characteristic.value else {
                print("Error: No se pudo obtener el valor de la característica.")
                return
            }
            
            if let bullet = deserializeBullet(data) {
                print("Central recibe bala en posicion: \(bullet.position)")
            } else {
                print("Error: No se pudo deserializar la bala recibida.")
            }
        }
    }
    
    func sendDataFromCentral(data: Data, characteristicUUID: CBUUID) {
        guard characteristicUUID == TransferService.characteristicUUID else {
            print("La característica no está configurada.")
            return
        }
        print("Enviando bala desde Central")
        peripheralFound.writeValue(data, for: chrcSubscribed, type: .withoutResponse)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let myError = error {
            print( "Central - Error al enviar datos: " + myError.localizedDescription)
        }
    }
}

// ----------------------------------------------------------------------------------------------------------- //

// ---- PERIPHERAL ----

extension ConnectionManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if (peripheralManager.isAdvertising) {
            peripheralManager.stopAdvertising()
        }
        
        // Create a service from the characteristic.
        let myService = CBMutableService(type: TransferService.serviceUUID, primary: true)
        
        // Add the characteristic to the service.
        myService.characteristics = [transferCharacteristic]
        
        // And add it to the peripheral manager.
        peripheralManager.add(myService)
        
        print("Peripheral - Init service tree and characteristic")
        
        // Start advertising the service
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[TransferService.serviceUUID], CBAdvertisementDataLocalNameKey: peripheralName])
                    
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
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("He encontrado central")
        if characteristic.uuid == TransferService.characteristicUUID {
            
            centralFound = central
            
            // Starting game on peripheral
            onSuccessfulConnection?()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
        print("Peripheral recibe data")
        
        for request in requests {
            guard request.characteristic.uuid == TransferService.characteristicUUID else {
                // Not the characteristic we want
                peripheral.respond(to: request, withResult: .attributeNotFound)
                continue
            }
            
            // Obtain the new bullet information
            if let value = request.value {
                let newBullet = deserializeBullet(value)
                
                // TODO: Spawn the received bullet
                print("Peripheral recibe bala en posicion \(String(describing: newBullet?.position))")
            }
        }
    }
    
    func sendDataFromPeripheral(data: Data, characteristicUUID: CBUUID) {
        guard characteristicUUID == TransferService.characteristicUUID else {
            print("La característica no está configurada.")
            return
        }
        print("Enviando bala desde Peripheral")
        peripheralManager?.updateValue(data, for: transferCharacteristic, onSubscribedCentrals: [centralFound])
    }

}
