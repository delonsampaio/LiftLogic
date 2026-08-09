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
    /// this view sits two presentation layers deep (fullScreenCover > pushed
    /// NavigationLink > sheet), where a plain dismiss() would only pop one.
    let onSetupLoaded: () -> Void

    @State private var cameraStatus: CameraPermissionStatus = CameraPermissionService.currentStatus()
    @State private var scannedItem: ScannedSetupRef?

    private var scannerAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        Group {
            if !scannerAvailable {
                Text("Live scanning isn't available on this device.")
                    .font(.subheadline)
                    .foregroundStyle(ThemeTokens.textMuted)
                    .padding()
            } else {
                switch cameraStatus {
                case .authorized:
                    QRScannerView { rawString in
                        if let payload = PartnerCodeService.decode(rawString) {
                            scannedItem = ScannedSetupRef(payload: payload)
                        }
                    }
                    .ignoresSafeArea()
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
            PartnerScanConfirmationView(payload: ref.payload) {
                apply(ref.payload)
                onSetupLoaded()
            }
        }
    }

    private func apply(_ payload: PartnerSetupPayload) {
        vm.selectedBar = payload.barType
        vm.collarType = payload.collarType
        vm.isSingleSided = payload.isSingleSided
        settings.unit = payload.unit
        vm.loadWeight(payload.weight)
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
            .foregroundStyle(ThemeTokens.accent)
        }
        .padding()
    }
}
