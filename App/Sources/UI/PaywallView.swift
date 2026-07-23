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

    private func benefit(_ symbol: String, _ text: String) -> some View {
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
                            Text("Save \(saving)%")
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
        var base = "\(product.displayPrice) / \(plan.cadence)"
        if plan == .annual, let perMonth = subscriptions.monthlyEquivalentPrice(for: plan) {
            base = "\(base) — that's \(perMonth) a month"
        }
        if let trial = subscriptions.freeTrialText(for: plan) {
            return "\(trial), then \(base)"
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
        }
        .padding(.bottom, 24)
    }

    private func purchase() {
        isPurchasing = true
        Task {
            defer { isPurchasing = false }
            // Cancelled sheets and pending Ask-to-Buy both land here quietly;
            // only a completed purchase closes the paywall.
            if (try? await subscriptions.purchase(selectedPlan)) == true {
                dismiss()
            }
        }
    }

    private func restore() {
        isRestoring = true
        Task {
            defer { isRestoring = false }
            try? await subscriptions.restore()
            if subscriptions.isSubscribed {
                dismiss()
            }
        }
    }
}
