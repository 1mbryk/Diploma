import SwiftUI

struct SlidingMenuView: View {
    @ObservedObject var viewModel: ContentListViewModel
    @State private var dragOffset: CGFloat = 2500
    
    var body: some View {
        ZStack {
            
            if viewModel.showSlidingMenu {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            viewModel.showSlidingMenu = false
                            dragOffset = 2500
                        }
                    }
            }
            
            // SlidingMenu
            ZStack (alignment: .leading) {
                VStack {
                    VStack (alignment: .leading, spacing: 10) {
                        VStack (alignment: .leading, spacing: 2) {
                            Text("\(String(localized: "FileName", table: "General")):")
                                .font(.caption)
                                .fontWeight(.thin)
                            Text(viewModel.metadata.name)
                        }
                        VStack (alignment: .leading, spacing: 2) {
                            Text("\(String(localized: "FileCreationDate", table: "General")):")
                                .font(.caption)
                                .fontWeight(.thin)
                            Text(viewModel.metadata.getCreatedTime())
                        }
                        VStack (alignment: .leading, spacing: 2) {
                            Text("\(String(localized: "FileModificationDate", table: "General")):")
                                .font(.caption)
                                .fontWeight(.thin)
                            Text(viewModel.metadata.getModifiedTime())
                            
                        }
                        
                         if viewModel.metadata.mimeType != "Folder" {
                            VStack (alignment: .leading, spacing: 2) {
                                Text("\(String(localized: "FileSize", table: "General")):")
                                    .font(.caption)
                                    .fontWeight(.thin)
                                Text("\(viewModel.metadata.size ?? 0) Kb")
                            }
                        }
                        VStack (alignment: .leading, spacing: 2) {
                            Text("\(String(localized: "FileType", table: "General")):")
                                .font(.caption)
                                .fontWeight(.thin)
                            Text(viewModel.metadata.mimeType)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(25)
                    
                    Spacer()
                }
                .frame(height: 500)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 25.0))
                .shadow(radius: 10)
                .offset(y:200)
                .offset(y: viewModel.showSlidingMenu ? 0 : dragOffset)
                .animation(.easeInOut, value: viewModel.showSlidingMenu)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if gesture.translation.width > -250 && gesture.translation.width < 0 {
                                dragOffset = gesture.translation.width
                            }
                        }
                        .onEnded { gesture in
                            withAnimation {
                                if gesture.translation.width < -100 {
                                    dragOffset = -250
                                    viewModel.showSlidingMenu = false
                                } else {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}
