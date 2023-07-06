//
//  ContentView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 06.07.23.
//

import SwiftUI

struct MainView: View {
    var body: some View {
            VStack {
                Text("გამოიცანი")
                    .font(.custom("BPGNinoMtavruli-Bold", size: 44))
                    .foregroundColor(.white)
                    .padding(.top, 100)
                
                
                Text("🪄")
                    .font(.custom("", size: 100))
                    .blendMode(.luminosity)
                    .padding(.top, 50)
                
                Spacer()
                
                Group {
                    CustomButton(title: "თამაში")
                    CustomButton(title: "წესები")
                    CustomButton(title: "პარამეტრები")
                }.padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("Primary"))
        }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
