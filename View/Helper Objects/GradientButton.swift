//
//  GradientButton.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2024-12-15.
//

import SwiftUI

struct GradientButton: View {
    var title: String
    var icon: String
    var onClick: () -> ()
    var body: some View {
        Button (action: onClick, label: {
            HStack(spacing: 15) {
                Text(title)
                Image(systemName: icon)
            }
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 35)
            .background(.linearGradient(colors: [Color(UIColor(hex: "primary")), Color(UIColor(hex: "primary")).opacity(0.7)], startPoint: .top, endPoint: .bottom), in: .capsule)
        })
    }
}
