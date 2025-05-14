//
//  IAPStoreKit2App.swift
//  IAPStoreKit2
//
//  Created by José Briones on 13/5/25.
//

import SwiftUI

@main
struct IAPStoreKit2App: App {
    @StateObject private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentView(storeManager: storeManager)
        }
    }
}
