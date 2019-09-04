//
//  MainViewController.swift
//  CompassCompanion
//
//  Created by Rick Smith on 04/07/2016.
//  Copyright © 2016 Rick Smith. All rights reserved.
//

import UIKit
import Moya
import CoreLocation
import CoreBluetooth

class MainViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

  var resetButton = UIButton()

  var manager:CBCentralManager? = nil
  var mainPeripheral:CBPeripheral? = nil
  var mainCharacteristic:CBCharacteristic? = nil

  let BLEService = "DFB0"
  let BLECharacteristic = "DFB1"

  let ringBoom = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
  let ringSend = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
  let ringGet  = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
    
  @IBOutlet weak var recievedMessageText: UILabel!
  var detailLabel = UILabel()

  // 座標位置
  let userLocation = CLLocationManager()
  var currentLocation: CLLocation?

  // 使用者
  var userDetail = User()
  let provider = MoyaProvider<BluetoothApi>()
    
  override func viewDidLoad() {
    super.viewDidLoad()

    // 觸發 centralManagerDidUpdateState
    manager = CBCentralManager(delegate: self, queue: nil);
    customiseNavigationBar()

    setButton()
    setDetailLabel()

    userLocation.delegate = self
//  開始定位
    userLocation.startUpdatingLocation()
//  限制距離已觸發delegate
    userLocation.distanceFilter = 150
  }

  override func viewDidAppear(_ animated: Bool) {

    if CLLocationManager.authorizationStatus() == .notDetermined {

      userLocation.requestWhenInUseAuthorization()
      userLocation.startUpdatingLocation()
    }
    else if CLLocationManager.authorizationStatus() == .denied {

      let alertController = UIAlertController(title: "定位權限已關閉",
                                              message: "如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟",
                                              preferredStyle: .alert)

      let okAction = UIAlertAction(title: "去開啟", style: .cancel) { _ in
        let url = URL(string: UIApplicationOpenSettingsURLString)

        if let url = url, UIApplication.shared.canOpenURL(url) {

          if #available(iOS 10, *) { UIApplication.shared.open(url,
                                                               options: [:],
                                                               completionHandler: { (success) in })

          } else {
            UIApplication.shared.openURL(url)
          }
        }
      }

      let iKnowAction = UIAlertAction(title: "知道了", style: .default, handler: nil)

      alertController.addAction(iKnowAction)
      alertController.addAction(okAction)
      self.present(alertController,
                   animated: true,
                   completion: nil)
    }
      // 使用者已經同意定位自身位置權限
    else if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {

      userLocation.startUpdatingLocation()
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    if (segue.identifier == "scan-segue") {
      let scanController : ScanTableViewController = segue.destination as! ScanTableViewController

      //set the manager's delegate to the scan view so it can call relevant connection methods
      manager?.delegate = scanController
      scanController.manager = manager
      scanController.parentView = self
    }

  }

  func setDetailLabel() {

    let main = view.bounds
    detailLabel.frame = CGRect(x: main.midX - 125, y: main.midY + 150, width: 250, height: 150)
    detailLabel.textAlignment = .center
    detailLabel.backgroundColor = .skyBlue
    detailLabel.layer.cornerRadius = 25
    detailLabel.clipsToBounds = true
    detailLabel.numberOfLines = 5
    detailLabel.text = "HERE"
    view.addSubview(detailLabel)
  }

  func setButton() {

    let main = view.bounds
    resetButton.frame = CGRect(x: main.midX - 25, y: main.midY + 50, width: 60, height: 50)
    resetButton.backgroundColor = .lightGray
    resetButton.setTitle("clear", for: .normal)
    resetButton.layer.cornerRadius = 10
    resetButton.addTarget(self, action: #selector(actionButton), for: .touchUpInside)
    view.addSubview(resetButton)
  }

  @objc func actionButton() {

    recievedMessageText.text = "clear ..."
    detailLabel.text = "clear ..."
  }
    
    func customiseNavigationBar () {
        
        self.navigationItem.rightBarButtonItem = nil
        
        let rightButton = UIButton()
        
        if (mainPeripheral == nil) {
            rightButton.setTitle("Scan", for: [])
            rightButton.setTitleColor(UIColor.blue, for: [])
            rightButton.frame = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 60, height: 30))
            rightButton.addTarget(self, action: #selector(self.scanButtonPressed), for: .touchUpInside)
        } else {
            rightButton.setTitle("Disconnect", for: [])
            rightButton.setTitleColor(UIColor.blue, for: [])
            rightButton.frame = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 100, height: 30))
            rightButton.addTarget(self, action: #selector(self.disconnectButtonPressed), for: .touchUpInside)
        }
        
        let rightBarButton = UIBarButtonItem()
        rightBarButton.customView = rightButton
        self.navigationItem.rightBarButtonItem = rightBarButton
    }

    // MARK: Button Methods
    @objc func scanButtonPressed() {
        performSegue(withIdentifier: "scan-segue", sender: nil)
    }
    
    @objc func disconnectButtonPressed() {
        //this will call didDisconnectPeripheral, but if any other apps are using the device it will not immediately disconnect
        manager?.cancelPeripheralConnection(mainPeripheral!)
    }
        
    // MARK: - CBCentralManagerDelegate Methods    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        mainPeripheral = nil
        customiseNavigationBar()
        print("Disconnected" + peripheral.name!)
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(central.state)
    }
    
    // MARK: CBPeripheralDelegate Methods 判斷設備 uuid
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        for service in peripheral.services! {
            
            print("Service found with UUID: " + service.uuid.uuidString)
            
            //device information service
            if service.uuid.uuidString == ringSend {
                peripheral.discoverCharacteristics(nil, for: service)
            }
            
            //GAP (Generic Access Profile) for Device Name
            // This replaces the deprecated CBUUIDGenericAccessProfileString
            if service.uuid.uuidString == ringGet {
                peripheral.discoverCharacteristics(nil, for: service)
            }
            
            //Bluno Service
            if service.uuid.uuidString == ringBoom {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }


    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {

        //get device name
      if (service.uuid.uuidString == ringBoom) {

        for characteristic in service.characteristics! {

          if (characteristic.uuid.uuidString == ringGet) {
            //we'll save the reference, we need it to write data
            mainCharacteristic = characteristic

            //Set Notify is useful to read incoming data async
            peripheral.setNotifyValue(true, for: characteristic)
            print("Found ringringBoom Data Characteristic")
          }
        }
      }
        
    }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

    if characteristic.uuid.uuidString == ringGet {

      let stringValue = String(data: characteristic.value!, encoding: String.Encoding.utf8)!

      recievedMessageText.text = stringValue

      detailLabel.text = "now floor:  \(userDetail.floorid)\ndeviceid:  \(userDetail.deviceid)\nuser lat: \(userDetail.lat)\nuser lng:  \(userDetail.lng)"


      let request = BluetoothApi.request(floorid: userDetail.floorid,
                                         deviceid: userDetail.deviceid,
                                         lat: userDetail.lat,
                                         lng: userDetail.lng)

      provider.request(request) { (result) in
        switch result {

        case .success(_):
          print("Cool")
        case .failure(_):
          print("Too bad")
        }
      }
    } else if characteristic.uuid.uuidString == ringSend {

      let stringValue = String(data: characteristic.value!, encoding: String.Encoding.utf8)!

      recievedMessageText.text = stringValue
    }
  }

  /* 將資料傳送到 peripheral 時如果遇到錯誤會呼叫 */
  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    if error != nil {
      print("寫入資料錯誤: \(error!)")
    }
  }
    
}
