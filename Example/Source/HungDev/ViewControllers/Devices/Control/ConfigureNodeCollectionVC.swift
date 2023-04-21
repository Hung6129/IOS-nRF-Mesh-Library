//
//  ConfigureNodeVC.swift
//  nRF Mesh
//
//  Created by Hưng Nguyễn on 20/04/2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class ConfigureNodeCollectionVC: ProgressCollectionViewController {

  // MARK: - Variable
  struct ModelStruct{
    var indexPath: IndexPath
    var isServer: Bool
    var status: Any!
    var range: Any!
  }
  struct ElementStruct{
    var models: [ModelStruct]
    var name: String!
  }

  var node: Node!
  var aNode:[ElementStruct] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.dataSource = self
    collectionView.delegate = self

    if node.isCompositionDataReceived{
      getModel()
    }else{
      alertNoConnectFunc()
    }
  }


  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    collectionView.reloadData()
  }

}

extension ConfigureNodeCollectionVC {

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return aNode.count
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if aNode.count > 0 {
      return aNode[section].models.count
    }else{
      return 0
    }
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "modelCollectionViewCell", for: indexPath) as! ModelCollectionCell
    let index = aNode[indexPath.section].models[indexPath.row].indexPath
    let amodel = aNode[indexPath.section].models[indexPath.row]
    let model = node.elements[index.section].models[index.row]
    switch model.modelId32 {
    case Apollo.Model.GenericOnOffServer:
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "modelCollectionViewCell", for: indexPath) as! ModelCollectionCell
      let status = amodel.status as? GenericOnOffStatus
      if(status != nil) {
        if (status!.isOn) {
          cell.imgIcon.image = UIImage(named: "bao_btn_ON")
        } else {
          cell.imgIcon.image = UIImage(named: "bao_btn_OFF")
        }
      }else{
        cell.imgIcon.image = UIImage(named: "bao_btn_ON")
      }
      cell.imgIcon.backgroundColor = UIColor.clear
      cell.modelName.text = vietSub("On - Off")
      break
    
    default:
      cell.imgIcon.image = UIImage(named: "tab_settings_outline_black_24pt")
      break
    }
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    let headerText = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "elementCollectionReusableView", for: indexPath) as! ElementCollectionReusable
    if(aNode[indexPath.section].name != nil) {
      headerText.elementNum.text = aNode[indexPath.section].name
    } else{
      headerText.elementNum.text = "\(vietSub("Element")) \(indexPath.section)"
    }
    return headerText
  }
}


extension ConfigureNodeCollectionVC: UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let itemSize = (collectionView.frame.width - (collectionView.contentInset.left + collectionView.contentInset.right + 10)) / 3.3
    return CGSize(width: itemSize, height: itemSize)
  }
}

extension ConfigureNodeCollectionVC{

  // alert connection
  func alertNoConnectFunc()
  {
    let alert = UIAlertController(title: vietSub("No connection"), message: vietSub("This function is only used when having a connection! Please keep devices closely and wait for connection!"), preferredStyle: UIAlertController.Style.alert)
    let OK = UIAlertAction(title: vietSub("OK"), style: UIAlertAction.Style.cancel, handler: nil)
    alert.addAction(OK)
    self.present(alert,animated: true)
  }


  // get models form node
  func getModel(){
    let elements = node.elements
    aNode = []
    for i in 0..<elements.count {
      let models = elements[i].models
      var Models: [ModelStruct] = []
      for j in 0..<models.count {
        var status: Any! = nil
        var range: Any! = nil
        var isServer = true
        let index = IndexPath(row: j, section: i)
        switch models[j].modelId32 {
        case Apollo.Model.GenericOnOffServer:
          isServer = true
          status = GenericOnOffStatus(false)
          break
        case Apollo.Model.LightLightnessServer:

          isServer = true
          status = LightLightnessStatus(lightness: 0x7FFF)
          break
        case Apollo.Model.LightHSLServer:

          isServer = true
          status = LightHSLStatus(lightness: 0, hue: 0, saturation: 0)
          break
        case Apollo.Model.GenericLevelServer:

          isServer = true
          status = GenericLevelStatus(level: 0)
          break
        case Apollo.Model.LightCTLServer:

          isServer = true
          let minmax = UInt16(800)...UInt16(20000)
          range = LightCTLTemperatureRangeStatus(report: minmax)
          status = LightCTLStatus(lightness: 0x7FFF, temperature: 0x7FFF)
          break
        case Apollo.Model.VendorPIRServer:

          isServer = true
          break
        case Apollo.Model.LightHSLClient:

          isServer = true
          break
        default:
          break
        }

        if(models[j].isSupport) {
          Models.append(ModelStruct(indexPath: index, isServer: isServer, status: status,range: range))
        }
      }

      let E = ElementStruct(models: Models, name: elements[i].name)
      aNode.append(E)
    }
  }
}
