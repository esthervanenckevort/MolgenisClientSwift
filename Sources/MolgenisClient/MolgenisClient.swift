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
    private lazy var session: URLSession = URLSession(configuration: self.configuration, token: nil)
    private var barrierQueue = DispatchQueue(label: "barrier")
    private var configuration: URLSessionConfiguration
    
    public init(baseURL url: URL, using configuration: URLSessionConfiguration = URLSessionConfiguration.default) throws {
        guard url.path == "/" || url.path == "" else {
            throw MolgenisError.invalidURL(message: "URL \(url) must not contain the API path.")
        }
        self.baseURL = url
        self.configuration = configuration
    }

    public func aggregates<E: EntityResponse, X: Decodable, Y: Decodable>(entity: E.Type, x: String, y: String? = nil, distinct: String? = nil) throws -> AnyPublisher<AggregateResponse<X,Y>, Error> {
        let decoder = JSONDecoder.iso8601()
        var components = URLComponents(url: apiPathV2.appendingPathComponent(E._entityName), resolvingAgainstBaseURL: true)
        var queryItems = [URLQueryItem]()
        queryItems.append(makeAggregateQueryItem(x: x, y: y, distinct: distinct))
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw MolgenisError.invalidURL(message: "Failed to build URL")
        }
        return session.ocombine.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: AggregateResponse<X, Y>.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    public func get<T: EntityResponse>(id: String, with subscriber: AnySubscriber<T, Error>) {
        let url = apiPathV2.appendingPathComponent(T._entityName).appendingPathComponent(id)
        let decoder = JSONDecoder.iso8601()
        return session.ocombine.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: T.self, decoder: decoder)
            .subscribe(subscriber)
    }
    
    public func get<T: EntityResponse>(with subscriber: AnySubscriber<T, Error>) {
        let url = apiPathV2.appendingPathComponent(T._entityName)
        let decoder = JSONDecoder.iso8601()
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
        let decoder = JSONDecoder.iso8601()
        let encoder = JSONEncoder.iso8601()
        let body = LoginRequest(username: user, password: password)
        var request = URLRequest(url: apiEndPointLogin)
        request.method = .post
        guard let httpBody = try? encoder.encode(body) else {
            fatalError("Unexpected error: failed to encode login message as JSON.")
        }
        request.httpBody = httpBody
        return session.ocombine.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: LoginResponse.self, decoder: decoder)
            .map { (login) in
                self.barrierQueue.sync {
                    self.session = URLSession(configuration: self.configuration, token: login.token)
                }
                return true
            }
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }
    
    public func logout() -> AnyPublisher<Bool, Never> {
        var request = URLRequest(url: apiEndPointLogout)
        request.method = .post
        return session.ocombine.dataTaskPublisher(for: request)
            .map {
                self.barrierQueue.sync {
                    self.session = URLSession(configuration: self.configuration, token: nil)
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

    public enum MolgenisError: Error {
        case invalidURL(message: String)
    }
}
