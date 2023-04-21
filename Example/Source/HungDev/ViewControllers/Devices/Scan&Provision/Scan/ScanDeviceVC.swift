//
//  ScanDeviceVC.swift
//  nRF Mesh
//
//  Created by Hưng Nguyễn on 20/04/2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//



import UIKit
import CoreBluetooth
import nRFMeshProvision

class ScanDevicesVC: UITableViewController {

    // MARK: - Outlets and Actions
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Properties
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals = [(device: UnprovisionedDevice, peripheral: CBPeripheral, rssi: Int)]()

    private var alert: UIAlertController?
    private var selectedDevice: UnprovisionedDevice?
    weak var delegate: ProvisioningViewDelegate?
    private var selectedIndex = 0
    private var bearer:PBGattBearer!

  var nodes: [Node]!

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.setEmptyView(title: "Can't see your device?", message: "1. Make sure the device is turned on\nand connected to a power source.\n\n2. Make sure the relevant firmware\nand SoftDevices are flashed.", messageImage: #imageLiteral(resourceName: "baseline-bluetooth"))
        centralManager = CBCentralManager()
        tableView.showEmptyView()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        discoveredPeripherals = []
        tableView.reloadData()

        if(self.bearer != nil) {
            self.bearer.close()
            self.bearer = nil
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if centralManager.state == .poweredOn {
            startScanning()
        } else {
            startScanning()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ScanToProvision" {
            let destination = segue.destination as! ProvisionDeviceVC
            destination.unprovisionedDevice = self.selectedDevice
            destination.tPeripheral = self.discoveredPeripherals[selectedIndex].peripheral
            destination.bearer = sender as? ProvisioningBearer
            selectedIndex = 0
            selectedDevice = nil
        }
    }

    // MARK: - UITableViewDelegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredPeripherals.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newDeviceViewCell", for: indexPath) as! ScanDeviceCell
        let peripheral = discoveredPeripherals[indexPath.row]
//        print("peripheral : \(String(describing: peripheral.device.name))")
        cell.setupView(withDevice: peripheral.device, andRSSI: peripheral.rssi)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

      bearer = PBGattBearer(target: discoveredPeripherals[indexPath.row].peripheral)
      bearer.logger = MeshNetworkManager.instance.logger
      bearer.delegate = self
      selectedIndex = indexPath.row

      stopScanning()
      selectedDevice = discoveredPeripherals[indexPath.row].device
      print("Selected : \(String(describing: selectedDevice?.uuid))")

      alert = UIAlertController(title: "Status", message: "Connecting...", preferredStyle: .alert)
      alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
          action.isEnabled = false
          self.alert!.title   = "Aborting"
          self.alert!.message = "Cancelling connection..."
          self.bearer.close()
      })

      present(alert!, animated: true) {
          self.bearer.open()
      }
    }
}

// MARK: - CBCentralManagerDelegate
extension ScanDevicesVC: CBCentralManagerDelegate {
    private func startScanning() {
        activityIndicator.startAnimating()
        centralManager.delegate = self
        centralManager.scanForPeripherals(withServices: [MeshProvisioningService.uuid],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
    }

    private func stopScanning() {
        activityIndicator.stopAnimating()
        centralManager.stopScan()
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {

        if !discoveredPeripherals.contains(where: { $0.peripheral == peripheral }) {
            if let unprovisionedDevice = UnprovisionedDevice(advertisementData: advertisementData) {
                discoveredPeripherals.append((unprovisionedDevice, peripheral, RSSI.intValue))
                tableView.insertRows(at: [IndexPath(row: discoveredPeripherals.count - 1, section: 0)], with: .fade)
                tableView.hideEmptyView()
            }
        } else {
            if let index = discoveredPeripherals.firstIndex(where: { $0.peripheral == peripheral }) {
                if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ScanDeviceCell {
                    cell.deviceDidUpdate(discoveredPeripherals[index].device, andRSSI: RSSI.intValue)
                }
            }
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
            startScanning()
        }
    }

}


extension ScanDevicesVC: GattBearerDelegate {

    func bearerDidConnect(_ bearer: Bearer) {
        DispatchQueue.main.async {
            self.alert?.message = "Discovering services..."
        }
    }

    func bearerDidDiscoverServices(_ bearer: Bearer) {
        DispatchQueue.main.async {
            self.alert?.message = "Initializing..."
        }
    }

    func bearerDidOpen(_ bearer: Bearer) {
        DispatchQueue.main.async {
            self.alert?.dismiss(animated: false) {
                self.performSegue(withIdentifier: "ScanToProvision", sender: bearer)
            }

            self.alert = nil
        }
    }

    func bearer(_ bearer: Bearer, didClose error: Error?) {
        DispatchQueue.main.async {
            self.alert?.message = "Device disconnected"
            self.alert?.dismiss(animated: true)
            self.alert = nil
            self.selectedDevice = nil
            self.startScanning()
        }
    }
}
