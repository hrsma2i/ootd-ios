//
//  FloatingActionButton.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/30.
//

import SwiftUI

struct FloatingActionButton: View {
    let systemName: String
    var action: () -> Void = {}

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    Image(systemName: systemName)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                }
                .padding()
            }
        }
    }
}

#Preview {
    FloatingActionButton(systemName: "pencil")
}
