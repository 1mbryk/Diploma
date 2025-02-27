import Foundation
class User: Codable {
    var name: String?
    var email: String?
    var accessToken: String?
    var refreshToken: String?
    var accessTokenCreationDate: Date?
    var profilePicURL: URL?
    
    init(name: String?, email: String?, accessToken: String?, refreshToken: String?, accessTokenCreationDate: Date,profilePicURL: URL?) {
        self.name = name
        self.email = email
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accessTokenCreationDate = accessTokenCreationDate
        
        self.profilePicURL = profilePicURL
    }
    
    init(){
        name = nil
        email = nil
        accessToken = nil
        refreshToken = nil
        accessTokenCreationDate = nil
        profilePicURL = nil
    }
    
    func copy(from other: User){
        self.name = other.name
        self.email = other.email
        self.accessToken = other.accessToken
        self.refreshToken = other.refreshToken
        self.accessTokenCreationDate = other.accessTokenCreationDate
        self.profilePicURL = other.profilePicURL
    }
    
    func setAccessToken(accessToken: String){
        self.accessToken = accessToken
        self.accessTokenCreationDate = Date()
    }
    
    func save(storageURL: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self)
            try data.write(to: storageURL, options: [.atomic, .completeFileProtection])
            print("Data saved successfully")
            print("Saved data: \(String(data:data, encoding: .utf8)!)")
            
        }catch{
            print("Unable to save.")
            print(error.localizedDescription)
        }
        
    }
}
