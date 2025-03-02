import SwiftUI

class GoogleManager {
    var files: [[String: String]]?
    var folderId: String?
    private let baseURL = "https://www.googleapis.com/drive/v3/files"
    
    var user: User
    
    init(user: User) {
        self.user = user
    }
    
    struct OAuthTokenResponse: Decodable {
        let access_token: String?
        let expires_in: Int?
        let scope: String?
        let token_type: String?
        let error: String?
        let error_description: String?
        
    }
    
    
    // MARK: - Helper Methods
    
    /// Creates an authorized URLRequest with the given HTTP method and optional body.
    private func createAuthorizedRequest(url: URL, method: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(user.accessToken!)", forHTTPHeaderField: "Authorization")
        if let body = body {
            request.httpBody = body
        }
        return request
    }
    
    /// Performs a network request and handles JSON parsing.
    private func performDataTask<T: Decodable>(request: URLRequest, decodingType: T.Type, completion: @escaping (T?) -> Void) {
        // ⚠️ DEPRECATED
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(decodedData)
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
    
    private func performDataTask<T: Decodable>(request: URLRequest, decodingType: T.Type) async -> T? {
        let decodedData: T
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            decodedData = try JSONDecoder().decode(decodingType, from: data)
            
        } catch {
            print("❌ Error: failed to get data")
            return nil
        }
        return decodedData
    }
    
    
    
    // MARK: - Google Drive Methods
    
    func fetchFiles(inFolder folderId: String) async -> [[String: String]]? {
        let query = "'\(folderId)' in parents"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?q=\(encodedQuery)&fields=files(id,name,mimeType)") else {
            return nil
        }
        
        let request = createAuthorizedRequest(url: url, method: "GET")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode([String: [[String: String]]].self, from: data)
            return response["files"]
        } catch {
            print("❌ Error fetching files: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchFilename(id: String) async -> String? {
        let urlString = "\(baseURL)/\(id)?fields=name"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(user.accessToken!)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error: Invalid response from Google Drive")
                return nil
            }
            let decodedData = String(data:data, encoding: .utf8)
            let result = try JSONDecoder().decode([String: String].self, from: data)
            return result["name"]
        } catch {
            print("Error fetching filename: \(error.localizedDescription)")
            return nil
        }
    }

    func refreshAccessToken() async -> String? {
        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        guard let refreshToken = self.user.refreshToken else {
            print("❌ Error: Refresh token is nil")
            return nil
        }
        
        guard let configPath = Bundle.main.url(forResource: "config", withExtension: "json"),
              let clientID = try? JSONDecoder().decode([String:String].self, from: Data(contentsOf: configPath))["google_client_id"] else {
            print("❌ Error: Unable to load google client id")
            return nil
        }
        
        let bodyParams = [
            "client_id": clientID,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        request.httpBody = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        
        guard let response = await self.performDataTask(request: request, decodingType: OAuthTokenResponse.self) else {
            print("❌ Error: Unable to refresh access token")
            return nil
        }
        return response.access_token
    }
    
    func getFileMetadata(fileId: String) async -> Metadata? {
        let url = URL(string: "\(baseURL)/\(fileId)?fields=id,name,mimeType,size,createdTime,modifiedTime")!
        let request = createAuthorizedRequest(url: url, method: "GET")
        
        guard let metadata = await performDataTask(request: request, decodingType: Metadata.self) else {
            print("❌ Error: failed fetch metadata")
            return nil
        }
        return metadata
    }
    
    func downloadImage(from fileId: String) async -> UIImage? {
        let url = URL(string: "\(baseURL)/\(fileId)?alt=media")!
        let request = createAuthorizedRequest(url: url, method: "GET")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("❌ Server returned an error")
                return nil
            }
            return UIImage(data: data)
        } catch {
            print("❌ Network error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteFile(fileId: String, completion: @escaping (_ error: String?) -> Void) {
        let url = URL(string: "\(baseURL)/\(fileId)")!
        let request = createAuthorizedRequest(url: url, method: "DELETE")
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Error deleting file: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
                print("✅ File deleted successfully!")
                completion(nil)
            } else {
                print("❌ Failed to delete file")
                completion("Failed to delete file")
            }
        }.resume()
    }
    
    func createFolder(name: String, parentFolderId: String?, completion: @escaping (_ error: String?) -> Void) {
        let url = URL(string: "\(baseURL)")!
        
        var folderMetadata: [String: Any] = [
            "name": name,
            "mimeType": "application/vnd.google-apps.folder"
        ]
        
        if let parentFolderId = parentFolderId {
            folderMetadata["parents"] = [parentFolderId]
        }
        
        guard let jsonBody = try? JSONSerialization.data(withJSONObject: folderMetadata, options: []) else {
            print("❌ Error creating JSON")
            completion("Failed to create folder")
            return
        }
        
        var request = createAuthorizedRequest(url: url, method: "POST", body: jsonBody)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")  // Ensure proper header
        
        performDataTask(request: request, decodingType: [String: String].self) { response in
            let folderId = response?["id"]
            if let folderId = folderId {
                print("✅ Folder created with ID: \(folderId)")
                completion(nil)
            } else {
                print("❌ Failed to create folder")
                completion("Failed to create folder")

            }
        }
    }
    
    func createFolder(name: String, parentFolderId: String?) async -> Bool {
        let url = URL(string: baseURL)!
        
        var folderMetadata: [String: Any] = [
            "name": name,
            "mimeType": "application/vnd.google-apps.folder"
        ]
        
        if let parentFolderId = parentFolderId {
            folderMetadata["parents"] = [parentFolderId]
        }
        
        guard let jsonBody = try? JSONSerialization.data(withJSONObject: folderMetadata, options: []) else {
            print("❌ Error creating JSON")
            return false
        }
        
        var request = createAuthorizedRequest(url: url, method: "POST", body: jsonBody)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            if let folderId =  await performDataTask(request: request, decodingType: [String: String].self)?["id"] {
                print("✅ Folder created with id: \(folderId)")
                return true
            } else {
                print("❌ Failed to create folder")
                return false
            }
            
        }
    }
    
    
    func uploadPhoto(imageData: Data, fileName: String, folderId: String, completion: @escaping (_ error: String?) -> Void) {
        let mimeType: String
        if fileName.hasSuffix(".jpg") || fileName.hasSuffix(".jpeg"){
            mimeType = "image/jpeg"
        } else {
            mimeType = "image/png"
        }
        
        let metadata: [String: Any] = [
            "name": fileName,
            "mimeType": mimeType,
            "parents": [folderId]
        ]
        guard let metadataJSON = try? JSONSerialization.data(withJSONObject: metadata, options: []) else {
            completion("Failed to upload photo")
            print("❌ Error creating metadata JSON")
            return
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = createAuthorizedRequest(url: URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")!, method: "POST")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add metadata
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(metadataJSON)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion("Failed to upload photo")
                print("❌ Upload error: \(error)")
                return
            }
            if let data = data, let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) {
                print("✅ Upload response: \(jsonResponse)")
                completion(nil)
            }
        }.resume()
    }
    
    func renameFile(fileId: String, newName: String) async -> Bool {
        let url = URL(string: "\(baseURL)/\(fileId)")!
        let jsonBody = ["name": newName]
        
        guard let body = try? JSONSerialization.data(withJSONObject: jsonBody, options: []) else {
            print("❌ Error creating JSON")
            return false
        }
        
        var request = createAuthorizedRequest(url: url, method: "PATCH", body: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return true
            }
        } catch {
            print("❌ Error renaming file: \(error)")
        }
        return false
    }
    
    
}
