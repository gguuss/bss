import SwiftUI
import AppKit

public struct FirstRunWizardView: View {
    @ObservedObject var permissions = PermissionsManager.shared
    @State private var testSuccessMessage: String?
    public var onComplete: (() -> Void)?

    public init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 16) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 44))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Better Screen Shot")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Let's configure your Mac permissions so you can capture windows directly to your clipboard.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 10)

            Divider()

            // Permission Items
            VStack(spacing: 16) {
                // Screen Recording Permission
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: permissions.hasScreenRecordingPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundColor(permissions.hasScreenRecordingPermission ? .green : .orange)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Screen Recording Permission (Required)")
                            .font(.headline)
                        Text("Allows Better Screen Shot to capture window and desktop pixels.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if permissions.hasScreenRecordingPermission {
                        Text("Granted")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                    } else {
                        Button("Open Settings") {
                            permissions.requestScreenRecordingPermission()
                            permissions.openScreenRecordingSettings()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // Accessibility Permission
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: permissions.hasAccessibilityPermission ? "checkmark.circle.fill" : "info.circle.fill")
                        .font(.title3)
                        .foregroundColor(permissions.hasAccessibilityPermission ? .green : .blue)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Accessibility Permission (Recommended)")
                            .font(.headline)
                        Text("Allows precise cursor tracking and window detection across spaces.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if permissions.hasAccessibilityPermission {
                        Text("Granted")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                    } else {
                        Button("Open Settings") {
                            permissions.requestAccessibilityPermission()
                            permissions.openAccessibilitySettings()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }

            // Test Capture Action
            VStack(spacing: 8) {
                Button(action: {
                    let success = CaptureEngine.shared.captureDisplayToClipboard()
                    if success {
                        testSuccessMessage = "Screenshot copied to clipboard! Try pressing ⌘V in any chat."
                    } else {
                        testSuccessMessage = "Capture failed. Please check permissions in System Settings."
                    }
                }) {
                    Label("Test Screenshot (Copy to Clipboard)", systemImage: "camera.fill")
                }
                .buttonStyle(.bordered)

                if let message = testSuccessMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .transition(.opacity)
                }
            }

            Spacer()

            Divider()

            // Footer
            HStack {
                Button("Refresh Status") {
                    _ = permissions.refreshPermissions()
                }

                Spacer()

                Button("Get Started") {
                    UserDefaults.standard.set(true, forKey: "hasCompletedFirstRunWizard")
                    onComplete?()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!permissions.hasScreenRecordingPermission)
            }
        }
        .padding(24)
        .frame(width: 540, height: 480)
        .onAppear {
            _ = permissions.refreshPermissions()
        }
    }
}
