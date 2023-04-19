//
//  CommonClass.swift
//  nRF Mesh
//
//  Created by Hưng Nguyễn on 19/04/2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import nRFMeshProvision


// MARK: - Translate
public func vietSub(_ STR: String!) -> String {
    if (NSLocalizedString(STR, comment: "") == "")
    {
        return STR
    }
    return NSLocalizedString(STR, comment: "")
}



public class ProxyFilterNode: NSObject, NSCoding, Codable {

    var ID:         UInt16
    var uuid:       String
    var type:       String

    static let _id = "id"
    static let _address = "address"
    static let _data = "data"

    init(id: UInt16, uuid: String, type: String) {
        self.ID = id
        self.uuid = uuid
        self.type = type
    }
    required convenience public init(coder aDecoder: NSCoder) {
        let ID = aDecoder.decodeObject(forKey: "id_automation") as! UInt16
        let uuid = aDecoder.decodeObject(forKey: "address_automation") as! String
        let type = aDecoder.decodeObject(forKey: "data_automation") as! String
        self.init(id: ID, uuid: uuid, type: type)
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(ID, forKey: "id_automation")
        aCoder.encode(uuid, forKey: "address_automation")
        aCoder.encode(type, forKey: "data_automation")
    }
    enum CodingKeys: String, CodingKey {
        case ID
        case uuid
        case type
    }
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ID = try container.decode(UInt16.self, forKey: .ID)
        uuid = try container.decode(String.self, forKey: .uuid)
        type = try container.decode(String.self, forKey: .type)
    }
}




class HunExtensions{
  func getDeviceUUIDtoMACformat(uuidToString: String) -> String{
    let uuidHex = uuidToString.replacingOccurrences(of: "-", with: "")
    let macHex = uuidHex.suffix(12)
    let macString = stride(from: 0, to: 12, by: 2).map { i -> String in
        let startIndex = macHex.index(macHex.startIndex, offsetBy: i)
        let endIndex = macHex.index(macHex.startIndex, offsetBy: i+2)
        return String(macHex[startIndex..<endIndex])
    }.joined(separator: ":").suffix(5)
    return "\(macString)"
  }

}



extension Model{

  var isSupport: Bool {
    let idx = Apollo.Model.ListModel.firstIndex(of: modelId32)
    if(idx != nil) {
      return true
    }else{
      return false
    }
  }

  var modelId32: UInt32 {
    let companyId = isBluetoothSIGAssigned ? 0 : companyIdentifier!
    return (UInt32(companyId) << 16) | UInt32(modelIdentifier)
  }
}


class Apollo {

  class Model {
    static let GenericOnOffServer:          UInt32 = 0x1000
    static let GenericOnOffClient:          UInt32 = 0x1001
    static let GenericLevelServer:          UInt32 = 0x1002
    static let GenericLevelClient:          UInt32 = 0x1003
    static let SceneSever:                  UInt32 = 0x1203
    static let SceneSetupServer:            UInt32 = 0x1204
    static let SceneClient:                 UInt32 = 0x1205
    static let LightLightnessServer:        UInt32 = 0x1300
    static let LightLightnessClient:        UInt32 = 0x1302
    static let LightCTLServer:              UInt32 = 0x1303
    static let LightCTLClient:              UInt32 = 0x1305
    static let LightHSLServer:              UInt32 = 0x1307
    static let LightHSLClient:              UInt32 = 0x1309
    static let VendorLightServer:           UInt32 = 0x80010001
    static let VendorLightClient:           UInt32 = 0x80018001
    static let VendorPIRServer:             UInt32 = 0x80020002
    static let VendorPIRClient:             UInt32 = 0x80028002
    static let VendorLightSensorServer:     UInt32 = 0x80030003
    static let VendorLightSensorClient:     UInt32 = 0x80038003
    static let VendorGatewayServer:         UInt32 = 0x80000000
    static let VendorRemoteServer:          UInt32 = 0x80060006
    static let VendorRemoteClient:          UInt32 = 0x80068006

