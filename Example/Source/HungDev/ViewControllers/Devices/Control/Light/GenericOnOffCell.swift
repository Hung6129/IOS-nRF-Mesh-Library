//
//  GenericOnOffCell.swift
//  nRF Mesh
//
//  Created by Hưng Nguyễn on 20/04/2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//


import UIKit
import nRFMeshProvision

class GenericOnOffCell: ModelGroupCell {

    // MARK: - Outlets and Actions

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!

    @IBOutlet weak var onButton: UIButton!
    @IBAction func onTapped(_ sender: UIButton) {
        sendGenericOnOffMessage(turnOn: true)
    }
    @IBOutlet weak var offButton: UIButton!
    @IBAction func offTapped(_ sender: UIButton) {
        sendGenericOnOffMessage(turnOn: false)
    }

    // MARK: - Implementation

    override func reload() {
        // On iOS 12.x tinted icons are initially black.
        // Forcing adjustment mode fixes the bug.
        icon.tintAdjustmentMode = .normal

        let numberOfDevices = models.count
        if numberOfDevices == 1 {
            title.text = "1 device"
        } else {
            title.text = "\(numberOfDevices) devices"
        }

        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        let isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false

        onButton.isEnabled = isEnabled
        offButton.isEnabled = isEnabled
    }
}

private extension GenericOnOffCell {

    func sendGenericOnOffMessage(turnOn: Bool) {
        let label = turnOn ? "Turning ON..." : "Turning OFF..."
        delegate?.send(GenericOnOffSet(turnOn),
                       description: label, using: applicationKey)
    }

}
