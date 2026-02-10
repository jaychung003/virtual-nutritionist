//
//  AuthContainerView.swift
//  Virtual Nutritionist iOS
//
//  Container view for authentication flow with login/signup toggle.
//

import SwiftUI

struct AuthContainerView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Auth Mode", selection: $selectedTab) {
                    Text("Sign In").tag(0)
                    Text("Sign Up").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                TabView(selection: $selectedTab) {
                    LoginView()
                        .tag(0)

                    SignupView()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Diet Watch")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AuthContainerView()
        .environmentObject(AuthViewModel())
}
