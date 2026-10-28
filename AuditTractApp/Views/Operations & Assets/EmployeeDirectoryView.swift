//
//  EmployeeDirectoryView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/28/26.
//

import SwiftUI
import SwiftData

struct EmployeeDirectoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Employee.name) private var employees: [Employee]
    
    @State private var searchText = ""
    @State private var showingAddEmployeeSheet = false
    @State private var selectedEmployeeForEdit: Employee? = nil
    
    var filteredEmployees: [Employee] {
        if searchText.isEmpty { return employees }
        return employees.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.role.localizedCaseInsensitiveContains(searchText) ||
            $0.department.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if employees.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Personnel Records")
                            .font(.headline)
                        
                        Text("Add staff members to assign asset custody and track compliance responsibilities.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button {
                            showingAddEmployeeSheet = true
                        } label: {
                            Label("Add First Employee", systemImage: "person.badge.plus")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredEmployees) { employee in
                            Button {
                                selectedEmployeeForEdit = employee
                            } label: {
                                employeeRow(employee)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteEmployees)
                    }
                    #if os(iOS)
                    .listStyle(.insetGrouped)
                    #elseif os(macOS)
                    .listStyle(.sidebar)
                    #else
                    .listStyle(.automatic)
                    #endif
                    .searchable(text: $searchText, prompt: "Search by name, role, department...")
                }
            }
            .navigationTitle("Employee Directory")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddEmployeeSheet = true
                    } label: {
                        Label("Add Personnel", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEmployeeSheet) {
                AddEmployeeSheet()
            }
            .sheet(item: $selectedEmployeeForEdit) { emp in
                EditEmployeeSheet(employee: emp)
            }
        }
    }
    
    @ViewBuilder
    private func employeeRow(_ employee: Employee) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text(employeeInitials(employee.name))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(employee.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Text(employee.role)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(employee.department)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
    
    private func deleteEmployees(at offsets: IndexSet) {
        for index in offsets {
            let employee = filteredEmployees[index]
            modelContext.delete(employee)
        }
        try? modelContext.save()
    }
    
    private func employeeInitials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Add Employee Sheet
struct AddEmployeeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String = ""
    @State private var role: String = ""
    @State private var department: String = "Engineering"
    
    let departments = [
        "Engineering", "Information Security", "DevOps / SRE",
        "IT & Operations", "Product & Design", "Finance", "Legal & Compliance", "HR"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Identity & Role") {
                    TextField("Full Name", text: $name)
                    TextField("Job Title", text: $role)
                }
                
                Section("Department") {
                    Picker("Department", selection: $department) {
                        ForEach(departments, id: \.self) { dept in
                            Text(dept).tag(dept)
                        }
                    }
                }
            }
            .navigationTitle("New Personnel")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newEmployee = Employee(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            role: role.trimmingCharacters(in: .whitespacesAndNewlines),
                            department: department
                        )
                        modelContext.insert(newEmployee)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Employee Sheet
struct EditEmployeeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var employee: Employee
    
    let departments = [
        "Engineering", "Information Security", "DevOps / SRE",
        "IT & Operations", "Product & Design", "Finance", "Legal & Compliance", "HR"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Identity & Role") {
                    TextField("Full Name", text: $employee.name)
                    TextField("Job Title", text: $employee.role)
                }
                
                Section("Department") {
                    Picker("Department", selection: $employee.department) {
                        ForEach(departments, id: \.self) { dept in
                            Text(dept).tag(dept)
                        }
                    }
                }
            }
            .navigationTitle("Personnel Record")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

