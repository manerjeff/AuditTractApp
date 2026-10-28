//
//  PaywallView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storeManager = StoreKitManager.shared
    @State private var selectedProductID: String = StoreKitManager.annualSubscriptionID
    
    var body: some View {
        ZStack {
            TractColor.canvas.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Dismiss Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(TractColor.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button("Restore Purchases") {
                        Task {
                            await storeManager.restorePurchases()
                            if storeManager.isSubscribed {
                                dismiss()
                            }
                        }
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(TractColor.copper)
                    .buttonStyle(.plain)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Branding Header
                        VStack(spacing: 8) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 46))
                                .foregroundColor(TractColor.copper)
                            
                            Text("AuditTract Pro")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(TractColor.ink)
                            
                            Text("Professional compliance engineering, complete multi-framework catalogs, and automated audit binder exports.")
                                .font(.subheadline)
                                .foregroundColor(TractColor.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 4)
                        
                        // Feature Comparison Card
                        VStack(alignment: .leading, spacing: 14) {
                            featureRow(icon: "list.bullet.rectangle.portrait.fill", title: "All 16 Compliance Frameworks", subtitle: "Full access to SOC 2, ISO 27001, HIPAA, PCI DSS, FedRAMP, GDPR, and more.")
                            featureRow(icon: "doc.zipper", title: "Full Audit Binder & JSON Exports", subtitle: "Generate comprehensive multi-module CSV and cryptographic JSON packages.")
                            featureRow(icon: "server.rack", title: "Unlimited Asset Scope & Custody", subtitle: "Link unlimited assets with employee custodians and automated scan heuristics.")
                            featureRow(icon: "lock.shield.fill", title: "100% Private & Air-Gapped", subtitle: "All workpapers, artifacts, and scan evaluations remain on-device.")
                        }
                        .padding(18)
                        .background(TractColor.card)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(TractColor.stroke, lineWidth: 1))
                        .padding(.horizontal)
                        
                        // Pricing Product Selectors
                        VStack(spacing: 12) {
                            // Annual Tier
                            planOptionCard(
                                id: StoreKitManager.annualSubscriptionID,
                                title: "Annual Access Plan",
                                badge: "MOST POPULAR",
                                priceDescription: storeManager.products.first(where: { $0.id == StoreKitManager.annualSubscriptionID })?.displayPrice ?? "$79.99/year",
                                subtext: "Includes 7-day free trial • Cancel anytime"
                            )
                            
                            // Lifetime Tier
                            planOptionCard(
                                id: StoreKitManager.lifetimePurchaseID,
                                title: "Lifetime License",
                                badge: "ONE-TIME",
                                priceDescription: storeManager.products.first(where: { $0.id == StoreKitManager.lifetimePurchaseID })?.displayPrice ?? "$199.99",
                                subtext: "Permanent access to all current and future updates"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Action Button
                        VStack(spacing: 10) {
                            Button(action: executePurchase) {
                                HStack {
                                    if storeManager.purchaseInProgress {
                                        ProgressView()
                                            .controlSize(.small)
                                            .tint(.black)
                                    } else {
                                        Text(selectedProductID == StoreKitManager.annualSubscriptionID ? "Start 7-Day Free Trial" : "Unlock Lifetime Access")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                            .fixedSize()
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(TractColor.copper)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            .disabled(storeManager.purchaseInProgress)
                            
                            if let error = storeManager.errorMessage {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Manage or cancel in Apple Account Settings.")
                                .font(.system(size: 9))
                                .foregroundColor(TractColor.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Subviews
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(TractColor.copper)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(TractColor.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(TractColor.secondary)
            }
        }
    }
    
    private func planOptionCard(id: String, title: String, badge: String, priceDescription: String, subtext: String) -> some View {
        let isSelected = selectedProductID == id
        
        return Button(action: { selectedProductID = id }) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(TractColor.ink)
                        
                        if !badge.isEmpty {
                            Text(badge)
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(TractColor.copper.opacity(0.2))
                                .foregroundColor(TractColor.copper)
                                .clipShape(Capsule())
                        }
                    }
                    
                    if !subtext.isEmpty {
                        Text(subtext)
                            .font(.caption2)
                            .foregroundColor(TractColor.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer(minLength: 12)
                
                Text(priceDescription)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(TractColor.ink)
                    .layoutPriority(1)
            }
            .padding(14)
            .background(TractColor.card)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? TractColor.copper : TractColor.stroke, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func executePurchase() {
        guard let product = storeManager.products.first(where: { $0.id == selectedProductID }) else {
            // Fallback for previews/simulators without StoreKit config
            dismiss()
            return
        }
        
        Task {
            let success = await storeManager.purchase(product)
            if success {
                dismiss()
            }
        }
    }
}
