import SwiftUI

struct SavedProjectsView: View {
    @EnvironmentObject var vm: WallpaperEditorViewModel
    @State private var renamingProject: WallpaperProject?
    @State private var renameText: String = ""

    var body: some View {
        ScrollView {
            PanelHeader(title: "Saved", subtitle: "\(vm.savedProjects.count) project\(vm.savedProjects.count == 1 ? "" : "s")")

            if vm.savedProjects.isEmpty {
                Text("Projects you save will appear here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 14)], spacing: 16) {
                    ForEach(vm.savedProjects) { project in
                        projectCard(project)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 24)
        .onAppear { vm.refreshSavedProjects() }
        .alert("Rename Project", isPresented: renamingBinding) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                guard let project = renamingProject else { return }
                var updated = project
                updated.name = renameText
                try? PersistenceService.shared.save(updated)
                vm.refreshSavedProjects()
            }
        }
    }

    private var renamingBinding: Binding<Bool> {
        Binding(get: { renamingProject != nil }, set: { if !$0 { renamingProject = nil } })
    }

    private func projectCard(_ project: WallpaperProject) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                vm.openProject(project)
            } label: {
                ThumbnailCard(title: project.name, isSelected: vm.project.id == project.id) {
                    GradientThumbnailView(gradient: project.gradient)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 14) {
                Button {
                    renamingProject = project
                    renameText = project.name
                } label: { Image(systemName: "pencil") }
                Button {
                    vm.duplicateProject(project)
                } label: { Image(systemName: "plus.square.on.square") }
                Button(role: .destructive) {
                    vm.deleteProject(project)
                } label: { Image(systemName: "trash") }
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
