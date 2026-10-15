//
//  SecurityNewsView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI
import SwiftData

struct SecurityNewsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SecurityNewsArticle.publishedDate, order: .reverse) private var articles: [SecurityNewsArticle]
    
    var body: some View {
        NavigationStack {
            List(articles) { article in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(article.sourceName.uppercased())
                            .font(.caption2)
                            .fontWeight(.black)
                            .foregroundColor(.accentColor)
                        Spacer()
                        Text(article.publishedDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(article.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(article.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .padding(.vertical, 6)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Threat Intelligence & News")
            .onAppear {
                seedInitialNewsIfEmpty()
            }
        }
    }
    
    private func seedInitialNewsIfEmpty() {
        guard articles.isEmpty else { return }
        
        let a1 = SecurityNewsArticle(
            title: "NIST Releases Updated Cybersecurity Framework Guidance",
            summary: "NIST announces expanded implementation guidance for SP 800-53 Rev 5 supply chain controls.",
            sourceName: "NVD Feed",
            articleURL: "https://nvd.nist.gov",
            taggedFrameworkKey: "NIST"
        )
        let a2 = SecurityNewsArticle(
            title: "CISA Warns of Active Exploitation in Cloud Edge Routers",
            summary: "Federal agency issues emergency directive urging critical infrastructure operators to patch edge appliances.",
            sourceName: "CISA Alerts",
            articleURL: "https://cisa.gov"
        )
        modelContext.insert(a1)
        modelContext.insert(a2)
        try? modelContext.save()
    }
}
