//
//  DevicesVC.swift
//  nRF Mesh
//
//  Created by Hưng Nguyễn on 20/04/2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import CoreBluetooth
import nRFMeshProvision
import UIKit

private enum SectionType {
  case notConfiguredNodes
  case configuredNodes
  case provisionersNodes
  case thisProvisioner

  var title: String? {
    switch self {
    case .notConfiguredNodes: return nil
    case .configuredNodes:    return "Configured Nodes"
    case .provisionersNodes:  return "Other Provisioners"
    case .thisProvisioner:    return "This Provisioner"
    }
  }
}

private struct Section {
  let type: SectionType
  let nodes: [Node]

  init(type: SectionType, nodes: [Node]) {
    self.type = type
    self.nodes = nodes.reversed()
  }

  var title: String? {
    return type.title
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> DevicesCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "deviceViewCell", for: indexPath) as! DevicesCell
    cell.node = nodes[indexPath.row]
    return cell
  }
}

class DevicesVC : UITableViewController , UISearchBarDelegate  {
  enum ConnectType{
    case NoConnect
    case Bluetooth
    case Internet
  }

  // MARK: - Variable
  private var sections: [Section] = []
  private var filteredSections: [Section] = []

  private var nodesList: [Node] = []

  var node:Node!
  var TimerTick : Timer?
  var timecount: Int = 0
  var isDevelopt = false
  private var alert: UIAlertController?
  private var messageHandle: MessageHandle?

  // MARK: - Search bar
  private let searchController = UISearchController(searchResultsController: nil)

  private func createSearchBar(){

    navigationItem.searchController = searchController
    searchController.searchBar.placeholder = "Search by Node name, Unicast Address"
    searchController.searchBar.delegate = self

  }

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

    if searchText.isEmpty {
      filteredSections = sections

    } else {
      filteredSections = sections.map { section in
        let filteredNodes = section.nodes.filter { node in
          return node.name!.lowercased().contains(searchText.lowercased()) ||
          String(node.primaryUnicastAddress.asString()).lowercased().contains(searchText.lowercased()) ||
          String(node.uuid.uuidString).lowercased().contains(searchText.lowercased())
        }


        return Section(type: section.type, nodes: filteredNodes)
      }.filter { !$0.nodes.isEmpty }
    }
    tableView.reloadData()
  }


  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.text = ""
    filteredSections = sections
    tableView.reloadData()
  }


  // MARK: - viewLoad
  override func viewDidLoad() {
    navigationController?.navigationBar.prefersLargeTitles = true
    super.viewDidLoad()
    filteredSections = sections.reversed()
    createSearchBar()
    nodesList = MeshNetworkManager.instance.meshNetwork!.nodes
    tableView.setEmptyView(title: vietSub("No Nodes"), message: vietSub("Click + to provision a new device."), messageImage: #imageLiteral(resourceName: "baseline-network"))
    reloadData()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    searchController.searchBar.text = ""
    filteredSections = sections.reversed()
    tableView.reloadData()
    MeshNetworkManager.instance.delegate = self
    nodesList = MeshNetworkManager.instance.meshNetwork!.nodes
    enable_timer()
    reloadData()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    filteredSections = sections
    disable_timer()
  }


  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return  55
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier! {

    case "configure":
      let cell = sender as! DevicesCell
      let destination = segue.destination as! ConfigureNodeCollectionVC
      destination.node = cell.node
      break

    case "openConfig":
      let cell = sender as! Node
      let destination = segue.destination as! ConfigurationViewController
      destination.node = cell
      break

    default:
      break
    }
  }

  // MARK: - Outlet and action
  @IBOutlet weak var BtnDev: UIButton!
  @IBAction func BTNdev(_ sender: Any) {}

  @IBAction func ScanNew(_ sender: Any) {
    let vc = ScanDevicesVC()
    vc.nodes = MeshNetworkManager.instance.meshNetwork?.nodes
    self.performSegue(withIdentifier: "scanMoreDevices", sender: nil)
  }

  // MARK: - Table view data source
  override func numberOfSections(in tableView: UITableView) -> Int {
    return filteredSections.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return filteredSections[section].nodes.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return filteredSections[section].title
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return filteredSections[indexPath.section].tableView(tableView, cellForRowAt: indexPath)
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }

  override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    editNode(indexPath)
  }
}


