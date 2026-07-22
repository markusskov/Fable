import SwiftUI
import SwiftData

/// Every story ever told, newest first. Old favorites are half the ritual.
struct LibraryView: View {
    let profile: ChildProfile
    /// The stack's path; rows push stories onto it explicitly. Value-based
    /// NavigationLinks resolved unreliably from this pushed screen, so rows
    /// navigate the same way the Tonight flow does: `path.append(story)`.
    @Binding var path: NavigationPath

    @Query(sort: \Story.createdAt, order: .reverse) private var stories: [Story]

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
                            Text(story.theme.emoji).font(.title3)
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
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(FableTheme.card)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .fableBackground()
        .navigationTitle("Storybook")
    }
}
