//
//  File.swift
//  
//
//  Created by Mindhack on 12/15/20.
//

import Foundation
import Combine

public class User {
    public struct Profile: Codable {
        var username: String
        var groupID: String
        var groupName: String
        var isAdmin: Bool

        private enum CodingKeys: String, CodingKey {
            case username = "username"
            case groupID = "group_id"
            case groupName = "group_name"
            case isAdmin = "is_admin"
        }
    }

    public enum Failure: Error {
        case unknownError
    }
}

public protocol UserAccessible {
    func profile() -> AnyPublisher<User.Profile, Error>
    func authenticateFirebase() -> AnyPublisher<String, Error>
}

final public class UserManagerFactory {

    public static func getManager(with accessToken: String) -> UserAccessible {
        return UserManagerV3(with: accessToken)
    }

}

final class UserManagerV3: UserAccessible {

    private let baseURL = "https://rest.ino-vibe.ino-on.dev/rest/v3"
    private var accessToken: String

    private var cancellables = Set<AnyCancellable>()

    init(with accessToken: String) {
        self.accessToken = accessToken
    }

    /**
     Request user's profile.
     */
    func profile() -> AnyPublisher<User.Profile, Error> {
        NSLog("UserManager.profile()")

        let publisher = PassthroughSubject<User.Profile, Error>()

        let url = URL(string: "\(self.baseURL)/user/profile")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.allHTTPHeaderFields = [
            "Authorization": "Bearer \(self.accessToken)"
        ]

        URLSession.shared
            .dataTaskPublisher(for: req)
            .timeout(1.0, scheduler: RunLoop.current)
            .retry(5)
            .tryMap { try JSONDecoder().decode(User.Profile.self, from: $0.data) }
            .sink(receiveCompletion: {
                switch $0 {
                case .finished:
                    publisher.send(completion: .finished)
                default:
                    publisher.send(completion: .failure(User.Failure.unknownError))
                }
            }, receiveValue: {
                publisher.send($0)
            })
            .store(in: &self.cancellables)

        return publisher.eraseToAnyPublisher()
    }

    /**
     Get custom token to authenticate Firebase application.
     */
    func authenticateFirebase() -> AnyPublisher<String, Error> {
        NSLog("UserManager.authenticateFirebase()")

        let publisher = PassthroughSubject<String, Error>()

        let url = URL(string: "\(self.baseURL)/auth_firebase")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = [
            "Authorization": "Bearer \(self.accessToken)"
        ]

        URLSession.shared
            .dataTaskPublisher(for: req)
            .timeout(1.0, scheduler: RunLoop.current)
            .retry(5)
            .tryMap {
                if let token = String(data: $0.data, encoding: .utf8) {
                    return token
                } else {
                    throw User.Failure.unknownError
                }
            }
            .sink(receiveCompletion: {
                switch $0 {
                case .finished:
                    publisher.send(completion: .finished)
                default:
                    publisher.send(completion: .failure(User.Failure.unknownError))
                }
            }, receiveValue: {
                publisher.send($0)
            })
            .store(in: &self.cancellables)

        return publisher.eraseToAnyPublisher()
    }
}
