import SwiftUI
import SwiftData

/// Every story ever told, newest first. Old favorites are half the ritual.
struct LibraryView: View {
    let profile: ChildProfile

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
                    NavigationLink(value: story) {
                        HStack(spacing: 14) {
                            Text(story.theme.emoji).font(.title3)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(story.title)
                                    .font(.system(.body, design: .serif, weight: .medium))
                                    .foregroundStyle(FableTheme.cream)
                                    .lineLimit(2)
                                Text(story.createdAt, format: .dateTime.day().month().year())
                                    .font(.caption)
                                    .foregroundStyle(FableTheme.creamDim)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(FableTheme.card)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .fableBackground()
        .navigationTitle("Storybook")
        .navigationDestination(for: Story.self) { story in
            ReaderView(story: story)
        }
    }
}