extension DevicesVC: ProvisioningViewDelegate {

  // navigation
  func provisionerDidProvisionNewDevice(_ node: Node) {
    performSegue(withIdentifier: "configure", sender: node)
  }
}

private extension DevicesVC {
  func reloadData() {
    sections.removeAll()
    if let network = MeshNetworkManager.instance.meshNetwork {
      let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner })
      let configuredNodes    = network.nodes.filter({ $0.isConfigComplete && !$0.isProvisioner })

      if !notConfiguredNodes.isEmpty {
        sections.append(Section(type: .notConfiguredNodes, nodes: notConfiguredNodes))
      }

      if !configuredNodes.isEmpty {
        sections.append(Section(type: .configuredNodes, nodes: configuredNodes))
      }
    }

    filteredSections = sections
    tableView.reloadData()

    if filteredSections.isEmpty {
      tableView.showEmptyView()
    } else {
      tableView.hideEmptyView()
    }
  }

  // MARK: - Edit node
  func editNode(_ indexPath: IndexPath) {
    self.node = sections[indexPath.section].nodes[indexPath.row]
    let alert = UIAlertController(title: vietSub("Node Configuration"), message: self.node.name, preferredStyle: UIAlertController.Style.actionSheet)
    let EditName = UIAlertAction(title: vietSub("Edit name"), style: UIAlertAction.Style.default) { (UIAlertAction) in
      self.editName(indexPath)
      alert.dismiss(animated: true)
    }
    let Reset = UIAlertAction(title: vietSub("Reset"), style: UIAlertAction.Style.default) { (UIAlertAction) in
      self.ResetNode(indexPath)
      alert.dismiss(animated: true)
    }
    let Config = UIAlertAction(title: vietSub("Configure"), style: UIAlertAction.Style.default) { (UIAlertAction) in
      self.config(indexPath)
      alert.dismiss(animated: true)
    }
    let Cancel = UIAlertAction(title: vietSub("Cancel"), style: UIAlertAction.Style.default) { (UIAlertAction) in
      alert.dismiss(animated: true)
    }
    alert.addAction(EditName)
    alert.addAction(Reset)
    alert.addAction(Config)
    alert.addAction(Cancel)

    let viewi = tableView.cellForRow(at: indexPath)?.contentView
    alert.popoverPresentationController?.sourceView = viewi
    alert.popoverPresentationController?.sourceRect = viewi!.frame
    self.present(alert, animated: true)
  }

  func editName(_ indexPath: IndexPath) {

    self.node = sections[indexPath.section].nodes[indexPath.row]
    presentTextAlert(title: vietSub("Device name"),
                     message: nil,
                     text: self.node.name,
                     placeHolder: vietSub("Name"),
                     type: .nameRequired,
                     handler: {
      newName in self.node.name = newName
      if MeshNetworkManager.instance.save() {
        self.reloadData()
      }
    })
  }

  func ResetNode(_ indexPath: IndexPath) {

    self.node = sections[indexPath.section].nodes[indexPath.row]
    let alert = UIAlertController(title: vietSub("Reset device"), message: vietSub("Reset will delete device from list device! Device will reset and change to default state! Do you want to reset device"), preferredStyle: UIAlertController.Style.alert)
    let OK = UIAlertAction(title: vietSub("Confirm"), style: UIAlertAction.Style.default) { (UIAlertAction) in
      alert.dismiss(animated: true)
      self.start("Resetting node...") {
        let message = ConfigNodeReset()
        return try MeshNetworkManager.instance.send(message, to: self.node)
      }
    }
    let Cancel = UIAlertAction(title: vietSub("Cancel"), style: UIAlertAction.Style.cancel) { (UIAlertAction) in
      alert.dismiss(animated: true)
    }
    alert.addAction(OK)
    alert.addAction(Cancel)
    self.present(alert, animated: true)
  }

  func config(_ indexPath: IndexPath)  {
    self.node = sections[indexPath.section].nodes[indexPath.row]
    performSegue(withIdentifier: "openConfig", sender: self.node)
  }
}

