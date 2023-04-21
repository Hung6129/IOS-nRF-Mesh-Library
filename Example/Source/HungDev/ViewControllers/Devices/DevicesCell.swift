//
//  DevicesCell.swift
//  nRF Mesh
//
//  Created by Hưng Nguyễn on 20/04/2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class DevicesCell : UITableViewCell {

  @IBOutlet weak var imgIcon: UIImageView!
  @IBOutlet weak var lblName: UILabel!
  @IBOutlet weak var lblAddress: UILabel!
//  @IBOutlet weak var lblCompany: UILabel!
//  @IBOutlet weak var btnOnOff: UIButton!


  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  var node: Node! {
    didSet {
      lblName.text = node.name
      lblAddress.text = node.primaryUnicastAddress.hex
      imgIcon.image = UIImage(named: "mesh-64")
//      let Apollo = Apollo_Product()
//      let nameImage = Apollo.getImage(node: node)
//      if(nameImage != nil) {
//        imgIcon.image = UIImage(named: nameImage!)
//      } else {
//        imgIcon.image = UIImage(named: "mesh-64")
//      }

//      if(node.isCompositionDataReceived) {
//        let elements = node.elements
//        if elements.contains(modelWithIdentifier: UInt16(Model_Support.Generic_OnOff_Server)){
//          btnOnOff.isHidden = false
//          btnOnOff.setImage(UIImage(named: "bao_btn_OFF"), for: UIControl.State.normal)
//        } else {
//          btnOnOff.isHidden = true
//        }
//      } else {
//        btnOnOff.isHidden = false
//        btnOnOff.setImage(UIImage(named: "bao_btn_Error"), for: UIControl.State.normal)
//      }
//
//      btnOnOff.isHidden = true ///Do not show button ON OFF
//      lblCompany.text = node.uuid.uuidString
      //            if(node.companyIdentifier != nil) {
      //                lblCompany.text = CompanyIdentifier.name(for: node.companyIdentifier!) ?? vietSub("Unknown")
      //            } else {
      //                lblCompany.text = vietSub("Unknown")
      //            }
    }
  }

//  func updateCell(_ node: Node) {
//    lblName.text = node.name
//    lblAddress.text = node.primaryUnicastAddress.hex
//    let Apollo = Apollo_Product()
//    let nameImage = Apollo.getImage(node: node)
//    if(nameImage != nil) {
//      imgIcon.image = UIImage(named: nameImage!)
//    } else {
//      imgIcon.image = UIImage(named: "mesh-icon")
//    }
//
//    if(node.isCompositionDataReceived) {
//      let elements = node.elements
//      if elements.contains(modelWithIdentifier: UInt16(Model_Support.Generic_OnOff_Server)){
//        btnOnOff.isHidden = false
//        btnOnOff.setImage(UIImage(named: "bao_btn_OFF"), for: UIControl.State.normal)
//      } else {
//        btnOnOff.isHidden = true
//      }
//    } else {
//      btnOnOff.isHidden = false
//      btnOnOff.setImage(UIImage(named: "bao_btn_Error"), for: UIControl.State.normal)
//    }
//
//    btnOnOff.isHidden = true ///Do not show button ON OFF
//    if(node.companyIdentifier != nil) {
//      lblCompany.text = CompanyIdentifier.name(for: node.companyIdentifier!) ?? vietSub("Unknown")
//    } else {
//      lblCompany.text = vietSub("Unknown")
//    }
//  }
}

