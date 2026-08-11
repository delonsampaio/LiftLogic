import SwiftUI
import VisionKit

private struct ScannedSetupRef: Identifiable {
    let id = UUID()
    let payload: PartnerSetupPayload
}

struct ScanPartnerView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings
    /// Called after a scanned setup is confirmed and applied. The caller
    /// (LiftingPartnerView, via MainView) closes the ENTIRE Lifting Partner
    /// flow here — not just this screen — since the user's goal is to see
    /// their newly-loaded weight on the main CALC screen immediately, and
    /// this view sits three presentation layers deep (fullScreenCover > pushed
    /// NavigationLink > sheet), where a plain dismiss() would only pop one.
    let onSetupLoaded: () -> Void

    @State private var cameraStatus: CameraPermissionStatus = CameraPermissionService.currentStatus()
    @State private var scannedItem: ScannedSetupRef?

    var body: some View {
        Group {
            if !DataScannerViewController.isSupported {
                Text("Live scanning isn't available on this device.")
                    .font(.subheadline)
                    .foregroundStyle(ThemeTokens.textMuted)
                    .padding()
            } else {
                switch cameraStatus {
                case .authorized:
                    if DataScannerViewController.isAvailable {
                        QRScannerView { rawString in
                            if let payload = PartnerCodeService.decode(rawString) {
                                scannedItem = ScannedSetupRef(payload: payload)
                            }
                        }
                        .ignoresSafeArea()
                    } else {
                        Text("Live scanning isn't available right now.")
                            .font(.subheadline)
                            .foregroundStyle(ThemeTokens.textMuted)
                            .padding()
                    }
                case .denied:
                    deniedMessage
                case .notDetermined:
                    Color.clear
                        .task {
                            let granted = await CameraPermissionService.requestAccess()
                            cameraStatus = granted ? .authorized : .denied
                        }
                }
            }
        }
        .navigationTitle("Scan Partner's Code")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $scannedItem) { ref in
            PartnerScanConfirmationView(payload: ref.payload, accentColor: settings.accentColor) {
                apply(ref.payload)
                scannedItem = nil
                onSetupLoaded()
            }
        }
    }

    private func apply(_ payload: PartnerSetupPayload) {
        vm.applyConfiguration(weight: payload.weight, barType: payload.barType,
                               customBarWeight: payload.customBarWeight, collarType: payload.collarType,
                               unit: payload.unit, isSingleSided: payload.isSingleSided)
    }

    private var deniedMessage: some View {
        VStack(spacing: 16) {
            Text("Camera access is required to scan a partner's code.")
                .font(.subheadline)
                .foregroundStyle(ThemeTokens.textMuted)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundStyle(settings.accentColor)
        }
        .padding()
    }
}
