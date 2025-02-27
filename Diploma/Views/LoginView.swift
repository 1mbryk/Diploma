import Foundation
import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
//    @StateObject private var viewModel = LoginViewModel()
    @StateObject var viewModel : LoginViewModel
    
    fileprivate func SignInWithGoogleButton() -> some View{
        Button(action:{
            viewModel.handleSignIn()
        }){
            Image(.google)
                .resizable()
                .scaledToFit()
                .frame(width: CGFloat(20))
            Text("Sign in with Google")
        }
        .buttonStyle(.bordered)
    }
    
    var body: some View {
//        NavigationStack {
//            if viewModel.isLoggedIn {
//                ContentView()
//            } else {
            VStack{
                SignInWithGoogleButton()
                    .frame(width: 200, height: 50)
                Toggle("Stay logged in", isOn: $viewModel.stayLoggedIn)
                    .padding(.horizontal, 110)
                    .tint(Color(.black))
                
            }
        }
            
        }
//    }
//}
#Preview {
    LoginView(viewModel: LoginViewModel(user: User()))
}
