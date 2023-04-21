//
//  ProvisionDeviceVC.swift
//  nRF Mesh
//
//  Created by Hưng Nguyễn on 20/04/2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//


import UIKit
import SwiftProgressView
import CoreBluetooth
import nRFMeshProvision
import Foundation

class ProvisionDeviceVC: UIViewController {

  enum ProvisionStep {
    case Wait
    case Provision
    case Connect
    case GetComposition
    case GetTTL
    case AddAppKey
    case Bindkey
    case Success
    case Error

  }

  enum Processs{
    case Start
    case Wait
    case Error
    case TimeOut
    case Success
    case End
  }

  let connectionModeKey = "connectionMode"
  // MARK: - Outlets and Actions
  @IBOutlet weak var lblLog: UILabel!
  @IBOutlet weak var progress: ProgressRingView!
  @IBOutlet weak var provisionButton: UIBarButtonItem!
  @IBOutlet weak var actionProvision: UIBarButtonItem!

  @IBAction func provisionTapped(_ sender: UIBarButtonItem) {
    guard bearer.isOpen else {
      openBearer()
      return
    }

    self.begin()
    StepProvision = .Provision
    ProcessOfStep = .Start
  }

  // MARK: - Properties
  private var alert: UIAlertController?
  private var messageHandle: MessageHandle?
  var unprovisionedDevice: UnprovisionedDevice!
  var bearer: ProvisioningBearer!

  private var publicKey: PublicKey?
  private var authenticationMethod: AuthenticationMethod?

  private var provisioningManager: ProvisioningManager!
  private var capabilitiesReceived = false

  var ProgressPercent: CGFloat = 0
  var step = 0
  var StepProvision: ProvisionStep = .Wait
  var ProcessOfStep: Processs = .End
  var timeOutMax = 2000
  var countTimeOut = 0
  var timeTick = 0
  var tPeripheral: CBPeripheral!
  var TimerTick : Timer?
  var timecount: Int = 0
  var isDevelopt = false
  private var bbearer: GattBearer?


  var model: Model!
  var elementIndex = 0
  var modelIndex = 0
  let hunE = HunExtensions()
  var node: Node!



  // MARK: - Init view
  override func viewDidLoad()
  {
    super.viewDidLoad()
    setupLongPressGesture()
    progress.isShowPercentage = true
    title = unprovisionedDevice.name
    let manager = MeshNetworkManager.instance
    // Obtain the Provisioning Manager instance for the Unprovisioned Device.
    provisioningManager = try! manager.provision(unprovisionedDevice: unprovisionedDevice, over: bearer)
    provisioningManager.delegate = self
    provisioningManager.logger = MeshNetworkManager.instance.logger
    bbearer = GattBearer(target: tPeripheral)
    bbearer!.delegate = self
    bbearer!.logger = MeshNetworkManager.instance.logger
    bearer.delegate = self
    actionProvision.isEnabled = manager.meshNetwork!.localProvisioner != nil
    // We are now connected. Proceed by sending Provisioning Invite request.
    self.lblLog.text = vietSub("Identifying")
    presentStatusDialog(message: "Identifying...", animated: false) {
      do {
        try self.provisioningManager.identify(andAttractFor: ProvisioningViewController.attentionTimer)
      } catch {
        self.abort()
        self.presentAlert(title: "Error", message: error.localizedDescription)
      }
    }

    presentNameDialog()
  }

  override func viewWillAppear(_ animated: Bool) {
    enable_timer()
    MeshNetworkManager.instance.delegate = self
    if(StepProvision == .Success) {
      let alertEnd = UIAlertController(title: vietSub("Success"), message: vietSub("Provisioning Success! Turn back scan page!"), preferredStyle: UIAlertController.Style.alert)
      let OK = UIAlertAction(title: vietSub("OK"), style: UIAlertAction.Style.default) { (UIAlertAction) in
        alertEnd.dismiss(animated: true) {}
        self.back()
        self.navigationController!.popViewController(animated: true)
      }

      alertEnd.addAction(OK)
      self.present(alertEnd, animated: true)
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    disable_timer()
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier! {
    default:
      break
    }
  }
}


extension ProvisionDeviceVC: OobSelector {

}

private extension ProvisionDeviceVC {


