//
//  SwiftyYTDLApp.swift
//  SwiftyYTDL
//
//  Created by Danylo Kostyshyn on 20.07.2022.
//

import SwiftUI

@main
struct SwiftyYTDLApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(viewModel: ContentViewModel())
            }.navigationViewStyle(.stack)
        }
    }
}
