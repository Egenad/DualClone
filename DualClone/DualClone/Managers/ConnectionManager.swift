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
    var playerNameReceived: (() -> Void)?
    
    var playerType = TransferService.CENTRAL_PL
    var connectionType = TransferService.BLE_OPTION
    
    var gameFinished = false
    var playerName = ""
    var enemyPlayerName = ""
    
    // --- CENTRAL ---
    var centralManager: CBCentralManager?
    var peripheralFound: CBPeripheral!
    var chrcSubscribed: CBCharacteristic!
    var endGameChrcSubscribed: CBCharacteristic!
    var nameChrcSubscribed: CBCharacteristic!
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
    
    var playerNameCharacteristic = CBMutableCharacteristic(type: TransferService.nameCharacteristicUUID,
                                                        properties: [.notify, .write, .read, .writeWithoutResponse],
                                                        value: nil,
                                                        permissions: [.readable, .writeable])

    var chrSubscribedList: [CBUUID: CBCharacteristic] = [:]
    var chrOriginalList: [CBUUID: CBMutableCharacteristic] = [:]
    
    // --- MAIN FUNCTIONS ---
    
    func initParameters(){
        chrOriginalList = [
            TransferService.characteristicUUID: transferCharacteristic,
            TransferService.endGameCharacteristicUUID: endGameCharacteristic,
            TransferService.nameCharacteristicUUID: playerNameCharacteristic
        ]
    }
    
    func createPTPSession(){
        // Create a unique identifier for the peer
        print("Creating peerID with name: \(UIDevice.current.name)")
        peerID = MCPeerID(displayName: UIDevice.current.name)
        
        // Create the session with the peer ID and assign the delegate
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        print("Session created: \(String(describing: mcSession))")
    }
    
    func startBLERoom(){
        connectionType = TransferService.BLE_OPTION
        playerType = TransferService.PERIPHERAL_PL
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    }
    
    func joinBLERoom(){
        connectionType = TransferService.BLE_OPTION
        playerType = TransferService.CENTRAL_PL
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager?.scanForPeripherals(withServices: [TransferService.serviceUUID], options: nil)
    }
    
    func startWIFIRoom() {
        createPTPSession()
        connectionType = TransferService.WIFI_OPTION
        playerType = TransferService.PERIPHERAL_PL
        ptpAdvertiser.startAdvertising(peerID, mcSession)
    }
    
    func joinWIFIRoom(){
        createPTPSession()
        connectionType = TransferService.WIFI_OPTION
        playerType = TransferService.CENTRAL_PL
        ptpBrowser.startBrowse(peerID, mcSession)
    }
    
    func ptpDisconnect() {
        ptpBrowser.disconnect()
        ptpAdvertiser.disconnect()
        mcSession?.disconnect()
        print("PTP - Disconnected from session")
    }
    
    func sendDataBLE(data : Data?, characteristicUUID: CBUUID){
        
        guard data != nil else{
            return
        }
        
        if(playerType == TransferService.CENTRAL_PL){
            if let characteristicToWrite = chrSubscribedList[characteristicUUID] {
                sendDataFromCentral(data: data!, characteristic: characteristicToWrite)
            }
        }else if(playerType == TransferService.PERIPHERAL_PL){
            if let characteristicToWrite = chrOriginalList[characteristicUUID] {
                sendDataFromPeripheral(data: data!, characteristic: characteristicToWrite)
            }
        }
    }
    
    func sendPTPData(_ msg: PTPMessage?) {
        
        guard msg != nil else{
            return
        }
        
        if mcSession.connectedPeers.count > 0 {
            do {
                let data = try JSONEncoder().encode(msg)
                try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
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
        print ("Central - Connected with peripheral: " + peripheral.name!)
    }
}

// ---- CENTRAL - PERIPHERAL ----

extension ConnectionManager: CBPeripheralDelegate{
    
    // Did Discover Service --> Discover Characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            if service.uuid == TransferService.serviceUUID {
                peripheral.discoverCharacteristics(TransferService.uuidList, for: service)
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
            else if characteristic.uuid == TransferService.endGameCharacteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                endGameChrcSubscribed = characteristic
                print("Central - Found end game characteristic")
            }
            else if characteristic.uuid == TransferService.nameCharacteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                nameChrcSubscribed = characteristic
                print("Central - Found name characteristic")
                
                print("Central - sended playername: \(self.playerName)")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.sendDataBLE(data : self.playerName.data(using: .utf8)!, characteristicUUID: TransferService.nameCharacteristicUUID)
                }
            }
        }
        
        chrSubscribedList = [
            TransferService.characteristicUUID: chrcSubscribed,
            TransferService.endGameCharacteristicUUID: endGameChrcSubscribed,
            TransferService.nameCharacteristicUUID: nameChrcSubscribed
        ]
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
        } else if characteristic.uuid == TransferService.nameCharacteristicUUID {
            
            print("Central - obtained name characteristic")
            
            if let data = characteristic.value, let name = String(data: data, encoding: .utf8) {
                print("Enemy player name: \(name)")
                enemyPlayerName = name
                playerNameReceived?()
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
        myService.characteristics = [transferCharacteristic, endGameCharacteristic, playerNameCharacteristic]
        
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
            print( "Peripheral: Error posting a service:" + myError.localizedDescription)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Peripheral - He encontrado central")
        if characteristic.uuid == TransferService.characteristicUUID {
            
            centralFound = central
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.sendDataBLE(data: self.playerName.data(using: .utf8), characteristicUUID: TransferService.nameCharacteristicUUID)
            }
            
            // Starting game on peripheral
            onSuccessfulConnection?()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
        print("Peripheral - data received")
        
        for request in requests {
            guard TransferService.uuidList.contains(request.characteristic.uuid) else {
                // Not the characteristic we want
                peripheral.respond(to: request, withResult: .attributeNotFound)
                continue
            }
            
            if request.characteristic.uuid == TransferService.characteristicUUID {
                // Obtain the new bullet information
                if let value = request.value {
                    if let bullet = deserializeBullet(value) {
                        receiveBullet?(bullet)
                    }
                }
            } else if let data = request.value, let message = String(data: data, encoding: .utf8), message == "Game Over" {
                endGameReceived?()
            } else if request.characteristic.uuid == TransferService.nameCharacteristicUUID {
                if let data = request.value, let name = String(data: data, encoding: .utf8) {
                    enemyPlayerName = name
                    playerNameReceived?()
                }
            }
        }
    }
    
    func sendDataFromPeripheral(data: Data, characteristic: CBMutableCharacteristic) {
        peripheralManager?.updateValue(data, for: characteristic, onSubscribedCentrals: [centralFound])
    }
    
    func terminateConnection(){
        if(connectionType == TransferService.BLE_OPTION){
            if playerType == TransferService.CENTRAL_PL {
                if let centralManager = centralManager, let peripheralFound = peripheralFound {
                    centralManager.cancelPeripheralConnection(peripheralFound)
                }
            } else if playerType == TransferService.PERIPHERAL_PL {
                if let peripheralManager = peripheralManager {
                    peripheralManager.stopAdvertising()
                }
            }
        }else if(connectionType == TransferService.WIFI_OPTION){
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.ptpDisconnect()
            }
        }
    }
}

