final class ControlSyncManager: ObservableObject {
    static let shared = ControlSyncManager()
    
    @Published var tasks: [AuditTask] = []
    @Published var activeVersion: String = "1.0.0"
    
    private let cachedFileName = "cached_controls.json"
    
    init() {
        loadActiveControls()
    }
    
    func loadActiveControls() {
        // 1. Try loading cached cloud payload from Documents
        if let cachedData = readFromDocuments() {
            if decodeAndApply(data: cachedData) { return }
        }
        
        // 2. Try loading bundled controls.json inside App Bundle
        if let bundleURL = Bundle.main.url(forResource: "controls", withExtension: "json") ?? Bundle.main.url(forResource: "controls.json", withExtension: nil),
           let bundleData = try? Data(contentsOf: bundleURL) {
            if decodeAndApply(data: bundleData) { return }
        }
        
        print("ControlSyncManager: No local controls file found yet.")
    }
    
    @discardableResult
    private func decodeAndApply(data: Data) -> Bool {
        let decoder = JSONDecoder()
        
        // Case A: Wrapped Envelope Structure
        if let envelope = try? decoder.decode(ControlsEnvelope.self, from: data), !envelope.controls.isEmpty {
            self.tasks = envelope.controls
            self.activeVersion = envelope.version
            print("Successfully loaded \(envelope.controls.count) controls (v\(envelope.version))")
            return true
        }
        
        // Case B: Raw Array Structure
        if let rawTasks = try? decoder.decode([AuditTask].self, from: data), !rawTasks.isEmpty {
            self.tasks = rawTasks
            print("Successfully loaded \(rawTasks.count) controls from raw JSON array")
            return true
        }
        
        return false
    }
    
    // Cloud sync check...
    @MainActor
    func checkForUpdates() async {
        // Optional remote URL check...
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func readFromDocuments() -> Data? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(cachedFileName)
        return try? Data(contentsOf: fileURL)
    }
}
