import SwiftUI
import SwiftData

// MARK: - String Extension for Evidence Categories

extension String {
    static let image = "image"
    static let link = "link"
    static let document = "document"
    static let photo = "photo"
}

enum EvidenceType: String, Codable {
    case photo = "photo"
    case image = "image"
    case document = "document"
    case link = "link"
}

@Model
final class EvidenceItem {
    var id: UUID
    var fileName: String
    var fileType: String
    var createdDate: Date
    var fileData: Data?
    var urlString: String?
    var taskID: String?
    var localPath: String?
    
    init(id: UUID = UUID(), fileName: String, fileType: String, fileData: Data? = nil, urlString: String? = nil, taskID: String? = nil, localPath: String? = nil) {
        self.id = id
        self.fileName = fileName
        self.fileType = fileType
        self.createdDate = Date()
        self.fileData = fileData
        self.urlString = urlString
        self.taskID = taskID
        self.localPath = localPath
    }
    
    // Convenience initializer matching EvidenceLockerView call signature
    convenience init(taskID: String?, fileName: String, fileType: String, urlString: String? = nil, localPath: String? = nil, fileData: Data? = nil) {
        self.init(id: UUID(), fileName: fileName, fileType: fileType, fileData: fileData, urlString: urlString, taskID: taskID, localPath: localPath)
    }
    
    var evidenceEnum: EvidenceType {
        switch fileType.lowercased() {
        case "photo", "image", "png", "jpg", "jpeg":
            return .image
        case "link", "url":
            return .link
        default:
            return .document
        }
    }
    
    @discardableResult
    func saveFileToDocuments(data: Data, originalName: String) -> Bool {
        self.fileData = data
        self.fileName = originalName
        return true
    }
    
    @discardableResult
    static func saveFileToDocuments(data: Data, originalName: String, taskID: String? = nil) -> String {
        return originalName
    }
}

