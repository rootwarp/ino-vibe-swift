//
//  File.swift
//  
//
//  Created by Mindhack on 12/15/20.
//

import Foundation
import Combine


struct Auth0Credentials: Codable {
    var accessToken: String

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

class Auth0 {

    private var cancellables = Set<AnyCancellable>()
    private let audience = "https://api.prod.ino-vibe.ino-on.net/app/"
    private let clientID = "wRSzzwMOjvZ713ShO76t0MSIcVZHy78C"
    private let clientSecret = "iV09ldjHqz1XFYzTjvWJgZG6PA2Px1WZOXFgfNHMY0njGRqN7kc77X8pBmBDESMo"

    enum APIError: Error {
        case authFailed
    }

    func login(username: String, password: String) -> AnyPublisher<String, Error> {
        let publisher = PassthroughSubject<String, Error>()

        let path = "https://ino-vibe.auth0.com/oauth/token"
        let data = [
            "username": username,
            "password": password,
            "grant_type": "password",
            "audience": audience,
            "client_id": clientID,
            "client_secret": clientSecret,
        ]

        var req = URLRequest(url: URL(string: path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = [
            "Content-Type": "application/json; charset=utf-8"
        ]
        req.httpBody = try! JSONEncoder().encode(data)

        URLSession.shared
            .dataTaskPublisher(for: req)
            .timeout(5.0, scheduler: RunLoop.current)
            .retry(5)
            .tryMap { try JSONDecoder().decode(Auth0Credentials.self, from: $0.data) }
            .sink(receiveCompletion: {
                NSLog("Auth0.login() -> receiveCompletion \($0)")
                switch $0 {
                case .finished:
                    publisher.send(completion: .finished)
                default:
                    publisher.send(completion: .failure(APIError.authFailed))
                }
            }, receiveValue: {
                NSLog("Auth0.login() -> receiveValue")
                publisher.send($0.accessToken)
            })
            .store(in: &cancellables)

        return publisher.eraseToAnyPublisher()
    }

}
