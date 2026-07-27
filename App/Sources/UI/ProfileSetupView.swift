import SwiftUI
import SwiftData

/// Who are tonight's stories for? One screen, four questions, no account,
/// no email — by design. Used at first run, and as a sheet when a Fable+
/// family adds another child.
struct ProfileSetupView: View {
    /// True when presented as a sheet to add an additional child.
    var isAddingAnotherChild = false
    /// Set to change an existing child instead of creating one. The same
    /// screen, the same validation: a name that could not be stored today
    /// must not survive just because it was stored yesterday.
    var editing: ChildProfile?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(PersistenceHealth.self) private var persistence
    @AppStorage("activeProfileUUID") private var activeProfileUUID = ""

    @State private var name = ""
    @State private var ageBand: AgeBand = .little
    @State private var companion = ""
    @State private var comfortObject = ""
    @State private var hasLoadedExisting = false
    @FocusState private var focusedField: Field?
    @ScaledMetric(relativeTo: .largeTitle) private var sparkleSize = 44

    private enum Field {
        case name, companion, comfortObject
    }

    private var canContinue: Bool {
        nameProblem == nil && companionProblem == nil && comfortProblem == nil
            && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Input-boundary safety (external review 2026-07-24): nothing that trips
    // any language's story vocabulary is ever persisted, so every place that
    // shows the stored name (greeting, reader dedication) is safe without
    // further checks. The message is gentle — the parent just picks a
    // nickname and moves on.
    private var nameProblem: LocalizedStringKey? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return ContentSafetyCheck.isStorableName(trimmed)
            ? nil
            : "That name can't go into a story. A nickname works great."
    }

    private var companionProblem: LocalizedStringKey? {
        ContentSafetyCheck.isStorableProfileField(companion)
            ? nil
            : "Stories can't use that word. Try a friendlier sidekick."
    }

    private var comfortProblem: LocalizedStringKey? {
        ContentSafetyCheck.isStorableProfileField(comfortObject)
            ? nil
            : "Stories can't use that word. Try something cozier."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("✨")
                        .font(.system(size: sparkleSize))
                        .accessibilityHidden(true)
                    Text(titleText)
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .foregroundStyle(FableTheme.cream)
                    Text("Stays on this device. Fable never sends or collects it, and there is no account, ever.")
                        .font(.footnote)
                        .foregroundStyle(FableTheme.creamDim)
                }
                .padding(.top, 24)

                field("Their name", problem: nameProblem) {
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

                field("A favorite friend or animal. Skip it and a small brave fox steps in", problem: companionProblem) {
                    TextField("", text: $companion, prompt: prompt("Bruno the dog"))
                        .focused($focusedField, equals: .companion)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .comfortObject }
                }

                field("Something cozy they sleep with, optional too", problem: comfortProblem) {
                    TextField("", text: $comfortObject, prompt: prompt("the yellow blanket"))
                        .focused($focusedField, equals: .comfortObject)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                }

                Button(action: save) {
                    Text(buttonText)
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
        .onAppear {
            loadExistingIfNeeded()
            focusedField = .name
        }
        // Soften scrolled text before it reaches the status bar — review
        // 2026-07-22 saw the title collide with the clock.
        .scrollEdgeEffectStyle(.soft, for: .top)
        .fableBackground()
    }

    private var titleText: LocalizedStringKey {
        if editing != nil { return "Change these\ndetails" }
        return isAddingAnotherChild ? "Another hero\njoins the family" : "Who are tonight's\nstories for?"
    }

    private var buttonText: LocalizedStringKey {
        if editing != nil { return "Save changes" }
        return isAddingAnotherChild ? "Welcome them in" : "Begin the first story"
    }

    /// Fills the fields from the child being changed, once.
    private func loadExistingIfNeeded() {
        guard let editing, !hasLoadedExisting else { return }
        hasLoadedExisting = true
        name = editing.name
        ageBand = editing.ageBand
        companion = editing.companion
        comfortObject = editing.comfortObject
    }

    private func save() {
        // canContinue already blocks unstorable input in this UI; the guard
        // makes the persistence function itself refuse it, and storableName/
        // storableProfileField persist the SAME canonical representation the
        // validation judged (round three: an invisible-only companion was
        // validated as empty but stored non-empty).
        guard canContinue else { return }
        let safeName = ContentSafetyCheck.storableName(from: name)
        let safeCompanion = ContentSafetyCheck.storableProfileField(from: companion)
        let safeComfort = ContentSafetyCheck.storableProfileField(from: comfortObject)

        if let editing {
            editing.name = safeName
            editing.ageBand = ageBand
            editing.companion = safeCompanion
            editing.comfortObject = safeComfort
            // An edit that does not reach disk is a lie the parent can see:
            // report it rather than swallowing it (finding #6).
            Persistence.save(modelContext, whileDoing: "saving these details", health: persistence)
            dismiss()
            return
        }

        let profile = ChildProfile(
            name: safeName,
            ageBand: ageBand,
            companion: safeCompanion,
            comfortObject: safeComfort
        )
        modelContext.insert(profile)
        // The newest child takes the stage right away.
        activeProfileUUID = profile.uuid.uuidString
        Persistence.save(modelContext, whileDoing: "adding this child", health: persistence)
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

    private func field(
        _ title: LocalizedStringKey,
        problem: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> some View
    ) -> some View {
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
            if let problem {
                Text(problem)
                    .font(.footnote)
                    .foregroundStyle(FableTheme.gold)
            }
        }
    }
}
