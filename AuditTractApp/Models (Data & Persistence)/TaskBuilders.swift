//
//  TaskBuilders.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import Foundation
import Combine

// MARK: - Audit Estimator Engine
class AuditEstimator: ObservableObject {
    @Published var totalHours: Int = 0
    
    init() {}
    
    static func estimateHours(for tasks: [AuditTask]) -> Int {
        return tasks.count * 2
    }
    
    static func calculateProgress(evaluations: [ControlEvaluation], totalTasks: Int) -> Double {
        guard totalTasks > 0 else { return 0.0 }
        let completed = evaluations.filter { $0.status != "Not Evaluated" }.count
        return Double(completed) / Double(totalTasks)
    }
}

// MARK: - Extension for Fallback Tasks Ingestion
extension AuditEstimator {
    func buildAllFallbackTasks() -> [AuditTask] {
        var tasks: [AuditTask] = []
        
        // 1. SOC 2 Controls
        let soc2Categories = [
            ("CC1", "Control Environment", 5),
            ("CC2", "Communication & Information", 3),
            ("CC3", "Risk Assessment", 4)
        ]
        
        for (catCode, catName, count) in soc2Categories {
            for i in 1...count {
                let id = "SOC2-\(catCode)-\(String(format: "%02d", i))"
                let title = "\(catName) - Evaluation Focus Point \(i)"
                tasks.append(
                    AuditTask(
                        id: id,
                        frameworkKey: "SOC2",
                        title: title,
                        category: catCode,
                        blurb: "Verify compliance with SOC 2 Trust Services Criteria for \(catName).",
                        discussion: "Ensure operational controls are documented and routinely tested by internal audit teams.",
                        controlStatement: "The organization maintains controls to fulfill the \(catName) criteria.",
                        controlActivities: "Review evidence logs and policy documents.",
                        examinationObjects: ["Policy Manual", "Audit Log"],
                        interviewRoles: ["CISO", "Compliance Lead"],
                        relatedControls: ["NIST-AC-01", "ISO-27001-A.5"]
                    )
                )
            }
        }
        
        // 2. NIST SP 800-53 Fallbacks
        let nistControls = [
            ("NIST-AC-01", "AC", "Access Control Policy and Procedures", "Develop, document, and disseminate access control policies and procedures."),
            ("NIST-AC-02", "AC", "Account Management", "Manage information system accounts including creation, activation, modification, and disabling."),
            ("NIST-AU-02", "AU", "Event Logging", "Identify and log audit events sufficient to establish what events occurred and who initiated them."),
            ("NIST-IA-02", "IA", "Identification and Authentication", "Uniquely identify and authenticate organizational users and processes.")
        ]
        
        for (id, cat, title, blurb) in nistControls {
            tasks.append(
                AuditTask(
                    id: id,
                    frameworkKey: "NIST",
                    title: title,
                    category: cat,
                    blurb: blurb,
                    discussion: "Refer to NIST SP 800-53 Rev 5 supplemental guidance for implementation details.",
                    controlStatement: "The system implements mechanisms to support \(title.lowercased()).",
                    controlActivities: "Inspect active configuration settings and access lists.",
                    examinationObjects: ["System Config", "Account Registry"],
                    interviewRoles: ["System Administrator", "Security Officer"],
                    relatedControls: ["SOC2-CC1-01"]
                )
            )
        }
        
        return tasks
    }
}
