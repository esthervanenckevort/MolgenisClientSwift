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
        let subscriber = AnySubscriber<EntityType, Error>(Subscribers.Sink<EntityType, Error>(receiveCompletion: {
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
        })

        molgenis.get(id: "sys_md_Attribute", with: subscriber)
        wait(for: [expectation], timeout: 2)
    }

    func testDownloadCollectionOfEntity() {
        let expectation = XCTestExpectation()
        guard let molgenis = MolgenisClient(baseURL: URL(string: "https://directory.bbmri-eric.eu/")!) else {
            XCTFail()
            return
        }
        let subscriber = AnySubscriber<EntityType, Error>(Subscribers.Sink<EntityType, Error>(receiveCompletion: {
            (completion) in
            switch completion {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .finished:
                expectation.fulfill()
            }
        }) { (_) in
            
        })
        molgenis.get(with: subscriber)
        wait(for: [expectation], timeout: 2)
    }

    func testAggregateXAndY() throws {
        let expectation = XCTestExpectation()
        guard let molgenis = MolgenisClient(baseURL: URL(string: "https://samples.rd-connect.eu/")!) else {
            XCTFail()
            return
        }
        let subscriber = AnySubscriber<AggregateResponse<Int?, Int?>, Error>(Subscribers.Sink<AggregateResponse<Int?, Int?>, Error>(receiveCompletion: { completion in
            switch completion {
            case .finished:
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }) { response in
            
        })
        try molgenis.aggregates(entity: Sample.self, x: "AgeAtSampling", y: "AgeAtDiagnosis").subscribe(subscriber)
        wait(for: [expectation], timeout: 2)
    }

    func testAggregateXOnly() throws {
        let expectation = XCTestExpectation()
        guard let molgenis = MolgenisClient(baseURL: URL(string: "https://samples.rd-connect.eu/")!) else {
            XCTFail()
            return
        }
        let subscriber = AnySubscriber<AggregateResponse<Int?, Int?>, Error>(Subscribers.Sink<AggregateResponse<Int?, Int?>, Error>(receiveCompletion: { completion in
            switch completion {
            case .finished:
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }) { response in

        })
        try molgenis.aggregates(entity: Sample.self, x: "AgeAtSampling").subscribe(subscriber)
        wait(for: [expectation], timeout: 2)
    }

    func testAggregateXOnlyWithDistinct() throws {
        let expectation = XCTestExpectation()
        guard let molgenis = MolgenisClient(baseURL: URL(string: "https://samples.rd-connect.eu/")!) else {
            XCTFail()
            return
        }
        let subscriber = AnySubscriber<AggregateResponse<Int?, Int?>, Error>(Subscribers.Sink<AggregateResponse<Int?, Int?>, Error>(receiveCompletion: { completion in
            switch completion {
            case .finished:
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }) { response in

        })
        try molgenis.aggregates(entity: Sample.self, x: "AgeAtSampling", distinct: "ParticipantID").subscribe(subscriber)
        wait(for: [expectation], timeout: 2)
    }

    func testAggregateXYWithDistinct() throws {
        let expectation = XCTestExpectation()
        guard let molgenis = MolgenisClient(baseURL: URL(string: "https://samples.rd-connect.eu/")!) else {
            XCTFail()
            return
        }
        let subscriber = AnySubscriber<AggregateResponse<Int?, Int?>, Error>(Subscribers.Sink<AggregateResponse<Int?, Int?>, Error>(receiveCompletion: { completion in
            switch completion {
            case .finished:
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }) { response in

        })
        try molgenis.aggregates(entity: Sample.self, x: "AgeAtSampling", y: "AgeAtDiagnosis", distinct: "ParticipantID").subscribe(subscriber)
        wait(for: [expectation], timeout: 2)
    }

    struct Sample: EntityResponse {
        static var _entityName = "rd_connect_Sample"
        var _id: String { ID }
        var _label: String { ID }
        let ID: String
        let AgeAtSampling: Int?
        let AgeAtDiagnosis: Int?
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
