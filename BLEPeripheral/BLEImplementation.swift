//
//  BLEImplementation.swift
//  BLEPeripheral
//
//  Created by 今野浩紀 on 2016/10/26.
//  Copyright © 2016年 今野浩紀. All rights reserved.
//

import Foundation
import CoreBluetooth

class BLEImplementation:  NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager!
    var peripheralArray = [CBPeripheral]()
    var serviceArray = [CBService]()
    var characteristicArray = [CBCharacteristic]()
    var nearestPeripheral: CBPeripheral!
    var tempRSSI: Int! = -100
    var timer: Timer!
    var text: String!
    
    func startDiscover(){
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        //最初にcentralManagerDidUpdateStateメソッドが呼び出される
        //scanForPeripherals
        //見つかったペリフェラルそれぞれに対してcentralManager(CBCentralManager, didDiscoverPeripheral, advertisementData, rssi)
        //目的のペリフェラルが見つかったらスキャンを停止しないとずっとスキャンし続ける
        //connectPeripheralメソッドで接続
        
    }
    
    // 1
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOff:
            print("PoweredOff")
        
        //コレが呼ばれる
        case .poweredOn:
            print("PoweredOn")
            central.scanForPeripherals(withServices: nil, options: nil)
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.onTime), userInfo: nil, repeats: false)
            //初期化
            nearestPeripheral = nil
            
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
    
    // 2
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        //見つけたペリフェラルの名前,uuid,rssiをコンソールに表示
        guard let name = peripheral.name else { return }
        let uuidString = peripheral.identifier.uuidString
        print(advertisementData)
        print(name)
        print(uuidString)
        print(RSSI)
        print("---------------------")
        
       //新発見のperipheralをリストに格納
        if peripheralArray.index(of: peripheral) == nil{
            self.peripheralArray.append(peripheral)
        }

        //一番近いやつに上書き
        if RSSI.intValue >= tempRSSI && peripheral.name == "raspberrypi"{
            tempRSSI = RSSI.intValue
            nearestPeripheral = peripheral
        }
    }
    
    //スキャン開始後1秒たったら呼ばれる
    func onTime(){
        //スキャン終了
        self.centralManager.stopScan()
        
        //見つかったペリフェラルをコンソール出力
        print("------scan ended------")
        
        if(nearestPeripheral == nil){
            print("見つからなかったか，接続スパンが短すぎ")
            return
        }
        
        for i in 0...peripheralArray.count-1{
            print(peripheralArray[i].identifier.uuidString)
        }
        
        //一番近いのをコンソール出力
        print("---------------------")
        print("nearest is: ")
        print(nearestPeripheral.name!)
        print(tempRSSI)

        //初期化
        peripheralArray = []
        tempRSSI = -100
        
        //接続処理
        centralManager.connect(nearestPeripheral, options: nil)
    }
    
    
    //接続成功で呼ばれる
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("接続成功")
        
        //サービス検索
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
    }
    
    //接続失敗で呼ばれる
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("接続失敗")
    }
    
    //サービスが見つかったら呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error{
            print("error: \(error)")
            return
        }
        
        let services = peripheral.services!
        print("service:\(services.count) \(services)")
        
        //キャラクタリスティック検索
        for service in services{
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    //キャラクタリスティックが見つかったら呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil{
            print("エラー \(error)")
            return
        }
        
        let characteristics = service.characteristics!
        print("characteristics: \(characteristics)")

        //リードを行わない場合はここで切断
        //centralManager.cancelPeripheralConnection(peripheral)
        
        
        //値をリードする
        for characteristic in characteristics{
            //peripheral.readValue(for: characteristic)
            
        }
        
        //値をライトする
        for characteristic in characteristics {
            let new_str = "writting test"
            let data = new_str.data(using: .utf8, allowLossyConversion: true)
            peripheral.writeValue(data!, for: characteristic, type: .withResponse)
        }
 
    }
    
    //書き込み失敗した時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("書き込み失敗")
    }
    
    
    //リードしたら呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil{
            print("読み込めなかった \(error)")
            return
        }
        
        guard let value = characteristic.value else { return }
        guard let str = String(data: value, encoding: .utf8) else { return }
        
        print("value: \(str)")
        
        
        
//        guard let new_value = characteristic.value else { return }
//        guard let new_new_str = String(data: new_value, encoding: .utf8) else { return }
//        
//        print("value: \(new_new_str)")
        
        //得た情報をナビゲートに反映
        
        
        //切断
        centralManager.cancelPeripheralConnection(peripheral)
        
    }
    
    func writingTest(){
        
    }
    
}