    static let ListModel:[UInt32] = [
//      0x1000,
//      0x1001,
//      0x1002,
//      0x1003,
//      0x1004,
//      0x1006,
//      0x1007,
//      0x1102,
//      0x1203,
//      0x1204,
//      0x1205,
//      0x1207,
//      0x1300,
//      0x1301,
//      0x1302,
//      0x1303,
//      0x1305,
//      0x1307,
//      0x1308,
//      0x1309,
//      0x1310,
//      0x130F,
//      0x80010000,
//      0x80010001,
//      0x80018001,
//      0x80020002,
//      0x80028002,
//      0x80030003,
//      0x80038003,
//      0x80000000,
//      0x80060006,
//      0x80068006
      0x1000,
      0x1001,
      0x1002,
      0x1003,
      0x1203,
      0x1204,
      0x1205,
      0x1300,
      0x1302,
      0x1303,
      0x1305,
      0x1307,
      0x1309,
      0x80010000,
      0x80010001,
      0x80018001,
      0x80020002,
      0x80028002,
      0x80030003,
      0x80038003,
      0x80000000,
      0x80060006,
      0x80068006
    ]

    ////
    static let ListModelToControl:[UInt32] = [
      0x1000,
      0x1001,
      0x1002,
      0x1003,
      0x1203,
      0x1204,
      0x1205,
      0x1300,
      0x1302,
      0x1303,
      0x1305,
      0x1307,
      0x1309,
      0x80010000,
      0x80010001,
      0x80018001,
      0x80020002,
      0x80028002,
      0x80030003,
      0x80038003,
      0x80000000,
      0x80060006,
      0x80068006
    ]

    static let ListServerModel:[UInt32] = [
      0x1000,
      0x1002,
      0x1203,
      0x1204,
      0x1300,
      0x1303,
      0x1307,
      0x80010001,
      0x80020002,
      0x80030003,
      0x80060006,
      0x80000000
    ]

    static let ListClientModel:[UInt32] = [
      0x1001,
      0x1003,
      0x1205,
      0x1302,
      0x1305,
      0x1309,
      0x80018001,
      0x80028002,
      0x80038003,
      0x80068006
    ]
  }

