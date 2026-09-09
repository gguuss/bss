import SwiftUI
import AppKit

public struct FirstRunWizardView: View {
    @ObservedObject var permissions = PermissionsManager.shared
    @State private var testSuccessMessage: String?
    @State private var isTestingCapture = false
    public var onComplete: (() -> Void)?

    public init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 18) {
            // Header
            HStack(spacing: 16) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Better Screen Shot")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Configure your Mac permissions to enable instant window and display capture.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 6)

            Divider()

            // Permission Items
            VStack(spacing: 14) {
                // 1. Screen Recording Permission
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
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.12))
                            .cornerRadius(6)
                    } else {
                        HStack(spacing: 8) {
                            Button("Open Settings") {
                                permissions.requestScreenRecordingPermission()
                                permissions.openScreenRecordingSettings()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Relaunch App") {
                                permissions.relaunchApp()
                            }
                            .buttonStyle(.bordered)
                            .help("macOS requires restarting the app after enabling Screen Recording in System Settings.")
                        }
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // 2. Accessibility Permission (Optional)
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: permissions.hasAccessibilityPermission ? "checkmark.circle.fill" : "info.circle.fill")
                        .font(.title3)
                        .foregroundColor(permissions.hasAccessibilityPermission ? .green : .secondary)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Accessibility Permission (Optional)")
                            .font(.headline)
                        Text("Enhances multi-space window inspection. Not required for basic screen capture.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if permissions.hasAccessibilityPermission {
                        Text("Granted")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.12))
                            .cornerRadius(6)
                    } else {
                        Button("Open Settings") {
                            permissions.requestAccessibilityPermission()
                            permissions.openAccessibilitySettings()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }

            // Test Capture Action
            VStack(spacing: 6) {
                Button(action: {
                    guard !isTestingCapture else { return }
                    isTestingCapture = true
                    Task { @MainActor in
                        let success = await CaptureEngine.shared.captureDisplayToClipboard()
                        if success {
                            testSuccessMessage = "✓ Screenshot copied to clipboard! Press ⌘V to paste."
                            await permissions.verifyScreenRecordingAccess()
                            _ = permissions.refreshPermissions()
                        } else {
                            testSuccessMessage = "Capture failed. If you just toggled Settings, click 'Relaunch App' to apply."
                        }
                        isTestingCapture = false
                    }
                }) {
                    Label(
                        isTestingCapture ? "Capturing..." : "Test Screenshot (Copy to Clipboard)",
                        systemImage: isTestingCapture ? "hourglass" : "camera.fill"
                    )
                }
                .buttonStyle(.bordered)
                .disabled(isTestingCapture)

                if let message = testSuccessMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(testSuccessMessage?.starts(with: "✓") == true ? .green : .orange)
                        .transition(.opacity)
                }
            }

            Spacer()

            Divider()

            // Footer
            HStack {
                Button("Refresh") {
                    Task { @MainActor in
                        await permissions.verifyScreenRecordingAccess()
                        _ = permissions.refreshPermissions()
                    }
                }

                Spacer()

                Button(permissions.hasScreenRecordingPermission ? "Get Started" : "Continue to Menu Bar") {
                    UserDefaults.standard.set(true, forKey: "hasCompletedFirstRunWizard")
                    onComplete?()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(width: 560, height: 500)
        .onAppear {
            _ = permissions.refreshPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            _ = permissions.refreshPermissions()
        }
    }
}
