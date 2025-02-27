import SwiftUI
import PhotosUI

struct EmptyImageView: View{
    @Binding var show: Bool
    var body: some View{
        Image(systemName: "person.fill")
            .frame(width: 100, height: 100)
            .font(.largeTitle)
            .foregroundStyle(.white)
            .background(.gray,in: Circle())
            .padding(.top, show ? 0 : 50)
            .frame(maxWidth: show ? .infinity : 100, maxHeight: show ? 240 : 200)
    }
}
struct ProfileImageView: View {
    @Binding var show : Bool
    var profileImage: Image
    
    var body: some View {
        GeometryReader(content: { geo in
            profileImage
                .resizable()
                .scaledToFill()
                .frame(width: show ? geo.size.width : 100, height: show ? 320 : 100 )
                .clipShape(.rect(cornerRadius: show ? 0 : 100))
                .padding(.top, show ? 0 : 50)
                .onTapGesture {
                    withAnimation(.easeInOut){
                        show.toggle()
                        
                    }
                }
        })
        .frame(maxWidth: show ? .infinity : 100, maxHeight: show ? 240 : 200)
    }
}
struct NameView: View {
    @Binding var show: Bool
    @State var name: String?
    @State var email: String?
    
    var body: some View {
        VStack(alignment: .leading){
            Text(name ?? "Unknown")
                .bold()
                .font(.largeTitle)
                .foregroundStyle(show ? .white : .black)
                .padding(.top, show ? 30 : 0)
            Text(email ?? "unknown@example.com")
                .fontWeight(.thin)
            
        }
        .padding(.leading, 50)
        .padding(.leading, show ? 0 : 250)
        .padding(.top, show ? 190 : 30)
    }
}

struct ProfileView: View {
    @StateObject var viewModel : LoginViewModel
    @State var show = false
    @State var selectedItem: PhotosPickerItem? = nil
    @State var isSignOut = false
    
    fileprivate func LogoutButton() -> some View{
        Button(role: .destructive, action: {
            Task{
                isSignOut = true
            }
        }){
            HStack{
                Image(systemName: "rectangle.portrait.and.arrow.forward")
                Text("Log Out")
            }
            
        }.confirmationDialog(
            "Are you sure?",
            isPresented: $isSignOut,
            titleVisibility: .visible
        ) {
            Button("Yes", role: .destructive) {
                DispatchQueue.main.async {
                    Task {
                        viewModel.signOut()
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {}
        }
    }
    
    var body: some View {
        NavigationStack{
            ScrollView{
                // Profile pic area
                VStack{
                    ZStack(alignment: .top){
                        Color(red: 241/255, green: 241/255, blue: 247/255).ignoresSafeArea()
                        ZStack {
                            VStack {
                                AsyncImage(url: viewModel.user.profilePicURL) { phase in
                                    if let image = phase.image {
                                        ProfileImageView(show: $show, profileImage: image)
                                    } else {
                                        ProfileImageView(show: $show, profileImage: Image(uiImage:
                                                                                            ImageRenderer(content: Rectangle()
                                                                                                .fill(Color.red)
                                                                                                .frame(width: 200, height: 200)).uiImage!))
                                        //                                        ProfileImageView(show: $show, profileImage: Image(systemName: "person.fill"))
                                    }
                                }
                            }
                            NameView(show: $show, name: viewModel.user.name, email: viewModel.user.email)
                                .frame(height: 40)
                        }
                        .padding(.leading, show ? 0: -250)
                        
                    }
                    .frame(height: show ? 240 : 170)
                    // Options area
                    VStack{
                        List{
                            Section(){
                                
                            }
                            Section(){
                                LogoutButton()
                            }
                        }
                        
                    }
                    .frame(height: 700)
                    .offset(y:-8) // TODO: fix that
                    
                }
                
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    ProfileView(viewModel: LoginViewModel(user: User()))
}