  class Node {
    static let ListProductID:[UInt16] = [
      0x1000 ,//: "Apollo Mini Gateway",
      0x1002 ,//: "Apollo PIR Sensor",
      0x1003 ,//: "Apollo Light Sensor",
      0x1004 ,//: "Apollo Temperature Sensor",
      0x1005 ,//: "Switch 1 Chanel",
      0x1006 ,//: "Remote",
      0x1050 ,//: "Apollo Bulb A60 D" ,
      0x1051 ,//: "Apollo Bulb A60 W" ,
      0x1052 ,//: "Apollo Bulb A60 RGB" ,
      0x1053 ,//: "Apollo Bulb A60 RGBD" ,
      0x1054 ,//: "Apollo Bulb A60 RGBW" ,
      0x1055 ,//: "Apollo Bulb A60 RGBDW" ,
      0x1056 ,//: "Apollo Bulb G95 D" ,
      0x1057 ,//: "Apollo Bulb G95 W" ,
      0x1058 ,//: "Apollo Bulb G95 RGB" ,
      0x1059 ,//: "Apollo Bulb G95 RGBD" ,
      0x105A ,//: "Apollo Bulb G95 RGBW" ,
      0x105B ,//: "Apollo Bulb G95 RGBDW" ,
      0x105C ,//: "Apollo Bulb G120 D" ,
      0x105D ,//: "Apollo Bulb G120 W" ,
      0x105E ,//: "Apollo Bulb G120 RGB" ,
      0x105F ,//: "Apollo Bulb G120 RGBD" ,
      0x1060 ,//: "Apollo Bulb G120 RGBW" ,
      0x1061 ,//: "Apollo Bulb G120 RGBDW" ,
      0x1062 ,//: "Apollo Led Trip D" ,
      0x1063 ,//: "Apollo Led Trip W" ,
      0x1064 ,//: "Apollo Led Trip RGB" ,
      0x1065 ,//: "Apollo Led Trip RGBD" ,
      0x1066 ,//: "Apollo Led Trip RGBW" ,
      0x1067 ,//: "Apollo Led Trip RGBDW" ,
      0x1068 ,//: "Apollo LRD04 P5 D" ,
      0x1069 ,//: "Apollo LRD04 P5 W" ,
      0x106A ,//: "Apollo LRD04 P5 RGB" ,
      0x106B ,//: "Apollo LRD04 P5 RGBD" ,
      0x106C ,//: "Apollo LRD04 P5 RGBW" ,
      0x106D ,//: "Apollo LRD04 P5 RGBDW" ,
      0x106E ,//: "Apollo LRD04 P7 D" ,
      0x106F ,//: "Apollo LRD04 P7 W" ,
      0x1070 ,//: "Apollo LRD04 P7 RGB" ,
      0x1071 ,//: "Apollo LRD04 P7 RGBD" ,
      0x1072 ,//: "Apollo LRD04 P7 RGBW" ,
      0x1073 ,//: "Apollo LRD04 P7 RGBDW" ,
      0x1074 ,//: "Apollo LRD10 P9 D" ,
      0x1075 ,//: "Apollo LRD10 P9 W" ,
      0x1076 ,//: "Apollo LRD10 P9 RGB" ,
      0x1077 ,//: "Apollo LRD10 P9 RGBD" ,
      0x1078 ,//: "Apollo LRD10 P9 RGBW" ,
      0x1079 ,//: "Apollo LRD10 P9 RGBDW" ,
      0x107A ,//: "Apollo SCU01 D" ,
      0x107B ,//: "Apollo SCU01 W" ,
      0x107C ,//: "Apollo SCU01 RGB" ,
      0x107D ,//: "Apollo SCU01 RGBD" ,
      0x107E ,//: "Apollo SCU01 RGBW" ,
      0x107F ,//: "Apollo SCU01 RGBDW" ,
      0x1080 ,//: "Apollo SCU02 D" ,
      0x1081 ,//: "Apollo SCU02 W" ,
      0x1082 ,//: "Apollo SCU02 RGB" ,
      0x1083 ,//: "Apollo SCU02 RGBD" ,
      0x1084 ,//: "Apollo SCU02 RGBW" ,
      0x1085 ,//: "Apollo SCU02 RGBDW" ,
      0x1086 ,//: "Apollo LED Ball D" ,
      0x1087 ,//: "Apollo LED Ball W" ,
      0x1088 ,//: "Apollo LED Ball RGB" ,
      0x1089 ,//: "Apollo LED Ball RGBD" ,
      0x108A ,//: "Apollo LED Ball RGBW" ,
      0x108B ,//: "Apollo LED Ball RGBDW" ,
      0x108C ,//: "Apollo Panel D" ,
      0x108D ,//: "Apollo Panel W" ,
      0x108E ,//: "Apollo Panel RGB" ,
      0x108F ,//: "Apollo Panel RGBD" ,
      0x1090 ,//: "Apollo Panel RGBW" ,
      0x1091 //: "Apollo Panel RGBDW"
    ]

