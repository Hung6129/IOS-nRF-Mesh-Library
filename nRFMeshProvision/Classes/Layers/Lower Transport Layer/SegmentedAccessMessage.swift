//
//  SegmentedAccessMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 31/05/2019.
//

import Foundation

internal struct SegmentedAccessMessage: SegmentedMessage {
    let message: MeshMessage?
    let localElement: Element?
    let source: Address
    let destination: Address
    let networkKey: NetworkKey
    
    /// The Application Key identifier.
    /// This field is set to `nil` if the message is signed with a
    /// Device Key instead.
    let aid: UInt8?
    /// The size of Transport MIC: 4 or 8 bytes.
    let transportMicSize: UInt8
    /// The sequence number used to encode this message.
    let sequence: UInt32
    
    let sequenceZero: UInt16
    let segmentOffset: UInt8
    let lastSegmentNumber: UInt8
    
    let upperTransportPdu: Data
    
    var transportPdu: Data {
        var octet0: UInt8 = 0x80 // SEG = 1
        if let aid = aid {
            octet0 |= 0b01000000 // AKF = 1
            octet0 |= aid
        }
        let octet1 = ((transportMicSize << 4) & 0x80) | UInt8(sequenceZero >> 6)
        let octet2 = UInt8((sequenceZero & 0x3F) << 2) | (segmentOffset >> 3)
        let octet3 = ((segmentOffset & 0x07) << 5) | (lastSegmentNumber & 0x1F)
        return Data([octet0, octet1, octet2, octet3]) + upperTransportPdu
    }
    
    let type: LowerTransportPduType = .accessMessage
    
    /// Creates a Segment of an Access Message from a Network PDU that contains
    /// a segmented access message. If the PDU is invalid, the
    /// init returns `nil`.
    ///
    /// - parameter networkPdu: The received Network PDU with segmented
    ///                         Upper Transport message.
    init?(fromSegmentPdu networkPdu: NetworkPdu) {
        let data = networkPdu.transportPdu
        guard data.count >= 5, data[0] & 0x80 != 0 else {
            return nil
        }
        let akf = (data[0] & 0b01000000) != 0
        if akf {
            aid = data[0] & 0x3F
        } else {
            aid = nil
        }
        let szmic = data[1] >> 7
        transportMicSize = szmic == 0 ? 4 : 8
        
        sequenceZero = (UInt16(data[1] & 0x7F) << 6) | UInt16(data[2] >> 2)
        segmentOffset = ((data[2] & 0x03) << 3) | ((data[3] & 0xE0) >> 5)
        lastSegmentNumber = data[3] & 0x1F
        guard segmentOffset <= lastSegmentNumber else {
            return nil
        }
        upperTransportPdu = data.advanced(by: 4)
        sequence = (networkPdu.sequence & 0xFFE000) | UInt32(sequenceZero)
        
        source = networkPdu.source
        destination = networkPdu.destination
        networkKey = networkPdu.networkKey
        message = nil
        localElement = nil
    }

    /// Creates a Segment of an Access Message object from the Upper Transport PDU
    /// with given segment offset.
    ///
    /// - parameter pdu: The segmented Upper Transport PDU.
    /// - parameter networkKey: The Network Key to encrypt the PCU with.
    /// - parameter offset: The segment offset.
    init(fromUpperTransportPdu pdu: UpperTransportPdu, usingNetworkKey networkKey: NetworkKey, offset: UInt8) {
        self.message = pdu.message
        self.localElement = pdu.localElement
        self.aid = pdu.aid
        self.source = pdu.source
        self.destination = pdu.destination
        self.networkKey = networkKey
        self.transportMicSize = pdu.transportMicSize
        self.sequence = pdu.sequence
        self.sequenceZero = UInt16(pdu.sequence & 0x1FFF)
        self.segmentOffset = offset
        
        let lowerBound = Int(offset * 12)
        let upperBound = min(pdu.transportPdu.count, Int(offset + 1) * 12)
        let segment = pdu.transportPdu.subdata(in: lowerBound..<upperBound)
        self.lastSegmentNumber = UInt8((pdu.transportPdu.count + 11) / 12) - 1
        self.upperTransportPdu = segment
    }
}

extension SegmentedAccessMessage: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "Segmented \(type) (\(source.hex)->\(destination.hex)) for SeqZero: \(sequenceZero) (\(segmentOffset + 1)/\(lastSegmentNumber + 1)), Seq: \(sequence), 0x\(upperTransportPdu.hex)"
    }
    
}
