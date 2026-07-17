import CoreGraphics
import Foundation
import JardinCore

/// Repli via une API de reconnaissance en ligne, utilisé uniquement si l'utilisateur
/// a configuré une clé dans les réglages et si les sources locales sont peu sûres.
/// Deux fournisseurs supportés : Pl@ntNet (recherche académique) et Plant.id.
public struct RemoteAPIConfiguration: Sendable, Equatable {
    public enum Provider: String, CaseIterable, Sendable {
        case plantNet = "plantnet"
        case plantID = "plantid"

        public var label: String {
            switch self {
            case .plantNet: return "Pl@ntNet"
            case .plantID: return "Plant.id"
            }
        }
    }

    public let provider: Provider
    public let apiKey: String

    public init(provider: Provider, apiKey: String) {
        self.provider = provider
        self.apiKey = apiKey
    }

    public static let providerDefaultsKey = "remoteAPIProvider"
    public static let apiKeyDefaultsKey = "remoteAPIKey"

    /// Lit la configuration depuis les réglages ; `nil` si non configurée.
    public static func fromDefaults(_ defaults: UserDefaults = .standard) -> RemoteAPIConfiguration? {
        guard let rawProvider = defaults.string(forKey: providerDefaultsKey),
              let provider = Provider(rawValue: rawProvider),
              let key = defaults.string(forKey: apiKeyDefaultsKey),
              !key.isEmpty else { return nil }
        return RemoteAPIConfiguration(provider: provider, apiKey: key)
    }
}

public struct RemoteAPIIdentifier: PlantIdentifying {
    let configuration: RemoteAPIConfiguration
    let session: URLSession

    public init(configuration: RemoteAPIConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    public func identify(cgImage: CGImage) async throws -> [IdentificationCandidate] {
        guard let jpeg = ImageUtils.jpegData(from: ImageUtils.resized(cgImage, maxDimension: 1024) ?? cgImage) else {
            throw IdentificationError.featurePrintFailed
        }
        switch configuration.provider {
        case .plantNet: return try await identifyWithPlantNet(jpeg: jpeg)
        case .plantID: return try await identifyWithPlantID(jpeg: jpeg)
        }
    }

    // MARK: Pl@ntNet (multipart)

    struct PlantNetResponse: Decodable {
        struct Result: Decodable {
            struct Species: Decodable {
                let scientificNameWithoutAuthor: String
                let commonNames: [String]?
            }
            let score: Double
            let species: Species
        }
        let results: [Result]
    }

    func identifyWithPlantNet(jpeg: Data) async throws -> [IdentificationCandidate] {
        var components = URLComponents(string: "https://my-api.plantnet.org/v2/identify/all")!
        components.queryItems = [
            URLQueryItem(name: "api-key", value: configuration.apiKey),
            URLQueryItem(name: "lang", value: "fr"),
        ]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.timeoutInterval = 20

        let boundary = "jardin-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n".data(using: .utf8)!)
        }
        appendField("organs", "auto")
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"images\"; filename=\"photo.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(jpeg)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let decoded: PlantNetResponse = try await send(request)
        return decoded.results.prefix(5).map { result in
            IdentificationCandidate(
                name: result.species.commonNames?.first ?? result.species.scientificNameWithoutAuthor,
                scientificName: result.species.scientificNameWithoutAuthor,
                confidence: result.score,
                source: .apiDistante
            )
        }
    }

    // MARK: Plant.id (JSON)

    struct PlantIDResponse: Decodable {
        struct ResultBlock: Decodable {
            struct Classification: Decodable {
                struct Suggestion: Decodable {
                    struct Details: Decodable {
                        let common_names: [String]?
                    }
                    let name: String
                    let probability: Double
                    let details: Details?
                }
                let suggestions: [Suggestion]
            }
            let classification: Classification
        }
        let result: ResultBlock
    }

    func identifyWithPlantID(jpeg: Data) async throws -> [IdentificationCandidate] {
        var request = URLRequest(url: URL(string: "https://api.plant.id/v3/identification")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.apiKey, forHTTPHeaderField: "Api-Key")

        let payload: [String: Any] = [
            "images": ["data:image/jpeg;base64,\(jpeg.base64EncodedString())"],
            "similar_images": false,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let decoded: PlantIDResponse = try await send(request)
        return decoded.result.classification.suggestions.prefix(5).map { suggestion in
            IdentificationCandidate(
                name: suggestion.details?.common_names?.first ?? suggestion.name,
                scientificName: suggestion.name,
                confidence: suggestion.probability,
                source: .apiDistante
            )
        }
    }

    func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw IdentificationError.network(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw IdentificationError.network("HTTP \(code)")
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw IdentificationError.invalidResponse
        }
    }
}
