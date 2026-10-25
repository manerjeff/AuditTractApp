//
//  InventoryView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI
import SwiftData

// MARK: - Asset Display Helpers

extension AssetStatus {
    var iconName: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .decommissioned: return "archivebox.fill"
        case .disposed: return "trash.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .active: return .green
        case .maintenance: return .orange
        case .decommissioned: return .secondary
        case .disposed: return .red
        }
    }
}

extension AssetCriticality {
    var color: Color {
        switch self {
        case .tier1: return .red
        case .tier2: return .orange
        case .tier3: return .blue
        }
    }
    
    var shortName: String {
        switch self {
        case .tier1: return "Tier 1"
        case .tier2: return "Tier 2"
        case .tier3: return "Tier 3"
        }
    }
}

// MARK: - Main Inventory View

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InventoryItem.name) private var items: [InventoryItem]
    
    @State private var searchText: String = ""
    @State private var filterStatus: AssetStatus? = nil
    @State private var showingAddSheet: Bool = false
    @State private var selectedItem: InventoryItem? = nil
    
    var filteredItems: [InventoryItem] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.assetType.localizedCaseInsensitiveContains(searchText) ||
                item.ownerDisplayName.localizedCaseInsensitiveContains(searchText) ||
                (item.ipAddressOrURL?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                item.notes.localizedCaseInsensitiveContains(searchText)
            
            let matchesStatus = filterStatus == nil || item.status == filterStatus
            return matchesSearch && matchesStatus
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Stat Cards
                summaryCards
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                // Status Filter Chips
                filterChips
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                Divider()
                
                // Asset List / Content
                if filteredItems.isEmpty {
                    ContentUnavailableView {
                        Label("No Assets Found", systemImage: "server.rack")
                    } description: {
                        Text(items.isEmpty ? "Tap '+' to add your first asset to the inventory." : "No assets match your search or filter.")
                    } actions: {
                        if items.isEmpty {
                            Button("Load Sample Inventory") {
                                seedDefaultInventory()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            Button {
                                selectedItem = item
                            } label: {
                                assetRow(for: item)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.primary.opacity(0.03))
            .navigationTitle("Asset Inventory")
            .searchable(text: $searchText, prompt: "Search assets by name, type, owner...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Add Asset", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddInventoryItemSheet()
            }
            .sheet(item: $selectedItem) { item in
                InventoryItemDetailSheet(item: item)
            }
            .onAppear {
                if items.isEmpty {
                    seedDefaultInventory()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var summaryCards: some View {
        HStack(spacing: 10) {
            statCard(title: "Total", count: items.count, icon: "server.rack", color: .accentColor)
            statCard(title: "Active", count: items.filter { $0.status == .active }.count, icon: "checkmark.circle.fill", color: .green)
            statCard(title: "Critical", count: items.filter { $0.criticality == .tier1 }.count, icon: "exclamationmark.triangle.fill", color: .red)
            statCard(title: "Decommissioned", count: items.filter { $0.status == .decommissioned || $0.status == .disposed }.count, icon: "archivebox.fill", color: .secondary)
        }
    }
    
    private func statCard(title: String, count: Int, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Spacer()
                Text("\(count)")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", isSelected: filterStatus == nil) {
                    filterStatus = nil
                }
                ForEach(AssetStatus.allCases, id: \.self) { status in
                    filterChip(title: status.rawValue, isSelected: filterStatus == status) {
                        filterStatus = (filterStatus == status) ? nil : status
                    }
                }
            }
        }
    }
    
    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private func assetRow(for item: InventoryItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(item.assetType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: item.status.iconName)
                        .font(.caption2)
                    Text(item.status.rawValue)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.status.color.opacity(0.15))
                .foregroundColor(item.status.color)
                .clipShape(Capsule())
            }
            
            HStack(spacing: 8) {
                Label(item.ownerDisplayName, systemImage: "person.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let ip = item.ipAddressOrURL, !ip.isEmpty {
                    Text("•")
                        .foregroundColor(.secondary)
                    Label(ip, systemImage: "network")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if item.isEncrypted {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                
                // Criticality badge
                Text(item.criticality.shortName)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(item.criticality.color.opacity(0.15))
                    .foregroundColor(item.criticality.color)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            if !item.linkedControlIDs.isEmpty {
                HStack(spacing: 4) {
                    ForEach(item.linkedControlIDs.prefix(3), id: \.self) { control in
                        Text(control)
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    if item.linkedControlIDs.count > 3 {
                        Text("+\(item.linkedControlIDs.count - 3)")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredItems[index]
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
    
    private func seedDefaultInventory() {
        guard items.isEmpty else { return }
        for sample in InventoryItem.buildDefaultInventory() {
            modelContext.insert(sample)
        }
        try? modelContext.save()
    }
}

// MARK: - Add Inventory Item Sheet

struct AddInventoryItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Employee.name) private var employees: [Employee]
    
    @State private var name: String = ""
    @State private var assetType: String = "Server"
    @State private var selectedEmployee: Employee? = nil
    @State private var customOwner: String = ""
    @State private var isCreatingNewEmployee: Bool = false
    @State private var newEmployeeName: String = ""
    @State private var newEmployeeRole: String = "Staff"
    @State private var newEmployeeDepartment: String = "IT"
    
    @State private var ipAddressOrURL: String = ""
    @State private var status: AssetStatus = .active
    @State private var classification: DataClassification = .internalData
    @State private var criticality: AssetCriticality = .tier2
    @State private var isEncrypted: Bool = true
    @State private var linkedControlsInput: String = ""
    @State private var notes: String = ""
    
    let commonAssetTypes = ["Server", "Database", "Cloud Resource", "Workstation", "Mobile Device", "Network Appliance", "SaaS Application", "Data Asset"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Asset Name", text: $name)
                    Picker("Asset Type", selection: $assetType) {
                        ForEach(commonAssetTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    TextField("IP Address or URL (Optional)", text: $ipAddressOrURL)
                }
                
                Section("Assigned Employee / Custodian") {
                    Picker("Assign Employee", selection: $selectedEmployee) {
                        Text("None / Unassigned").tag(Employee?.none)
                        ForEach(employees) { emp in
                            Text("\(emp.name) (\(emp.department))").tag(Employee?.some(emp))
                        }
                    }
                    
                    Toggle("Create New Employee Record", isOn: $isCreatingNewEmployee)
                    
                    if isCreatingNewEmployee {
                        TextField("Employee Full Name", text: $newEmployeeName)
                        TextField("Role / Title", text: $newEmployeeRole)
                        TextField("Department", text: $newEmployeeDepartment)
                    } else if selectedEmployee == nil {
                        TextField("Owner / Team Label (Fallback)", text: $customOwner)
                    }
                }
                
                Section("Governance & Classification") {
                    Picker("Status", selection: $status) {
                        ForEach(AssetStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    Picker("Classification", selection: $classification) {
                        ForEach(DataClassification.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    Picker("Criticality", selection: $criticality) {
                        ForEach(AssetCriticality.allCases, id: \.self) { crit in
                            Text(crit.rawValue).tag(crit)
                        }
                    }
                    Toggle("Encrypted at Rest / Transit", isOn: $isEncrypted)
                }
                
                Section("Compliance Mapping") {
                    TextField("Linked Control IDs (comma-separated, e.g. PCI-REQ-03, SI-02)", text: $linkedControlsInput)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Asset")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveItem() {
        var finalEmployee: Employee? = selectedEmployee
        
        if isCreatingNewEmployee && !newEmployeeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let createdEmp = Employee(
                name: newEmployeeName.trimmingCharacters(in: .whitespacesAndNewlines),
                role: newEmployeeRole.trimmingCharacters(in: .whitespacesAndNewlines),
                department: newEmployeeDepartment.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            modelContext.insert(createdEmp)
            finalEmployee = createdEmp
        }
        
        let controls = linkedControlsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let newItem = InventoryItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            assetType: assetType,
            owner: customOwner.trimmingCharacters(in: .whitespacesAndNewlines),
            assignedEmployee: finalEmployee,
            ipAddressOrURL: ipAddressOrURL.isEmpty ? nil : ipAddressOrURL.trimmingCharacters(in: .whitespacesAndNewlines),
            status: status,
            classification: classification,
            criticality: criticality,
            linkedControlIDs: controls,
            isEncrypted: isEncrypted,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        modelContext.insert(newItem)
        try? modelContext.save()
    }
}

// MARK: - Inventory Item Detail Sheet

struct InventoryItemDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Employee.name) private var allEmployees: [Employee]
    @Bindable var item: InventoryItem
    
    @State private var isEditing: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Asset Details") {
                    LabeledContent("Name") {
                        if isEditing {
                            TextField("Name", text: $item.name)
                                .multilineTextAlignment(.trailing)
                        } else {
                            Text(item.name)
                        }
                    }
                    
                    LabeledContent("Type") {
                        if isEditing {
                            TextField("Type", text: $item.assetType)
                                .multilineTextAlignment(.trailing)
                        } else {
                            Text(item.assetType)
                        }
                    }
                    
                    LabeledContent("IP / Host") {
                        if isEditing {
                            TextField("IP or Host", text: Binding(
                                get: { item.ipAddressOrURL ?? "" },
                                set: { item.ipAddressOrURL = $0.isEmpty ? nil : $0 }
                            ))
                            .multilineTextAlignment(.trailing)
                        } else {
                            Text(item.ipAddressOrURL ?? "None")
                                .foregroundColor(item.ipAddressOrURL == nil ? .secondary : .primary)
                        }
                    }
                }
                
                Section("Assigned Employee / Custodian") {
                    if isEditing {
                        Picker("Assigned Employee", selection: $item.assignedEmployee) {
                            Text("None / Unassigned").tag(Employee?.none)
                            ForEach(allEmployees) { emp in
                                Text("\(emp.name) (\(emp.department))").tag(Employee?.some(emp))
                            }
                        }
                        
                        if item.assignedEmployee == nil {
                            TextField("Owner / Team Label (Fallback)", text: $item.owner)
                        }
                    } else {
                        if let emp = item.assignedEmployee {
                            LabeledContent("Assigned Person", value: emp.name)
                            LabeledContent("Role", value: emp.role)
                            LabeledContent("Department", value: emp.department)
                        } else {
                            LabeledContent("Owner / Team", value: item.owner.isEmpty ? "Unassigned" : item.owner)
                        }
                    }
                }
                
                Section("Security & Status") {
                    Picker("Status", selection: $item.status) {
                        ForEach(AssetStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .disabled(!isEditing)
                    
                    Picker("Classification", selection: $item.classification) {
                        ForEach(DataClassification.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    .disabled(!isEditing)
                    
                    Picker("Criticality", selection: $item.criticality) {
                        ForEach(AssetCriticality.allCases, id: \.self) { crit in
                            Text(crit.rawValue).tag(crit)
                        }
                    }
                    .disabled(!isEditing)
                    
                    Toggle("Encrypted", isOn: $item.isEncrypted)
                        .disabled(!isEditing)
                }
                
                if let certID = item.sanitizationCertificateID {
                    Section("Sanitization & Decommission") {
                        LabeledContent("Certificate ID", value: certID)
                        if let date = item.decommissionedDate {
                            LabeledContent("Decommissioned Date", value: date.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                }
                
                if !item.linkedControlIDs.isEmpty {
                    Section("Linked Audit Controls") {
                        ForEach(item.linkedControlIDs, id: \.self) { control in
                            Label(control, systemImage: "shield.lefthalf.filled")
                        }
                    }
                }
                
                Section("Notes") {
                    if isEditing {
                        TextEditor(text: $item.notes)
                            .frame(minHeight: 80)
                    } else {
                        Text(item.notes.isEmpty ? "No notes recorded." : item.notes)
                            .foregroundColor(item.notes.isEmpty ? .secondary : .primary)
                    }
                }
            }
            .navigationTitle(item.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Done" : "Close") {
                        if isEditing {
                            try? modelContext.save()
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            try? modelContext.save()
                            isEditing = false
                        } else {
                            isEditing = true
                        }
                    }
                }
            }
        }
    }
}