    static let Name:[UInt16:String] = [
      0x1000 : "Apollo Mini Gateway",
      0x1002 : "Apollo PIR Sensor",
      0x1003 : "Apollo Light Sensor",
      0x1004 : "Apollo Temperature Sensor",
      0x1005 : "Switch 1 Chanel",
      0x1006 : "Remote",
      0x1050 : "Apollo Bulb A60 D" ,
      0x1051 : "Apollo Bulb A60 W" ,
      0x1052 : "Apollo Bulb A60 RGB" ,
      0x1053 : "Apollo Bulb A60 RGBD" ,
      0x1054 : "Apollo Bulb A60 RGBW" ,
      0x1055 : "Apollo Bulb A60 RGBDW" ,
      0x1056 : "Apollo Bulb G95 D" ,
      0x1057 : "Apollo Bulb G95 W" ,
      0x1058 : "Apollo Bulb G95 RGB" ,
      0x1059 : "Apollo Bulb G95 RGBD" ,
      0x105A : "Apollo Bulb G95 RGBW" ,
      0x105B : "Apollo Bulb G95 RGBDW" ,
      0x105C : "Apollo Bulb G120 D" ,
      0x105D : "Apollo Bulb G120 W" ,
      0x105E : "Apollo Bulb G120 RGB" ,
      0x105F : "Apollo Bulb G120 RGBD" ,
      0x1060 : "Apollo Bulb G120 RGBW" ,
      0x1061 : "Apollo Bulb G120 RGBDW" ,
      0x1062 : "Apollo Led Trip D" ,
      0x1063 : "Apollo Led Trip W" ,
      0x1064 : "Apollo Led Trip RGB" ,
      0x1065 : "Apollo Led Trip RGBD" ,
      0x1066 : "Apollo Led Trip RGBW" ,
      0x1067 : "Apollo Led Trip RGBDW" ,
      0x1068 : "Apollo LRD04 P5 D" ,
      0x1069 : "Apollo LRD04 P5 W" ,
      0x106A : "Apollo LRD04 P5 RGB" ,
      0x106B : "Apollo LRD04 P5 RGBD" ,
      0x106C : "Apollo LRD04 P5 RGBW" ,
      0x106D : "Apollo LRD04 P5 RGBDW" ,
      0x106E : "Apollo LRD04 P7 D" ,
      0x106F : "Apollo LRD04 P7 W" ,
      0x1070 : "Apollo LRD04 P7 RGB" ,
      0x1071 : "Apollo LRD04 P7 RGBD" ,
      0x1072 : "Apollo LRD04 P7 RGBW" ,
      0x1073 : "Apollo LRD04 P7 RGBDW" ,
      0x1074 : "Apollo LRD10 P9 D" ,
      0x1075 : "Apollo LRD10 P9 W" ,
      0x1076 : "Apollo LRD10 P9 RGB" ,
      0x1077 : "Apollo LRD10 P9 RGBD" ,
      0x1078 : "Apollo LRD10 P9 RGBW" ,
      0x1079 : "Apollo LRD10 P9 RGBDW" ,
      0x107A : "Apollo SCU01 D" ,
      0x107B : "Apollo SCU01 W" ,
      0x107C : "Apollo SCU01 RGB" ,
      0x107D : "Apollo SCU01 RGBD" ,
      0x107E : "Apollo SCU01 RGBW" ,
      0x107F : "Apollo SCU01 RGBDW" ,
      0x1080 : "Apollo SCU02 D" ,
      0x1081 : "Apollo SCU02 W" ,
      0x1082 : "Apollo SCU02 RGB" ,
      0x1083 : "Apollo SCU02 RGBD" ,
      0x1084 : "Apollo SCU02 RGBW" ,
      0x1085 : "Apollo SCU02 RGBDW" ,
      0x1086 : "Apollo LED Ball D" ,
      0x1087 : "Apollo LED Ball W" ,
      0x1088 : "Apollo LED Ball RGB" ,
      0x1089 : "Apollo LED Ball RGBD" ,
      0x108A : "Apollo LED Ball RGBW" ,
      0x108B : "Apollo LED Ball RGBDW" ,
      0x108C : "Apollo Panel D" ,
      0x108D : "Apollo Panel W" ,
      0x108E : "Apollo Panel RGB" ,
      0x108F : "Apollo Panel RGBD" ,
      0x1090 : "Apollo Panel RGBW" ,
      0x1091 : "Apollo Panel RGBDW"
    ]

