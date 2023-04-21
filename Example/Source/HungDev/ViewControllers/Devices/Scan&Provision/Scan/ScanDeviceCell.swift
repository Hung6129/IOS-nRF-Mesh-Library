//
//  ScanDeviceCell.swift
//  nRF Mesh
//
//  Created by Hưng Nguyễn on 20/04/2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//



import UIKit
import CoreBluetooth
import nRFMeshProvision

class ScanDeviceCell: UITableViewCell {

  //MARK: - Outlets and Actions

  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var uuid: UILabel!
  @IBOutlet weak var rssiIcon: UIImageView!


  // MARK: - Properties

  private var lastUpdateTimestamp = Date()

  // MARK: - Implementation



  func setupView(withDevice device: UnprovisionedDevice, andRSSI rssi: Int) {
    let uuidToMACFormat = HunExtensions().getDeviceUUIDtoMACformat(uuidToString: device.uuid.uuidString)
    let nameD = "\(device.name ?? "Unknown Device") - \(uuidToMACFormat)"
    name.text = nameD
    uuid.text = device.uuid.uuidString
    updateRssi(rssi)
  }

  func deviceDidUpdate(_ device: UnprovisionedDevice, andRSSI rssi: Int) {
    if Date().timeIntervalSince(lastUpdateTimestamp) > 1.0 {
      lastUpdateTimestamp = Date()
      setupView(withDevice: device, andRSSI: rssi)

      // Hide the RSSI icon when the device is no loger advertising.
      // Timeout is around 5 seconds.
      DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
        guard let self = self else { return }
        if Date().timeIntervalSince(self.lastUpdateTimestamp) > 4.5 {
          self.setupView(withDevice: device, andRSSI: -128)
        }
      }
    }
  }

  private func updateRssi(_ rssi: Int) {
    switch rssi {
    case -128:
      rssiIcon.image = nil
    case -127 ..< -80:
      rssiIcon.image = #imageLiteral(resourceName: "rssi_1")
    case -80 ..< -60:
      rssiIcon.image = #imageLiteral(resourceName: "rssi_2")
    case -60 ..< -40:
      rssiIcon.image = #imageLiteral(resourceName: "rssi_3")
    default:
      rssiIcon.image = #imageLiteral(resourceName: "rssi_4")
    }
  }
}