  func back() {
    dismiss(animated: true)
  }

  /// Presents a dialog to edit the Provisioner name.
  func presentNameDialog() {
    let deviceUUID = hunE.getDeviceUUIDtoMACformat(uuidToString: unprovisionedDevice.uuid.uuidString)
    let deviceName = unprovisionedDevice.name ?? "My Device"
    presentTextAlert(title: "Device name", message: nil,
                     text: deviceName + "-" + deviceUUID,
                     placeHolder: "Name",
                     type: .nameRequired, handler:
                      { newName in
      self.unprovisionedDevice.name = newName
      guard self.bearer.isOpen else {
        self.openBearer()
        return
      }

      self.begin()
      self.StepProvision = .Provision
      self.ProcessOfStep = .Start
    })
  }


  // start to pop-up the provisioning dialog
  func begin() {
    MeshNetworkManager.bearer.isConnectionModeAutomatic = false
    self.navigationItem.hidesBackButton = true
    self.tabBarController?.tabBar.isHidden = true
    self.provisionButton.isEnabled = false
    progress.setProgress(0, animated: true)
  }

  func finnish() {
    MeshNetworkManager.bearer.isConnectionModeAutomatic = true
    self.tabBarController?.tabBar.isHidden = false
    self.navigationItem.hidesBackButton = false
  }

  func presentStatusDialog(message: String, animated flag: Bool = true, completion: (() -> Void)? = nil) {
    DispatchQueue.main.async {
      if let alert = self.alert {
        alert.message = message
        completion?()
      } else {
        self.alert = UIAlertController(title: "Status", message: message, preferredStyle: .alert)
        self.alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
          action.isEnabled = false
          self.abort()
        })

        if(self.isDevelopt) {
          self.present(self.alert!, animated: flag, completion: completion)
        } else {
          completion?()
        }
      }
    }
  }

  func dismissStatusDialog(completion: (() -> Void)? = nil) {
    DispatchQueue.main.async {
      if let alert = self.alert {
        alert.dismiss(animated: true, completion: completion)
      } else {
        completion?()
      }

      if(!self.isDevelopt){
        completion?()
      }

      self.alert = nil
    }
  }

  func abort() {
    DispatchQueue.main.async {
      self.alert?.title   = "Aborting"
      self.alert?.message = "Cancelling connection..."
      self.bearer.close()
    }
  }
}

private extension ProvisionDeviceVC {

  /// This method tries to open the bearer had it been closed when on this screen.
  func openBearer() {
    presentStatusDialog(message: "Connecting...") {
      self.bearer.open()
    }
  }

  // set publish
  func setPublication(){
    let meshNetwork = MeshNetworkManager.instance.meshNetwork!
    let keys = meshNetwork.applicationKeys
    let applicationKey = keys[0]
    let destination = MeshAddress(hex: "FFFF")

    start("Setting Model Publication...") {
      let publish = Publish(to: destination!, using: applicationKey,
                            usingFriendshipMaterial: false, ttl: 0xFF,
                            period: Publish.Period(steps: 0, resolution: StepResolution(rawValue: 0)!),
                            retransmit: Publish.Retransmit(publishRetransmitCount: 0, intervalSteps: 0))

      let message: ConfigMessage =
      ConfigModelPublicationSet(publish, to: self.model) ??
      ConfigModelPublicationVirtualAddressSet(publish, to: self.model)!
      return try MeshNetworkManager.instance.send(message, to: self.node)
    }
  }

  // bind appkey func
  func bind() {
    let meshNetwork = MeshNetworkManager.instance.meshNetwork!
    let keys = meshNetwork.applicationKeys
    let selectedAppKey = keys[0]

    guard let message = ConfigModelAppBind(applicationKey: selectedAppKey, to: self.model) else {
      return presentAlert(title: "Error", message: "Fail using \(selectedAppKey) to bind to \(self.model.name ?? "Model")")
    }

    start("Binding Application Key...") {
      return try MeshNetworkManager.instance.send(message, to: self.node)
    }
  }

