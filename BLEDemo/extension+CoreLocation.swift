//
//  extension+CoreLocation.swift
//  BLEDemo
//
//  Created by 洪立德 on 2019/9/4.
//  Copyright © 2019 Rick Smith. All rights reserved.
//

import CoreLocation

extension MainViewController: CLLocationManagerDelegate {


  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // 取得目前最新位置
    currentLocation = locations.last

    userDetail.floorid = "2"
    userDetail.deviceid = "12"
    userDetail.lat = (currentLocation?.coordinate.latitude)!
    userDetail.lng = (currentLocation?.coordinate.longitude)!
    print("成功取得位置資料")
  }
}
