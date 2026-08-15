import SwiftUI

struct PresetsGalleryView: View {
    @EnvironmentObject var vm: WallpaperEditorViewModel
    @State private var selectedCategory: PresetCategory? = nil

    private let columns = [GridItem(.adaptive(minimum: 130), spacing: 14)]

    var body: some View {
        ScrollView {
            PanelHeader(title: "Presets", subtitle: "Tap to load — every preset stays fully editable")

            categoryFilter

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredPresets) { preset in
                    Button {
                        vm.applyPreset(preset)
                    } label: {
                        ThumbnailCard(title: preset.name, isSelected: vm.project.name == preset.name) {
                            GradientThumbnailView(gradient: preset.gradient)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private var filteredPresets: [WallpaperPreset] {
        guard let category = selectedCategory else { return WallpaperPreset.all }
        return WallpaperPreset.presets(in: category)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ChipButton(title: "All", systemImage: nil, isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(PresetCategory.allCases) { category in
                    ChipButton(title: category.rawValue, systemImage: nil, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
}
