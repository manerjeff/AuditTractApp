import SwiftUI
import Combine

// MARK: - Article Model

struct IntelligenceArticle: Identifiable, Codable {
    var id = UUID()
    let title: String
    let summary: String
    let category: String
    let source: String
    let date: String
    let urlString: String
}

// MARK: - Live Feed Manager

@MainActor
class IntelligenceFeedManager: ObservableObject {
    @Published var articles: [IntelligenceArticle] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Live RSS Feed Sources
    private let feedURLs: [(url: String, source: String, category: String)] = [
        ("https://www.cisa.gov/cybersecurity-advisories/all.xml", "CISA", "Advisory"),
        ("https://www.cisa.gov/news-events/cybersecurity-advisories.xml", "CISA KEV", "Vulnerability"),
        ("https://www.federalregister.gov/api/v1/documents.rss?conditions%5Bterm%5D=cybersecurity", "FedRegister", "Regulatory")
    ]
    
    init() {
        loadLiveFeed()
    }
    
    func loadLiveFeed() {
        isLoading = true
        errorMessage = nil
        
        Task {
            var fetchedArticles: [IntelligenceArticle] = []
            
            for feed in feedURLs {
                if let url = URL(string: feed.url) {
                    do {
                        let (data, response) = try await URLSession.shared.data(from: url)
                        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                            let parser = RSSParser(data: data, source: feed.source, defaultCategory: feed.category)
                            let parsed = parser.parse()
                            fetchedArticles.append(contentsOf: parsed)
                        }
                    } catch {
                        print("Failed to fetch live feed from \(feed.source): \(error.localizedDescription)")
                    }
                }
            }
            
            if fetchedArticles.isEmpty {
                // Fallback to curated feed if offline or network fails
                self.articles = self.fallbackArticles
            } else {
                // Limit to top 10 live items
                self.articles = Array(fetchedArticles.prefix(10))
            }
            
            self.isLoading = false
        }
    }
    
    // Curated Fallback Articles for Offline / Airplane Mode
    private var fallbackArticles: [IntelligenceArticle] {
        [
            IntelligenceArticle(
                title: "CISA Issues Binding Operational Directive on Cloud Security Baselines",
                summary: "Federal agencies mandated to implement stricter identity and access management controls across cloud environments.",
                category: "Regulatory",
                source: "CISA",
                date: "Oct 2026",
                urlString: "https://www.cisa.gov"
            ),
            IntelligenceArticle(
                title: "Critical Zero-Day Vulnerability Discovered in Core Web Authentication Protocol",
                summary: "Active exploitation detected targeting OAuth token generation endpoints across enterprise SaaS apps.",
                category: "Vulnerability",
                source: "NVD",
                date: "Oct 2026",
                urlString: "https://nvd.nist.gov"
            ),
            IntelligenceArticle(
                title: "NIST Releases Final Draft of Cybersecurity Framework 2.0 Governance Category",
                summary: "Expanded guidance focuses on supply chain risk management and enterprise risk alignment.",
                category: "Compliance",
                source: "NIST",
                date: "Sep 2026",
                urlString: "https://www.nist.gov"
            ),
            IntelligenceArticle(
                title: "EU EDPB Publishes Updated Binding Corporate Rules Guidance",
                summary: "New benchmarks established for cross-border data transfer impact assessments under GDPR.",
                category: "Privacy",
                source: "EDPB",
                date: "Aug 2026",
                urlString: "https://edpb.europa.eu"
            ),
            IntelligenceArticle(
                title: "SEC Enforces First Penalties Under Updated Incident Disclosure Guidelines",
                summary: "Public companies penalized for failing to disclose material cybersecurity incidents within the 4-day window.",
                category: "Advisory",
                source: "SEC EDGAR",
                date: "Aug 2026",
                urlString: "https://www.sec.gov"
            )
        ]
    }
}

// MARK: - Native XML/RSS Delegate Parser

private class RSSParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private let defaultSource: String
    private let defaultCategory: String
    
    private var articles: [IntelligenceArticle] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var insideItem = false
    
    init(data: Data, source: String, defaultCategory: String) {
        self.parser = XMLParser(data: data)
        self.defaultSource = source
        self.defaultCategory = defaultCategory
        super.init()
        self.parser.delegate = self
    }
    
    func parse() -> [IntelligenceArticle] {
        parser.parse()
        return articles
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName.lowercased()
        if currentElement == "item" || currentElement == "entry" {
            insideItem = true
            currentTitle = ""
            currentDescription = ""
            currentLink = ""
            currentPubDate = ""
        }
        if insideItem && currentElement == "link", let href = attributeDict["href"] {
            currentLink = href
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        let clean = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        switch currentElement {
        case "title":
            currentTitle += " " + clean
        case "description", "summary":
            currentDescription += " " + clean
        case "link":
            if currentLink.isEmpty { currentLink += clean }
        case "pubdate", "published", "updated":
            currentPubDate += " " + clean
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let element = elementName.lowercased()
        if element == "item" || element == "entry" {
            insideItem = false
            let cleanTitle = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanDesc = stripHTML(currentDescription.trimmingCharacters(in: .whitespacesAndNewlines))
            let cleanLink = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanDate = formatDate(currentPubDate)
            
            if !cleanTitle.isEmpty {
                let dynamicCategory = classifyCategory(title: cleanTitle, summary: cleanDesc, fallback: defaultCategory)
                
                let article = IntelligenceArticle(
                    title: cleanTitle,
                    summary: cleanDesc.isEmpty ? "Tap to view full regulatory advisory." : cleanDesc,
                    category: dynamicCategory,
                    source: defaultSource,
                    date: cleanDate,
                    urlString: cleanLink.isEmpty ? "https://www.cisa.gov" : cleanLink
                )
                articles.append(article)
            }
        }
    }
    
    // Keyword Classifier Engine
    private func classifyCategory(title: String, summary: String, fallback: String) -> String {
        let content = (title + " " + summary).lowercased()
        
        if content.contains("cve-") || content.contains("vulnerability") || content.contains("exploit") || content.contains("zero-day") || content.contains("kev") {
            return "Vulnerability"
        } else if content.contains("privacy") || content.contains("gdpr") || content.contains("hipaa") || content.contains("ccpa") || content.contains("data protection") {
            return "Privacy"
        } else if content.contains("soc 2") || content.contains("iso") || content.contains("pci") || content.contains("nist") || content.contains("framework") || content.contains("compliance") {
            return "Compliance"
        } else if content.contains("rule") || content.contains("regulatory") || content.contains("directive") || content.contains("sec") || content.contains("mandate") || content.contains("register") {
            return "Regulatory"
        } else {
            return fallback
        }
    }
    
    private func stripHTML(_ str: String) -> String {
        return str.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
    
    private func formatDate(_ dateStr: String) -> String {
        let trimmed = dateStr.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Live Feed" }
        let components = trimmed.components(separatedBy: " ")
        if components.count >= 4 {
            return "\(components[1]) \(components[2])"
        }
        return "Live Feed"
    }
}
