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
            HStack {
                Image(.google)
                    .resizable()
                    .scaledToFit()
                    .frame(width: CGFloat(20))
                Text(String(localized:"SignInWithGoogle", table: "General"))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    
            }
        }
        .frame(alignment: .center)
        .buttonStyle(.bordered)
    }
    
    var body: some View {
//        NavigationStack {
//            if viewModel.isLoggedIn {
//                ContentView()
//            } else {
            VStack{
                SignInWithGoogleButton()
                    .frame(height: 50)
                Toggle(String(localized: "StayLoggedIn", table: "General"), isOn: $viewModel.stayLoggedIn)
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
