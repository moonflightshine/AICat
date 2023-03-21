//
//  AICatApp.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import SwiftUI
import Blackbird
import Foundation

let dbPath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/db.sqlite"

@main
struct AICatApp: App {

    var database = try! Blackbird.Database(path: dbPath, options: .debugPrintEveryQuery)

    @AppStorage("openApiKey")
    var apiKey: String?

    var body: some Scene {
        WindowGroup {
            if apiKey != nil {
                ContentView()
                    .environment(\.blackbirdDatabase, database)
                    .font(.custom("Avenir Next", size: 16))
            } else {
                AddApiKeyView(onValidateSuccess: {})
                    .font(.custom("Avenir Next", size: 16))
            }
        }
    }
}
