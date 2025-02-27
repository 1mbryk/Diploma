import SwiftUI
import PhotosUI

struct ContentListView: View {
    let MAX_FILENAME_LEN = 24
    
    @StateObject var viewModel: ContentListViewModel
    //    @ObservedObject var viewModel: ContentListViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var directoryID = "root"
    
    // MARK: - Content Button
    func ContentButton(content: Binding<Content>) -> some View {
        HStack {
            
            // Selection Button
            if viewModel.isSelectOptionOn {
                Button(action: { viewModel.select(currentContent: content) }) {
                    Image(systemName: content.wrappedValue.isSelected ? "checkmark.circle.fill" : "circle")
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.blue)
                }
            }
            // Content Button
            if content.wrappedValue.type == "Folder" {
                
                // FIXME: toolbar is not displaing in childish views
                NavigationLink(destination: ContentListView(viewModel: viewModel, directoryID: content.wrappedValue.id)
                    .toolbar(.visible, for: .tabBar)
                ){
                    HStack {
                        Image(systemName: "folder.fill")
                        Text(content.wrappedValue.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundStyle(.blue)
                    .padding(.leading, 5)
                }
                .disabled(viewModel.isSelectOptionOn)
                
                
            } else {
                
                Button(action: {
                    viewModel.pickedImageId = content.wrappedValue.id
                    withAnimation(.easeInOut(duration: 0.3)){
                        viewModel.showImagePreview = true
                    }
                    viewModel.pickImage(which: .current)
                    
                }) {
                    HStack {
                        Image(systemName: content.wrappedValue.type == "Photo" ? "photo" : "folder.fill")
                        Text(content.wrappedValue.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .padding(.leading, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundStyle(Color(.blue).opacity(viewModel.isSelectOptionOn ? 0.5 : 1))
                .disabled(viewModel.isSelectOptionOn)
            }
            
            // Spacer
            Spacer()
            
            // Info & Options Buttons
            HStack(spacing: 10) {
                Button(action: {
                    if viewModel.isSelectOptionOn {
                        return
                    }
                    viewModel.getMetadata(id: content.wrappedValue.id)
                    withAnimation{
                        viewModel.showSlidingMenu.toggle()
                        
                    }
                }) {
                    Image(systemName: "info.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.blue)
                }
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
                .buttonStyle(PlainButtonStyle())
                
                Menu {
                    Button("Copy", systemImage: "doc.on.doc") { }
                    Button("Rename", systemImage: "square.and.pencil") {
                        viewModel.showChangeNameView = true
                        viewModel.currentContent = content.wrappedValue
                    }
                    Button(role: .destructive,
                           action: {
                        viewModel.deleteFile(id: content.wrappedValue.id)
                        
                    }, label: {
                        Text("Delete")
                        Image(systemName: "trash")
                    })
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.blue)
                }
                .frame(width: 30, height: 30)
            }
        }
        .contentShape(Rectangle())
    }
    
    // MARK: - Header
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
    
    var body: some View {
        
        //        NavigationStack {
        ZStack {
            VStack { // Header
                
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
        //        }
        .toolbar(viewModel.isSelectOptionOn || viewModel.showImagePreview ? .hidden : .automatic, for: .tabBar) // FIXME: toolbar is vanishing after open image in childish views
        .navigationBarBackButtonHidden(true)
    }
}

//#Preview{
//    ContentListView(viewModel: ContentListViewModel(user: User()))
//}
