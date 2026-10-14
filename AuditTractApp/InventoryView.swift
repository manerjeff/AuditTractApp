//
//  InventoryView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//


import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Live Queries from SQLite via SwiftData
    @Query(sort: \AssetItem.name) private var assets: [AssetItem]
    @Query(sort: \Location.name) private var locations: [Location]
    @Query(sort: \Employee.name) private var employees: [Employee]
    
    @State private var searchText: String = ""
    @State private var selectedFilterType: String = "All"
    
    // Sheet States
    @State private var showingAddAssetSheet: Bool = false
    @State private var showingAddLocationSheet: Bool = false
    @State private var showingAddEmployeeSheet: Bool = false
    
    // Form Inputs - New Asset
    @State private var newAssetName: String = ""
    @State private var newAssetIP: String = ""
    @State private var newAssetType: String = "Server"
    @State private var newAssetCriticality: String = "High"
    @State private var selectedLocationID: String = ""
    @State private var selectedOwnerID: String = ""
    
    // Form Inputs - New Location
    @State private var newLocationName: String = ""
    @State private var newLocationAddress: String = ""
    @State private var newLocationType: String = "Data Center"
    
    // Form Inputs - New Employee
    @State private var newEmployeeName: String = ""
    @State private var newEmployeeEmail: String = ""
    @State private var newEmployeeRole: String = "System Administrator"
    @State private var newEmployeeDept: String = "IT Infrastructure"
    
    var filteredAssets: [AssetItem] {
        assets.filter { item in
            let matchesType = selectedFilterType == "All" || item.assetType == selectedFilterType
            if searchText.isEmpty {
                return matchesType
            } else {
                return matchesType && (
                    item.name.localizedCaseInsensitiveContains(searchText) ||
                    item.ipAddress.localizedCaseInsensitiveContains(searchText) ||
                    item.assetType.localizedCaseInsensitiveContains(searchText)
                )
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // MARK: - Sidebar Filter & Action Controls
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ENTERPRISE INVENTORY")
                                .font(.caption2)
                                .fontWeight(.black)
                                .foregroundColor(.accentColor)
                                .tracking(1)
                            
                            Text("Assets (\(filteredAssets.count))")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        
                        Menu {
                            Button(action: { showingAddAssetSheet = true }) {
                                Label("Add Asset", systemImage: "server.rack")
                            }
                            Button(action: { showingAddLocationSheet = true }) {
                                Label("Add Facility Location", systemImage: "building.2.fill")
                            }
                            Button(action: { showingAddEmployeeSheet = true }) {
                                Label("Add Employee", systemImage: "person.badge.plus")
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.accentColor)
                            .font(.subheadline)
                        TextField("Search assets, IPs...", text: $searchText)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                
                Divider()
                
                // Asset List
                List {
                    ForEach(filteredAssets) { asset in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(asset.name)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text(asset.criticality.uppercased())
                                    .font(.caption2)
                                    .fontWeight(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(criticalityColor(asset.criticality).opacity(0.18))
                                    .foregroundColor(criticalityColor(asset.criticality))
                                    .clipShape(Capsule())
                            }
                            
                            HStack(spacing: 12) {
                                Label(asset.ipAddress, systemImage: "network")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Label(asset.assetType, systemImage: "laptopcomputer.and.iphone")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let location = asset.location {
                                Label(location.name, systemImage: "mappin.and.ellipse")
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteAssets)
                }
                .listStyle(.insetGrouped)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.inline)
        } detail: {
            // MARK: - Detail View / Quick Overview Cards
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header Metrics Card
                    HStack(spacing: 16) {
                        MetricBox(title: "TOTAL ASSETS", count: "\(assets.count)", icon: "server.rack", color: .blue)
                        MetricBox(title: "LOCATIONS", count: "\(locations.count)", icon: "building.2.fill", color: .orange)
                        MetricBox(title: "PERSONNEL", count: "\(employees.count)", icon: "person.3.fill", color: .green)
                    }
                    
                    // Locations List Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("FACILITY LOCATIONS", systemImage: "building.2")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Add Location") { showingAddLocationSheet = true }
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        
                        if locations.isEmpty {
                            Text("No locations configured. Click 'Add Location' to set up facilities.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(locations) { loc in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(loc.name)
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                            Text(loc.address)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(loc.facilityType)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.primary.opacity(0.06))
                                            .clipShape(Capsule())
                                    }
                                    .padding(12)
                                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    // Employee Roster Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("PERSONNEL & RESPONSIBILITY DIRECTORY", systemImage: "person.3")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Add Employee") { showingAddEmployeeSheet = true }
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        
                        if employees.isEmpty {
                            Text("No personnel added. Click 'Add Employee' to populate your team.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(employees) { emp in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(emp.name)
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                            Text("\(emp.role) • \(emp.department)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(emp.email)
                                            .font(.caption2)
                                            .foregroundColor(.accentColor)
                                    }
                                    .padding(12)
                                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
        
        // MARK: - Add Asset Modal Sheet
        .sheet(isPresented: $showingAddAssetSheet) {
            NavigationStack {
                Form {
                    Section("Asset Details") {
                        TextField("Asset Hostname / Name", text: $newAssetName)
                        TextField("IP Address or Endpoint", text: $newAssetIP)
                        Picker("Asset Type", selection: $newAssetType) {
                            ForEach(["Server", "Workstation", "Cloud Router", "Database", "Firewall"], id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        Picker("Criticality", selection: $newAssetCriticality) {
                            ForEach(["High", "Medium", "Low"], id: \.self) { crit in
                                Text(crit).tag(crit)
                            }
                        }
                    }
                    
                    Section("Assignments") {
                        Picker("Facility Location", selection: $selectedLocationID) {
                            Text("None").tag("")
                            ForEach(locations) { loc in
                                Text(loc.name).tag(loc.id)
                            }
                        }
                        Picker("Assigned Owner", selection: $selectedOwnerID) {
                            Text("None").tag("")
                            ForEach(employees) { emp in
                                Text(emp.name).tag(emp.id)
                            }
                        }
                    }
                }
                .navigationTitle("Add Inventory Asset")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddAssetSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveAsset()
                            showingAddAssetSheet = false
                        }
                        .disabled(newAssetName.isEmpty || newAssetIP.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        
        // MARK: - Add Location Modal Sheet
        .sheet(isPresented: $showingAddLocationSheet) {
            NavigationStack {
                Form {
                    Section("Facility Info") {
                        TextField("Location Name (e.g. Data Center East)", text: $newLocationName)
                        TextField("Address / Region", text: $newLocationAddress)
                        Picker("Facility Type", selection: $newLocationType) {
                            ForEach(["Data Center", "Corporate HQ", "Branch Office", "Cloud VPC"], id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                    }
                }
                .navigationTitle("Add Facility Location")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddLocationSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let loc = Location(name: newLocationName, address: newLocationAddress, facilityType: newLocationType)
                            modelContext.insert(loc)
                            try? modelContext.save()
                            newLocationName = ""
                            newLocationAddress = ""
                            showingAddLocationSheet = false
                        }
                        .disabled(newLocationName.isEmpty)
                    }
                }
            }
            .presentationDetents([.height(300)])
        }
        
        // MARK: - Add Employee Modal Sheet
        .sheet(isPresented: $showingAddEmployeeSheet) {
            NavigationStack {
                Form {
                    Section("Personnel Information") {
                        TextField("Full Name", text: $newEmployeeName)
                        TextField("Email Address", text: $newEmployeeEmail)
                        TextField("Role / Title", text: $newEmployeeRole)
                        TextField("Department", text: $newEmployeeDept)
                    }
                }
                .navigationTitle("Add Personnel")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddEmployeeSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let emp = Employee(name: newEmployeeName, email: newEmployeeEmail, role: newEmployeeRole, department: newEmployeeDept)
                            modelContext.insert(emp)
                            try? modelContext.save()
                            newEmployeeName = ""
                            newEmployeeEmail = ""
                            showingAddEmployeeSheet = false
                        }
                        .disabled(newEmployeeName.isEmpty)
                    }
                }
            }
            .presentationDetents([.height(350)])
        }
    }
    
    // MARK: - Persistence Actions
    private func saveAsset() {
        let asset = AssetItem(name: newAssetName, ipAddress: newAssetIP, assetType: newAssetType, criticality: newAssetCriticality)
        
        if !selectedLocationID.isEmpty {
            asset.location = locations.first(where: { $0.id == selectedLocationID })
        }
        if !selectedOwnerID.isEmpty {
            asset.assignedOwner = employees.first(where: { $0.id == selectedOwnerID })
        }
        
        modelContext.insert(asset)
        try? modelContext.save()
        
        newAssetName = ""
        newAssetIP = ""
    }
    
    private func deleteAssets(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredAssets[index]
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
    
    private func criticalityColor(_ crit: String) -> Color {
        switch crit {
        case "High": return .red
        case "Medium": return .orange
        default: return .blue
        }
    }
}

// MARK: - Metric Box Subview
struct MetricBox: View {
    let title: String
    let count: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline)
                Spacer()
            }
            Text(count)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
