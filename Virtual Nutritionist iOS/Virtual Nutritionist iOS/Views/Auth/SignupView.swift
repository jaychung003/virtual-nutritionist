//
//  SignupView.swift
//  Virtual Nutritionist iOS
//
//  Signup screen for new user registration.
//

import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var confirmPasswordError: String?

    var body: some View {
        VStack(spacing: 20) {
            // Title
            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Sign up to get started")
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
                    .onChange(of: email) { _, _ in
                        emailError = nil
                    }

                if let emailError = emailError {
                    Text(emailError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    if showPassword {
                        TextField("Enter your password", text: $password)
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Enter your password", text: $password)
                            .textContentType(.newPassword)
                    }

                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .onChange(of: password) { _, _ in
                    passwordError = nil
                }

                if let passwordError = passwordError {
                    Text(passwordError)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Text("At least 8 characters with a letter and number")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Confirm password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    if showConfirmPassword {
                        TextField("Confirm your password", text: $confirmPassword)
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Confirm your password", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }

                    Button(action: { showConfirmPassword.toggle() }) {
                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .onChange(of: confirmPassword) { _, _ in
                    confirmPasswordError = nil
                }

                if let confirmPasswordError = confirmPasswordError {
                    Text(confirmPasswordError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Error message from API
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            // Sign up button
            Button(action: {
                // Validate inputs
                emailError = authViewModel.validateEmail(email)
                passwordError = authViewModel.validatePassword(password)
                confirmPasswordError = authViewModel.validatePasswordMatch(password, confirmPassword)

                // Proceed if no errors
                if emailError == nil && passwordError == nil && confirmPasswordError == nil {
                    Task {
                        await authViewModel.register(email: email, password: password)
                    }
                }
            }) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign Up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
            .padding(.top, 10)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthViewModel())
}
