//
//  GMTextFieldView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 20/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI
import Combine

struct GMTextFieldView: View {
    @Binding var text: String
    var placeholder: String
    
    let textLimit: Int
    
    var body: some View {
        TextField(String.empty, text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.7)))
            .foregroundColor(.white)
            .font(F.Mersad.bold.swiftUIFont(size: Constants.fontSize))
            .frame(height: Constants.height)
            .textFieldStyle(RoundedTextFieldStyle())
            .onReceive(Just(text)) { _ in limitText(textLimit) }
    }
    
    func limitText(_ upper: Int) {
        if text.count > upper {
            text = String(text.prefix(upper))
        }
    }
}

extension GMTextFieldView {
    enum Constants {
        static let height: CGFloat = 44
        static let fontSize: CGFloat = 18
    }
}

struct GMTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            GMTextFieldView(text: .constant(""), placeholder: "Left Padding", textLimit: 10)
            GMTextFieldView(text: .constant(""), placeholder: "Right Padding", textLimit: 10)
            GMTextFieldView(text: .constant(""), placeholder: "Equal Padding", textLimit: 10)
        }
        .padding()
        .background(Color.gray)
    }
}


