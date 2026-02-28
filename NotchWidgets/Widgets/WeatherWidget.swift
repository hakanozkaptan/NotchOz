import SwiftUI

struct WeatherWidget: View {
    let compact: Bool
    @StateObject private var viewModel: WeatherWidgetViewModel

    private static let iconColor = Color(red: 0.42, green: 0.75, blue: 0.98)

    init(compact: Bool, service: WeatherServiceProtocol = OpenMeteoWeatherService()) {
        self.compact = compact
        _viewModel = StateObject(wrappedValue: WeatherWidgetViewModel(service: service))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.weather == nil {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(Color.white.opacity(0.5))
                    Text(L10n.string("weather_loading"))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else if let w = viewModel.weather {
                weatherContent(w)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Self.iconColor)
                    Text(L10n.string("weather_set_city"))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .onAppear { viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private func weatherContent(_ w: WeatherData) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 5) {
                Image(systemName: w.symbolName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Self.iconColor)
                Text("\(w.temperature)°")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.white)
                    .kerning(-0.5)
            }
            Text(w.description)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.38))
                .tracking(0.2)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - ViewModel

@MainActor
final class WeatherWidgetViewModel: ObservableObject {
    @Published private(set) var weather: WeatherData?
    @Published private(set) var isLoading = false

    private let service: WeatherServiceProtocol

    init(service: WeatherServiceProtocol = OpenMeteoWeatherService()) {
        self.service = service
    }

    func loadIfNeeded() {
        let city = SettingsManager.shared.weatherCity
        guard !city.isEmpty, !isLoading else { return }
        Task { await fetch(city: city) }
    }

    private func fetch(city: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            weather = try await service.fetchWeather(for: city)
        } catch {
            // Keep stale data on error; user will see last known weather
        }
    }
}
