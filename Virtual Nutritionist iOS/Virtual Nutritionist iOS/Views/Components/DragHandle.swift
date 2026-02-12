//
//  DragHandle.swift
//  Virtual Nutritionist iOS
//
//  Standard iOS bottom sheet drag handle indicator
//

import SwiftUI

struct DragHandle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 40, height: 5)
            .padding(.top, 8)
    }
}

#Preview {
    DragHandle()
        .padding()
        .background(Color(.systemBackground))
}
