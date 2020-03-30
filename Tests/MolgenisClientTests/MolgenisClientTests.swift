import XCTest
import MolgenisClient
import OpenCombine

final class MolgenisClientTests: XCTestCase {
    func testDownloadOneEntity() throws {
        let expectation = XCTestExpectation()
        let molgenis = try MolgenisClient(baseURL: URL(string: "https://directory.bbmri-eric.eu/")!)
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

    func testDownloadCollectionOfEntity() throws {
        let expectation = XCTestExpectation()
        let molgenis = try MolgenisClient(baseURL: URL(string: "https://directory.bbmri-eric.eu/")!)
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
        try molgenis.get(with: subscriber, filter: nil)
        wait(for: [expectation], timeout: 2)
    }

    func testAggregateXAndY() throws {
        let expectation = XCTestExpectation()
        let molgenis = try MolgenisClient(baseURL: URL(string: "https://samples.rd-connect.eu/")!)
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
        let molgenis = try MolgenisClient(baseURL: URL(string: "https://samples.rd-connect.eu/")!)
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
        let molgenis = try MolgenisClient(baseURL: URL(string: "https://samples.rd-connect.eu/")!)
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
        let molgenis = try MolgenisClient(baseURL: URL(string: "https://samples.rd-connect.eu/")!)
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

    func testInvalidLogin() throws {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        let molgenis = try MolgenisClient(baseURL: URL(string: "https://directory.bbmri-eric.eu/")!)
        let cancelable = molgenis.login(user: User.invalid.username, password: User.invalid.password).sink(receiveCompletion: { (_) in }) { loggedIn in
            if loggedIn {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2)
        cancelable.cancel()
    }
    
    func testValidLogin() throws {
        let expectation = XCTestExpectation()
        let molgenis = try MolgenisClient(baseURL: URL(string: "https://directory.bbmri-eric.eu/")!)
        let cancelable = molgenis.login(user: User.admin.username, password: User.admin.password)
            .sink(receiveCompletion: {
                (completion) in
                self.evaluate(completion: completion)
            }) { loggedIn in
            if loggedIn {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2)
        cancelable.cancel()
    }
    
    func testLogout() throws {
        let expectation = XCTestExpectation()
        let molgenis = try MolgenisClient(baseURL: URL(string: "https://directory.bbmri-eric.eu")!)
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

    private func evaluate<T: Error>(completion: Subscribers.Completion<T>, with expectation: XCTestExpectation? = nil, function: String = #function) {
        switch completion {
        case .finished:
            print("Finished in \(function)")
            expectation?.fulfill()
        case .failure(let error):
            print("Failure in \(function): \(error)")
            XCTFail(error.localizedDescription)
        }
    }
}