  ///// Starts provisioning process of the device.
  func startProvisioning() {
    guard let capabilities = provisioningManager.provisioningCapabilities else {
      return
    }

    /// MARK: - Developt
    if(isDevelopt) {
      // If the device's Public Key is available OOB, it should be read.
      let publicKeyNotAvailable = capabilities.publicKeyType.isEmpty
      guard publicKeyNotAvailable || publicKey != nil else {
        presentOobPublicKeyDialog(for: unprovisionedDevice) { publicKey in
          self.publicKey = publicKey
          self.startProvisioning()
        }
        return
      }

      publicKey = publicKey ?? .noOobPublicKey

      // If any of OOB methods is supported, if should be chosen.
      //      let staticOobNotSupported = capabilities.staticOobType.isEmpty
      let outputOobNotSupported = capabilities.outputOobActions.isEmpty
      let inputOobNotSupported  = capabilities.inputOobActions.isEmpty
      guard (
        //        staticOobNotSupported &&
        outputOobNotSupported && inputOobNotSupported) || authenticationMethod != nil else {
        presentOobOptionsDialog(for: provisioningManager, from: provisionButton) { method in
          self.authenticationMethod = method
          self.startProvisioning()
        }

        return
      }

      // If none of OOB methods are supported, select the only option left.
      if authenticationMethod == nil {
        authenticationMethod = .noOob
      }
    } else {
      publicKey = .noOobPublicKey
      authenticationMethod = .noOob
    }

    if provisioningManager.networkKey == nil {
      let network = MeshNetworkManager.instance.meshNetwork!
      let networkKey = try! network.add(networkKey: Data.random128BitKey(), name: "Primary Network Key")
      provisioningManager.networkKey = networkKey
    }

    let _network = MeshNetworkManager.instance.meshNetwork!
    if _network.applicationKeys.isEmpty {
      let key = Data.random128BitKey()
      _ = try? _network.add(applicationKey: key, name: "appkey 1")
    }

    presentStatusDialog(message: "Provisioning...") {
      do {
        try self.provisioningManager.provision(usingAlgorithm:       .BTM_ECDH_P256_CMAC_AES128_AES_CCM,
                                               publicKey:            self.publicKey!,
                                               authenticationMethod: self.authenticationMethod!)
      } catch {
        self.abort()
        self.presentAlert(title: "Error", message: error.localizedDescription)
      }
    }
  }
}

// MARK: GattBearerDelegate
extension ProvisionDeviceVC: GattBearerDelegate {

  func bearerDidConnect(_ bearer: Bearer) {
    presentStatusDialog(message: "Discovering services...")
  }

  func bearerDidDiscoverServices(_ bearer: Bearer) {
    presentStatusDialog(message: "Initializing...")
  }

  func bearerDidOpen(_ bearer: Bearer) {
    if(StepProvision == .Connect) {
      MeshNetworkManager.bearer.use(proxy: bearer as! GattBearer)
      self.ProcessOfStep = .Success
    } else {
      presentStatusDialog(message: "Identifying...") {
        do {
          try self.provisioningManager!.identify(andAttractFor: ProvisioningViewController.attentionTimer)
        } catch {
          self.abort()
          self.presentAlert(title: "Error", message: error.localizedDescription)
        }
      }
    }
  }

  func bearer(_ bearer: Bearer, didClose error: Error?) {
    if(StepProvision == .Provision) {
      if(!isDevelopt){
        dismissStatusDialog()
      }else {
        ProcessOfStep = .Success
      }
    }
  }

}
// MARK: - ProvisioningDelegate
extension ProvisionDeviceVC: ProvisioningDelegate {

