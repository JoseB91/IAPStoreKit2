//
//  ContentView.swift
//  IAPStoreKit2
//
//  Created by José Briones on 13/5/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var storeManager: StoreManager
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            ForEach(storeManager.products) { product in
                HStack {
                    VStack(alignment: .leading) {
                        Text(product.displayName)
                            .font(.headline)
                        Text(product.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if storeManager.isPurchased(product.id) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    } else {
                        Button(action: {
                            Task {
                                isPurchasing = true
                                do {
                                    _ = try await storeManager.purchase(product)
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                                isPurchasing = false
                            }
                        }) {
                            Text(product.formattedPrice)
                                .bold()
                                .padding(8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(isPurchasing)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .alert("Purchase Error", isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let message = errorMessage {
                Text(message)
            }
        }
    }
}

//#Preview {
//    ContentView()
//}

