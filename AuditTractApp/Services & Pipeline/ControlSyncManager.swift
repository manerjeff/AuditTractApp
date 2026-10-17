//
//  ControlSyncManager.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import Foundation
import Combine

// MARK: - Control Sync Manager
final class ControlSyncManager: ObservableObject {
    static let shared = ControlSyncManager()
    
    @Published var tasks: [AuditTask] = []
    @Published var activeVersion: String = "1.0.0"
    @Published var isSyncing: Bool = false
    
    private let remoteURL: URL? = nil
    private let cachedFileName = "cached_controls.json"
    
    init() {
        loadActiveControls()
    }
    
    func loadActiveControls() {
        print("🔍 ControlSyncManager: Attempting to load controls...")
        var loadedTasks: [AuditTask] = []
        
        // 1. Read controls from Bundle if available
        if let bundleURL = Bundle.main.url(forResource: "controls", withExtension: "json") ?? Bundle.main.url(forResource: "controls.json", withExtension: nil) {
            if let data = try? Data(contentsOf: bundleURL) {
                let decoder = JSONDecoder()
                if let envelope = try? decoder.decode(ControlsEnvelope.self, from: data) {
                    loadedTasks = envelope.controls
                } else if let rawTasks = try? decoder.decode([AuditTask].self, from: data) {
                    loadedTasks = rawTasks
                }
            }
        }
        
        // 2. Read local fallback tasks (SOC2, NIST, ISO 27001) from TaskBuilders
        let fallbacks = AuditEstimator().buildAllFallbackTasks()
        
        // 3. Merge both lists without duplicates
        var combined = loadedTasks
        for fallback in fallbacks {
            if !combined.contains(where: { $0.id == fallback.id }) {
                combined.append(fallback)
            }
        }
        
        self.tasks = combined
        print("🎉 SUCCESS: Total controls active in memory: \(self.tasks.count)")
    }

    @MainActor
    func checkForUpdates() async {
        guard let url = remoteURL else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            
            if let remoteEnvelope = try? JSONDecoder().decode(ControlsEnvelope.self, from: data) {
                if remoteEnvelope.version != activeVersion {
                    saveToDocuments(data: data)
                    self.tasks = remoteEnvelope.controls
                    self.activeVersion = remoteEnvelope.version
                }
            }
        } catch {
            print("Sync skipped: \(error.localizedDescription)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func saveToDocuments(data: Data) {
        let fileURL = getDocumentsDirectory().appendingPathComponent(cachedFileName)
        try? data.write(to: fileURL)
    }
    
    private func readFromDocuments() -> Data? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(cachedFileName)
        return try? Data(contentsOf: fileURL)
    }
}

