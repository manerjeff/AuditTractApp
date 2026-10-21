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
            // Top Segmented Bar
            Picker("Navigation", selection: $selectedTab) {
                Text("Controls").tag("Controls")
                Text("Inventory").tag("Inventory")
                Text("Attack Surface").tag("Attack Surface")
                Text("Intelligence").tag("Intelligence")
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            
            // Tab Content Switcher
            switch selectedTab {
            case "Controls":
                ControlCenterView()
            case "Inventory":
                InventoryView() // 👈 Plug in the new InventoryView here!
            case "Attack Surface":
                Text("Attack Surface View Placeholder")
            case "Intelligence":
                Text("Intelligence View Placeholder")
            default:
                ControlCenterView()
            }
        }
    }
}
