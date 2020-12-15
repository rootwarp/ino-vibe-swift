import XCTest
import Combine
@testable import ino_vibe_swift


final class UserTests: XCTestCase {

    var cancellables = Set<AnyCancellable>()

    var auth0 = Auth0()
    var userManager: UserAccessible?

    override func setUpWithError() throws {
        NSLog("Setup")

        let expectRecv = XCTestExpectation(description: "Wait API Call")

        self.auth0.login(username: "develop@ino-on.com", password: "inoon0312!")
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in
                expectRecv.fulfill()
            }, receiveValue: {
                self.userManager = UserManagerFactory.getManager(with: $0)
            })
            .store(in: &self.cancellables)

        wait(for: [expectRecv], timeout: 5.0)
    }

    func testProfile() {
        let expectRecv = XCTestExpectation(description: "Wait API Call")

        self.userManager?.profile()
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: {
                NSLog("testProfile \($0)")

                expectRecv.fulfill()
            }, receiveValue: {
                NSLog("\($0)")
                XCTAssert($0.username == "develop@ino-on.com")
                XCTAssert($0.groupName == "이노온")
                XCTAssert($0.isAdmin == false)
            })
            .store(in: &self.cancellables)

        wait(for: [expectRecv], timeout: 5.0)
    }

    func testAuthFirebase() {
        let expectRecv = XCTestExpectation(description: "Wait API Call")

        self.userManager?.authenticateFirebase()
            .sink(receiveCompletion: {
                NSLog("testAuthFirebase \($0)")
                expectRecv.fulfill()
            }, receiveValue: {
                XCTAssert($0 != "")
            })
            .store(in: &self.cancellables)

        wait(for: [expectRecv], timeout: 5.0)
    }

    static var allTests = [
        ("testProfile", testProfile),
        ("testAuthFirebase", testAuthFirebase),
    ]
}
