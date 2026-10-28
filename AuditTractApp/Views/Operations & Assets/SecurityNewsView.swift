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
    
    @State private var isRefreshing: Bool = false
    @State private var searchText: String = ""
    @State private var selectedFilter: String = "All"
    @State private var selectedArticleURL: URL? = nil
    
    var filteredArticles: [SecurityNewsArticle] {
        articles.filter { article in
            let matchesSearch = searchText.isEmpty ||
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.summary.localizedCaseInsensitiveContains(searchText) ||
                article.sourceName.localizedCaseInsensitiveContains(searchText)
            
            switch selectedFilter {
            case "Bookmarked":
                return matchesSearch && article.isBookmarked
            case "CISA":
                return matchesSearch && article.sourceName.contains("CISA")
            case "NIST":
                return matchesSearch && article.sourceName.contains("NIST")
            default:
                return matchesSearch
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter bar
                HStack {
                    Picker("Feed Filter", selection: $selectedFilter) {
                        Text("All Feeds").tag("All")
                        Text("CISA Alerts").tag("CISA")
                        Text("NIST NVD").tag("NIST")
                        Text("Bookmarked").tag("Bookmarked")
                    }
                    .pickerStyle(.segmented)
                    
                    if isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.leading, 6)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.12))
                
                Divider()
                
                // Content List
                if filteredArticles.isEmpty {
                    ContentUnavailableView {
                        Label("No Threat Intelligence", systemImage: "antenna.radiowaves.left.and.right")
                    } description: {
                        Text(isRefreshing ? "Fetching latest threat feeds..." : "No articles found matching your filter. Tap 'Refresh' to check for updates.")
                    } actions: {
                        Button("Refresh Feeds") {
                            triggerFeedRefresh()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isRefreshing)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredArticles) { article in
                            articleRow(article)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await RSSFeedService.shared.fetchLatestThreatNews(context: modelContext)
                    }
                }
            }
            .background(Color.primary.opacity(0.03))
            .navigationTitle("Threat Intelligence & News")
            .searchable(text: $searchText, prompt: "Search CVE advisories, CISA alerts...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        triggerFeedRefresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(isRefreshing)
                }
            }
            .sheet(item: $selectedArticleURL) { item in
                SafariViewWrapper(url: item)
            }
            .onAppear {
                if articles.isEmpty {
                    triggerFeedRefresh()
                }
            }
        }
    }
    
    @ViewBuilder
    private func articleRow(_ article: SecurityNewsArticle) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(article.sourceName.uppercased())
                    .font(.caption2)
                    .fontWeight(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(sourceColor(article.sourceName).opacity(0.15))
                    .foregroundColor(sourceColor(article.sourceName))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Spacer()
                
                Text(article.publishedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Button {
                    article.isBookmarked.toggle()
                    try? modelContext.save()
                } label: {
                    Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.caption)
                        .foregroundColor(article.isBookmarked ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text(article.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Text(article.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .lineSpacing(2)
            
            if let url = URL(string: article.articleURL), !article.articleURL.isEmpty {
                Button {
                    selectedArticleURL = url
                } label: {
                    HStack(spacing: 4) {
                        Text("Read Official Advisory")
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }
    
    private func triggerFeedRefresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        Task { @MainActor in
            await RSSFeedService.shared.fetchLatestThreatNews(context: modelContext)
            isRefreshing = false
        }
    }
    
    private func sourceColor(_ source: String) -> Color {
        if source.contains("CISA") {
            return .red
        } else if source.contains("NIST") {
            return .blue
        }
        return .accentColor
    }
}

// MARK: - In-App Safari Browser Presentation Wrapper
#if canImport(SafariServices)
import SafariServices

struct SafariViewWrapper: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.dismissButtonStyle = .close
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#else
struct SafariViewWrapper: View {
    let url: URL
    var body: some View {
        Link("Open in Default Browser", destination: url)
            .padding()
    }
}
#endif

// Identifiable conformance on URL for sheet presentation
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
