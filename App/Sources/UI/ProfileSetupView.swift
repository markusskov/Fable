import SwiftUI
import SwiftData

/// Who are tonight's stories for? One screen, four questions, no account,
/// no email — by design. Used at first run, and as a sheet when a Fable+
/// family adds another child.
struct ProfileSetupView: View {
    /// True when presented as a sheet to add an additional child.
    var isAddingAnotherChild = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("activeProfileUUID") private var activeProfileUUID = ""

    @State private var name = ""
    @State private var ageBand: AgeBand = .little
    @State private var companion = ""
    @State private var comfortObject = ""
    @FocusState private var focusedField: Field?
    @ScaledMetric(relativeTo: .largeTitle) private var sparkleSize = 44

    private enum Field {
        case name, companion, comfortObject
    }

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("✨")
                        .font(.system(size: sparkleSize))
                        .accessibilityHidden(true)
                    Text(isAddingAnotherChild ? "Another hero\njoins the family" : "Who are tonight's\nstories for?")
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
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .companion }
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

                field("A favorite friend or animal — skip it and a small brave fox steps in") {
                    TextField("", text: $companion, prompt: prompt("Bruno the dog"))
                        .focused($focusedField, equals: .companion)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .comfortObject }
                }

                field("Something cozy they sleep with — optional too") {
                    TextField("", text: $comfortObject, prompt: prompt("the yellow blanket"))
                        .focused($focusedField, equals: .comfortObject)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                }

                Button(action: save) {
                    Text(isAddingAnotherChild ? "Welcome them in" : "Begin the first story")
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
        // Ready to type straight away — the name is the only required step
        // on the way to the first story.
        .onAppear { focusedField = .name }
        // Soften scrolled text before it reaches the status bar — review
        // 2026-07-22 saw the title collide with the clock.
        .scrollEdgeEffectStyle(.soft, for: .top)
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
        // The newest child takes the stage right away.
        activeProfileUUID = profile.uuid.uuidString
        if isAddingAnotherChild {
            dismiss()
        }
    }

    private func label(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(FableTheme.creamDim)
    }

    private func prompt(_ text: LocalizedStringKey) -> Text {
        Text(text).foregroundStyle(FableTheme.cream.opacity(0.25))
    }

    private func field(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            label(title)
                .accessibilityHidden(true) // the field itself carries the label
            content()
                .padding(14)
                .foregroundStyle(FableTheme.cream)
                .background(FableTheme.card, in: RoundedRectangle(cornerRadius: 14))
                // The visible title is a sibling Text, so VoiceOver would
                // otherwise announce these fields as bare text boxes.
                .accessibilityLabel(title)
        }
    }
}
