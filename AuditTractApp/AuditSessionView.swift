//
//  AuditSessionView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//


import SwiftUI
import SwiftData

struct AuditSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Assessment.createdDate, order: .reverse) private var assessments: [Assessment]
    @Query(sort: \Location.name) private var locations: [Location]
    @Query(sort: \Employee.name) private var employees: [Employee]
    
    @State private var showingNewSessionSheet: Bool = false
    @State private var sessionTitle: String = ""
    @State private var selectedFramework: String = "NIST"
    @State private var selectedLocationID: String = ""
    @State private var selectedAuditorID: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("Active & Historical Audits") {
                    if assessments.isEmpty {
                        Text("No active audit sessions found. Tap '+' to create a framework audit.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(assessments) { audit in
                            NavigationLink(destination: ControlCenterView(activeFrameworkKey: audit.frameworkKey)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(audit.title)
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        Spacer()
                                        Text(audit.frameworkKey)
                                            .font(.caption2)
                                            .fontWeight(.black)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(audit.frameworkKey == "NIST" ? Color.green.opacity(0.18) : Color.orange.opacity(0.18))
                                            .foregroundColor(audit.frameworkKey == "NIST" ? .green : .orange)
                                            .clipShape(Capsule())
                                    }
                                    
                                    HStack(spacing: 12) {
                                        if let loc = audit.scopedLocation {
                                            Label(loc.name, systemImage: "building.2.fill")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        if let lead = audit.leadAuditor {
                                            Label(lead.name, systemImage: "person.badge.shield.checkmark.fill")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteAssessments)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Audit Sessions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewSessionSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewSessionSheet) {
                NavigationStack {
                    Form {
                        Section("Audit Scope") {
                            TextField("Audit Session Title", text: $sessionTitle)
                            Picker("Framework Standard", selection: $selectedFramework) {
                                Text("NIST SP 800-53 Rev 5").tag("NIST")
                                Text("SOC 2 Type II Criteria").tag("SOC2")
                            }
                        }
                        
                        Section("Assignments") {
                            Picker("Target Facility / Location", selection: $selectedLocationID) {
                                Text("Unassigned").tag("")
                                ForEach(locations) { loc in
                                    Text(loc.name).tag(loc.id)
                                }
                            }
                            Picker("Lead Auditor", selection: $selectedAuditorID) {
                                Text("Unassigned").tag("")
                                ForEach(employees) { emp in
                                    Text(emp.name).tag(emp.id)
                                }
                            }
                        }
                    }
                    .navigationTitle("New Audit Session")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingNewSessionSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                createSession()
                                showingNewSessionSheet = false
                            }
                            .disabled(sessionTitle.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    private func createSession() {
        let audit = Assessment(title: sessionTitle, frameworkKey: selectedFramework)
        if !selectedLocationID.isEmpty {
            audit.scopedLocation = locations.first(where: { $0.id == selectedLocationID })
        }
        if !selectedAuditorID.isEmpty {
            audit.leadAuditor = employees.first(where: { $0.id == selectedAuditorID })
        }
        modelContext.insert(audit)
        try? modelContext.save()
        sessionTitle = ""
    }
    
    private func deleteAssessments(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(assessments[index])
        }
        try? modelContext.save()
    }
}
