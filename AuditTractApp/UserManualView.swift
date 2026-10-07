import SwiftUI

struct UserManualView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Title Lockup
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(TractColor.copper)
                                .frame(width: 12, height: 2)
                            
                            Text("ENTERPRISE GRC PLATFORM")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(2.0)
                                .foregroundColor(TractColor.label)
                        }
                        
                        HStack(spacing: 6) {
                            Text("Audit")
                                .font(.custom("NewYork-Medium", size: 30, relativeTo: .title))
                                .foregroundColor(TractColor.ink)
                            Text("Tract")
                                .font(.system(size: 30, weight: .light))
                                .foregroundColor(TractColor.ink)
                        }
                        
                        Text("USER OPERATIONS MANUAL • RELEASE 5.0")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(TractColor.copper)
                    }
                    
                    Divider().background(TractColor.stroke)
                    
                    // 1. Introduction
                    ManualSectionCard(
                        number: "01",
                        title: "INTRODUCTION & CORE CAPABILITIES",
                        icon: "shield.checkerboard",
                        content: """
                        Audit Tract is an enterprise GRC audit management platform engineered natively for iPadOS. Managing 992 controls across 8 major standards, Audit Tract provides real-time composite readiness scoring, sandbox evidence vaulting, multi-workspace switching, and live RSS threat intelligence.
                        """
                    )
                    
                    // 2. Dashboard & Scope Toggling
                    ManualSectionCard(
                        number: "02",
                        title: "FRAMEWORK SURVEY & SCOPE ENGINE",
                        icon: "slider.horizontal.3",
                        content: """
                        • Global Readiness Metric: Calculated dynamically across active frameworks:
                          Score = Compliant / (Scoped Controls - N/A Controls) × 100%
                        
                        • In-Scope / Excluded Toggles: Tap the scope badge on any framework card to toggle it in or out of scope. Excluding a standard instantly drops its controls from your global denominator without deleting saved assessment history.
                        
                        • Search & Category Filters: Use the search bar or quick-select pills (ALL, CYBER, PRIVACY, TRUST, FINSEC, GOV) to filter framework cards.
                        """
                    )
                    
                    // 3. Workspaces
                    ManualSectionCard(
                        number: "03",
                        title: "WORKSPACE CONTEXT MANAGEMENT",
                        icon: "building.2.fill",
                        content: """
                        Tap the corporate name in the header bar to switch between client environments or select 'New Audit Workspace...' to create a fresh audit context (e.g., Q4 2026 SOC 2 Audit).
                        """
                    )
                    
                    // 4. Control Assessments
                    ManualSectionCard(
                        number: "04",
                        title: "WORKING WITH CONTROLS & STATUSES",
                        icon: "list.bullet.clipboard.fill",
                        content: """
                        Launch the Control Center to assign 4-state compliance statuses:
                        • COMPLIANT: Requirement fully met and verified with evidence.
                        • IN PROGRESS: Implementation or documentation underway.
                        • NOT COMPLIANT: Control failing or unaddressed.
                        • NOT APPLICABLE: Excluded from operational scope.
                        
                        Always complete the 6-Point Response methodology: WHAT is implemented, WHO owns it, WHEN it runs, WHERE it resides, HOW it is verified, and EVIDENCE attached.
                        """
                    )
                    
                    // 5. Evidence Vault
                    ManualSectionCard(
                        number: "05",
                        title: "AUDITOR EVIDENCE VAULT",
                        icon: "tray.full.fill",
                        content: """
                        • Screenshots & Photos: Import directly from the iPad photo library.
                        • Documents: Upload PDFs, policy documents, and system exports.
                        • External Links: Attach live URLs (Jira tickets, AWS S3 buckets, Confluence pages).
                        • QuickLook Preview: Tap 'PREVIEW' on any attached file to launch Apple's native document viewer inside the app.
                        """
                    )
                    
                    // 6. Threat Intelligence
                    ManualSectionCard(
                        number: "06",
                        title: "LIVE REGULATORY INTELLIGENCE",
                        icon: "antenna.radiowaves.left.and.right",
                        content: """
                        The dashboard continuously fetches live security advisories and regulatory changes from CISA, NVD, and the Federal Register. Incoming articles are automatically color-coded into 5 categories: Vulnerability (Rose), Regulatory (Sapphire), Privacy (Violet), Compliance (Emerald), and Advisory (Copper).
                        """
                    )
                }
                .padding(24)
            }
            .navigationTitle("User Operations Manual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(TractColor.secondary)
                    }
                }
            }
            .background(TractColor.canvas)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Manual Section Card Subview

struct ManualSectionCard: View {
    let number: String
    let title: String
    let icon: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SECTION \(number)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(TractColor.copper)
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(TractColor.copper)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(TractColor.ink)
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(TractColor.secondary)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TractColor.card)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(TractColor.stroke, lineWidth: 1)
        )
    }
}
