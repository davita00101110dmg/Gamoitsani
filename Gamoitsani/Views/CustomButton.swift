//
//  CustomButton.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 07.07.23.
//

import SwiftUI

struct CustomButton: View {
    var title: String
    
    var body: some View {
        Button(action: {

        }, label: {
            Text(title)
                .font(.custom("BPGNinoMtavruli-Bold", size: 22))
                .foregroundColor(.white)
                .padding()
                .frame(width: 290, height: 40)
                .background(Color("Secondary")).cornerRadius(15)
        
        })
    }
}

struct Button_Previews: PreviewProvider {
    static var previews: some View {
        CustomButton(title: "ღილაკი")
    }
}
