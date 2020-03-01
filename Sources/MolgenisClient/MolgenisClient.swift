import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(OSLog)
import OSLog
#endif
import OpenCombine
import OpenCombineFoundation
import OpenCombineDispatch

public class MolgenisClient {
    private let baseURL: URL
    private var apiEndPointLogin: URL { baseURL.appendingPathComponent("api/v1/login") }
    private var apiEndPointLogout: URL { baseURL.appendingPathComponent("api/v1/logout") }
    private var apiPathV2: URL { baseURL.appendingPathComponent("api/v2/") }
    private var session: URLSession
    private var barrierQueue = DispatchQueue(label: "barrier")
    private var processQueue = DispatchQueue.global()
    private var configuration: URLSessionConfiguration
    
    public init?(baseURL url: URL, using configuration: URLSessionConfiguration = URLSessionConfiguration.default) {
        guard url.path == "/" || url.path == "" else {
            #if os(Linux)
            print("URL \(url) must not contain the API path.")
            #else
            if #available(OSX 10.12, *) {
                os_log("URL [%@] must not contain the API path.", [url])
            } else {
                print("URL \(url) must not contain the API path.")
            }
            #endif
            return nil
        }
        self.baseURL = url
        self.configuration = configuration
        self.configuration.httpAdditionalHeaders = MolgenisClient.makeHeaders(with: configuration.httpAdditionalHeaders, token: nil)
        self.session = URLSession(configuration: configuration)
    }

    public func aggregates<E: EntityResponse, X: Decodable, Y: Decodable>(entity: E.Type, x: String, y: String? = nil, distinct: String? = nil) throws -> AnyPublisher<AggregateResponse<X,Y>, Error> {
        let decoder = JSONDecoder()
        var components = URLComponents(url: apiPathV2.appendingPathComponent(E._entityName), resolvingAgainstBaseURL: true)
        var queryItems = [URLQueryItem]()
        queryItems.append(makeAggregateQueryItem(x: x, y: y, distinct: distinct))
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw MolgenisError.invalidURL
        }
        return Publishers.Sequence<[URL], Never>(sequence: [url])
            .tryMap { (url) -> URLRequest in
                var request = URLRequest(url: url)
                request.httpMethod = Method.get.rawValue
                return request
            }
            .flatMap { self.session.ocombine.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .map { $0.data }
            .decode(type: AggregateResponse<X, Y>.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    public func get<T: EntityResponse>(id: String, with subscriber: AnySubscriber<T, Error>) {
        let url = apiPathV2.appendingPathComponent(T._entityName).appendingPathComponent(id)
        let decoder = JSONDecoder()
        if #available(OSX 10.12, *) {
            decoder.dateDecodingStrategy = .iso8601
        } else {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-ddTHH\\:mm\\:ss.fffffffzzz"
            decoder.dateDecodingStrategy = .formatted(df)
        }
        return Publishers.Sequence<[URL], Never>(sequence: [url])
            .tryMap { (url) -> URLRequest in
                var request = URLRequest(url: url)
                request.httpMethod = Method.get.rawValue
                return request
            }
            .flatMap { self.session.ocombine.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .map { $0.data }
            .decode(type: T.self, decoder: decoder)
            .subscribe(subscriber)
    }
    
    public func get<T: EntityResponse>(with subscriber: AnySubscriber<T, Error>) {
        let url = apiPathV2.appendingPathComponent(T._entityName)
        let decoder = JSONDecoder()
        if #available(OSX 10.12, *) {
            decoder.dateDecodingStrategy = .iso8601
        } else {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-ddTHH\\:mm\\:ss.fffffffzzz"
            decoder.dateDecodingStrategy = .formatted(df)
        }
        let subject = PassthroughSubject<URL, Never>()
        subject
            .tryMap { (url) -> URLRequest in
                var request = URLRequest(url: url)
                request.httpMethod = Method.get.rawValue
                return request
            }
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
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        if #available(OSX 10.12, *) {
            decoder.dateDecodingStrategy = .iso8601
            encoder.dateEncodingStrategy = .iso8601
        } else {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-ddTHH\\:mm\\:ss.fffffffzzz"
            decoder.dateDecodingStrategy = .formatted(df)
            encoder.dateEncodingStrategy = .formatted(df)
        }
        let body = LoginRequest(username: user, password: password)
        return Publishers.Sequence<[URL], Never>(sequence: [apiEndPointLogin])
            .tryMap { (url) -> URLRequest in
                var request = URLRequest(url: url)
                request.httpMethod = Method.post.rawValue
                request.httpBody = try encoder.encode(body)
                request.addValue(ContentType.json.rawValue, forHTTPHeaderField: Header.contentType.rawValue)
                return request
            }
            .flatMap { self.session.ocombine.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .map { $0.data }
            .decode(type: LoginResponse.self, decoder: decoder)
            .map { (login) in
                self.barrierQueue.sync {
                    self.configuration.httpAdditionalHeaders = MolgenisClient.makeHeaders(with: self.configuration.httpAdditionalHeaders, token: login.token)
                    self.session = URLSession(configuration: self.configuration)                }
                return true
            }
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }
    
    public func logout() -> AnyPublisher<Bool, Never> {
        return Publishers.Sequence<[URL], Never>(sequence: [apiEndPointLogout])
            .tryMap { (url) -> URLRequest in
                var request = URLRequest(url: url)
                request.httpMethod = Method.post.rawValue
                return request
            }
            .flatMap { self.session.ocombine.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .map {
                self.barrierQueue.sync {
                    self.configuration.httpAdditionalHeaders = MolgenisClient.makeHeaders(with: self.configuration.httpAdditionalHeaders, token: nil)
                    self.session = URLSession(configuration: self.configuration)
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

    private static func makeHeaders(with existing: [AnyHashable: Any]?, token: String?) -> [AnyHashable: Any] {
        var headers = [AnyHashable : Any]()
        if let existing = existing {
            headers.merge(existing) { (left, right) in left }
        }
        headers[Header.contentType.rawValue] = ContentType.json.rawValue
        if let token = token {
            headers[Header.token.rawValue] = token
        }
        return headers
    }

    public enum MolgenisError: Error {
        case invalidURL
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
