//
//  BLE.swift
//  BluTransducer
//
//  Created by David Kopp on 8/9/18.
//  Copyright © 2018 Validyne. All rights reserved.
//

// MARK: - This class is a singleton that services the connection between the application and the bluetooth component of the iphone.

import Foundation
import CoreBluetooth

private let SERVICEUUID = CBUUID(string: "0x2220") // discover
private let RECEIVEUUID = CBUUID(string: "0x2221") // recieve
private let SENDUUID = CBUUID(string: "0x2222") // send
private let DISCONNECTUUID = CBUUID(string: "0x2223") // disconnect
private var timer = Timer()

class BLE: NSObject {
    
    // MARK: - BLE shared instance
    static let sharedInstance = BLE()
    
    // MARK: - Properties
    var centralManager: CBCentralManager!
    var activeDevice: CBPeripheral!
    var listDevices = [CBPeripheral]()
    var rfDuinoData = String()
    var sendCharacteristic: CBCharacteristic!
    
    // MARK: - Init Method
    private override init() { }
}

// MARK: - CBCentralManagerDelegate protocol conformance
extension BLE: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: [SERVICEUUID])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected to " + activeDevice.name!)
        
        centralManager.stopScan()
        
        if centralManager.isScanning == false {
            print("Scanning has stopped")
        }
        peripheral.delegate = self
        peripheral.discoverServices([SERVICEUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from " + activeDevice.name!)
    }
    
//    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
//        //central.connect(activeDevice)
//        print("Restoring connecting to " + activeDevice.name!)
//    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Error connecting " + error.debugDescription)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Device Name: " + peripheral.name!)
        print("Advertisement Data: " + advertisementData.description)
        listDevices.append(peripheral)
        //print("List Devices: " + listDevices[0].name!)
    }
}

// MARK: - CBPeripheralDelegate protocol conformance
extension BLE: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Did discover services")
        
        if let discoveredServices = peripheral.services {
            for service in discoveredServices {
                if service.uuid == SERVICEUUID {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            print("did discover characteristic with UUID: " + characteristic.uuid.description)
            if characteristic.uuid == RECEIVEUUID {
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)
            } else if characteristic.uuid == SENDUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                sendCharacteristic = characteristic
            }
        }
        
        print("Did discover characteristics for service")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        if let string = String.init(data: data, encoding: String.Encoding.utf8) {
            print("Did recieve data from rfDuino = \(string)")
            rfDuinoData = string
            
        } else {
            print("Did recieve data from rfDuino")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            print("Error Discovering Services: error")
            return
        }
        print("Message send")
    }
}

// MARK: Helper Methods
extension BLE {
    
    // MARK: BLE Methods
    
    /// Starts the centralManager to initialize Bluetooth
    func start() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Connects to the device from the pickerview list
    func connect(device: CBPeripheral) {
        activeDevice = device
        centralManager.connect(activeDevice)
    }
    
    /// Disconnects the active Bluetooth connection
    func disconnect() {
        centralManager.cancelPeripheralConnection(activeDevice)
    }
    
    /// Sends data to the Bluetooth device(rfduino)
    func writeValue(data: Data) {
        activeDevice.writeValue(data, for: sendCharacteristic!, type: .withResponse)
    }
    
    /// Checks to see if a connection is active. Sends back a boolean value
    func isConnected() -> Bool {
        if activeDevice == nil {
            return false
        } else {
            return true
        }
    }
}
