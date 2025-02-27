 import Foundation
 import Security

// Class response for communication between server in client
 class SSLClient: NSObject, URLSessionDelegate, ObservableObject {
    
     private var session: URLSession!
     private var identity: SecIdentity?
     private var trust: SecTrust?
     private var url: URL
    
     override init() {
         self.url = URL(string: "https://127.0.0.1:8443")!
         super.init()
         let config = URLSessionConfiguration.default
         self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
         self.loadClientCertificate()
     }
    
     /// Load the client certificate from a `.p12` file in the app bundle
     private func loadClientCertificate() {
         DispatchQueue.global(qos: .userInitiated).async {

             guard let certPath = Bundle.main.path(forResource: "client_certificate", ofType: "p12"),
                   let certData = try? Data(contentsOf: URL(fileURLWithPath: certPath)) else {
                 print("❌ Client certificate not found")
                 return
             }

             guard let passPath = Bundle.main.url(forResource: "config", withExtension: "json"),
                   let certPassword = try? JSONDecoder().decode([String: String].self, from: Data(contentsOf: passPath))["p12_password"] else {
                 print("❌ p12 password not found in environment")
                 return
             }
             let options: NSDictionary = [kSecImportExportPassphrase as String: certPassword]
             var items: CFArray?

             let status = SecPKCS12Import(certData as CFData, options, &items)
             if status == errSecSuccess, let itemsArray = items as? [[String: Any]],
                let firstItem = itemsArray.first {

                 if let identity = firstItem[kSecImportItemIdentity as String] as! SecIdentity?,
                    let trust = firstItem[kSecImportItemTrust as String] as! SecTrust? {
                     
                     DispatchQueue.main.async {
                         self.identity = identity
                         self.trust = trust
                         print("✅ Client certificate loaded successfully")
                     }
                 } else {
                     print("❌ Failed to extract identity or trust from PKCS12")
                 }
             } else {
                 print("❌ Failed to load client certificate: \(status)")
             }
         }
     }

    
     /// Sends a secure HTTPS request
     func sendSecureRequest(url: URL? = nil, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
         print("Executing \(#function) on thread: \(Thread.current)")
         let requestUrl = url ?? self.url
         let task = session.dataTask(with: requestUrl, completionHandler: completion)
         task.resume()
     }
    
     /// Sends a secure HTTPS request with custom data
     func sendSecureRequest(url: URL? = nil, method: String = "POST", headers: [String: String] = [:], body: Data?, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
         print("Executing \(#function) on thread: \(Thread.current)")
         let requestUrl = url ?? self.url
         var request = URLRequest(url: requestUrl)
         request.httpMethod = method
         request.httpBody = body
        
         // Set default and custom headers
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         for (key, value) in headers {
             request.setValue(value, forHTTPHeaderField: key)
         }

         let task = session.dataTask(with: request, completionHandler: completion)
         task.resume()
     }

    
     /// Provide client certificate when requested
     func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
         print("Executing \(#function) on thread: \(Thread.current)")
        
         if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
             guard let identity = self.identity else {
                 print("❌ No client identity available")
                 completionHandler(.cancelAuthenticationChallenge, nil)
                 return
             }
            
             // Provide the client certificate
             let credential = URLCredential(identity: identity, certificates: nil, persistence: .forSession)
             completionHandler(.useCredential, credential)
             print("✅ Provided client certificate for authentication")
             return
         }
        
         // Handle standard SSL validation (server certificate)
         guard let serverTrust = challenge.protectionSpace.serverTrust else {
             completionHandler(.cancelAuthenticationChallenge, nil)
             return
         }
        
         let credential = URLCredential(trust: serverTrust)
         completionHandler(.useCredential, credential)
     }
 }
