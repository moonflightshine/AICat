//
//  View+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/22.
//

import SwiftUI

extension View {

    func endEditing(force: Bool) {
        UIApplication.shared.windows.forEach { $0.endEditing(force) }
    }
}
