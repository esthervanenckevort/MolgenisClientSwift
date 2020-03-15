import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import OpenCombine
import OpenCombineFoundation
import OpenCombineDispatch

public class MolgenisClient {
    private let baseURL: URL
    private lazy var apiEndPointLogin: URL = baseURL.appendingPathComponent("api/v1/login")
    private lazy var apiEndPointLogout: URL = baseURL.appendingPathComponent("api/v1/logout")
    private lazy var apiPathV2: URL = baseURL.appendingPathComponent("api/v2/")
    private var session: URLSession
    private var barrierQueue = DispatchQueue(label: "barrier")
    private var configuration: URLSessionConfiguration
    
    public init(baseURL url: URL, using configuration: URLSessionConfiguration = URLSessionConfiguration.default) throws {
        guard url.path == "/" || url.path == "" else {
            throw MolgenisError.invalidURL(message: "URL \(url) must not contain the API path.")
        }
        self.baseURL = url
        self.configuration = configuration
        self.session = MolgenisClient.makeSession(with: self.configuration, token: nil)
    }

    public func aggregates<E: EntityResponse, X: Decodable, Y: Decodable>(entity: E.Type, x: String, y: String? = nil, distinct: String? = nil) throws -> AnyPublisher<AggregateResponse<X,Y>, Error> {
        let decoder = makeJSONDecoder()
        var components = URLComponents(url: apiPathV2.appendingPathComponent(E._entityName), resolvingAgainstBaseURL: true)
        var queryItems = [URLQueryItem]()
        queryItems.append(makeAggregateQueryItem(x: x, y: y, distinct: distinct))
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw MolgenisError.invalidURL(message: "Failed to build URL")
        }
        return Publishers.Sequence<[URL], Error>(sequence: [url])
            .flatMap { self.session.ocombine.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .map { $0.data }
            .decode(type: AggregateResponse<X, Y>.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    public func get<T: EntityResponse>(id: String, with subscriber: AnySubscriber<T, Error>) {
        let url = apiPathV2.appendingPathComponent(T._entityName).appendingPathComponent(id)
        let decoder = makeJSONDecoder()
        return Publishers.Sequence<[URL], Error>(sequence: [url])
            .flatMap { self.session.ocombine.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .map { $0.data }
            .decode(type: T.self, decoder: decoder)
            .subscribe(subscriber)
    }
    
    public func get<T: EntityResponse>(with subscriber: AnySubscriber<T, Error>) {
        let url = apiPathV2.appendingPathComponent(T._entityName)
        let decoder = makeJSONDecoder()
        let subject = PassthroughSubject<URL, Error>()
        subject
            .flatMap { self.session.ocombine.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .map { $0.data }
            .decode(type: CollectionResponse<T>.self, decoder: decoder)
            .flatMap { (collection) -> Publishers.Sequence<Array<T>, Error> in
                defer {
                    if let url = collection.nextHref {
                        subject.send(url)
                    } else {
                        subject.send(completion: .finished)
                    }
                }
                return Publishers.Sequence<Array<T>, Error>(sequence: collection.items)
            }
            .subscribe(subscriber)
        subject.send(url)
    }
    
    public func login(user: String, password: String) -> AnyPublisher<Bool, Never> {
        let decoder = makeJSONDecoder()
        let encoder = makeJSONEncoder()
        let body = LoginRequest(username: user, password: password)
        var request = URLRequest(url: apiEndPointLogin)
        request.httpMethod = Method.post.rawValue
        guard let httpBody = try? encoder.encode(body) else {
            fatalError("Unexpected error: failed to encode login message as JSON.")
        }
        request.httpBody = httpBody
        request.addValue(ContentType.json.rawValue, forHTTPHeaderField: Header.contentType.rawValue)
        return session.ocombine.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: LoginResponse.self, decoder: decoder)
            .map { (login) in
                self.barrierQueue.sync {
                    self.session = MolgenisClient.makeSession(with: self.configuration, token: login.token)
                }
                return true
            }
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }
    
    public func logout() -> AnyPublisher<Bool, Never> {
        var request = URLRequest(url: apiEndPointLogout)
        request.httpMethod = Method.post.rawValue
        return session.ocombine.dataTaskPublisher(for: request)
            .map {
                self.barrierQueue.sync {
                    self.session = MolgenisClient.makeSession(with: self.configuration, token: nil)
                }
                return ($0.response as? HTTPURLResponse)?.statusCode  == 200
            }
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }

    private func makeAggregateQueryItem(x: String, y: String?, distinct: String?) -> URLQueryItem {
        switch (x, y, distinct) {
        case (let x, .none, .none):
            return URLQueryItem(name: "aggs", value: "x==\(x)")
        case (let x, .some(let y), .none):
            return URLQueryItem(name: "aggs", value: "x==\(x);y==\(y)")
        case (let x, .some(let y), .some(let distinct)):
            return URLQueryItem(name: "aggs", value: "x==\(x);y==\(y);distinct==\(distinct)")
        case (let x, .none, .some(let distinct)):
            return URLQueryItem(name: "aggs", value: "x==\(x);distinct==\(distinct)")
        }
    }

    private func makeJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        if #available(OSX 10.12, *) {
            encoder.dateEncodingStrategy = .iso8601
        } else {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-ddTHH\\:mm\\:ss.fffffffzzz"
            encoder.dateEncodingStrategy = .formatted(df)
        }
        return encoder
    }

    private func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        if #available(OSX 10.12, *) {
            decoder.dateDecodingStrategy = .iso8601
        } else {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-ddTHH\\:mm\\:ss.fffffffzzz"
            decoder.dateDecodingStrategy = .formatted(df)
        }
        return decoder
    }

    private static func makeSession(with configuration: URLSessionConfiguration, token: String?) -> URLSession {
        let configuration = configuration
        var headers = configuration.httpAdditionalHeaders ?? [AnyHashable: Any]()
        headers[Header.contentType.rawValue] = ContentType.json.rawValue
        if let token = token {
            headers[Header.token.rawValue] = token
        } else {
            headers.removeValue(forKey: Header.token.rawValue)
        }
        configuration.httpAdditionalHeaders = headers
        return URLSession(configuration: configuration)
    }

    public enum MolgenisError: Error {
        case invalidURL(message: String)
    }
    private enum Header: String {
        case contentType = "Content-Type"
        case token = "x-molgenis-token"
    }
    
    private enum Method: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
        case patch = "PATCH"
        case put = "PUT"
    }
    
    private enum ContentType: String {
        case json = "application/json;charset=UTF-8"
    }
}
