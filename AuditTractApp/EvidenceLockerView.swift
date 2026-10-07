import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers

struct EvidenceLockerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let controlLog: ControlLog
    
    @State private var showingImagePicker = false
    @State private var showingFileImporter = false
    @State private var showingAddLinkAlert = false
    @State private var linkURLString = ""
    @State private var linkTitle = ""
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                
                // Header Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(controlLog.taskID)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(TractColor.copper)
                    Text(controlLog.controlTitle)
                        .font(.headline)
                        .foregroundColor(TractColor.ink)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: { showingFileImporter = true }) {
                        Label("Upload File", systemImage: "doc.badge.plus")
                            .font(.caption)
                            .bold()
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(TractColor.card)
                            .foregroundColor(TractColor.ink)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(TractColor.stroke, lineWidth: 1))
                    }
                    
                    Button(action: { showingAddLinkAlert = true }) {
                        Label("Add Link", systemImage: "link")
                            .font(.caption)
                            .bold()
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(TractColor.card)
                            .foregroundColor(TractColor.copper)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(TractColor.copper.opacity(0.4), lineWidth: 1))
                    }
                }
                .padding(.horizontal)
                
                // Evidence List
                if controlLog.evidenceItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(TractColor.secondary)
                        Text("No Evidence Attached")
                            .font(.headline)
                            .foregroundColor(TractColor.secondary)
                        Text("Upload policies, screenshots, or audit log links to support this control.")
                            .font(.caption)
                            .foregroundColor(TractColor.label)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(controlLog.evidenceItems) { item in
                            HStack(spacing: 12) {
                                Image(systemName: iconForEvidence(item))
                                    .font(.title3)
                                    .foregroundColor(TractColor.copper)
                                    .frame(width: 32, height: 32)
                                    .background(TractColor.copper.opacity(0.15))
                                    .cornerRadius(6)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.fileName)
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(TractColor.ink)
                                    
                                    if let url = item.urlString, !url.isEmpty {
                                        Text(url)
                                            .font(.caption2)
                                            .foregroundColor(TractColor.copper)
                                            .lineLimit(1)
                                    } else {
                                        Text(item.createdDate.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundColor(TractColor.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(TractColor.card)
                        }
                        .onDelete(perform: deleteEvidence)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(TractColor.canvas)
            .navigationTitle("Evidence Locker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Add Link Evidence", isPresented: $showingAddLinkAlert) {
                TextField("Link Title (e.g. GitHub PR #102)", text: $linkTitle)
                TextField("URL (https://...)", text: $linkURLString)
                Button("Cancel", role: .cancel) {
                    linkTitle = ""
                    linkURLString = ""
                }
                Button("Add Link") {
                    addLinkEvidence()
                }
            } message: {
                Text("Enter a direct URL to an evidence document, ticket, or code repository.")
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let selectedURL = urls.first else { return }
                    addFileEvidence(url: selectedURL)
                case .failure(let error):
                    print("File import failed: \(error.localizedDescription)")
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func iconForEvidence(_ item: EvidenceItem) -> String {
        switch item.evidenceEnum {
        case .photo, .image: return "photo.fill"
        case .link: return "link"
        case .document: return "doc.fill"
        }
    }
    
    private func addLinkEvidence() {
        guard !linkURLString.isEmpty else { return }
        let title = linkTitle.isEmpty ? linkURLString : linkTitle
        let newItem = EvidenceItem(
            taskID: controlLog.taskID,
            fileName: title,
            fileType: String.link,
            urlString: linkURLString
        )
        controlLog.evidenceItems.append(newItem)
        try? modelContext.save()
        
        linkTitle = ""
        linkURLString = ""
    }
    
    private func addFileEvidence(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let fileData = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            let newItem = EvidenceItem(
                taskID: controlLog.taskID,
                fileName: fileName,
                fileType: String.document,
                localPath: url.path,
                fileData: fileData
            )
            controlLog.evidenceItems.append(newItem)
            try? modelContext.save()
        } catch {
            print("Failed to read imported file data: \(error)")
        }
    }
    
    private func deleteEvidence(at offsets: IndexSet) {
        for index in offsets {
            let item = controlLog.evidenceItems[index]
            modelContext.delete(item)
        }
        controlLog.evidenceItems.remove(atOffsets: offsets)
        try? modelContext.save()
    }
}

