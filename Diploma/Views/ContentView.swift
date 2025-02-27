import Foundation
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: LoginViewModel
    @ObservedObject var contentListViewModel : ContentListViewModel
    
    init(viewModel: LoginViewModel){
        UITabBar.appearance().backgroundColor = UIColor.white
        self.viewModel = viewModel
        contentListViewModel = ContentListViewModel(user: viewModel.user)
        contentListViewModel.refreshAccessToken()


    }
    var body: some View {
        NavigationStack{
            TabView{
                ProfileView(viewModel: viewModel)
                    .tabItem{
                        Image(systemName: "person")
                        Text("Profile")
                    }
                // temporary
                ContentListView(viewModel: contentListViewModel)
                    .tabItem {
                        Image(systemName: "folder")
                        Text("Content")
                    }
            }
        }
    }
}

#Preview {
    ContentView(viewModel: LoginViewModel(user: User()))
}
