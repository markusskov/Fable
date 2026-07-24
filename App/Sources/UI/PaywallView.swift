import SwiftUI
import StoreKit

/// The Fable+ sheet. Calm and honest, like everything else at bedtime:
/// real prices, a plain explanation of the free tier, no countdowns,
/// no guilt. Presented when the free meter is waiting, or from settings
/// surfaces later.
struct PaywallView: View {
    /// When the meter is waiting, we say so honestly — including exactly
    /// when the next free story arrives. Nil when browsing from elsewhere.
    var nextFreeStoryDate: Date?

    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: FablePlus.Plan = .annual
    @State private var isPurchasing = false
    @State private var isRestoring = false
    /// One calm line about what the store just said (Ask-to-Buy pending,
    /// offline, nothing to restore). Nil when there is nothing to report —
    /// quiet by default.
    @State private var storeNote: LocalizedStringKey?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                benefits
                planPicker
                purchaseButton
                footer
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .fableBackground()
        .presentationDragIndicator(.visible)
        // A failed catalog load is not sticky: reopening the paywall retries
        // (2026-07-24 money-path review). Also settles a cold-start .unknown.
        .task { await subscriptions.refreshOnReturn() }
        // Entitlement can arrive while the sheet is open — an Ask-to-Buy
        // approval, a purchase on another device, cold-start resolution. The
        // paywall's job is done the moment the family is subscribed.
        .onChange(of: subscriptions.isSubscribed) { _, isSubscribed in
            if isSubscribed { dismiss() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🌙")
                .font(.system(size: 40))
                .accessibilityHidden(true)
            Text("Every night deserves\nits own story")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(FableTheme.cream)
            if let nextFreeStoryDate {
                Text("Your next free story is ready \(nextFreeStoryDate.formatted(.relative(presentation: .named))) — or make story time unlimited with Fable+.")
                    .font(.subheadline)
                    .foregroundStyle(FableTheme.creamDim)
            } else {
                Text("Fable+ makes story time unlimited, every single night.")
                    .font(.subheadline)
                    .foregroundStyle(FableTheme.creamDim)
            }
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            benefit("moon.stars.fill", "A brand-new story every night, whenever you want one")
            benefit("books.vertical.fill", "Story series — adventures that continue night after night")
            benefit("person.2.fill", "Profiles for every child in the family")
            benefit("lock.fill", "Still private: everything stays on this device")
        }
    }

    private func benefit(_ symbol: String, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: symbol)
                .font(.subheadline)
                .foregroundStyle(FableTheme.gold)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(text)
                .font(.callout)
                .foregroundStyle(FableTheme.cream)
        }
    }

    @ViewBuilder private var planPicker: some View {
        if subscriptions.products.isEmpty {
            VStack(spacing: 8) {
                if subscriptions.isLoadingProducts {
                    ProgressView()
                        .tint(FableTheme.gold)
                } else {
                    Text("The bookshop can't be reached right now.\nPlease try again a little later.")
                        .font(.callout)
                        .foregroundStyle(FableTheme.creamDim)
                        .multilineTextAlignment(.center)
                    Button("Try again") {
                        Task { await subscriptions.loadProducts() }
                    }
                    .font(.callout.weight(.medium))
                    .foregroundStyle(FableTheme.gold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        } else {
            VStack(spacing: 12) {
                ForEach(FablePlus.Plan.allCases.sorted { $0.sortOrder < $1.sortOrder }) { plan in
                    if let product = subscriptions.product(for: plan) {
                        planCard(plan, product: product)
                    }
                }
            }
        }
    }

    private func planCard(_ plan: FablePlus.Plan, product: Product) -> some View {
        let isSelected = plan == selectedPlan
        return Button {
            selectedPlan = plan
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.displayName)
                            .font(.headline)
                            .foregroundStyle(FableTheme.cream)
                        if plan == .annual, let saving = subscriptions.yearlySavingPercent {
                            // .percent keeps the sign locale-correct ("33%" vs
                            // Norwegian "33 %") and keeps "%" out of format keys.
                            Text("Save \(saving, format: .percent)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(FableTheme.nightDeep)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(FableTheme.gold, in: Capsule())
                        }
                    }
                    Text(priceLine(for: plan, product: product))
                        .font(.subheadline)
                        .foregroundStyle(FableTheme.creamDim)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? FableTheme.gold : FableTheme.creamDim)
                    .accessibilityHidden(true) // selection is announced via the trait
            }
            .padding(16)
            .background(FableTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? FableTheme.gold : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func priceLine(for plan: FablePlus.Plan, product: Product) -> String {
        var base = String(localized: "\(product.displayPrice) / \(plan.cadence)")
        if plan == .annual, let perMonth = subscriptions.monthlyEquivalentPrice(for: plan) {
            base = String(localized: "\(base) — that's \(perMonth) a month")
        }
        if let trial = subscriptions.freeTrialText(for: plan) {
            return String(localized: "\(trial), then \(base)")
        }
        return base
    }

    private var purchaseButton: some View {
        VStack(spacing: 14) {
            Button(action: purchase) {
                Group {
                    if isPurchasing {
                        ProgressView().tint(FableTheme.nightDeep)
                    } else {
                        Text(subscriptions.freeTrialText(for: selectedPlan) != nil
                            ? "Start your free week"
                            : "Continue")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .foregroundStyle(FableTheme.nightDeep)
            .disabled(isPurchasing || subscriptions.product(for: selectedPlan) == nil)

            if let storeNote {
                Text(storeNote)
                    .font(.footnote)
                    .foregroundStyle(FableTheme.creamDim)
                    .multilineTextAlignment(.center)
            }

            Button("Maybe later") { dismiss() }
                .font(.subheadline)
                .foregroundStyle(FableTheme.creamDim)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subscriptions renew automatically until cancelled — cancel anytime in Settings. The free tier is yours forever: one new story every week, and every story you've told stays in your library.")
                .font(.footnote)
                .foregroundStyle(FableTheme.creamDim)
            Button(isRestoring ? "Restoring…" : "Restore purchases") {
                restore()
            }
            .font(.footnote)
            .foregroundStyle(FableTheme.gold)
            .disabled(isRestoring)
            // App Review 3.1.2: privacy policy and terms must be reachable
            // inside a subscription app, not just from the store listing.
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: FableLinks.privacyPolicy)
                Link("Terms of Use", destination: FableLinks.termsOfUse)
            }
            .font(.footnote)
            .foregroundStyle(FableTheme.gold)
        }
        .padding(.bottom, 24)
    }

    private func purchase() {
        isPurchasing = true
        storeNote = nil
        Task {
            defer { isPurchasing = false }
            // Each outcome gets an honest, calm word (2026-07-24 money-path
            // review: pending and offline used to be indistinguishable from
            // "nothing happened"). Only a cancelled sheet stays silent — the
            // family just changed their mind.
            switch await subscriptions.purchase(selectedPlan) {
            case .subscribed:
                dismiss()
            case .pending:
                storeNote = "Waiting for a parent to approve this purchase. Stories unlock the moment they do."
            case .cancelled:
                break
            case .failed:
                storeNote = "The App Store couldn't be reached. Please try again in a moment."
            }
        }
    }

    private func restore() {
        isRestoring = true
        storeNote = nil
        Task {
            defer { isRestoring = false }
            switch await subscriptions.restore() {
            case .subscribed:
                dismiss()
            case .nothingToRestore:
                storeNote = "No earlier purchase was found for this Apple Account."
            case .failed:
                storeNote = "Restore couldn't reach the App Store. Please check your connection and try again."
            }
        }
    }
}
