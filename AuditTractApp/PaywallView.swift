import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isSubscribed: Bool
    
    var body: some View {
        ZStack {
            TractColor.canvas.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Top Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(TractColor.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Restore Purchases") {
                        // Restore logic
                    }
                    .font(.caption)
                    .foregroundColor(TractColor.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Crown Branding Header
                        VStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 40))
                                .foregroundColor(TractColor.copper)
                            
                            Text("Audit Tract")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(TractColor.ink)
                            
                            Text("Unlock complete workpaper access, evidence tools, and automated compliance exports.")
                                .font(.subheadline)
                                .foregroundColor(TractColor.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 12)
                        
                        // Feature Highlights Container
                        VStack(alignment: .leading, spacing: 18) {
                            
                            featureRow(
                                icon: "shield.checkered",
                                title: "All 8 Compliance Frameworks",
                                subtitle: "Complete workpapers for SOC 2, ISO 27001, NIST, HIPAA, PCI DSS, SOC 1, FedRAMP, and GDPR."
                            )
                            
                            featureRow(
                                icon: "square.and.arrow.up.fill",
                                title: "Audit-Ready Exports",
                                subtitle: "Generate executive CSV and PDF compliance reports for auditors and clients."
                            )
                            
                            featureRow(
                                icon: "lock.shield.fill",
                                title: "Zero-Knowledge Local Storage",
                                subtitle: "Your compliance and security data never leaves your iPad."
                            )
                        }
                        .padding(20)
                        .background(TractColor.card)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(TractColor.stroke, lineWidth: 1))
                        .padding(.horizontal)
                        
                        // Pricing Plan Box
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Annual Access Plan")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(TractColor.ink)
                                    Text("7-day free trial • Cancel anytime")
                                        .font(.caption)
                                        .foregroundColor(TractColor.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("$49.99/yr")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(TractColor.ink)
                                    Text("Equivalent to $4.16/mo")
                                        .font(.caption2)
                                        .foregroundColor(TractColor.secondary)
                                }
                            }
                            .padding(16)
                            .background(TractColor.card)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(TractColor.copper, lineWidth: 1.5))
                        }
                        .padding(.horizontal)
                        
                        // CTA Action Button
                        Button(action: {
                            isSubscribed = true
                            dismiss()
                        }) {
                            Text("Start Free Trial & Subscribe")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(TractColor.copper)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        Text("Secured with App Store In-App Purchase. Terms & Privacy Apply.")
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundColor(TractColor.secondary)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(TractColor.copper)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(TractColor.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(TractColor.secondary)
            }
        }
    }
}

