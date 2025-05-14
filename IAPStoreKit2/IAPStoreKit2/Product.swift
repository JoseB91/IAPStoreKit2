//
//  Product.swift
//  IAPStoreKit2
//
//  Created by José Briones on 13/5/25.
//

import Foundation
import StoreKit

struct Product: Identifiable {
    let id: String
    let displayName: String
    let description: String
    let price: Decimal
    let storeKitProduct: StoreKit.Product
    
    var formattedPrice: String {
        storeKitProduct.displayPrice
    }
}
