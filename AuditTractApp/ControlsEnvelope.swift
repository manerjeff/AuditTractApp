//
//  ControlsEnvelope.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/13/26.
//

import Foundation

// Envelope structure for cloud sync
struct ControlsEnvelope: Codable {
    let version: String
    let updatedAt: String
    let controls: [AuditTask]
}
