import Foundation
import SwiftUI

extension ContentListView {
    func Header() -> some View {
        VStack {
            if (viewModel.isSelectOptionOn) {
                HStack {
                    Button(viewModel.SelectAll ? "Unselect all" : "Select All"){
                        if viewModel.SelectAll{
                            viewModel.unselectAll()
                        } else {
                            viewModel.selectAll()
                        }
                        viewModel.SelectAll.toggle()
                    }
                    Spacer()
                    Button("Cancel"){
                        viewModel.isSelectOptionOn = false
                        viewModel.unselectAll()
                    }
                    
                }
                .padding(.horizontal, 25)
                
            } else {
                HStack {
                    // BACK BUTTON
                    Button("", systemImage: "chevron.backward") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!viewModel.isGoBackAvailible())
                    .foregroundStyle(Color.blue.opacity(viewModel.isGoBackAvailible() ? 100 : 0))
                    
                    Spacer()
                    
                    // HEADER NAME
                    Text(viewModel.getCurrentDirectoryName())
                    Spacer()
                    // MARK: - POP-UP MENU
                    Menu("", systemImage: "ellipsis.circle") {
                        Button("Select", systemImage: "checkmark.circle"){
                            if viewModel.isSelectOptionOn {
                                viewModel.unselectAll()
                            }
                            withAnimation(){
                                viewModel.isSelectOptionOn = true
                            }
                        }
                        Menu ("Add", systemImage: "plus.circle"){
                            Button("Folder") { viewModel.showCreateFolderView = true}
                            Button("Image") {viewModel.showPhotosPicker = true}
                        }
                    }
                }
                .frame(alignment: .center)
                .padding(.horizontal, 25)
            }
        }
        .frame(height: 30)
    }
}
