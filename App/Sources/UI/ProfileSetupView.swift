import SwiftUI
import SwiftData

/// First run: who are tonight's stories for?
/// One screen, four questions, no account, no email — by design.
struct ProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var ageBand: AgeBand = .little
    @State private var companion = ""
    @State private var comfortObject = ""

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("✨")
                        .font(.system(size: 44))
                    Text("Who are tonight's\nstories for?")
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .foregroundStyle(FableTheme.cream)
                    Text("Everything stays on this device. No account, ever.")
                        .font(.footnote)
                        .foregroundStyle(FableTheme.creamDim)
                }
                .padding(.top, 24)

                field("Their name") {
                    TextField("", text: $name, prompt: prompt("Nova"))
                        .textContentType(.givenName)
                }

                VStack(alignment: .leading, spacing: 10) {
                    label("Their age")
                    Picker("Their age", selection: $ageBand) {
                        ForEach(AgeBand.allCases) { band in
                            Text(band.displayName).tag(band)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                field("A favorite friend or animal — stories need a sidekick") {
                    TextField("", text: $companion, prompt: prompt("Bruno the dog"))
                }

                field("Something cozy they sleep with") {
                    TextField("", text: $comfortObject, prompt: prompt("the yellow blanket"))
                }

                Button(action: save) {
                    Text("Begin the first story")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canContinue)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .fableBackground()
    }

    private func save() {
        let profile = ChildProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            ageBand: ageBand,
            companion: companion.trimmingCharacters(in: .whitespacesAndNewlines),
            comfortObject: comfortObject.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(profile)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(FableTheme.creamDim)
    }

    private func prompt(_ text: String) -> Text {
        Text(text).foregroundStyle(FableTheme.cream.opacity(0.25))
    }

    private func field(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            label(title)
            content()
                .padding(14)
                .foregroundStyle(FableTheme.cream)
                .background(FableTheme.card, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}
