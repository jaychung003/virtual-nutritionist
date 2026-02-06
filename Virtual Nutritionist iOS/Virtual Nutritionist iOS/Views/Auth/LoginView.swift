//
//  LoginView.swift
//  Virtual Nutritionist iOS
//
//  Login screen for authentication.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        VStack(spacing: 20) {
            // Title
            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Sign in to your account")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 20)

            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)

                TextField("Enter your email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }

            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    if showPassword {
                        TextField("Enter your password", text: $password)
                            .textContentType(.password)
                    } else {
                        SecureField("Enter your password", text: $password)
                            .textContentType(.password)
                    }

                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .textFieldStyle(.roundedBorder)
            }

            // Error message
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            // Login button
            Button(action: {
                Task {
                    await authViewModel.login(email: email, password: password)
                }
            }) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
            .padding(.top, 10)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
