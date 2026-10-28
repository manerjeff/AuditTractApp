//
//  RSSFeedService.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/28/26.
//


//
//  RSSFeedService.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/28/26.
//

import Foundation
import SwiftData

final class RSSFeedService: NSObject, @unchecked Sendable {
    static let shared = RSSFeedService()
    private override init() {}
    
    // Official public cybersecurity threat feeds
    private let feedSources: [(name: String, framework: String, url: String)] = [
        ("CISA Alerts", "NIST", "https://www.cisa.gov/cybersecurity-advisories/all.xml"),
        ("NIST NVD Updates", "NIST", "https://nvd.nist.gov/feeds/xml/cve/misc/nvd-rss.xml")
    ]
    
    @MainActor
    func fetchLatestThreatNews(context: ModelContext) async {
        for source in feedSources {
            guard let url = URL(string: source.url) else { continue }
            
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 10.0
                request.setValue("AuditTract-ComplianceEngine/1.0", forHTTPHeaderField: "User-Agent")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { continue }
                
                let parser = ThreatXMLParser(data: data, sourceName: source.name, frameworkKey: source.framework)
                let parsedArticles = parser.parse()
                
                for item in parsedArticles {
                    upsertArticle(item, context: context)
                }
            } catch {
                print("⚠️ [RSSFeedService] Failed fetching \(source.name): \(error.localizedDescription)")
            }
        }
        
        try? context.save()
    }
    
    @MainActor
    private func upsertArticle(_ article: ParsedArticle, context: ModelContext) {
        let title = article.title
        let descriptor = FetchDescriptor<SecurityNewsArticle>(
            predicate: #Predicate { item in
                item.title == title
            }
        )
        
        // If an article with the exact title already exists, update summary and url if changed
        if let existing = try? context.fetch(descriptor).first {
            existing.summary = article.summary
            existing.articleURL = article.link
        } else {
            let newArticle = SecurityNewsArticle(
                title: article.title,
                summary: article.summary,
                sourceName: article.sourceName,
                articleURL: article.link,
                publishedDate: article.publishedDate,
                isBookmarked: false,
                taggedFrameworkKey: article.frameworkKey
            )
            context.insert(newArticle)
        }
    }
}

// MARK: - Internal Parsed Data Structure
fileprivate struct ParsedArticle {
    var title: String
    var summary: String
    var link: String
    var publishedDate: Date
    var sourceName: String
    var frameworkKey: String
}

// MARK: - Native Foundation XML Parser
fileprivate final class ThreatXMLParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private let sourceName: String
    private let frameworkKey: String
    
    private var articles: [ParsedArticle] = []
    private var currentElement: String = ""
    private var currentTitle: String = ""
    private var currentLink: String = ""
    private var currentDescription: String = ""
    private var currentPubDateString: String = ""
    private var isInItem: Bool = false
    
    init(data: Data, sourceName: String, frameworkKey: String) {
        self.parser = XMLParser(data: data)
        self.sourceName = sourceName
        self.frameworkKey = frameworkKey
        super.init()
        self.parser.delegate = self
    }
    
    func parse() -> [ParsedArticle] {
        parser.parse()
        return articles
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName.lowercased()
        if currentElement == "item" || currentElement == "entry" {
            isInItem = true
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDateString = ""
        }
        
        // Handle Atom feed <link href="..."> attributes
        if isInItem && (currentElement == "link"), let href = attributeDict["href"] {
            currentLink = href
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInItem else { return }
        switch currentElement {
        case "title":
            currentTitle += string
        case "link":
            if currentLink.isEmpty { currentLink += string }
        case "description", "summary", "content":
            currentDescription += string
        case "pubdate", "published", "updated", "dc:date":
            currentPubDateString += string
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let tag = elementName.lowercased()
        if tag == "item" || tag == "entry" {
            isInItem = false
            
            let cleanTitle = cleanHTML(currentTitle).trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanDesc = cleanHTML(currentDescription).trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanLink = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !cleanTitle.isEmpty else { return }
            
            let date = parseDate(currentPubDateString)
            let article = ParsedArticle(
                title: cleanTitle,
                summary: cleanDesc.isEmpty ? "No extended advisory description provided." : cleanDesc,
                link: cleanLink,
                publishedDate: date,
                sourceName: sourceName,
                frameworkKey: frameworkKey
            )
            articles.append(article)
        }
    }
    
    // Remove inline HTML tags from RSS summaries
    private func cleanHTML(_ raw: String) -> String {
        return raw.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "\n", with: " ")
    }
    
    private func parseDate(_ dateStr: String) -> Date {
        let cleaned = dateStr.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatters: [DateFormatter] = {
            let rfc822 = DateFormatter()
            rfc822.locale = Locale(identifier: "en_US_POSIX")
            rfc822.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            
            let iso8601 = DateFormatter()
            iso8601.locale = Locale(identifier: "en_US_POSIX")
            iso8601.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            
            let simple = DateFormatter()
            simple.locale = Locale(identifier: "en_US_POSIX")
            simple.dateFormat = "yyyy-MM-dd"
            return [rfc822, iso8601, simple]
        }()
        
        for fmt in formatters {
            if let d = fmt.date(from: cleaned) {
                return d
            }
        }
        return Date()
    }
}
