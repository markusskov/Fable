import SwiftUI
import SwiftData
import UIKit

/// Every story ever told, newest first. Old favorites are half the ritual.
struct LibraryView: View {
    let profile: ChildProfile
    /// The stack's path; rows push stories onto it explicitly. Value-based
    /// NavigationLinks resolved unreliably from this pushed screen, so rows
    /// navigate the same way the Tonight flow does: `path.append(story)`.
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var modelContext
    @Environment(PersistenceHealth.self) private var persistence
    @Query(sort: \Story.createdAt, order: .reverse) private var allStories: [Story]
    @State private var storyPendingDeletion: Story?

    /// This child's storybook. Pre-profiles stories belong to everyone, but
    /// rows that predate the all-path gate remain stored and quarantined.
    private var stories: [Story] {
        allStories.filter { $0.belongs(to: profile) && $0.isReaderSafe }
    }

    var body: some View {
        Group {
            if stories.isEmpty {
                ContentUnavailableView {
                    Label("No stories yet", systemImage: "book.closed")
                } description: {
                    Text("Tonight's story will appear here, ready to read again.")
                }
                .foregroundStyle(FableTheme.creamDim)
            } else {
                List(stories) { story in
                    Button {
                        path.append(story)
                    } label: {
                        HStack(spacing: 14) {
                            if let cover = story.coverArt, let image = UIImage(data: cover) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .accessibilityHidden(true)
                            } else {
                                Text(story.theme.emoji).font(.title3)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(story.title)
                                    .font(.system(.body, design: .serif, weight: .medium))
                                    .foregroundStyle(FableTheme.cream)
                                    .lineLimit(2)
                                HStack(spacing: 6) {
                                    if let episode = story.episodeNumber {
                                        Text("Episode \(episode)")
                                            .font(.caption)
                                            .foregroundStyle(FableTheme.gold)
                                    }
                                    Text(story.createdAt, format: .dateTime.day().month().year())
                                        .font(.caption)
                                        .foregroundStyle(FableTheme.creamDim)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(FableTheme.creamDim)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(FableTheme.card)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            storyPendingDeletion = story
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                // Wider than the text column: list rows carry their own
                // card chrome and sit comfortably a little broader.
                .fableContentColumn(maxWidth: 700)
            }
        }
        .fableBackground()
        .navigationTitle("Storybook")
        // A story is a memory, so deleting one asks first — and says that it
        // cannot be undone, because on a device-only app that is literally
        // true (external review finding #6).
        .confirmationDialog(
            "Delete this story?",
            isPresented: Binding(
                get: { storyPendingDeletion != nil },
                set: { if !$0 { storyPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deletePendingStory() }
            Button("Keep", role: .cancel) { storyPendingDeletion = nil }
        } message: {
            Text("This story will be gone for good. It only exists on this device.")
        }
    }

    private func deletePendingStory() {
        guard let story = storyPendingDeletion else { return }
        storyPendingDeletion = nil
        modelContext.delete(story)
        Persistence.save(modelContext, whileDoing: "deleting this story", health: persistence)
    }
}
