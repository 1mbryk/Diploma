import Foundation
import SwiftUI

extension ContentListView {
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
                    Button(String(localized: "Copy", table: "General"), systemImage: "doc.on.doc") { }
                    Button(String(localized: "Rename", table: "General"), systemImage: "square.and.pencil") {
                        viewModel.showChangeNameView = true
                        viewModel.currentContent = content.wrappedValue
                    }
                    Button(role: .destructive,
                           action: {
                        viewModel.deleteFile(id: content.wrappedValue.id)
                        
                    }, label: {
                        Text(String(localized: "Delete", table: "General"))
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
}
