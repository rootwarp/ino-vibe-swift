//
//  File.swift
//  
//
//  Created by Mindhack on 12/15/20.
//

import XCTest
import Combine
@testable import ino_vibe_swift

final class DeviceTests: XCTestCase {

    var manager: DeviceAccessible?
    var auth0 = Auth0()

    var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        let expectRecv = XCTestExpectation()
        auth0.login(username: "develop@ino-on.com", password: "inoon0312!")
            .sink(receiveCompletion: { _ in
                expectRecv.fulfill()
            }, receiveValue: {
                self.manager = DeviceManagerFactory.getManager(with: $0)
            })
            .store(in: &self.cancellables)

        wait(for: [expectRecv], timeout: 5.0)
    }

    func testDetail() {
        let expectComplete = XCTestExpectation()
        let expectRecv = XCTestExpectation()

        self.manager?.detail(for: "000000030000000000000001")
            .sink(receiveCompletion: {
                NSLog("DeviceTests.testDetail() -> Complete \($0)")
                expectComplete.fulfill()
            }, receiveValue: {
                NSLog("DeviceTests.testDetail() -> Receive \($0)")
                expectRecv.fulfill()
            })
            .store(in: &self.cancellables)

        wait(for: [expectRecv, expectComplete], timeout: 5.0)
    }

    func testList() {
        let expectComplete = XCTestExpectation()
        let expectRecv = XCTestExpectation()

        self.manager?.list(in: Device.InstallStatus.installed)
            .sink(receiveCompletion: {
                NSLog("DeviceTests.testList() -> Complete \($0)")
                expectComplete.fulfill()
            }, receiveValue: {
                NSLog("DeviceTests.testList() -> Receive \($0)")
                expectRecv.fulfill()
            })
            .store(in: &self.cancellables)

        wait(for: [expectRecv, expectComplete], timeout: 5.0)
    }

    /*
    func testResetAlarm() {

    }

    func testPendingUninstall() {

    }

    func testUninstall() {

    }

    func testDiscard() {

    }
 */

}
