import Foundation
struct Metadata: Codable {
    var id: String
    var name: String
    var modifiedTime: Date
    var createdTime: Date
    var size: Int?
    var mimeType: String
    
    // TODO: extend metadata to [width, height, cameraMake, cameraModel, exposureTime, aperture, focalLength, isoSpace, colorSpace, whiteBalance, lens]
    init(id: String, name: String, mimeType: String, createdTime: Date,modifiedTime: Date, size: Int? = nil) {
        self.id = id
        self.name = name
        self.modifiedTime = modifiedTime
        self.createdTime = createdTime
        self.size = size
        switch mimeType {
        case "image/png":
            self.mimeType = "Image"
        case "image/jpg":
            self.mimeType = "Image"
        case "application/vnd.google-apps.folder":
            self.mimeType = "Folder"
        default:
            self.mimeType = "Other"
            
        }
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.size = try? container.decode(Int.self, forKey: .size)
        
        let rawMimeType = try container.decode(String.self, forKey: .mimeType)
        switch rawMimeType {
        case "image/png", "image/jpeg":
            self.mimeType = "Image"
        case "application/vnd.google-apps.folder":
            self.mimeType = "Folder"
        default:
            self.mimeType = "Other"
        }
        
        let createdTimeString = try container.decode(String.self, forKey: .createdTime)
        let modifiedTimeString = try container.decode(String.self, forKey: .modifiedTime)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let createdTimeDate = formatter.date(from: createdTimeString),
           let modifiedTimeDate = formatter.date(from: modifiedTimeString) {
            self.createdTime = createdTimeDate
            self.modifiedTime = modifiedTimeDate
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.createdTime, CodingKeys.modifiedTime], debugDescription: "Invalid date format"))
        }
    }
}
