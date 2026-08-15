import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: WallpaperEditorViewModel

    var body: some View {
        ScrollView {
            PanelHeader(title: "Settings")

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appearance").font(.subheadline.weight(.semibold))
                    Picker("Appearance", selection: appearanceBinding) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Export Format").font(.subheadline.weight(.semibold))
                    Picker("Format", selection: formatBinding) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if vm.settings.defaultExportFormat == .jpeg {
                    LabeledSlider(
                        title: "Default JPEG Quality",
                        value: jpegQualityBinding,
                        range: 0.3...1.0,
                        format: "%.0f%%"
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Canvas Size").font(.subheadline.weight(.semibold))
                    Menu {
                        ForEach(CanvasSize.presets) { size in
                            Button(size.name) {
                                var s = vm.settings
                                s.defaultCanvasSizeName = size.name
                                vm.updateSettings(s)
                            }
                        }
                    } label: {
                        HStack {
                            Text(vm.settings.defaultCanvasSizeName)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(uiColor: .tertiarySystemFill)))
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("About").font(.subheadline.weight(.semibold))
                    Text("Gradient Studio builds every wallpaper from a Core Graphics render pipeline, so exports always match the live preview pixel-for-pixel.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private var appearanceBinding: Binding<String> {
        Binding(
            get: { vm.settings.preferredColorScheme },
            set: { newValue in
                var s = vm.settings
                s.preferredColorScheme = newValue
                vm.updateSettings(s)
            }
        )
    }

    private var formatBinding: Binding<ExportFormat> {
        Binding(
            get: { vm.settings.defaultExportFormat },
            set: { newValue in
                var s = vm.settings
                s.defaultExportFormat = newValue
                vm.updateSettings(s)
            }
        )
    }

    private var jpegQualityBinding: Binding<Double> {
        Binding(
            get: { vm.settings.defaultJPEGQuality },
            set: { newValue in
                var s = vm.settings
                s.defaultJPEGQuality = newValue
                vm.updateSettings(s)
            }
        )
    }
}
