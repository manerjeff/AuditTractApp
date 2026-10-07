import Foundation

struct ReportExporter {
    
    static func generateCSV(workspace: UserWorkspace, tasks: [AuditTask]) -> String {
        var csv = "Task ID,Framework,Control Title,Category,Evaluation Status,Auditor Notes,Evidence Count,Last Updated\n"
        
        // Match workspace control logs against tasks
        for task in tasks {
            // Only export if framework is in scope
            guard workspace.isFrameworkInScope(task.frameworkKey) else { continue }
            
            let log = workspace.controlLogs.first(where: { $0.taskID == task.id })
            let status = log?.status ?? "Not Evaluated"
            let notes = sanitizeForCSV(log?.notes ?? "")
            let evidenceCount = log?.evidenceItems.count ?? 0
            let lastUpdated = log?.lastUpdated.formatted(date: .numeric, time: .shortened) ?? "N/A"
            let title = sanitizeForCSV(task.title)
            let category = sanitizeForCSV(task.category)
            
            let row = "\"\(task.id)\",\"\(task.frameworkKey)\",\"\(title)\",\"\(category)\",\"\(status)\",\"\(notes)\",\(evidenceCount),\"\(lastUpdated)\"\n"
            csv.append(row)
        }
        
        return csv
    }
    
    private static func sanitizeForCSV(_ text: String) -> String {
        var clean = text.replacingOccurrences(of: "\"", with: "\"\"")
        clean = clean.replacingOccurrences(of: "\n", with: " ")
        return clean
    }
}

