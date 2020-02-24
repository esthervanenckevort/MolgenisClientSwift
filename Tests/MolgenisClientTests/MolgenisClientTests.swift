import XCTest
import MolgenisClient
import OpenCombine

final class MolgenisClientTests: XCTestCase {
    func testDownloadOneEntity() {
        let expectation = XCTestExpectation()
        guard let molgenis = MolgenisClient(baseURL: URL(string: "https://directory.bbmri-eric.eu/")!) else {
            XCTFail()
            return
        }
        let subscriber = Subscribers.Sink<EntityType, Error>(receiveCompletion: {
            (completion) in
            switch completion {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .finished:
                break
            }
        }) { (test: EntityType) in
            XCTAssertEqual("sys_md_Attribute", test._id)
            expectation.fulfill()
        }
        molgenis.get(id: "sys_md_Attribute", with: subscriber)
        wait(for: [expectation], timeout: 2)
    }

    func testDownloadCollectionOfEntity() {
        let expectation = XCTestExpectation()
        guard let molgenis = MolgenisClient(baseURL: URL(string: "https://directory.bbmri-eric.eu/")!) else {
            XCTFail()
            return
        }
        let subscriber = Subscribers.Sink<EntityType, Error>(receiveCompletion: {
            (completion) in
            switch completion {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .finished:
                expectation.fulfill()
            }
        }) { (_) in
            
        }
        molgenis.get(with: subscriber)
        wait(for: [expectation], timeout: 2)
    }
    

    func testInvalidLogin() {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        guard let molgenis = MolgenisClient(baseURL: URL(string: "https://directory.bbmri-eric.eu/")!) else {
            XCTFail()
            return
        }
        let cancelable = molgenis.login(user: User.invalid.username, password: User.invalid.password).sink(receiveCompletion: { (_) in }) { loggedIn in
            if loggedIn {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2)
        cancelable.cancel()
    }
    
    func testValidLogin() {
        let expectation = XCTestExpectation()
        guard let molgenis = MolgenisClient(baseURL: URL(string: "https://directory.bbmri-eric.eu/")!) else {
            XCTFail()
            return
        }
        let cancelable = molgenis.login(user: User.admin.username, password: User.admin.password)
            .sink(receiveCompletion: { (_) in }) { loggedIn in
            if loggedIn {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2)
        cancelable.cancel()
    }
    
    func testLogout() {
        let expectation = XCTestExpectation()
        guard let molgenis = MolgenisClient(baseURL: URL(string: "https://directory.bbmri-eric.eu")!) else {
            XCTFail()
            return
        }
        let cancelable = molgenis.login(user: User.admin.username, password: User.admin.password)
            .flatMap { _ in molgenis.logout() }
            .sink(receiveCompletion: { (_) in }) { loggedOut in
            if loggedOut {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2)
        cancelable.cancel()
    }
}
