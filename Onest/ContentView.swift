//
//  ContentView.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct ContentView: View {
    @State private var isAuthenticated: Bool = AuthService.shared.isAuthenticated

    public init() {}

    public var body: some View {
        Group {
            if isAuthenticated {
                HomeView()
                    .transition(.opacity)
            } else {
                LoginView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isAuthenticated = true
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isAuthenticated)
        .onReceive(NotificationCenter.default.publisher(for: .sessionDidExpire)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isAuthenticated = false
            }
        }
        .onAppear {
            isAuthenticated = AuthService.shared.isAuthenticated
        }
    }
}

#Preview {
    ContentView()
}
