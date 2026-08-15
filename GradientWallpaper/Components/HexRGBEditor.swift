import SwiftUI

/// Precise numeric color entry: a HEX text field plus RGB and HSB sliders,
/// kept in sync with the bound `CodableColor`.
struct HexRGBEditor: View {
    @Binding var color: CodableColor
    var onCommit: () -> Void

    @State private var hexText: String = ""
    @State private var mode: Mode = .rgb

    enum Mode: String, CaseIterable { case rgb = "RGB", hsb = "HSB" }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("#").foregroundStyle(.secondary)
                TextField("RRGGBB", text: $hexText)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .onSubmit { commitHex() }
                Button("Apply") { commitHex() }
                    .buttonStyle(.bordered)
            }

            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if mode == .rgb {
                rgbSliders
            } else {
                hsbSliders
            }
        }
        .onAppear { hexText = color.hexString }
        .onChange(of: color.hexString) { _, newValue in hexText = newValue }
    }

    private var rgbSliders: some View {
        VStack(spacing: 8) {
            componentSlider("R", value: Binding(get: { color.red }, set: { color.red = $0 }))
            componentSlider("G", value: Binding(get: { color.green }, set: { color.green = $0 }))
            componentSlider("B", value: Binding(get: { color.blue }, set: { color.blue = $0 }))
        }
    }

    private var hsbSliders: some View {
        let hsb = color.hsb
        return VStack(spacing: 8) {
            componentSlider("H", value: Binding(
                get: { hsb.h },
                set: { newH in color = CodableColor.fromHSB(h: newH, s: hsb.s, b: hsb.b, alpha: color.alpha) }
            ))
            componentSlider("S", value: Binding(
                get: { hsb.s },
                set: { newS in color = CodableColor.fromHSB(h: hsb.h, s: newS, b: hsb.b, alpha: color.alpha) }
            ))
            componentSlider("B", value: Binding(
                get: { hsb.b },
                set: { newB in color = CodableColor.fromHSB(h: hsb.h, s: hsb.s, b: newB, alpha: color.alpha) }
            ))
        }
    }

    private func componentSlider(_ label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label).font(.caption.monospaced()).frame(width: 14)
            Slider(value: value, in: 0...1) { editing in
                if !editing { onCommit() }
            }
            Text("\(Int((value.wrappedValue * 255).rounded()))")
                .font(.caption.monospacedDigit())
                .frame(width: 32, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }

    private func commitHex() {
        if let parsed = CodableColor.fromHex(hexText) {
            color = CodableColor(red: parsed.red, green: parsed.green, blue: parsed.blue, alpha: color.alpha)
            onCommit()
        }
        hexText = color.hexString
    }
}
