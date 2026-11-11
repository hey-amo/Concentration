//
//  TitleScreenView.swift
//  Concentration
//

import SwiftUI

struct TitleScreenView: View {
    var body: some View {
        ZStack {
            Color("LaunchBackground").ignoresSafeArea()
            Image("launch-screen-iOS16")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            Text("Concentration")
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("Version 1.0")
            Text("Author: Amo")
        }
    }
}
