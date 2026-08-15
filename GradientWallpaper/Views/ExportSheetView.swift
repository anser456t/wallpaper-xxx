import SwiftUI

struct ExportSheetView: View {
    @EnvironmentObject var vm: WallpaperEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSize: CanvasSize
    @State private var useCustomSize = false
    @State private var customWidth: String = "2048"
    @State private var customHeight: String = "2732"
    @State private var format: ExportFormat
    @State private var jpegQuality: Double
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    @State private var exportError: String?
    @State private var savedToast = false

    init() {
        _selectedSize = State(initialValue: .ipadPortrait)
        _format = State(initialValue: .png)
        _jpegQuality = State(initialValue: 0.9)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Resolution") {
                    Toggle("Use Custom Resolution", isOn: $useCustomSize)
                    if useCustomSize {
                        HStack {
                            TextField("Width", text: $customWidth)
                                .keyboardType(.numberPad)
                            Text("×")
                            TextField("Height", text: $customHeight)
                                .keyboardType(.numberPad)
                        }
                    } else {
                        Picker("Preset", selection: $selectedSize) {
                            ForEach(CanvasSize.presets) { size in
                                Text("\(size.name) (\(size.width)×\(size.height))").tag(size)
                            }
                        }
                    }
                    Button("Use Maximum Available Resolution") {
                        useCustomSize = true
                        customWidth = "8192"
                        customHeight = String(Int(8192 / vm.project.canvasSize.aspectRatio))
                    }
                    .font(.footnote)
                }

                Section("Format") {
                    Picker("Format", selection: $format) {
                        ForEach(ExportFormat.allCases) { f in
                            Text(f.displayName).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)

                    if format == .jpeg {
                        LabeledSlider(title: "Quality", value: $jpegQuality, range: 0.3...1.0, format: "%.0f%%")
                    }
                    if format == .png {
                        Text("PNG export preserves transparency where the wallpaper includes any (e.g. glass or blur effects over a transparent base).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        performExport()
                    } label: {
                        if isExporting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Export Wallpaper", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isExporting)

                    Button {
                        saveDirectlyToPhotos()
                    } label: {
                        Label("Save to Photos", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isExporting)
                }

                if savedToast {
                    Section {
                        Label("Saved to Photos", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                if let exportError {
                    Section {
                        Text(exportError).foregroundStyle(.red).font(.footnote)
                    }
                }
            }
            .navigationTitle("Export")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                selectedSize = vm.project.canvasSize
                format = vm.settings.defaultExportFormat
                jpegQuality = vm.settings.defaultJPEGQuality
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private var resolvedResolution: CGSize {
        if useCustomSize, let w = Int(customWidth), let h = Int(customHeight), w > 0, h > 0 {
            return CGSize(width: w, height: h)
        }
        return selectedSize.pixelSize
    }

    private func performExport() {
        isExporting = true
        exportError = nil
        let project = vm.project
        let resolution = resolvedResolution
        let fmt = format
        let quality = jpegQuality

        Task.detached(priority: .userInitiated) {
            do {
                let url = try ExportService.shared.export(project: project, resolution: resolution, format: fmt, jpegQuality: quality)
                await MainActor.run {
                    self.exportedFileURL = url
                    self.isExporting = false
                    self.showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    self.exportError = error.localizedDescription
                    self.isExporting = false
                }
            }
        }
    }

    private func saveDirectlyToPhotos() {
        isExporting = true
        exportError = nil
        ExportService.shared.saveToPhotos(project: vm.project, resolution: resolvedResolution) { result in
            DispatchQueue.main.async {
                isExporting = false
                switch result {
                case .success:
                    savedToast = true
                case .failure(let error):
                    exportError = error.localizedDescription
                }
            }
        }
    }
}

/// Wraps `UIActivityViewController` so the export sheet can present the
/// native iPad share sheet (Save to Photos, Save to Files, AirDrop, etc).
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
