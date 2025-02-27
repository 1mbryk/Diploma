//
//  SwiftUIView.swift
//  MVVM-Test
//
//  Created by Mацвей Пажытных on 6.02.25.
//

import SwiftUI
import PhotosUI

struct SwiftUIView: View {
    @State private var avatarItem: PhotosPickerItem?
       @State private var avatarImage: Image?

       var body: some View {
           VStack {
               PhotosPicker("Select avatar", selection: $avatarItem, matching: .images)

               avatarImage?
                   .resizable()
                   .scaledToFit()
                   .frame(width: 300, height: 300)
           }
           .onChange(of: avatarItem) {
               Task {
                   if let loaded = try? await avatarItem?.loadTransferable(type: Image.self) {
                       avatarImage = loaded
                   } else {
                       print("Failed")
                   }
               }
           }
       }
}

#Preview {
    SwiftUIView()
}