extension DevicesVC : MeshNetworkDelegate {

  func meshNetworkManager(_ manager: MeshNetworkManager,
                          didReceiveMessage message: MeshMessage,
                          sentFrom source: Address, to destination: Address) {
    switch message{
    case is ConfigNodeReset:
      // The node has been reset remotely.
      (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
      reloadData()
      presentAlert(title: "Reset", message: "The mesh network was reset remotely.")
    case is ConfigNodeResetStatus:
      done() {
        self.reloadData()
      }

    default:
      break
    }
  }

}

extension  DevicesVC {
  // MARK: - Implementation

  override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
    super.dismiss(animated: flag, completion: completion)

    if #available(iOS 13.0, *) {
      if let presentationController = self.parent?.presentationController {
        presentationController.delegate?.presentationControllerDidDismiss?(presentationController)
      }
    }
  }

  /// Displays the progress alert with specified status message
  /// and calls the completion callback.
  ///
  /// - parameter message: Message to be displayed to the user.
  /// - parameter completion: A completion handler.
  func start(_ message: String, completion: @escaping (() -> Void)) {
    DispatchQueue.main.async {
      if self.alert == nil {
        self.alert = UIAlertController(title: "Status", message: message, preferredStyle: .alert)
        self.alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
          _ in self.alert = nil
        }))
        self.present(self.alert!, animated: true)
      } else {
        self.alert?.message = message
      }

      completion()
    }
  }

  /// Displays the progress alert with specified status message
  /// and calls the completion callback.
  ///
  /// - parameter message: Message to be displayed to the user.
  /// - parameter completion: A completion handler.
  func start(_ message: String, completion: @escaping (() throws -> MessageHandle?)) {
    DispatchQueue.main.async {
      do {
        self.messageHandle = try completion()
        guard let _ = self.messageHandle else {
          self.done()
          return
        }
        if(self.isDevelopt)
        {
          if self.alert == nil {
            self.alert = UIAlertController(title: "Status", message: message, preferredStyle: .alert)
            self.alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
              self.messageHandle?.cancel()
              self.alert = nil
            }))
            self.present(self.alert!, animated: true)
          } else {
            self.alert?.message = message
          }
        }
      } catch {
        self.done()
      }
    }
  }

  /// This method dismisses the progress alert dialog.
  ///
  /// - parameter completion: An optional completion handler.
  func done(completion: (() -> Void)? = nil) {
    if let alert = alert {
      DispatchQueue.main.async {
        alert.dismiss(animated: true, completion: completion)
      }
    } else {
      DispatchQueue.main.async {
        completion?()
      }
    }
    alert = nil
  }

}



// MARK: - Longpress
extension DevicesVC : UIGestureRecognizerDelegate {

  func setupLongPressGesture() {
    let longpress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(_:)))
    longpress.minimumPressDuration = 5
    longpress.delaysTouchesBegan = true
    longpress.delegate = self
    self.view.addGestureRecognizer(longpress)
  }

  @objc func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
    if (gestureRecognizer.state == .began)
    {
      let alertController = UIAlertController(title: "Become the developer", message: "DFU Feature is enable", preferredStyle: .alert)
      /// Do something
      self.isDevelopt = !self.isDevelopt
      BtnDev.isHidden = !isDevelopt
      self.present(alertController, animated: true)
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1), execute: {
        alertController.dismiss(animated: true)
      })
    }
  }
}

// MARK: - Timer tick
extension DevicesVC {
  /* Define in main
   var TimerTick : Timer?
   var timecount: Int = 0
   */
  func enable_timer()
  {
    TimerTick = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(TimeTickCode), userInfo: nil, repeats: true)
  }
  func disable_timer()
  {
    TimerTick?.invalidate()
  }
  @objc func TimeTickCode()
  {
    timecount = timecount + 1;
    if timecount >= 100
    {
      timecount = 0
    }
  }
}