    static let image:[UInt16:String] = [
      0x1000 : "icon_gateway",
      0x1002 : "icon_PIR",//"Apollo PIR Sensor",
      0x1003 : "bao_icon_logoDQ",//"Apollo Light Sensor",
      0x1004 : "bao_icon_logoDQ",//"Apollo Temperature Sensor",
      0x1005 : "bao_icon_logoDQ",//"Switch 1 chanel",
      0x1006 : "icon_remote",//"Remote",
      0x1050 : "icon_bulb_a60" ,
      0x1051 : "icon_bulb_a60" ,
      0x1052 : "icon_bulb_a60" ,
      0x1053 : "icon_bulb_a60" ,
      0x1054 : "icon_bulb_a60" ,
      0x1055 : "icon_bulb_a60" ,
      0x1056 : "icon_bulb_g95" ,
      0x1057 : "icon_bulb_g95" ,
      0x1058 : "icon_bulb_g95" ,
      0x1059 : "icon_bulb_g95" ,
      0x105A : "icon_bulb_g95" ,
      0x105B : "icon_bulb_g95" ,
      0x105C : "icon_bulb_g120" ,
      0x105D : "icon_bulb_g120" ,
      0x105E : "icon_bulb_g120" ,
      0x105F : "icon_bulb_g120" ,
      0x1060 : "icon_bulb_g120" ,
      0x1061 : "icon_bulb_g120" ,
      0x1062 : "icon_stripled" ,
      0x1063 : "icon_stripled" ,
      0x1064 : "icon_stripled" ,
      0x1065 : "icon_stripled" ,
      0x1066 : "icon_stripled" ,
      0x1067 : "icon_stripled" ,
      0x1068 : "icon_lrd04" ,
      0x1069 : "icon_lrd04" ,
      0x106A : "icon_lrd04" ,
      0x106B : "icon_lrd04" ,
      0x106C : "icon_lrd04" ,
      0x106D : "icon_lrd04" ,
      0x106E : "icon_lrd04" ,
      0x106F : "icon_lrd04" ,
      0x1070 : "icon_lrd04" ,
      0x1071 : "icon_lrd04" ,
      0x1072 : "icon_lrd04" ,
      0x1073 : "icon_lrd04" ,
      0x1074 : "icon_lrd10" ,
      0x1075 : "icon_lrd10" ,
      0x1076 : "icon_lrd10" ,
      0x1077 : "icon_lrd10" ,
      0x1078 : "icon_lrd10" ,
      0x1079 : "icon_lrd10" ,
      0x107A : "bao_icon_logoDQ",//"Apollo SCU01 D" ,
      0x107B : "bao_icon_logoDQ",//"Apollo SCU01 W" ,
      0x107C : "bao_icon_logoDQ",//"Apollo SCU01 RGB" ,
      0x107D : "bao_icon_logoDQ",//"Apollo SCU01 RGBD" ,
      0x107E : "bao_icon_logoDQ",//"Apollo SCU01 RGBW" ,
      0x107F : "bao_icon_logoDQ",//"Apollo SCU01 RGBDW" ,
      0x1080 : "icon_scu02" ,
      0x1081 : "icon_scu02" ,
      0x1082 : "icon_scu02" ,
      0x1083 : "icon_scu02" ,
      0x1084 : "icon_scu02" ,
      0x1085 : "icon_scu02" ,
      0x1086 : "bao_icon_logoDQ",//"Apollo LED Ball D" ,
      0x1087 : "bao_icon_logoDQ",//"Apollo LED Ball W" ,
      0x1088 : "bao_icon_logoDQ",//"Apollo LED Ball RGB" ,
      0x1089 : "bao_icon_logoDQ",//"Apollo LED Ball RGBD" ,
      0x108A : "bao_icon_logoDQ",//"Apollo LED Ball RGBW" ,
      0x108B : "bao_icon_logoDQ",//"Apollo LED Ball RGBDW" ,
      0x108C : "icon_panel" ,
      0x108D : "icon_panel" ,
      0x108E : "icon_panel" ,
      0x108F : "icon_panel" ,
      0x1090 : "icon_panel" ,
      0x1091 : "icon_panel"
    ]

