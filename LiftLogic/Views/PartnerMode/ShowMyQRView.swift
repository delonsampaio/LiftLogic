import SwiftUI

struct ShowMyQRView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    private var qrImage: UIImage? {
        guard let encoded = PartnerCodeService.encode(
            weight: vm.targetWeight,
            barType: vm.selectedBar,
            collarType: vm.collarType,
            unit: settings.unit,
            isSingleSided: vm.isSingleSided
        ) else { return nil }
        return QRCodeService.generateImage(from: encoded)
    }

    var body: some View {
        VStack(spacing: 20) {
            if vm.targetWeight == 0 {
                Text("Enter a weight in CALC mode first")
                    .font(.subheadline)
                    .foregroundStyle(ThemeTokens.textMuted)
            } else if let qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260, height: 260)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("\(vm.targetWeight.weightString) \(settings.unit.symbol) · \(vm.selectedBar.displayName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeTokens.textPrimary)
            } else {
                Text("Couldn't generate a QR code")
                    .font(.subheadline)
                    .foregroundStyle(ThemeTokens.textMuted)
            }
            Spacer()
        }
        .padding(.top, 40)
        .padding()
        .background(ThemeTokens.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Show My QR Code")
        .navigationBarTitleDisplayMode(.inline)
    }
}
