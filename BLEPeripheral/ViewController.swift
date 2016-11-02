//
//  ViewController.swift
//  BLEPeripheral
//
//  Created by 今野浩紀 on 2016/09/15.
//  Copyright © 2016年 今野浩紀. All rights reserved.
//

import UIKit

class ViewController: UIViewController{

    let ble: BLEImplementation = BLEImplementation()
    
    @IBAction func scanButton(_ sender: AnyObject) {
        ble.startDiscover()
    }
    
    
    override func viewDidLoad(){
        super.viewDidLoad()
    }

}

