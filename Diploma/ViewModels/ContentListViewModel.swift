import Foundation
import SwiftUI
import PhotosUI

enum PreviewPhoto {
    case current
    case previous
    case next
}

class ContentListViewModel : ObservableObject {
    //  MARK: -  FLAGS
    @Published var showCreateFolderView = false
    @Published var showChangeNameView = false
    @Published var showImagePreview = false
    @Published var showPhotosPicker = false
    @Published var showSlidingMenu = false
    @Published var showAlert = false
    
    @Published var isSelectOptionOn = false
    @Published private (set) var isPrevImageAvailable = false
    @Published private (set) var isNextImageAvailable = false
    @Published var SelectAll = false
    @Published var isLoading = false
    
    //  MARK: - VARS
    @Published var content: [Content] = [] // List of content in current folder
    @Published var currentContent: Content?
    @Published var selectedContent: [Content] = [] // List of selected content
    @Published var currentDirectory: Content = Content(id: "root", name: "Drive", type: "application/vnd.google-apps.folder", isSelected: false )
    
    @Published var user: User
    
    @Published var pickedImage: UIImage?
    @Published var pickedImageId: String = ""
    @Published var timer: Timer?
    
    @Published var metadata =  Metadata(id: "",
                                        name: "",
                                        mimeType: "",
                                        createdTime: Date(),
                                        modifiedTime: Date())
    
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var alertMessage = ""
    private var cachedImages: [String: UIImage] = [:]
    private var sslClient = SSLClient()
    private var imageName = ""
    
    
    private var googleManager: GoogleManager
    
    init(user: User) {
        self.user = user
        self.googleManager = GoogleManager(user: user)
    }
    
    // MARK: - Methods
    
    func changeDirectory(id: String) {
        
        // for debug!
        // FIXME: nil after access token is expired
        googleManager.getFileMetadata(fileId: id) { metadata in
            self.metadata = metadata ?? Metadata(id: "", name: "Untitled", mimeType: "", createdTime: Date(), modifiedTime: Date())
            self.currentDirectory = Content(id: id, name: self.metadata.name, type: "Folder", isSelected: false)
        }
    }
    
    func getPickedImage() async -> UIImage? {
        guard !pickedImageId.isEmpty else { return nil }
        if let image = cachedImages[pickedImageId] {
            return image
        }
        
        let image = await googleManager.downloadImage(from: pickedImageId)
        cachedImages[pickedImageId] = image
        return image
    }
    
    func pickImage(which: PreviewPhoto) {
        print("Open Image")
        self.refreshAccessToken()
        
        // Find current image index
        guard let currentImageIndex = content.firstIndex(where: { $0.id == self.pickedImageId }) else {
            return
        }
        
        var newIndex = currentImageIndex
        
        switch which {
        case .current:
            break
        case .previous:
            if currentImageIndex > content.startIndex {
                newIndex = content.index(before: currentImageIndex)
            }
        case .next:
            if currentImageIndex < content.index(before: content.endIndex) {
                newIndex = content.index(after: currentImageIndex)
            }
        }
        
        self.pickedImageId = content[newIndex].id
        
        let prevIndex = content.index(before: newIndex)
        let nextIndex = content.index(after: newIndex)
        
        self.isPrevImageAvailable = (newIndex > content.startIndex) && content[prevIndex].type == "Photo"
        self.isNextImageAvailable = (newIndex < content.index(before: content.endIndex)) && content[nextIndex].type == "Photo"
    }
    
    func deleteFile(id: String) {
        self.googleManager.deleteFile(fileId: id) { error in
            if error != nil {
                self.showAlert = true
                self.alertMessage = error!
            }
        }
        content.removeAll(where: {$0.id == id})
    }
    
    func deleteSelectedFiles() {
        for file in selectedContent {
            self.deleteFile(id: file.id)
            content.removeAll(where: {$0.id == file.id})
        }
    }
    
    func getCurrentDirectoryName() -> String{
        return currentDirectory.name
    }
    
    func isGoBackAvailible() -> Bool {
        currentDirectory.id != "root"
    }
    
    func isGroupAvailable() -> Bool {
        return self.selectedContent.count > 0
    }
    
    func unselectAll() {
        for i in content.indices {
            content[i].isSelected = false
        }
        self.selectedContent = []
    }
    
