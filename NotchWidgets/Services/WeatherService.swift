import Foundation

// MARK: - Domain Model

struct WeatherData: Equatable {
    let temperature: Int
    let description: String
    let symbolName:  String
    let city:        String
}

// MARK: - Error

enum WeatherError: LocalizedError {
    case cityNotFound
    case network(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .cityNotFound:      return "City not found"
        case .network(let e):    return e.localizedDescription
        case .invalidResponse:   return "Invalid server response"
        }
    }
}

// MARK: - Protocol

/// Protocol for services that provide weather data.
/// A mock implementation can be injected for testing.
protocol WeatherServiceProtocol: Sendable {
    func fetchWeather(for city: String) async throws -> WeatherData
}

// MARK: - Open-Meteo Implementation

/// Uses the Open-Meteo service; no API key required.
final class OpenMeteoWeatherService: WeatherServiceProtocol {

    private static let session = URLSession.shared

    func fetchWeather(for city: String) async throws -> WeatherData {
        let coords  = try await geocode(city: city)
        let weather = try await fetchConditions(lat: coords.lat, lon: coords.lon)
        let (symbol, desc) = Self.condition(for: weather.current.weatherCode)
        return WeatherData(
            temperature: Int(weather.current.temperature2m.rounded()),
            description: desc,
            symbolName:  symbol,
            city:        city
        )
    }

    // MARK: – Geocoding

    private struct GeoResponse: Decodable {
        let results: [GeoEntry]?
        struct GeoEntry: Decodable {
            let latitude:  Double
            let longitude: Double
        }
    }

    private func geocode(city: String) async throws -> (lat: Double, lon: Double) {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        components?.queryItems = [
            URLQueryItem(name: "name",  value: city),
            URLQueryItem(name: "count", value: "1")
        ]
        guard let url = components?.url else { throw WeatherError.invalidResponse }

        do {
            let (data, _) = try await Self.session.data(from: url)
            let result    = try JSONDecoder().decode(GeoResponse.self, from: data)
            guard let first = result.results?.first else { throw WeatherError.cityNotFound }
            return (first.latitude, first.longitude)
        } catch let error as WeatherError { throw error
        } catch { throw WeatherError.network(error) }
    }

    // MARK: – Forecast

    private struct ForecastResponse: Decodable {
        let current: Current
        struct Current: Decodable {
            let temperature2m: Double
            let weatherCode:   Int
            enum CodingKeys: String, CodingKey {
                case temperature2m = "temperature_2m"
                case weatherCode   = "weather_code"
            }
        }
    }

    private func fetchConditions(lat: Double, lon: Double) async throws -> ForecastResponse {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude",  value: "\(lat)"),
            URLQueryItem(name: "longitude", value: "\(lon)"),
            URLQueryItem(name: "current",   value: "temperature_2m,weather_code")
        ]
        guard let url = components?.url else { throw WeatherError.invalidResponse }

        do {
            let (data, _) = try await Self.session.data(from: url)
            return try JSONDecoder().decode(ForecastResponse.self, from: data)
        } catch let error as WeatherError { throw error
        } catch is DecodingError { throw WeatherError.invalidResponse
        } catch { throw WeatherError.network(error) }
    }

    // MARK: – WMO code → (SF Symbol, description)

    private static func condition(for wmoCode: Int) -> (symbol: String, description: String) {
        switch wmoCode {
        case 0:           return ("sun.max.fill",         "Açık")
        case 1, 2, 3:     return ("cloud.sun.fill",       "Parçalı bulutlu")
        case 45, 48:      return ("cloud.fog.fill",       "Sisli")
        case 51, 53, 55:  return ("cloud.drizzle.fill",   "Çisenti")
        case 61, 63, 65:  return ("cloud.rain.fill",      "Yağmurlu")
        case 71, 73, 75:  return ("cloud.snow.fill",      "Karlı")
        case 77:          return ("cloud.snow.fill",      "Kar taneleri")
        case 80, 81, 82:  return ("cloud.heavyrain.fill", "Sağanak")
        case 85, 86:      return ("cloud.snow.fill",      "Kar sağanağı")
        case 95:          return ("cloud.bolt.rain.fill", "Gök gürültülü")
        case 96, 99:      return ("cloud.bolt.rain.fill", "Gök gürültülü sağanak")
        default:          return ("cloud.sun.fill",       "Parçalı bulutlu")
        }
    }
}
