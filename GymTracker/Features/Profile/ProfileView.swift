import SwiftUI

struct ProfileView: View {
    @State private var apiKey = ""
    @State private var hasStoredKey = false
    @State private var statusMessage = "Paste your Claude API key to enable live Anthropic coaching."
    @State private var statusColor = AppTheme.gymSubtext

    private let keychain = AnthropicKeychainStore()

    var body: some View {
        ZStack {
            AppTheme.gymBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Profile")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.gymText)

                    Text("Claude Coach")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.gymSubtext)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Anthropic API Key")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.gymText)

                    SecureField("sk-ant-api...", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundStyle(AppTheme.gymText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(AppTheme.gymCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text(hasStoredKey ? "Claude key is saved in Keychain on this device." : "No Claude key saved yet.")
                        .font(.system(size: 13))
                        .foregroundStyle(statusColor)

                    Text(statusMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.gymSubtext)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    Button(action: saveKey) {
                        Text("Save Claude Key")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.gymText)
                            .foregroundStyle(AppTheme.gymBg)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: removeKey) {
                        Text("Remove")
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.gymCard)
                            .foregroundStyle(AppTheme.gymText)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("How it works")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.gymText)

                    Text("1. Save your Claude key here once.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.gymSubtext)

                    Text("2. Open any exercise tracker.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.gymSubtext)

                    Text("3. The tracking screen will show Claude status and speak the correction.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.gymSubtext)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 110)
        }
        .navigationBarHidden(true)
        .onAppear(perform: loadState)
    }

    private func loadState() {
        let storedKey = keychain.load()
        hasStoredKey = storedKey?.isEmpty == false
        apiKey = ""
        statusMessage = hasStoredKey
            ? "Claude is configured for future tracking sessions."
            : "Paste your Claude API key to enable live Anthropic coaching."
        statusColor = hasStoredKey ? AppTheme.success : AppTheme.gymSubtext
    }

    private func saveKey() {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "Paste a valid Claude API key first."
            statusColor = AppTheme.danger
            return
        }

        if keychain.save(apiKey) {
            hasStoredKey = true
            apiKey = ""
            statusMessage = "Claude key saved. Reopen tracking to use Anthropic."
            statusColor = AppTheme.success
        } else {
            statusMessage = "Could not save the Claude key."
            statusColor = AppTheme.danger
        }
    }

    private func removeKey() {
        if keychain.delete() {
            hasStoredKey = false
            apiKey = ""
            statusMessage = "Claude key removed."
            statusColor = AppTheme.warning
        } else {
            statusMessage = "Could not remove the Claude key."
            statusColor = AppTheme.danger
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
