//
//  File.swift
//  
//
//  Created by Mindhack on 12/15/20.
//

import Foundation
import Combine


public class Device {

    public enum Failure: Error {
        case unknownError
        case nonExist
        case unauthorized
        case noPermission
    }

    public enum DeviceType: Int, Codable {
        case unknown = 0
        case InoVibe = 2
        case InoVibeS = 3
        case InoVibePro = 100
    }

    public enum InstallStatus: Int, Codable {
        case initial = 0
        case requested
        case installing
        case installed
        case uninstalling
        case discarded
        case waitInstallComplete
    }

    public struct Entity: Codable {
        var id: String
        var alias: String?
        var groupName: String?
        var latitude: Double?
        var longitude: Double?
        var installer: String?
        var battery: Int?
        var temperature: Int?
        var rssi: Int?

        var installStatus: InstallStatus
        var devType: DeviceType
        var alivePeriodInMinutes: Int?
        var isAlarmed: Bool

        var installDate: String?
        var updateDate: String?
        var alarmDate: String?

        private enum CodingKeys: String, CodingKey {
            case id = "devid"
            case alias = "alias"
            case groupName = "group_name"
            case latitude = "lat"
            case longitude = "lng"
            case installer = "installer"
            case battery = "bat"
            case temperature = "temp"
            case rssi = "rssi"
            case installStatus = "install_status"
            case devType = "dev_type"
            case alivePeriodInMinutes = "period"
            case isAlarmed = "is_alarmed"
            case installDate = "install_date"
            case updateDate = "update_date"
            case alarmDate = "alarm_date"
        }
    }

}

struct ListResponse: Codable {
    var devices: [Device.Entity]
    var installStatus: Device.InstallStatus

    private enum CodingKeys: String, CodingKey {
        case devices = "devs"
        case installStatus = "install_status"
    }
}

public protocol DeviceAccessible {
    func list(in status: Device.InstallStatus) -> AnyPublisher<[Device.Entity], Error>
    func detail(for id: String) -> AnyPublisher<Device.Entity, Error>
}

final public class DeviceManagerFactory {

    public static func getManager(with accessToken: String) -> DeviceAccessible {
        return DeviceManagerV3(with: accessToken)
    }

}

final class DeviceManagerV3: DeviceAccessible {

    private let base = "https://rest.ino-vibe.ino-on.dev/rest/v3/device"
    private let defaultTimeoutSeconds = 3
    private let defaultRetryCount = 5

    private var accessToken: String
    private var defaultHTTPHeaderFields: [String:String]
    private var cancellables = Set<AnyCancellable>()

    init(with accessToken: String) {
        self.accessToken = accessToken
        self.defaultHTTPHeaderFields = [
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer \(self.accessToken)"
        ]
    }

    func detail(for id: String) -> AnyPublisher<Device.Entity, Error> {

        let publisher = PassthroughSubject<Device.Entity, Error>()

        let url = URL(string: "\(self.base)/\(id)")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.allHTTPHeaderFields = self.defaultHTTPHeaderFields

        URLSession.shared
            .dataTaskPublisher(for: req)
            .timeout(.seconds(defaultTimeoutSeconds), scheduler: DispatchQueue.main)
            .retry(defaultRetryCount)
            .tryMap { try JSONDecoder().decode(Device.Entity.self, from: $0.data) }
            .sink(receiveCompletion: { _ in
                publisher.send(completion: .finished)
            }, receiveValue: {
                NSLog("DeviceManagerV3.detail() -> \($0)")
                publisher.send($0)

            })
            .store(in: &self.cancellables)

        return publisher.eraseToAnyPublisher()
    }

    func list(in status: Device.InstallStatus) -> AnyPublisher<[Device.Entity], Error> {
        let publisher = PassthroughSubject<[Device.Entity], Error>()

        let url = URL(string: "\(self.base)?install_status=\(status.rawValue)")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.allHTTPHeaderFields = self.defaultHTTPHeaderFields

        URLSession.shared
            .dataTaskPublisher(for: req)
            .timeout(.seconds(defaultTimeoutSeconds), scheduler: DispatchQueue.main)
            .retry(defaultRetryCount)
            .tryMap { output -> ListResponse in
                guard let resp = output.response as? HTTPURLResponse else {
                    throw Device.Failure.unknownError
                }

                switch resp.statusCode {
                case 200:
                    return try JSONDecoder().decode(ListResponse.self, from: output.data)
                case 401:
                    throw Device.Failure.unauthorized
                case 403:
                    throw Device.Failure.noPermission
                default:
                    throw Device.Failure.unknownError
                }
            }
            .tryMap { $0.devices }
            .sink(receiveCompletion: {
                switch $0 {
                case .finished:
                    publisher.send(completion: .finished)
                case .failure(let err):
                    publisher.send(completion: .failure(err))
                }
            }, receiveValue: {
                publisher.send($0)
            })
            .store(in: &self.cancellables)

        return publisher.eraseToAnyPublisher()
    }
}
