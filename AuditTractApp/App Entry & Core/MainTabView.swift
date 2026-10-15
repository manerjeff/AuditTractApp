//
//  MainTabView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ControlCenterView()
                .tabItem {
                    Label("Controls", systemImage: "shield.checkered")
                }
            
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "server.rack")
                }
            
            VulnerabilityView()
                .tabItem {
                    Label("Attack Surface", systemImage: "exclamationmark.shield")
                }
            
            SecurityNewsView()
                .tabItem {
                    Label("Intelligence", systemImage: "newspaper")
                }
        }
    }
}
