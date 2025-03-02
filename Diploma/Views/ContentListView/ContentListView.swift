import SwiftUI
import PhotosUI

struct ContentListView: View {
    let MAX_FILENAME_LEN = 24
    
    @StateObject var viewModel: ContentListViewModel
    //    @ObservedObject var viewModel: ContentListViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var directoryID = "root"
    
    var body: some View {
        
        ZStack {
            VStack {
                
                Header()
                VStack { // main content
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        if viewModel.content.isEmpty {
                            VStack {
                                Image(systemName: "folder")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                
                                Text("Folder is empty")
                                    .fontWeight(.light)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground))
                        } else {
                            List {
                                ForEach($viewModel.content, id: \.id) { $content in
                                    ContentButton(content: $content)
                                }
                            }
                            .refreshable {
                                viewModel.getContent()
                            }
                        }
                    }
                }
                .photosPicker(isPresented: $viewModel.showPhotosPicker,
                              selection: $viewModel.selectedPhotos,
                              matching: .any(of: [.images, .not(.screenshots)]))
                .onChange(of: viewModel.selectedPhotos) {
                    print("⚙️ .onChange(selectedPhotos)")
                    viewModel.uploadPhotos()
                    viewModel.getContent()
                    
                }
                
                // MARK: - ON APPEAR
                .onAppear {
                    print("⚠️ ContentListView is appear")
                    if !viewModel.showImagePreview {
                            DispatchQueue.main.async {
                                withAnimation {
                                    viewModel.showImagePreview = false
                                }
                            }
                        }
                    viewModel.changeDirectory(id: directoryID)
                    viewModel.getContent(folderId: directoryID)
                    viewModel.showImagePreview = false
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .alignmentGuide(.leading) { _ in 0 }
                .alert("Oops", isPresented: $viewModel.showAlert) {
                    Button("Ok") {
                        viewModel.showAlert = false
                        viewModel.alertMessage = ""
                    }
                } message: {
                    Text(viewModel.alertMessage)
                }
                
                
                // MARK: - Additional windows
                if viewModel.isSelectOptionOn {
                    VStack {
                        HStack{
                            Menu("Group by") {
                                Section("Group by") {
                                    Button("Faces") {
                                        viewModel.groupContent(by: "Face")
                                        viewModel.unselectAll()
                                        viewModel.isSelectOptionOn = false
                                    }
                                    Button("Date") {
                                        viewModel.groupContent(by: "Date")
                                        viewModel.unselectAll()
                                        viewModel.isSelectOptionOn = false
                                    }
                                    // TODO: add method group by metadata
                                }
                            }
                            .disabled(!viewModel.isGroupAvailable())
                            Spacer()
                            Text("Select items")
                            Spacer()
                            Button("", systemImage: "trash", action: {viewModel.deleteSelectedFiles()})
                        }
                        .frame(alignment: .center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 40)
                    .padding(.horizontal, 30)
                    
                }
                
                
            }
            if viewModel.showChangeNameView {
                ChangeNameView(viewModel: viewModel)
                    .transition(.opacity)
                // Fade in/out animation
            }
            if viewModel.showCreateFolderView {
                CreateFolderView(viewModel: viewModel)
                    .transition(.opacity)
            }
            SlidingMenuView(viewModel: viewModel)
            PreviewPhotoView(viewModel: viewModel)
        }
        .toolbar(viewModel.isSelectOptionOn || viewModel.showImagePreview ? .hidden : .automatic, for: .tabBar)
        .navigationBarBackButtonHidden(true)
    }
}
