import Foundation
import GoogleSignIn
import GoogleSignInSwift

enum LoginError : Error {
    case EmptySavedData
}

class LoginViewModel: ObservableObject {
    let storageURL = URL.documentsDirectory.appending(path: "login-info")
    
    @Published var stayLoggedIn = false
    @Published var user : User
    @Published var isLoggedIn: Bool
    
    
    init(user : User) {
        do {
            let data = try Data(contentsOf: storageURL)
            
            if String(data: data, encoding: .utf8) == "{\n\n}"{
                throw LoginError.EmptySavedData
            }
            user.copy(from: try JSONDecoder().decode(User.self, from: data))
            isLoggedIn = true
        } catch {
            print("Unable to load data.")
            print("Error: \(error.localizedDescription)")
            isLoggedIn = false
        }
        self.user = user
    }
        
    func handleSignIn() {
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first else {
            return
        }
        
        Task {
            do {
                let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: ["https://www.googleapis.com/auth/drive", "https://www.googleapis.com/auth/drive.file"])
                let googleUser = signInResult.user
                
                DispatchQueue.main.async {
                
                    self.user.copy(from: User(name: googleUser.profile?.name,
                                              email: googleUser.profile?.email,
                                              accessToken: googleUser.accessToken.tokenString,
                                              refreshToken: googleUser.refreshToken.tokenString,
                                              accessTokenCreationDate: Date(),
                                              profilePicURL: googleUser.profile?.imageURL(withDimension: 200)))
                    print("Granted scopes: \(googleUser.grantedScopes!)")
                    self.isLoggedIn = true
                    if(self.stayLoggedIn) {
                        self.user.save(storageURL: self.storageURL)
                        
                    }

                }

               
            } catch {
                print("Sign-in failed: \(error.localizedDescription)")
            }
        }
        
        
    }
    
    
    func signOut() {
        DispatchQueue.main.async {
            GIDSignIn.sharedInstance.signOut()
            self.user = User()
            self.user.save(storageURL: self.storageURL)
            self.isLoggedIn = false
        }
    }
}