// ----------------------------------------------------------------------------------------------------------- //

// ---- PTP ----

extension ConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
            case .connected:
                print("Connected: \(peerID.displayName)")
                
                // Send player name
            let nameMessage = PTPMessage(type: .playerName, content: playerName.data(using: .utf8))
            
                sendPTPData(nameMessage)
            
                print("PTP - Sended playername: \(playerName)")
            
                onSuccessfulConnection?()
            case .connecting:
                print("Connecting: \(peerID.displayName)")
            case .notConnected:
                print("Not Connected: \(peerID.displayName)")
                
                if session.connectedPeers.isEmpty && !gameFinished {
                    print("Warning: All peers disconnected.")
                    // Try to reconnect
                    attemptReconnect()
                }
            
            @unknown default:
                print("Unknown state received: \(peerID.displayName)")
        }
    }
    
    func attemptReconnect() {
        if mcSession?.connectedPeers.isEmpty == true {
            
            print("Attempting to reconnect...")
            
            if(playerType == TransferService.PERIPHERAL_PL){
                ptpAdvertiser.startAdvertising(peerID, mcSession)
            }else{
                ptpBrowser.startBrowse(peerID, mcSession)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        do {
            let message = try JSONDecoder().decode(PTPMessage.self, from: data)
            handleReceivedMessage(message)
        } catch {
            print("Error recibiendo el mensaje: \(error.localizedDescription)")
        }
        
        print("Received PTP data: \(data)")
        /*if let bullet = deserializeBullet(data) {
            print("PTP - bullet at position \(String(describing: bullet.position))")
            receiveBullet?(bullet)
        }else if let message = String(data: data, encoding: .utf8), message == "Game Over" {
            gameFinished = true
            endGameReceived?()
        }else if let name = String(data: data, encoding: .utf8) {
            print("PTP - player name: \(name)")
            self.enemyPlayerName = name
            playerNameReceived?()
        }*/
    }
    
    private func handleReceivedMessage(_ message: PTPMessage){
        if let content = message.content {
            switch message.type {
                case .gameOver:
                    if let message = String(data: content, encoding: .utf8), message == "Game Over" {
                        gameFinished = true
                        endGameReceived?()
                    }
                case .bullet:
                    if let bullet = deserializeBullet(content) {
                        print("PTP - bullet at position \(String(describing: bullet.position))")
                        receiveBullet?(bullet)
                    }
                case .playerName:
                    if let name = String(data: content, encoding: .utf8) {
                        print("PTP - player name: \(name)")
                        self.enemyPlayerName = name
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.playerNameReceived?()
                        }
                    }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        if let myError = error {
            print( "PTP - Connection finished: " + myError.localizedDescription)
        }
    }
}