  func provisioningState(of unprovisionedDevice: UnprovisionedDevice, didChangeTo state: ProvisioningState) {
    DispatchQueue.main.async {
      switch state {

      case .requestingCapabilities:
        self.presentStatusDialog(message: "Identifying...")

      case .capabilitiesReceived(_):

        // If the Unicast Address was set to automatic (nil), it should be
        // set to the correct value by now, as we know the number of elements.
        let addressValid = self.provisioningManager.isUnicastAddressValid == true
        if !addressValid {
          self.provisioningManager.unicastAddress = nil
        }

        self.actionProvision.isEnabled = addressValid
        let capabilitiesWereAlreadyReceived = self.capabilitiesReceived
        self.capabilitiesReceived = true

        let deviceSupported = self.provisioningManager.isDeviceSupported == true

        self.dismissStatusDialog() {
          if deviceSupported && addressValid {
            // If the device got disconnected after the capabilities were received
            // the first time, the app had to send invitation again.
            // This time we can just directly proceed with provisioning.
            if capabilitiesWereAlreadyReceived {
              self.startProvisioning()
            }
          } else {
            if !deviceSupported {
              self.presentAlert(title: "Error", message: "Selected device is not supported.")
              self.actionProvision.isEnabled = false
            } else if !addressValid {
              self.presentAlert(title: "Error", message: "No available Unicast Address in Provisioner's range.")
            }
          }
        }

      case .complete:
        if MeshNetworkManager.instance.save() {
          let network = MeshNetworkManager.instance.meshNetwork!
          if let anode = network.node(for: self.unprovisionedDevice){
            self.node = anode
            //                        self.saveProxyUUID(id: anode.primaryUnicastAddress, uuid: self.tPeripheral.identifier.uuidString, type: "NotConfig")
          }
        } else {
          self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
        self.bearer.close()
        self.presentStatusDialog(message: "Disconnecting...")
        self.ProcessOfStep = .Success
      case let .fail(error):
        self.dismissStatusDialog() {
          self.presentAlert(title: "Error", message: error.localizedDescription)
          self.abort()
        }

      default:
        break
      }
    }
  }

  func authenticationActionRequired(_ action: AuthAction) {
    switch action {
    case let .provideStaticKey(callback: callback):
      self.dismissStatusDialog() {
        let message = "Enter 16-character hexadecimal string."
        self.presentTextAlert(title: "Static OOB Key", message: message,
                              type:.publicKeyRequired, cancelHandler: nil) { hex in
          callback(Data(hex: hex))
        }
      }
    case let .provideNumeric(maximumNumberOfDigits: _, outputAction: action, callback: callback):
      self.dismissStatusDialog() {
        var message: String
        switch action {
        case .blink:
          message = "Enter number of blinks."
        case .beep:
          message = "Enter number of beeps."
        case .vibrate:
          message = "Enter number of vibrations."
        case .outputNumeric:
          message = "Enter the number displayed on the device."
        default:
          message = "Action \(action) is not supported."
        }

        self.presentTextAlert(title: "Authentication", message: message,
                              type: .unsignedNumberRequired, cancelHandler: nil) { text in
          callback(UInt(text)!)
        }
      }
    case let .provideAlphanumeric(maximumNumberOfCharacters: _, callback: callback):
      self.dismissStatusDialog() {
        let message = "Enter the text displayed on the device."
        self.presentTextAlert(title: "Authentication", message: message,
                              type: .nameRequired, cancelHandler: nil) { text in
          callback(text)
        }
      }
    case let .displayAlphanumeric(text):
      self.presentStatusDialog(message: "Enter the following text on your device:\n\n\(text)")
    case let .displayNumber(value, inputAction: action):
      self.presentStatusDialog(message: "Perform \(action) \(value) times on your device.")
    }
  }

  func inputComplete() {
    self.presentStatusDialog(message: "Provisioning...")
  }
}

extension ProvisionDeviceVC: SelectionDelegate {
  func networkKeySelected(_ networkKey: NetworkKey?) {
    self.provisioningManager.networkKey = networkKey
  }
}

// MARK: - Get composition data
private extension ProvisionDeviceVC {
  /// Presents a dialog to edit the default TTL.
  func presentTTLDialog() {
    presentTextAlert(title: "Default TTL",
                     message: "TTL = Time To Live\n\nTTL limits the number of times a message can be relayed.\nMax value is 127.",
                     text: node.defaultTTL != nil ? "\(node.defaultTTL!)" : nil,
                     type: .ttlRequired, handler:  { value in
      let ttl = UInt8(value)!
      self.setTtl(ttl)
    })
  }

