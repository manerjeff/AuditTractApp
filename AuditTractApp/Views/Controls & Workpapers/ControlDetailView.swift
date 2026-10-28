//
// ControlDetailView.swift
// AuditTractApp
//
// Created by: Jeff Maner 10/14/2026
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ControlDetailView: View {
    let task: AuditTask
    @Environment(\.modelContext) private var modelContext
    @Query private var evaluations: [ControlEvaluation]
    @Query private var allFindings: [VulnerabilityFinding]
    
    @State private var status: String = "Not Evaluated"
    @State private var auditorNotes: String = ""
    @State private var evidenceLocation: String = ""
    @State private var lastSavedTime: String = ""
    @State private var showSavedToast = false
    @State private var showingFileImporter = false
    @State private var selectedFinding: VulnerabilityFinding? = nil
    
    var currentEvaluation: ControlEvaluation? {
        evaluations.first { $0.controlID == task.id }
    }
    
    // Correlate attack surface findings mapped to this control
    var correlatedFindings: [VulnerabilityFinding] {
        allFindings.filter { finding in
            guard let mapped = finding.mappedControlID else { return false }
            return task.id.localizedCaseInsensitiveContains(mapped) ||
                   mapped.localizedCaseInsensitiveContains(task.id) ||
                   task.id.components(separatedBy: "-").contains(where: { $0.caseInsensitiveCompare(mapped) == .orderedSame })
        }
    }
    
    var openFindingsCount: Int {
        correlatedFindings.filter { !$0.isRemediated }.count
    }
    
    var dynamicEvidenceRequirements: [String] {
        if let explicitObjects = task.examinationObjects, !explicitObjects.isEmpty {
            return explicitObjects
        }
        if let statement = task.controlStatement, !statement.isEmpty {
            let parsed = statement.components(separatedBy: CharacterSet(charactersIn: ";\n"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count > 5 }
            if !parsed.isEmpty {
                return parsed
            }
        }
        return [
            "Written Policy & Governance Documentation",
            "System Administrative Logs & Configuration Export",
            "Technical Verification / Screenshot Artifact"
        ]
    }
    
    var body: some View {
        Form {
            // MARK: - 1. Control Summary
            Section("Control Summary") {
                HStack {
                    Text("Control ID")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(task.id)
                        .fontWeight(.bold)
                }
                HStack {
                    Text("Category")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(task.category)
                        .fontWeight(.semibold)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(task.title)
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            
            // MARK: - 2. Attack Surface Correlated Flaws & CVEs
            if !correlatedFindings.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("\(correlatedFindings.count) Attack Surface Finding(s)", systemImage: "shield.lefthalf.filled")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(openFindingsCount > 0 ? .red : .green)
                            
                            Spacer()
                            
                            if openFindingsCount > 0 {
                                Text("\(openFindingsCount) Open")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.red.opacity(0.15))
                                    .foregroundColor(.red)
                                    .clipShape(Capsule())
                            } else {
                                Text("All Remediated")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Divider()
                        
                        ForEach(correlatedFindings) { finding in
                            Button {
                                selectedFinding = finding
                            } label: {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(finding.cveIdentifier)
                                                .font(.caption)
                                                .fontWeight(.black)
                                            
                                            Text("CVSS \(String(format: "%.1f", finding.cvssScore))")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(finding.cvssScore >= 7.0 ? .red : .orange)
                                        }
                                        
                                        Text(finding.title)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        
                                        Text("Host: \(finding.affectedIP)\(finding.targetAsset != nil ? " • " + finding.targetAsset!.name : "")")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: finding.isRemediated ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(finding.isRemediated ? .green : .red)
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 2)
                        }
                        
                        Divider()
                        
                        Button {
                            attachFindingsToEvidence()
                        } label: {
                            Label("Attach Findings Summary to Evidence Manifest", systemImage: "doc.badge.plus")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Automated Attack Surface Correlation")
                } footer: {
                    Text("AuditTract automatically correlates scan findings from registered assets and ad-hoc IP/URL audits to this control requirement.")
                }
            }
            
            // MARK: - 3. Control Requirement
            if let statement = task.controlStatement, !statement.isEmpty {
                Section("Control Requirement") {
                    Text(statement)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                }
            } else if let blurb = task.blurb, !blurb.isEmpty {
                Section("Control Description") {
                    Text(blurb)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                }
            }
            
            // MARK: - 4. Discussion & Guidance
            if let discussion = task.discussion, !discussion.isEmpty {
                Section("Supplemental Guidance & Discussion") {
                    Text(discussion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
            }
            
            // MARK: - 5. REQUIRED EVIDENCE CHECKLIST
            Section("Required Evidence Checklist") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Curate and verify the following artifacts prior to final auditor submission:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(dynamicEvidenceRequirements, id: \.self) { requirement in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "doc.badge.arrow.up")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.top, 2)
                            Text(requirement)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineSpacing(3)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // MARK: - 6. RELATED CONTROLS
            if let related = task.relatedControls, !related.isEmpty {
                Section("Related Controls") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(related, id: \.self) { item in
                                Text(item)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.primary.opacity(0.08))
                                    .foregroundColor(.secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
            // MARK: - 7. COMPLIANCE STATUS
            Section("Compliance Status") {
                Picker("Status", selection: $status) {
                    Text("Not Evaluated").tag("Not Evaluated")
                    Text("In Progress").tag("In Progress")
                    Text("Evidence Collected").tag("Evidence Collected")
                    Text("Compliant").tag("Compliant")
                    Text("Non-Compliant").tag("Non-Compliant")
                    Text("Not Applicable").tag("Not Applicable")
                }
                .pickerStyle(.menu)
                .onChange(of: status) { _, _ in autoSave() }
                
                if openFindingsCount > 0 && (status == "Compliant" || status == "Evidence Collected") {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Note: This control has \(openFindingsCount) unremediated flaw(s) on the attack surface.")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // MARK: - 8. EVIDENCE MANIFEST & FILE REFERENCES
            Section(
                header: Text("Evidence Manifest & File References"),
                footer: Text("Enter file names, local path references, or tap the folder icon to attach a file from your device.")
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button(action: { showingFileImporter = true }) {
                            Image(systemName: "folder.badge.gearshape")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.borderless)
                        
                        Text("Evidence File / Location Reference")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        TextField("e.g. /AuditVault/2026/AC-02/User_Access_Review_Q3.pdf", text: $evidenceLocation)
                            .textFieldStyle(.roundedBorder)
                            .font(.subheadline)
                            .onChange(of: evidenceLocation) { _, _ in autoSave() }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // MARK: - 9. CLIENT WORKING NOTES
            Section(
                header: Text("Client Working Notes"),
                footer: Text("Use this space to log internal team notes, ongoing gap analysis, or pending questions for system owners.")
            ) {
                TextEditor(text: $auditorNotes)
                    .frame(minHeight: 110)
                    .onChange(of: auditorNotes) { _, _ in autoSave() }
            }
            
            // MARK: - 10. AUTO-SAVE ACTION & TIMESTAMP BAR
            Section {
                Button(action: { autoSave(explicitTrigger: true) }) {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save & Update Progress")
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
                if !lastSavedTime.isEmpty {
                    HStack {
                        Spacer()
                        Text("Auto-saved at \(lastSavedTime)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(task.id)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(item: $selectedFinding) { finding in
            FindingDetailSheet(finding: finding)
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                if let selectedURL = urls.first {
                    self.evidenceLocation = selectedURL.lastPathComponent
                    autoSave()
                }
            case .failure(let error):
                print("❌ File selection error: \(error.localizedDescription)")
            }
        }
        .onAppear {
            if let existing = currentEvaluation {
                self.status = existing.status
                self.auditorNotes = existing.auditorNotes
                self.evidenceLocation = existing.evidenceLocation
                
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                self.lastSavedTime = formatter.string(from: existing.lastUpdated)
            }
        }
        .overlay(alignment: .bottom) {
            if showSavedToast {
                Text("Progress Saved")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private func attachFindingsToEvidence() {
        let summaryPointers = correlatedFindings.map { f in
            "[\(f.cveIdentifier)] \(f.affectedIP) - \(f.isRemediated ? "REMEDIATED" : "OPEN")"
        }.joined(separator: "; ")
        
        if self.evidenceLocation.isEmpty {
            self.evidenceLocation = "AttackSurfaceScan: \(summaryPointers)"
        } else if !self.evidenceLocation.contains("AttackSurfaceScan") {
            self.evidenceLocation += " | AttackSurfaceScan: \(summaryPointers)"
        }
        
        let noteEntry = "\n[Automated Scan Correlated on \(Date().formatted(date: .abbreviated, time: .shortened))]: Attached \(correlatedFindings.count) finding(s) (\(openFindingsCount) open)."
        if !self.auditorNotes.contains(noteEntry.trimmingCharacters(in: .whitespacesAndNewlines)) {
            self.auditorNotes += noteEntry
        }
        
        autoSave(explicitTrigger: true)
    }
    
    private func autoSave(explicitTrigger: Bool = false) {
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        self.lastSavedTime = formatter.string(from: now)
        
        if let existing = currentEvaluation {
            existing.status = status
            existing.auditorNotes = auditorNotes
            existing.evidenceLocation = evidenceLocation
            existing.lastUpdated = now
        } else {
            let newEval = ControlEvaluation(
                id: UUID().uuidString,
                controlID: task.id,
                frameworkKey: task.frameworkKey.isEmpty ? "NIST_800_53" : task.frameworkKey,
                status: status,
                auditorNotes: auditorNotes,
                evidenceLocation: evidenceLocation,
                lastUpdated: now
            )
            modelContext.insert(newEval)
        }
        
        try? modelContext.save()
        
        if explicitTrigger {
            withAnimation { showSavedToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showSavedToast = false }
            }
        }
    }
}

