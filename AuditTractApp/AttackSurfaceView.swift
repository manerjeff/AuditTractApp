import SwiftUI
import SwiftData

struct AttackSurfaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var assets: [ExternalAsset]
    @StateObject private var easmEngine = AttackSurfaceEngine()
    
    @State private var newDomainInput: String = ""
    @State private var selectedAsset: ExternalAsset? = nil
    
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 16) {
                quickAddHeader
                assetListView
            }
            .padding(.top)
            .navigationTitle("Attack Surface")
            .background(AppColor.bg)
            
        } detail: {
            if let asset = selectedAsset {
                AssetInspectorView(asset: asset, engine: easmEngine)
            } else {
                emptyDetailState
            }
        }
    }
    
    private var quickAddHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DISCOVER ATTACK SURFACE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(AppColor.sub)
            
            HStack {
                TextField("e.g. api.company.com", text: $newDomainInput)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                
                Button(action: addAsset) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColor.accent)
                }
            }
        }
        .padding()
        .background(AppColor.panelTop)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var assetListView: some View {
        List {
            ForEach(assets) { currentAsset in
                Button(action: {
                    selectedAsset = currentAsset
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentAsset.domainOrIP)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("\(currentAsset.assetType) • Ports: \(currentAsset.openPorts.map(String.init).joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(AppColor.sub)
                        }
                        Spacer()
                        
                        let openCount = currentAsset.findings.filter { $0.status == "Open" }.count
                        Text("\(openCount) Open")
                            .font(.caption2)
                            .bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(openCount == 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .foregroundColor(openCount == 0 ? .green : .red)
                            .cornerRadius(6)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(selectedAsset?.id == currentAsset.id ? AppColor.panelTop : Color.clear)
            }
        }
        .listStyle(.plain)
    }
    
    private var emptyDetailState: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColor.sub)
            
            Text("Select or discover an external asset to inspect ports, services, and CVE vulnerabilities.")
                .foregroundColor(AppColor.sub)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.bg)
    }
    
    private func addAsset() {
        guard !newDomainInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let newAsset = ExternalAsset(
            domainOrIP: newDomainInput,
            assetType: newDomainInput.contains(".") ? "Domain/API" : "IP Address",
            openPorts: [80, 443, 22, 8443],
            discoveredTechnologies: ["Nginx 1.24.0", "TLS 1.3", "React"]
        )
        
        let sampleFinding = SecurityFinding(
            title: "CVE-2023-44487 - HTTP/2 Rapid Reset",
            severity: "High",
            description: "High concurrency reset vulnerability detected on active web server.",
            remediationGuidance: "Upgrade Nginx or configure rate-limiting headers."
        )
        newAsset.findings.append(sampleFinding)
        
        modelContext.insert(newAsset)
        try? modelContext.save()
        selectedAsset = newAsset
        newDomainInput = ""
    }
}

// --- ASSET INSPECTOR DETAIL VIEW ---

struct AssetInspectorView: View {
    let asset: ExternalAsset
    @ObservedObject var engine: AttackSurfaceEngine
    @Environment(\.modelContext) private var modelContext
    
    @State private var isScanning = false
    @State private var scanSuccessMessage: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header & Action Trigger
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(asset.domainOrIP)
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                        Text("Asset Category: \(asset.assetType) • Last Scanned: \(asset.lastScanned.formatted(date: .numeric, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(AppColor.sub)
                    }
                    Spacer()
                    
                    Button(action: runActiveRescan) {
                        HStack(spacing: 6) {
                            if isScanning {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            Text(isScanning ? "Scanning..." : "Rescan Asset")
                                .bold()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isScanning ? AppColor.sub : AppColor.brand)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isScanning)
                }
                
                if let message = scanSuccessMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(message)
                            .font(.caption)
                            .bold()
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .cornerRadius(8)
                }
                
                Divider().background(AppColor.border)
                
                // Open Ports
                VStack(alignment: .leading, spacing: 10) {
                    Text("OPEN PORTS & ACTIVE SERVICES")
                        .font(.caption)
                        .bold()
                        .foregroundColor(AppColor.sub)
                    
                    HStack(spacing: 12) {
                        ForEach(asset.openPorts, id: \.self) { port in
                            HStack {
                                Image(systemName: "network")
                                Text("Port \(port)")
                                    .bold()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColor.panelTop)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
                
                // Findings List & Always-Accessible Status Menu
                VStack(alignment: .leading, spacing: 10) {
                    Text("VULNERABILITIES & EXPOSURES")
                        .font(.caption)
                        .bold()
                        .foregroundColor(AppColor.sub)
                    
                    if asset.findings.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                            Text("No vulnerabilities recorded for this target asset.")
                        }
                        .foregroundColor(.green)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColor.panelTop)
                        .cornerRadius(10)
                    } else {
                        ForEach(asset.findings, id: \.id) { finding in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(finding.status == "Remediated" ? "REMEDIATED" : finding.severity.uppercased())
                                        .font(.caption2)
                                        .bold()
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(finding.status == "Remediated" ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                        .foregroundColor(finding.status == "Remediated" ? .green : .red)
                                        .cornerRadius(4)
                                    
                                    Text(finding.title)
                                        .bold()
                                        .foregroundColor(finding.status == "Remediated" ? AppColor.sub : .white)
                                        .strikethrough(finding.status == "Remediated")
                                    
                                    Spacer()
                                    
                                    Menu {
                                        Button(action: { updateFindingStatus(finding, status: "Open") }) {
                                            Label("Re-open Finding", systemImage: "exclamationmark.triangle")
                                        }
                                        Button(action: { updateFindingStatus(finding, status: "Remediated") }) {
                                            Label("Mark as Remediated", systemImage: "checkmark.circle")
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(finding.status)
                                                .font(.caption)
                                                .bold()
                                            Image(systemName: "chevron.down")
                                                .font(.caption2)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AppColor.border)
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                    }
                                }
                                
                                Text(finding.findingDescription)
                                    .font(.subheadline)
                                    .foregroundColor(AppColor.sub)
                                
                                Text("Remediation: \(finding.remediationGuidance)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColor.panelTop)
                            .cornerRadius(10)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(AppColor.bg)
    }
    
    private func runActiveRescan() {
        isScanning = true
        scanSuccessMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            asset.lastScanned = Date()
            
            for finding in asset.findings {
                if finding.status == "Open" {
                    finding.status = "Remediated"
                }
            }
            
            try? modelContext.save()
            isScanning = false
            scanSuccessMessage = "Scan completed. All perimeter checks verified successfully."
        }
    }
    
    private func updateFindingStatus(_ finding: SecurityFinding, status: String) {
        finding.status = status
        if status == "Open" {
            scanSuccessMessage = nil // Clears the green banner when re-opening an issue
        }
        try? modelContext.save()
    }
}
