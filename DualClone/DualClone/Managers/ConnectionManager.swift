//
//  BLEManager.swift
//  DualClone
//
//  Created by Angel Terol on 13/5/24.
//

import Foundation
import CoreBluetooth
import MultipeerConnectivity

class ConnectionManager: NSObject{
    
    static let instance = ConnectionManager()
    
    var onSuccessfulConnection: (() -> Void)?
    var receiveBullet: ((Bullet) -> Void)?
    var endGameReceived: (() -> Void)?
    
    var playerType = TransferService.CENTRAL_PL
    var connectionType = TransferService.BLE_OPTION
    
    // --- CENTRAL ---
    var centralManager: CBCentralManager?
    var peripheralFound: CBPeripheral!
    var chrcSubscribed: CBCharacteristic!
    var endGameChrcSubscribed: CBCharacteristic!
    let peripheralName = "DualClonePeripheral"
    
    // --- PERIPHERAL ---
    var peripheralManager : CBPeripheralManager!
    var centralFound: CBCentral!
    
    // --- MULTIPEER ---
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var ptpAdvertiser = PTPAdvertiser()
    var ptpBrowser = PTPBrowser()
    
    var transferCharacteristic = CBMutableCharacteristic(type: TransferService.characteristicUUID,
                                                         properties: [.notify, .write, .read, .writeWithoutResponse],
                                                         value: nil,
                                                         permissions: [.readable, .writeable])
    
    var endGameCharacteristic = CBMutableCharacteristic(type: TransferService.endGameCharacteristicUUID,
                                                        properties: [.notify, .write, .read, .writeWithoutResponse],
                                                        value: nil,
                                                        permissions: [.readable, .writeable])

    
    // --- MAIN FUNCTIONS ---
    
    override init(){
        super.init()
                
        // Create a unique identifier for the peer
        peerID = MCPeerID(displayName: UIDevice.current.name)
        
        // Create the session with the peer ID and assign the delegate
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
    }
    
    func startBLERoom(){
        playerType = TransferService.PERIPHERAL_PL
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    }
    
    func joinBLERoom(){
        playerType = TransferService.CENTRAL_PL
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager?.scanForPeripherals(withServices: [TransferService.serviceUUID], options: nil)
    }
    
    func startWIFIRoom() {
        ptpAdvertiser.startAdvertising(peerID, mcSession)
    }
    
    func joinWIFIRoom(){
        ptpBrowser.startBrowse(peerID, mcSession)
    }
    
    func sendDataBLE(data : Data?, characteristicUUID: CBUUID){
        
        guard data != nil else{
            return
        }
        
        if(characteristicUUID == TransferService.characteristicUUID){
            if(playerType == TransferService.CENTRAL_PL){
                sendDataFromCentral(data: data!, characteristic: chrcSubscribed)
            }else{
                sendDataFromPeripheral(data: data!, characteristic: transferCharacteristic)
            }
        }else if(characteristicUUID == TransferService.endGameCharacteristicUUID){
            if(playerType == TransferService.CENTRAL_PL){
                sendDataFromCentral(data: data!, characteristic: endGameChrcSubscribed)
            }else{
                sendDataFromPeripheral(data: data!, characteristic: endGameCharacteristic)
            }
        }
    }
    
    func sendPTPData(_ data: Data?) {
        
        guard data != nil else{
            return
        }
        
        if mcSession.connectedPeers.count > 0 {
            do {
                try mcSession.send(data!, toPeers: mcSession.connectedPeers, with: .reliable)
            } catch let error {
                print("Error sending data: \(error.localizedDescription)")
            }
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
                peripheral.discoverCharacteristics([TransferService.characteristicUUID, TransferService.endGameCharacteristicUUID], for: service)
                print("Central - Found the service \(service) and looking for characteristics")
            }
        }
    }
    
    // Did Discover Characteristics --> Look for bullet characteristic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            if characteristic.uuid == TransferService.characteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                chrcSubscribed = characteristic
                print("Central - Found bullet characteristic")
            }
            if characteristic.uuid == TransferService.endGameCharacteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                endGameChrcSubscribed = characteristic
                print("Central - Found end game characteristic")
            }
        }
    }
    
    // Found asked characteristic
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if characteristic.uuid == TransferService.characteristicUUID {
            guard let data = characteristic.value else {
                print("Error: No se pudo obtener el valor de la característica bullet.")
                return
            }
            
            if let bullet = deserializeBullet(data) {
                receiveBullet?(bullet)
            } else {
                print("Error: No se pudo deserializar la bala recibida.")
            }
        } else if characteristic.uuid == TransferService.endGameCharacteristicUUID {
            if let data = characteristic.value, let message = String(data: data, encoding: .utf8), message == "Game Over" {
                print("Game Over received")
                endGameReceived?()
            }
        }
    }
    
    func sendDataFromCentral(data: Data, characteristic: CBCharacteristic) {
        peripheralFound.writeValue(data, for: characteristic, type: .withoutResponse)
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
        myService.characteristics = [transferCharacteristic, endGameCharacteristic]
        
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
            guard request.characteristic.uuid == TransferService.characteristicUUID || request.characteristic.uuid == TransferService.endGameCharacteristicUUID else {
                // Not the characteristic we want
                peripheral.respond(to: request, withResult: .attributeNotFound)
                continue
            }
            
            if request.characteristic.uuid == TransferService.characteristicUUID {
                // Obtain the new bullet information
                if let value = request.value {
                    if let bullet = deserializeBullet(value) {
                        print("Peripheral recibe bala en posicion \(String(describing: bullet.position))")
                        receiveBullet?(bullet)
                    }
                }
            } else if let data = request.value, let message = String(data: data, encoding: .utf8), message == "Game Over" {
                endGameReceived?()
            }
        }
    }
    
    func sendDataFromPeripheral(data: Data, characteristic: CBMutableCharacteristic) {
        peripheralManager?.updateValue(data, for: characteristic, onSubscribedCentrals: [centralFound])
    }
    
    func terminateConnection(){
        if playerType == TransferService.CENTRAL_PL {
            if let centralManager = centralManager, let peripheralFound = peripheralFound {
                centralManager.cancelPeripheralConnection(peripheralFound)
            }
        } else if playerType == TransferService.PERIPHERAL_PL {
            if let peripheralManager = peripheralManager {
                peripheralManager.stopAdvertising()
            }
        }
    }
}

extension ConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
            case .connected:
                print("Connected: \(peerID.displayName)")
                onSuccessfulConnection?()
            case .connecting:
                print("Connecting: \(peerID.displayName)")
            case .notConnected:
                print("Not Connected: \(peerID.displayName)")
            @unknown default:
                print("Unknown state received: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("Received PTP data: \(data)")
        if let bullet = deserializeBullet(data) {
            print("PTP - bullet at position \(String(describing: bullet.position))")
            receiveBullet?(bullet)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}
