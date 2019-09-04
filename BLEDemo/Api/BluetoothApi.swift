//
//  BluetoothApi.swift
//  BLEDemo
//
//  Created by 洪立德 on 2019/9/4.
//  Copyright © 2019 Rick Smith. All rights reserved.
//

import Foundation
import Moya

public enum BluetoothApi {

  case request(floorid: String, deviceid: String, lat: Double, lng: Double)
}

extension BluetoothApi: TargetType {

  public var baseURL: URL {
    return URL(string: "http://180.176.40.140/n3dtest")!
  }

  public var path: String {
    switch self {
    case .request(let floorid, let deviceid, let lat, let lng):
      return "/n3ddevlog.php"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .request:
      return .get
    }
  }

  public var sampleData: Data {
    return Data()
  }

  public var task: Task {

    switch self{
    case .request(let floorid, let deviceid, let lat, let lng):
      return .requestParameters(parameters: ["floorid" : floorid, "devid" : deviceid, "lat" : lat, "lng" : lng], encoding: URLEncoding.queryString)
    }
    
  }

  public var headers: [String : String]? {
    return nil
  }
}