    static let VendorModel:[UInt16:UInt32] = [
      0x1000 : Model.VendorGatewayServer,
      0x1006 : Model.VendorRemoteServer ,
      0x1050 : Model.VendorLightServer ,
      0x1051 : Model.VendorLightServer ,
      0x1052 : Model.VendorLightServer ,
      0x1053 : Model.VendorLightServer ,
      0x1054 : Model.VendorLightServer ,
      0x1055 : Model.VendorLightServer ,
      0x1056 : Model.VendorLightServer ,
      0x1057 : Model.VendorLightServer ,
      0x1058 : Model.VendorLightServer ,
      0x1059 : Model.VendorLightServer ,
      0x105A : Model.VendorLightServer ,
      0x105B : Model.VendorLightServer ,
      0x105C : Model.VendorLightServer ,
      0x105D : Model.VendorLightServer ,
      0x105E : Model.VendorLightServer ,
      0x105F : Model.VendorLightServer ,
      0x1060 : Model.VendorLightServer ,
      0x1061 : Model.VendorLightServer ,
      0x1062 : Model.VendorLightServer ,
      0x1063 : Model.VendorLightServer ,
      0x1064 : Model.VendorLightServer ,
      0x1065 : Model.VendorLightServer ,
      0x1066 : Model.VendorLightServer ,
      0x1067 : Model.VendorLightServer ,
      0x1068 : Model.VendorLightServer ,
      0x1069 : Model.VendorLightServer ,
      0x106A : Model.VendorLightServer ,
      0x106B : Model.VendorLightServer ,
      0x106C : Model.VendorLightServer ,
      0x106D : Model.VendorLightServer ,
      0x106E : Model.VendorLightServer ,
      0x106F : Model.VendorLightServer ,
      0x1070 : Model.VendorLightServer ,
      0x1071 : Model.VendorLightServer ,
      0x1072 : Model.VendorLightServer ,
      0x1073 : Model.VendorLightServer ,
      0x1074 : Model.VendorLightServer ,
      0x1075 : Model.VendorLightServer ,
      0x1076 : Model.VendorLightServer ,
      0x1077 : Model.VendorLightServer ,
      0x1078 : Model.VendorLightServer ,
      0x1079 : Model.VendorLightServer ,
      0x107A : Model.VendorLightServer ,
      0x107B : Model.VendorLightServer ,
      0x107C : Model.VendorLightServer ,
      0x107D : Model.VendorLightServer ,
      0x107E : Model.VendorLightServer ,
      0x107F : Model.VendorLightServer ,
      0x1080 : Model.VendorLightServer ,
      0x1081 : Model.VendorLightServer ,
      0x1082 : Model.VendorLightServer ,
      0x1083 : Model.VendorLightServer ,
      0x1084 : Model.VendorLightServer ,
      0x1085 : Model.VendorLightServer ,
      0x1086 : Model.VendorLightServer ,
      0x1087 : Model.VendorLightServer ,
      0x1088 : Model.VendorLightServer ,
      0x1089 : Model.VendorLightServer ,
      0x108A : Model.VendorLightServer ,
      0x108B : Model.VendorLightServer ,
      0x108C : Model.VendorLightServer ,
      0x108D : Model.VendorLightServer ,
      0x108E : Model.VendorLightServer ,
      0x108F : Model.VendorLightServer ,
      0x1090 : Model.VendorLightServer ,
      0x1091 : Model.VendorLightServer
    ]
  }
}

