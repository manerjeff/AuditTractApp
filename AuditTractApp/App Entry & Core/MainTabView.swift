//
//  MainTabView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: String = "Controls"
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Segmented Bar
            Picker("Navigation", selection: $selectedTab) {
                Text("Controls").tag("Controls")
                Text("Inventory").tag("Inventory")
                Text("Attack Surface").tag("Attack Surface")
                Text("Intelligence").tag("Intelligence")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            
            // Active Tab View Content
            ZStack {
                switch selectedTab {
                case "Controls":
                    ControlCenterView()
                case "Inventory":
                    InventoryView()
                case "Attack Surface":
                    VulnerabilityView()
                case "Intelligence":
                    SecurityNewsView()
                default:
                    ControlCenterView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
