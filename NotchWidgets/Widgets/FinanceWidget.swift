import SwiftUI

// MARK: - View

struct FinanceWidget: View {
    let compact: Bool

    @StateObject private var viewModel: FinanceWidgetViewModel

    init(compact: Bool, service: FinanceServiceProtocol = TCMBFinanceService()) {
        self.compact = compact
        _viewModel = StateObject(
            wrappedValue: FinanceWidgetViewModel(service: service)
        )
    }

    var body: some View {
        Group {
            if let rates = viewModel.rates {
                ratesRow(rates)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else if viewModel.isLoading {
                placeholderRow
                    .transition(.opacity)
            } else {
                emptyRow
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: viewModel.rates != nil ? "rates" : viewModel.isLoading ? "loading" : "empty")
        .onAppear  { viewModel.loadIfNeeded() }
        .onDisappear { viewModel.cancelRefresh() }
    }

    private func ratesRow(_ rates: FinanceRates) -> some View {
        HStack(spacing: 14) {
            rateItem(label: L10n.string("finance_usd"), value: rates.usdBuying, alignment: .leading)
            Spacer(minLength: 8)
            if let gold = rates.goldGram {
                rateItem(label: L10n.string("finance_gold"), value: gold, decimals: 2, alignment: .center)
                Spacer(minLength: 8)
            }
            rateItem(label: L10n.string("finance_eur"), value: rates.eurBuying, alignment: .trailing)
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundStyle(.white)
        .padding(.vertical, 6)
    }

    private func rateItem(label: String, value: Double, decimals: Int = 4, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 1) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.5))
            Text(String(format: "%.\(decimals)f", value))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
    }

    private var placeholderRow: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.7)
                .progressViewStyle(.circular)
                .tint(.white.opacity(0.7))
            Text(L10n.string("finance_loading"))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var emptyRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.4))
            Text(L10n.string("finance_error"))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

// MARK: - ViewModel

@MainActor
final class FinanceWidgetViewModel: ObservableObject {
    @Published private(set) var rates:     FinanceRates?
    @Published private(set) var isLoading = false
    @Published private(set) var error:     Error?

    private let service: FinanceServiceProtocol
    private var refreshTask: Task<Void, Never>?

    init(service: FinanceServiceProtocol = TCMBFinanceService()) {
        self.service = service
    }

    func loadIfNeeded() {
        guard !isLoading, rates == nil else { return }
        refreshTask = Task { await fetch() }
    }

    func cancelRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func fetch() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let newRates = try await service.fetchRates()
            rates = newRates
        } catch {
            self.error = error
            rates = nil
        }
    }
}
