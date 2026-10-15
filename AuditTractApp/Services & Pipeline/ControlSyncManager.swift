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
        
        // 1. Check App Bundle
        if let bundleURL = Bundle.main.url(forResource: "controls", withExtension: "json") ?? Bundle.main.url(forResource: "controls.json", withExtension: nil) {
            print("✅ Found controls.json at URL: \(bundleURL)")
            do {
                let data = try Data(contentsOf: bundleURL)
                let decoder = JSONDecoder()
                
                // Attempt decoding Envelope
                if let envelope = try? decoder.decode(ControlsEnvelope.self, from: data) {
                    self.tasks = envelope.controls
                    print("🎉 SUCCESS: Loaded \(self.tasks.count) controls from ControlsEnvelope!")
                    return
                }
                
                // Attempt decoding Raw Array
                if let rawTasks = try? decoder.decode([AuditTask].self, from: data) {
                    self.tasks = rawTasks
                    print("🎉 SUCCESS: Loaded \(self.tasks.count) controls from raw [AuditTask] array!")
                    return
                }
                
                print("❌ DECODING ERROR: controls.json was found, but JSONDecoder failed to match AuditTask schema.")
            } catch {
                print("❌ READ ERROR: Could not read data from controls.json: \(error)")
            }
        } else {
            print("❌ FILE NOT FOUND: controls.json is missing from Bundle.main.")
        }
    }

    @MainActor
    func checkForUpdates() async {
        guard let url = remoteURL else { 
            print("ControlSyncManager: Remote URL disabled. Using local bundle controls (147 items).")
            return
        }
        
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

