import SwiftUI

struct PreviewPhotoView: View {
    @ObservedObject var viewModel: ContentListViewModel
    @State private var image: UIImage?
    @State private var transitionDirection = 0.0
    @State private var showProgressBar = true
    @State private var isTransitionEnabled = false

    var body: some View {
        ZStack {
            if viewModel.showImagePreview {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            viewModel.showImagePreview = false
                        }
                    }
            }

            if viewModel.showImagePreview {
                HStack {
                    if !showProgressBar, let image = image {
                        Button(action: {
                            if viewModel.isPrevImageAvailable {
                                transitionDirection = -1.0
                                isTransitionEnabled = true
                                viewModel.pickImage(which: .previous)
                                loadImage()
                            }
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                        }
                        .disabled(!viewModel.isPrevImageAvailable)
                        .foregroundStyle(Color.white.opacity(viewModel.isPrevImageAvailable ? 1 : 0))

                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .transition(isTransitionEnabled ?
                                .asymmetric(
                                    insertion: .move(edge: transitionDirection < 0 ? .leading : .trailing),//.combined(with: .opacity),
                                    removal: .move(edge: transitionDirection > 0 ? .trailing : .leading)//.combined(with: .opacity)
                                ) : .identity
                            )
                            .id(viewModel.pickedImageId)

                        Button(action: {
                            if viewModel.isNextImageAvailable {
                                transitionDirection = 1.0
                                isTransitionEnabled = true
                                viewModel.pickImage(which: .next)
                                loadImage()
                            }
                        }) {
                            Image(systemName: "chevron.right.circle.fill")
                        }
                        .disabled(!viewModel.isNextImageAvailable)
                        .foregroundStyle(Color.white.opacity(viewModel.isNextImageAvailable ? 1 : 0))
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 25)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    let translation = gesture.translation

                    guard abs(translation.width) > abs(translation.height),
                          abs(translation.width) > 50 else { return }

                    if translation.width < 0 {
                        if viewModel.isNextImageAvailable {
                            transitionDirection = 1.0
                            isTransitionEnabled = true
                            viewModel.pickImage(which: .next)
                            loadImage()
                        }
                    } else {
                        if viewModel.isPrevImageAvailable {
                            transitionDirection = -1.0
                            isTransitionEnabled = true
                            viewModel.pickImage(which: .previous)
                            loadImage()
                        }
                    }
                }
        )
        .onChange(of: viewModel.showImagePreview) {
            // При первом открытии — без перехода
            isTransitionEnabled = false
            loadImage()
        }
    }

    func loadImage() {
        Task {
            showProgressBar = true
            let image = await viewModel.getPickedImage()
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.image = image
                    self.showProgressBar = false
                }
            }
        }
    }
}


#Preview {
    PreviewPhotoView(viewModel: ContentListViewModel(user: User()))
}
