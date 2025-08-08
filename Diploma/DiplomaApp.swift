//
//  DiplomaApp.swift
//  Diploma
//
//  Created by Mацвей Пажытных on 27.02.25.
//

import SwiftUI
import os

@main
struct DiplomaApp: App {
    var user: User
    var viewModel: LoginViewModel
    
    init(){
        user = User()
        viewModel = LoginViewModel(user: user)
        let log = OSLog(subsystem: "com.your.bundle.identifier", category: "silent")
        os_log("Logging disabled", log: log, type: .fault)

    }
    var body: some Scene {
        WindowGroup {
            ViewSwitcher(viewModel: viewModel)
        }
    }
}

struct ViewSwitcher : View {
    @StateObject var viewModel: LoginViewModel
    
    var body: some View {
        if(viewModel.isLoggedIn){
            ContentView(viewModel: viewModel)
        }else{
            LoginView(viewModel: viewModel)
                
        }
    }
}
