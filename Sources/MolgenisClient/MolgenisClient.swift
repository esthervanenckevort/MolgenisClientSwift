import Foundation
import OSLog
import Combine

public class MolgenisClient {
    private let baseURL: URL
    private var apiEndPointLogin: URL { baseURL.appendingPathComponent("api/v1/login") }
    private var apiEndPointLogout: URL { baseURL.appendingPathComponent("api/v1/logout") }
    private var apiPathV2: URL { baseURL.appendingPathComponent("api/v2/") }
    private let session: URLSession
    private var login: LoginResponse?
    private var barrierQueue = DispatchQueue(label: "barrier")
    private var processQueue = DispatchQueue.global()
    
    public init?(baseURL url: URL, using session: URLSession = .shared) {
        guard url.path == "/" || url.path == "" else {
            os_log("URL [%@] must not contain the API path.", [url])
            return nil
        }
        self.baseURL = url
        self.session = session
    }
    
    public func get<T: Entity>(with id: String) -> AnyPublisher<T, Error> {
        let url = apiPathV2.appendingPathComponent(T._entityName).appendingPathComponent(id)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return makeGETRequest(url: url)
            .flatMap { self.session.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .print(#function)
            .map { $0.data }
            .decode(type: T.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    public func login(user: String, password: String) -> AnyPublisher<Bool, Never> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return makePOSTRequest(url: apiEndPointLogin, body: Login(username: user, password: password))
            .flatMap { self.session.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .map { $0.data }
            .decode(type: LoginResponse.self, decoder: decoder)
            .receive(on: barrierQueue) // Use barrier queue to avoid reading concurrent access to self.login
            .map {
                self.login = $0
                return true
            }
            .receive(on: processQueue) // Switch back to a concurrent queue
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }
    
    public func logout() -> AnyPublisher<Bool, Never> {
        let login: Login? = nil
        return makePOSTRequest(url: apiEndPointLogout, body: login)
            .flatMap { self.session.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .print(#function)
            .map { ($0.response as? HTTPURLResponse)?.statusCode  == 200 }
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }
    
    private func makeGETRequest(url: URL) -> AnyPublisher<URLRequest, Error> {
        return Publishers.Sequence<[URL], Never>(sequence: [url])
            .receive(on: barrierQueue)  // Use barrier queue to avoid reading concurrent access to self.login
            .tryMap { (url) -> URLRequest in
                var request = URLRequest(url: url)
                request.httpMethod = Method.get.rawValue
                request.addValue(ContentType.json.rawValue, forHTTPHeaderField: Header.contentType.rawValue)
                if let token = self.login?.token {
                    request.addValue(token, forHTTPHeaderField: Header.token.rawValue)
                }
                return request
            }
            .receive(on: processQueue) // Switch back to a concurrent queue
            .eraseToAnyPublisher()
    }
    
    private func makePOSTRequest<T: Encodable>(url: URL, body: T?) -> AnyPublisher<URLRequest, Error> {
        let encoder = JSONEncoder()
        return Publishers.Sequence<[URL], Never>(sequence: [url])
            .receive(on: barrierQueue)  // Use barrier queue to avoid reading concurrent access to self.login
            .tryMap { (url) -> URLRequest in
                var request = URLRequest(url: url)
                request.httpMethod = Method.post.rawValue
                request.addValue(ContentType.json.rawValue, forHTTPHeaderField: Header.contentType.rawValue)
                if let token = self.login?.token {
                    request.addValue(token, forHTTPHeaderField: Header.token.rawValue)
                }
                if let body = body {
                    request.httpBody = try encoder.encode(body)
                }
                return request
            }
            .receive(on: processQueue) // Switch back to a concurrent queue
            .eraseToAnyPublisher()
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
        case json = "application/json"
    }
}
