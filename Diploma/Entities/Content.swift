import Foundation
struct Content: Identifiable {
    let id: String
    var name: String
    var type: String
    var isSelected: Bool
    
    
    init(id: String, name: String, type: String, isSelected: Bool) {
        self.id = id
        self.name = name
        if (type == "application/vnd.google-apps.folder") {
            self.type = "Folder"
        } else if (type.starts(with: "image/")) {
            self.type = "Photo"
        } else {
            self.type = "Other"
        }
        self.isSelected = isSelected
    }
}
