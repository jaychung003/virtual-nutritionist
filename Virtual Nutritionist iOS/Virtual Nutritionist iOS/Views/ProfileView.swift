import SwiftUI

/// View for managing user's dietary protocol selections
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfile: UserProfile
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                        
                        Text("Your Dietary Protocols")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Select the dietary protocols you follow. Menu items will be analyzed against all selected protocols.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Protocol cards
                    VStack(spacing: 16) {
                        ForEach(DietaryProtocol.allProtocols) { dietProtocol in
                            ProtocolCard(
                                dietProtocol: dietProtocol,
                                isSelected: userProfile.isProtocolSelected(dietProtocol.id),
                                onToggle: {
                                    withAnimation(.spring(response: 0.3)) {
                                        userProfile.toggleProtocol(dietProtocol.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Info section
                    InfoBox()
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

/// Card view for displaying a dietary protocol option
struct ProtocolCard: View {
    let dietProtocol: DietaryProtocol
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.green : Color(.systemGray5))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: dietProtocol.icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? .white : .secondary)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(dietProtocol.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        // Checkmark
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(isSelected ? .green : .secondary)
                    }
                    
                    Text(dietProtocol.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Information box about the app's analysis approach
struct InfoBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text("How It Works")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "camera.fill", text: "Take a photo of any restaurant menu")
                InfoRow(icon: "brain", text: "AI analyzes menu items and infers ingredients")
                InfoRow(icon: "checkmark.shield.fill", text: "Items are rated based on your protocols")
                InfoRow(icon: "exclamationmark.triangle.fill", text: "When uncertain, items are flagged as caution")
            }
            
            Text("Always verify with restaurant staff for items with potential triggers.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(16)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserProfile())
}
