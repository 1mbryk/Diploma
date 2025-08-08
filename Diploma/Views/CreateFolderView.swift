import SwiftUI

struct SimpleView1: View {
    @ObservedObject var viewModel = ContentListViewModel(user: User())

    var body: some View {
        ZStack {
            Color(.white).ignoresSafeArea()

            Button("Change Name", action: {
                withAnimation {
                    viewModel.showCreateFolderView = true
                }
            })

            if viewModel.showCreateFolderView {
                CreateFolderView(viewModel: viewModel)
                    .transition(.opacity) // Fade in/out animation
            }
        }
    }
}

struct CreateFolderView: View {
    @ObservedObject var viewModel: ContentListViewModel
    @State var name = ""

    var body: some View {
        VStack(alignment: .center) {
            ZStack(alignment: .top) {
                Color(.white)

                VStack(spacing: 25) {
                    Form {
                        TextField(String(localized: "EnterNewName", table: "General"), text: $name)
                
                    }
                    .scrollContentBackground(.hidden)
                    .frame(height: 80)

                    HStack(spacing: 80) {
                        Button(String(localized: "Cancel", table: "General"), role: .destructive, action: {
                            withAnimation {
                                viewModel.showCreateFolderView = false
                            }
                        })
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                        Button(String(localized:"Confirm", table: "General"), action: {
                            withAnimation {
                                viewModel.createFolder(name: name)
                                viewModel.showCreateFolderView = false

                            }
                        })
                    }
                }
            }
            .frame(width: 300, height: 150, alignment: .center)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(radius: 10)
        }
        .opacity(viewModel.showCreateFolderView ? 1 : 0) // Control visibility based on state
        .animation(.easeInOut(duration: 0.3), value: viewModel.showCreateFolderView) // Apply animation
    }
}

#Preview {
    SimpleView1()
}
