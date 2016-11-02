//
//  SettingVIewController.swift
//  BLEPeripheral
//
//  Created by Hiroaki Egashira on 11/2/16.
//  Copyright © 2016 今野浩紀. All rights reserved.
//

import UIKit
import CoreBluetooth

class SettingVIewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource {
    fileprivate let tableView = UITableView()
    fileprivate let protectView = UIView()
    fileprivate let indicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    fileprivate var centralManager: CBCentralManager!
    fileprivate var peripherals = Set<CBPeripheral>()
    fileprivate var peripheralsAry:[CBPeripheral] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        configureAppearance()
        configureBLE()
    }
    
}

// MARK: - private methods
private extension SettingVIewController {
    func configureTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func configureAppearance() {
        let refreshBtn = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refresh))
        self.navigationItem.rightBarButtonItem = refreshBtn
        
        tableView.frame = view.frame
        view = tableView
        
        protectView.frame = view.frame
        protectView.alpha = 0.6
        protectView.backgroundColor = .black
        protectView.isHidden = true
        view.addSubview(protectView)
        
        indicator.center = CGPoint(x: view.center.x, y: view.center.y)
        protectView.addSubview(indicator)
        
        tableView.tableFooterView = UIView()
        tableView.bounces = false
    }
    
    func configureBLE() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    @objc func refresh() {
        peripherals.removeAll()
        peripheralsAry.removeAll()
        
        startScan()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(3)) {
            self.stopScan()
        }
    }
    
    func startScan(){
        protectView.isHidden = false
        indicator.startAnimating()
        
        print("start scanning")
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScan(){
        centralManager.stopScan()
        peripheralsAry = Array(self.peripherals)
        tableView.reloadData()
        protectView.isHidden = true
        indicator.stopAnimating()
    }
    
}

// MARK: - CBCentralManagerDelegate
internal extension SettingVIewController {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOff:
            print("PoweredOff")
            
        case .poweredOn:
            print("PoweredOn")
            
            startScan()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(4)) {
                self.stopScan()
            }
    
        case .resetting:
            print("Reseting")
            
        case .unauthorized:
            print("Unauthorized")
            
        case .unknown:
            print("Unknown")
            
        case .unsupported:
            print("Unsupported")
        }
    }
    
    // if peripheral's name is not "raspberrypi", the peripheral will not be inserted.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name, name == "raspberrypi" else { return }
            
        print("discovered peripheral")
        peripherals.insert(peripheral)
    
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connection success")
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("connection failed")
    }
}

// MARK: - CBPeripheralDelegate
internal extension SettingVIewController {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("failed to discover services")
            print("disconnect with peripheral")
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
        guard let services = peripheral.services else {
            print("This peripheral does not have any services")
            print("disconnect with peripheral")
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("failed to discover characteristics")
            print("disconnect with peripheral")
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
        guard let characteristics = service.characteristics else {
            print("This service does not have any characteristics")
            print("disconnect with peripheral")
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        
        for characteristic in characteristics {
            print("writting value to characteristic")
            
            let str = "some data"
            let data = str.data(using: .utf8)!
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("failed to write data")
        }else{
            print("success to write data")
        }
        
        print("disconnect with peripheral")
        centralManager.cancelPeripheralConnection(peripheral)
    }
}

// MARK: - UITableViewDelegate
internal extension SettingVIewController {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral = peripheralsAry[indexPath.row]
        
        print("connecting \(peripheral.name!)")
        centralManager.connect(peripheral, options: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

// MARK: - UITableViewDataSource
internal extension SettingVIewController {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheralsAry.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        guard let label = cell.textLabel, let name = peripheralsAry[indexPath.row].name else {
            return UITableViewCell()
        }
        
        label.text = String(name)
        
        return cell
    }
}