    func select(currentContent: Binding<Content>){
        currentContent.wrappedValue.isSelected.toggle()
        if (currentContent.wrappedValue.isSelected) {
            self.selectedContent.append(currentContent.wrappedValue)
        } else {
            self.selectedContent.removeAll(where: {$0.id == currentContent.wrappedValue.id})
        }
    }
    
    func selectAll(){
        for i in content.indices {
            content[i].isSelected = true
        }
        self.selectedContent = self.content
    }
    
    func getMetadata(id: String) {
        self.refreshAccessToken()
        googleManager.getFileMetadata(fileId: id) { metadata in
            self.metadata = metadata!
            
        }
    }
    
    func getContent(folderId: String? = nil ) {
        print("⚙️ \(#function)")
        self.isLoading = true
        let id: String
        if folderId == nil {
            id = self.currentDirectory.id
        } else {
            id = folderId!
        }
        self.refreshAccessToken()
        self.content = []
        self.googleManager.fetchFiles(inFolder: id) { files in
            if files == nil {
                print("files is nil")
                return
            }
            
            
            self.parseFilesInfo(files: files)
            self.isLoading = false
        }
    }
    
    func changeName(name: String) {
        guard let fileId = currentContent?.id else { return }
        
        Task {
            let success = await googleManager.renameFile(fileId: fileId, newName: name)
            if success {
                DispatchQueue.main.async {
                    self.getContent(folderId: self.currentDirectory.id)
                }
            } else {
                print("❌ Rename failed")
                self.showAlert = true
                self.alertMessage = "Rename failed"
            }
        }
        self.showChangeNameView = false
    }
    
    func groupContent(by method: String = "Faces") {
        self.refreshAccessToken()
        let json: [String: Any] = [
            "Type": "Group",
            "Method": method,
            "AccessToken" : user.accessToken ?? "",
            "CurrentDirectory" : self.currentDirectory.id,
            "Content": self.selectedContent.map { $0.id }
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            
            sslClient.sendSecureRequest(body: jsonData) { data, response, error in
                if error != nil {
                    print("❌ Error: \(error!)")
                    self.alertMessage = "Something went wrong with group content"
                    self.showAlert = true
                    return
                }
                print("Response: \(response!)")
            }
        } catch {
            print("❌ Error serializing JSON: \(error)")
            self.alertMessage = "Something went wrong with group content"
            self.showAlert = true
        }
    }
    
    func createFolder(name: String) {
        self.isLoading = true
        self.googleManager.createFolder(name: name, parentFolderId: currentDirectory.id) { error in
            if error != nil {
                
                self.alertMessage = error!
                self.showAlert = true
            }
            self.getContent()
            self.isLoading = false
        }
    }
    
    func uploadPhotos() {
        for photo in self.selectedPhotos {
            Task {
                if let photoData = try? await photo.loadTransferable(type: Data.self) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd.MM.Y"
                    let name = "IMG_\(Int.random(in: 1...10000))_\(formatter.string(from: Date())).jpg"
                    self.googleManager.uploadPhoto(imageData: photoData, fileName: name, folderId: self.currentDirectory.id) { error in
                        if error != nil {
                            self.alertMessage = error!
                            self.showAlert = true
                        }
                    }
                    
                }
            }
        }
        self.selectedPhotos = []
    }
    
    // MARK: - Helper methods

        
    func refreshAccessToken() {
        if abs(Date().timeIntervalSince(user.accessTokenCreationDate!)) >= 3600 {
            self.googleManager.refreshAccessToken() { newToken in
                if (newToken != nil){
                    self.user.setAccessToken(accessToken: newToken!)
                    print("✅ Access token refreshed successfuly!")
                    self.user.save(storageURL: URL.documentsDirectory.appending(path: "login-info"))
                } else {
                    print("❌ Access token is nil")
                    self.alertMessage = "Access token is null"
                    self.showAlert = true
                }
            }
        }
    }
    
    private func parseFilesInfo(files: [[String : String]]?) {
        var new_content: [Content] = []
        if files == nil {
            return
        }
        for file in files! {
            
            if (file["mimeType"]! != "application/vnd.google-apps.folder" &&
                !file["mimeType"]!.starts(with: "image/") ) {
                continue
            }
            new_content.append((Content(id: file["id"]!,
                                        name: file["name"] ?? "Untitled",
                                        type: file["mimeType"]!,
                                        isSelected: false))
            )
        }
        self.content = new_content.sorted(by: {$0.type < $1.type})
    }
    
    
}
