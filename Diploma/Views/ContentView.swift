import Foundation
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: LoginViewModel
    @ObservedObject var contentListViewModel : ContentListViewModel
    
    init(viewModel: LoginViewModel){
        UITabBar.appearance().backgroundColor = UIColor.white
        self.viewModel = viewModel
        contentListViewModel = ContentListViewModel(user: viewModel.user)
    }
    var body: some View {
        TabView {
            ProfileView(viewModel: viewModel)
                .tabItem{
                    Image(systemName: "person")
                    Text("Profile")
                }
            NavigationStack {
                ContentListView(viewModel: contentListViewModel)
            }
            .tabItem {
                Image(systemName: "folder")
                Text("Content")
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
        
}

#Preview {
    ContentView(viewModel: LoginViewModel(user: User()))
}