  @objc func getCompositionData() {
    start("Requesting Composition Data...") {
      let message = ConfigCompositionDataGet()
      return try MeshNetworkManager.instance.send(message, to: self.node)
    }
  }

  func getTtl() {
    start("Requesting default TTL...") {
      let message = ConfigDefaultTtlGet()
      return try MeshNetworkManager.instance.send(message, to: self.node)
    }
  }

  func setTtl(_ ttl: UInt8) {
    start("Setting TTL to \(ttl)...") {
      let message = ConfigDefaultTtlSet(ttl: ttl)
      return try MeshNetworkManager.instance.send(message, to: self.node)
    }
  }
}

extension ProvisionDeviceVC : MeshNetworkDelegate {
  func meshNetworkManager(_ manager: MeshNetworkManager,
                          didReceiveMessage message: MeshMessage,
                          sentFrom source: Address, to destination: Address) {
    // Has the Node been reset remotely.
    guard !(message is ConfigNodeReset) else {
      (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
      self.navigationController?.popToRootViewController(animated: true)
      return
    }

    // Handle the message based on its type.
    switch message {
    case is ConfigCompositionDataStatus:
      done() {}
      ProcessOfStep = .Success

    case is ConfigDefaultTtlStatus:
      done() {}
      ProcessOfStep = .Success

    case is ConfigNodeResetStatus:
      self.navigationController?.popViewController(animated: true)

    case let status as ConfigAppKeyStatus:
      print("App Model ConfigAppKeyStatus = \(status)")
      done() {}
      if status.status == .success {
        self.dismiss(animated: true)
        self.ProcessOfStep = .Success
      }

    case let status as ConfigModelAppStatus:
      print("App Model ConfigModelAppStatus = \(status)")
      done() {
        if status.status == .success {
          self.dismiss(animated: true)
          self.ProcessOfStep = .Success
        } else {
          self.presentAlert(title: "Error", message: "\(status.status)")
        }
      }

    case let status as ConfigModelPublicationStatus:
      print("App Model ConfigModelPublicationStatus = \(status)")
      done() {
        if status.status == .success {
          self.dismiss(animated: true)
          self.ProcessOfStep = .Success
          self.timeTick = 0
        } else {
          self.presentAlert(title: "Error", message: status.message)
        }
      }

    default:
      break
    }
  }

  func meshNetworkManager(_ manager: MeshNetworkManager,
                          failedToSendMessage message: MeshMessage,
                          from localElement: Element, to destination: Address,
                          error: Error){
    self.presentAlert(title: "Error", message: error.localizedDescription)
    ProcessOfStep = .TimeOut
  }
}

extension  ProvisionDeviceVC {
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

