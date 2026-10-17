//
//  EvidenceLockerView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct EvidenceLockerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EvidenceArtifact.addedDate, order: .reverse) private var artifacts: [EvidenceArtifact]
    
    @State private var searchText = ""
    @State private var showingFileImporter = false
    
    init() {}
    
    var filteredArtifacts: [EvidenceArtifact] {
        if searchText.isEmpty {
            return artifacts
        }
        return artifacts.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.controlID.localizedCaseInsensitiveContains(searchText) ||
            $0.filePath.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredArtifacts.isEmpty {
                    ContentUnavailableView(
                        "No Evidence Artifacts",
                        systemImage: "doc.badge.plus",
                        description: Text("Add local file references, URLs, or cloud storage paths to build your audit submission manifest.")
                    )
                } else {
                    ForEach(filteredArtifacts) { artifact in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(artifact.controlID.isEmpty ? "General Evidence" : artifact.controlID)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                                
                                Spacer()
                                
                                Text(artifact.addedDate.formatted(date: .numeric, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(artifact.title)
                                .font(.headline)
                            
                            if !artifact.filePath.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "folder")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(artifact.filePath)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteArtifacts)
                }
            }
            .searchable(text: $searchText, prompt: "Search evidence manifest...")
            .navigationTitle("Evidence Locker")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingFileImporter = true }) {
                        Label("Add Artifact", systemImage: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    if let file = urls.first {
                        let artifact = EvidenceArtifact(
                            title: file.lastPathComponent,
                            filePath: file.path,
                            fileType: file.pathExtension.uppercased()
                        )
                        modelContext.insert(artifact)
                        try? modelContext.save()
                    }
                case .failure(let error):
                    print("❌ Error importing artifact: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deleteArtifacts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredArtifacts[index])
        }
        try? modelContext.save()
    }
}
