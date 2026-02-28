import Foundation

// MARK: - Model

/// Daily exchange rate data from TCMB (Central Bank of Turkey).
struct FinanceRates: Equatable {
    let usdBuying: Double       // USD/TRY buying
    let eurBuying: Double       // EUR/TRY buying
    let goldGram:  Double?      // Gold per gram in TRY (XAU ÷ 31.1035); nil if unavailable
    let fetchedAt: Date
}

// MARK: - Error

enum FinanceError: LocalizedError {
    case network(Error)
    case parsing
    case missingCurrency(String)

    var errorDescription: String? {
        switch self {
        case .network(let e):          return e.localizedDescription
        case .parsing:                 return "Response could not be parsed"
        case .missingCurrency(let c):  return "Currency not found: \(c)"
        }
    }
}

// MARK: - Protocol

/// Protocol for services that provide exchange rate data.
/// A mock implementation can be injected for testing.
protocol FinanceServiceProtocol: Sendable {
    func fetchRates() async throws -> FinanceRates
}

// MARK: - TCMB Implementation

/// Fetches and parses the daily exchange rate XML from TCMB (Central Bank of Turkey).
/// No API key required; updated on business days (~11:00 and ~15:30 Turkey time).
final class TCMBFinanceService: FinanceServiceProtocol {

    private static let endpoint = URL(string: "https://www.tcmb.gov.tr/kurlar/today.xml")!

    private static let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 12
        cfg.timeoutIntervalForResource = 20
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: cfg)
    }()

    func fetchRates() async throws -> FinanceRates {
        var request = URLRequest(url: Self.endpoint)
        request.setValue("NotchOz/1.0 (macOS)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await Self.session.data(for: request)
            return try TCMBXMLParser().parse(data)
        } catch let error as FinanceError {
            throw error
        } catch {
            throw FinanceError.network(error)
        }
    }
}

// MARK: - XML Parser (private)

private final class TCMBXMLParser: NSObject, XMLParserDelegate {

    private var buyingRates: [String: Double] = [:]
    private var currentCode: String?
    private var inForexBuying = false
    private var buffer = ""

    func parse(_ data: Data) throws -> FinanceRates {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else { throw FinanceError.parsing }

        guard let usd = buyingRates["USD"] else { throw FinanceError.missingCurrency("USD") }
        guard let eur = buyingRates["EUR"] else { throw FinanceError.missingCurrency("EUR") }

        // XAU (gold per troy ounce) may not always be published — keep optional
        let goldGram = buyingRates["XAU"].map { $0 / 31.1035 }

        return FinanceRates(
            usdBuying: usd,
            eurBuying: eur,
            goldGram:  goldGram,
            fetchedAt: Date()
        )
    }

    // MARK: XMLParserDelegate

    func parser(_ parser: XMLParser,
                didStartElement name: String,
                namespaceURI: String?,
                qualifiedName: String?,
                attributes: [String: String]) {
        if name == "Currency" { currentCode = attributes["CurrencyCode"] }
        inForexBuying = (name == "ForexBuying")
        buffer = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inForexBuying { buffer += string }
    }

    func parser(_ parser: XMLParser,
                didEndElement name: String,
                namespaceURI: String?,
                qualifiedName: String?) {
        if name == "ForexBuying",
           let code  = currentCode,
           let value = Double(buffer.trimmingCharacters(in: .whitespaces)) {
            buyingRates[code] = value
        }
        if name == "Currency"    { currentCode  = nil }
        if name == "ForexBuying" { inForexBuying = false }
    }
}
