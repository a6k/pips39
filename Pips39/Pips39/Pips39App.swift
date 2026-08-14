//
//  Pips39App.swift
//  Pips39
//
//  Created by develop on 13.08.26.
//

import SwiftUI

@main
struct Pips39App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Erzwungen dunkel, damit `.primary` weiß wird, `.secondary` hell
                // grau und die Symbole der Statusleiste hell. Ohne das stünde auf
                // dem violetten Grund schwarzer Text.
                .preferredColorScheme(.dark)
                .tint(.white)
        }
    }
}
