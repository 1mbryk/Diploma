import SwiftUI

struct PreviewPhotoView: View {
    @ObservedObject var viewModel: ContentListViewModel
    @State var image : UIImage?
    
    var body: some View {
        ZStack{
            if viewModel.showImagePreview {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            viewModel.showImagePreview = false
                        }
//                        viewModel.showImagePreview = false
                        image = nil
                    }
            }
            
            if viewModel.showImagePreview {
                HStack() {
                    if let image = image {
                        Button(action: {
                            self.image = nil
                            viewModel.pickImage(which: .previous)
                        }){
                            Image(systemName: "chevron.left.circle.fill")
                        }
                        .disabled(!viewModel.isPrevImageAvailable)
                        .foregroundStyle(Color.white.opacity(viewModel.isPrevImageAvailable ? 100 : 0))
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                        
                        Button(action: {
                            viewModel.pickImage(which: .next)
                            self.image = nil
                        }){
                            Image(systemName: "chevron.right.circle.fill")
                        }
                        .disabled(!viewModel.isNextImageAvailable)
                        .foregroundStyle(Color.white.opacity(viewModel.isNextImageAvailable ? 1000 : 0))
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 25)
                .task(id: viewModel.pickedImageId) {
                    image = await viewModel.getPickedImage()
                }

            }
            
        }
    }
}

#Preview {
    PreviewPhotoView(viewModel: ContentListViewModel(user: User()))
}