        if(self.isDevelopt) {
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
// MARK: - Timer tick
extension ProvisionDeviceVC {
  /* Define in main
   var TimerTick : Timer?
   var timecount: Int = 0
   */
  func enable_timer() {
    TimerTick = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(TimeTickCode), userInfo: nil, repeats: true)
  }

  func disable_timer() {
    TimerTick?.invalidate()
  }

  @objc func TimeTickCode() {
    timecount = timecount + 1;
    if timecount >= 10 {
      timecount = 0
      step = step + 1
      if (step > 100) {
        step = 0
      }
    }

    switch StepProvision {
    case .Wait: ///Nothing
      break

    case .Provision:/// Start provisioning
      switch ProcessOfStep {
      case .Wait:
        timeTick = timeTick + 1
        if (timeOutMax < timeTick) {
          ProcessOfStep = .TimeOut
          timeTick = 0
        }
        break
      case .Start:
        self.lblLog.text = vietSub("Provisioning")
        startProvisioning()
        ProcessOfStep = .Wait
        timeOutMax = 2000
        timeTick=0
        break
      case .TimeOut:
        ProcessOfStep = .Error
        timeTick = 0
        break
      case .Error:
        StepProvision = .Error
        break
      case .Success:
        ProcessOfStep = .End
        break
      case .End:
        self.ProgressPercent = 0.07
        progress.setProgress(self.ProgressPercent, animated: true)
        StepProvision = .Connect
        ProcessOfStep = .Start
        countTimeOut = 0
        break
      }
      break

    case .Connect:///Reconnect after provisioning
      switch ProcessOfStep  {
      case .Wait:
        timeTick = timeTick + 1
        if (timeOutMax < timeTick){
          let status =  MeshNetworkManager.bearer!
          if(status.isOpen == true){
            ProcessOfStep = .Success
          }else{
            ProcessOfStep = .TimeOut
          }

          timeTick = 0
        }
        break
      case .Start:
        self.lblLog.text = vietSub("Reconnect")
        bbearer!.open()
        ProcessOfStep = .Wait
        timeOutMax = 1000
        timeTick=0
        break
      case .TimeOut:
        if(countTimeOut>2) {
          countTimeOut = 0
          ProcessOfStep = .Error
        } else {
          countTimeOut = countTimeOut + 1
          ProcessOfStep = .Start
        }
        break
      case .Error:
        StepProvision = .Error
        ProcessOfStep = .Start
        break
      case .Success:
        ProcessOfStep = .End
        break
      case .End:
        self.ProgressPercent = 0.15
        progress.setProgress(self.ProgressPercent, animated: true)
        StepProvision = .GetComposition
        ProcessOfStep = .Start
        break
      }
      break

    case .GetComposition:/// Get composition data
      switch ProcessOfStep {
      case .Wait:
        timeTick = timeTick + 1
        if (timeOutMax < timeTick){
          ProcessOfStep = .TimeOut
          timeTick = 0
        }
        break
      case .Start:
        self.lblLog.text = vietSub("Get Composition Data")
        self.getCompositionData()
        ProcessOfStep = .Wait
        timeTick=0
        break
      case .TimeOut:
        if(countTimeOut>2) {
          countTimeOut = 0
          ProcessOfStep = .Error
        } else {
          countTimeOut = countTimeOut + 1
          ProcessOfStep = .Start
        }
        break
      case .Error:
        StepProvision = .Error
        ProcessOfStep = .Start
        break
      case .Success:
        ProcessOfStep = .End
        break
      case .End:
        self.ProgressPercent = 0.23
        progress.setProgress(self.ProgressPercent, animated: true)
        StepProvision = .GetTTL
        ProcessOfStep = .Start
        break
      }
      break

    case .GetTTL:///Get TTL of Node
      switch ProcessOfStep
      {
      case .Wait:
        timeTick = timeTick + 1
        if (timeOutMax < timeTick)
        {
          ProcessOfStep = .TimeOut
          timeTick = 0
        }
        break
      case .Start:
        self.lblLog.text = vietSub("Get TTL")
        self.getTtl()
        ProcessOfStep = .Wait
        timeTick=0
        break
      case .TimeOut:
        if(countTimeOut>2){
          countTimeOut = 0
          ProcessOfStep = .Error
        }else {
          countTimeOut = countTimeOut + 1
          ProcessOfStep = .Start
        }
        break
      case .Error:
        StepProvision = .Error
        ProcessOfStep = .Start
        break
      case .Success:
        ProcessOfStep = .End
        break
      case .End:
        self.ProgressPercent = 0.35
        progress.setProgress(self.ProgressPercent, animated: true)
        StepProvision = .AddAppKey
        ProcessOfStep = .Start
        break
      }
      break

    case .AddAppKey:/// Add appkey for device
      switch ProcessOfStep {
      case .Wait:
        timeTick = timeTick + 1
        if (timeOutMax < timeTick) {
          ProcessOfStep = .TimeOut
          timeTick = 0
        }

        break
      case .Start:
        self.lblLog.text = vietSub("Adding Application Key")
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        let keys = meshNetwork.applicationKeys
        let selectedKey = keys[0]

        start("Adding Application Key...") {
          return try MeshNetworkManager.instance.send(ConfigAppKeyAdd(applicationKey: selectedKey), to: self.node)
        }

        ProcessOfStep = .Wait
        timeTick=0
        break
      case .TimeOut:
        if(countTimeOut>2) {
          countTimeOut = 0
          ProcessOfStep = .Error
        } else {
          countTimeOut = countTimeOut + 1
          ProcessOfStep = .Start
        }

        break

      case .Error:
        StepProvision = .Error
        ProcessOfStep = .Start
        break

      case .Success:
        ProcessOfStep = .End
        break
      case .End:
        modelIndex = 0
        elementIndex = 0
        self.ProgressPercent = 0.42
        progress.setProgress(self.ProgressPercent, animated: true)
        StepProvision = .Bindkey
        self.lblLog.text = vietSub("Bind key")
        ProcessOfStep = .Start
        break
      }
      break

    case .Bindkey:/// Bind key for models supported
      switch ProcessOfStep {
      case .Wait:
        timeTick = timeTick + 1
        if (timeOutMax < timeTick) {
          ProcessOfStep = .TimeOut
          timeTick = 0
        }

        break
      case .Start:
        let elements = self.node.elements
        if(elementIndex < elements.count) {
          let element = elements[elementIndex]
          let models = element.models
          if(modelIndex < models.count) {
            self.model = models[modelIndex]
            if(self.model.isSupport) {
              print("App Model= 0x\(self.model.modelIdentifier.hex) - Model Name = \(String(describing: self.model.name))")
              self.bind()
              modelIndex = modelIndex + 1
              ProcessOfStep = .Wait
              timeTick=0
            } else {
              modelIndex = modelIndex + 1
            }
          }else{
            modelIndex = 0
            elementIndex = elementIndex + 1
          }
        } else{
          ProcessOfStep = .End
          timeTick=0
        }
        break
      case .TimeOut:
        if(countTimeOut>2) {
          countTimeOut = 0
          ProcessOfStep = .Error
        } else {
          countTimeOut = countTimeOut + 1
          modelIndex = modelIndex - 1
          ProcessOfStep = .Start
        }
        break
      case .Error:
        StepProvision = .Error
        ProcessOfStep = .Start
        break
      case .Success:
        ProcessOfStep = .Start
        break
      case .End:
        modelIndex = 0
        elementIndex = 0
        self.lblLog.text = vietSub("Finish")
        StepProvision = .Success
        ProcessOfStep = .Start
        progress.setProgress(1.0, animated: true)
        break
      }
      break



    case .Success:///Provision success
      //            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
      self.finnish()
      let alertEnd = UIAlertController(title: vietSub("Success"), message: vietSub("Provisioning Success! Return back scan page!"), preferredStyle: UIAlertController.Style.alert)
      let OK = UIAlertAction(title: vietSub("OK"), style: UIAlertAction.Style.default) { (UIAlertAction) in
        alertEnd.dismiss(animated: true)
        _ = self.navigationController?.popViewController(animated: true)
      }

      alertEnd.addAction(OK)
      self.present(alertEnd, animated: true)
      self.disable_timer()
      //            }
      break
    case .Error:///Provision Error
      StepProvision = .Wait
      self.finnish()
      let alertEnd = UIAlertController(title: vietSub("Error"), message: vietSub("Get something error! Please reset and try again!"), preferredStyle: UIAlertController.Style.alert)
      let OK = UIAlertAction(title: vietSub("OK"), style: UIAlertAction.Style.default) { (UIAlertAction) in
        alertEnd.dismiss(animated: true)
        _ = self.navigationController?.popViewController(animated: true)
      }

      alertEnd.addAction(OK)
      self.present(alertEnd, animated: true)
      self.disable_timer()
      break
    }
  }
}

// MARK: - Longpress
extension ProvisionDeviceVC: UIGestureRecognizerDelegate {
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
      let alertController = UIAlertController(title: "Trở thành nhà phát triền", message: "DFU Feature is enable", preferredStyle: .alert)
      /// Do something
      self.isDevelopt = !self.isDevelopt
      self.present(alertController, animated: true)
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(3), execute: {
        alertController.dismiss(animated: true)
      })
    }
  }
}
