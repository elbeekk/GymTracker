import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            AppTheme.gymBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(AppTheme.gymText)
                    Text("Gymo")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.gymSubtext)
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 28)

                // AI Coach status card
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.gymGreen.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20))
                            .foregroundStyle(AppTheme.gymGreen)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Claude AI Coach")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.gymText)
                        Text("Cloud coaching runs when a Claude key is configured")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.gymSubtext)
                    }
                    Spacer()
                    Circle()
                        .fill(AppTheme.gymGreen)
                        .frame(width: 8, height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppTheme.gymSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                // How it works
                VStack(alignment: .leading, spacing: 12) {
                    Text("How it works")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.gymSubtext)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .padding(.horizontal, 20)

                    VStack(spacing: 1) {
                        HowItWorksRow(number: "1", text: "Pick an exercise from the Workout tab")
                        Divider().background(AppTheme.gymBorder).padding(.horizontal, 20)
                        HowItWorksRow(number: "2", text: "Stand in front of the camera and start")
                        Divider().background(AppTheme.gymBorder).padding(.horizontal, 20)
                        HowItWorksRow(number: "3", text: "The coach speaks live corrections from pose analysis")
                    }
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

private struct HowItWorksRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Text(number)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.gymAccent)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.gymText)
            Spacer()
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 20)
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
