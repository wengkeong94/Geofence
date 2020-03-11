//
//  MapKitSynchronizerTests.swift
//  MapKitServiceTests
//
//  Created by Walter Wong on 29/02/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import XCTest
import MapKit
import RxSwift
import RxTest
import RxBlocking
import RxCocoa
@testable import MapKitService

class MapKitSynchronizerTests: XCTestCase {

  var mapKitSynchronizer: MapKitSynchronizer!
  var geofenceStorage: MockGeofenceStorage!
  var mapKitHandler: MockMapKitHandler!

  override func setUp() {
    super.setUp()
    let mapView = MKMapView()
    let locationManager = CLLocationManager()
    geofenceStorage = MockGeofenceStorage()
    mapKitHandler = MockMapKitHandler()

    mapKitSynchronizer = DefaultMapKitSynchronizer(mapView: mapView,
                                                   locationManager: locationManager,
                                                   mapKitHandler: mapKitHandler,
                                                   geofenceStorage: geofenceStorage)
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  func test_addGeofence() {
    let initialStorage = try? geofenceStorage.loadGeofence().toBlocking().first()
    XCTAssertEqual(initialStorage?.count, 0)

    let mockGeofenceEntity = MockObject.generateMockGeofenceEntity(id: "geofence1", zoneGeofence: mockZoneGeofence, wifiGeofence: mockWifiGeofence)

    _ = try? mapKitSynchronizer.updateGeofence(mockGeofenceEntity, userAction: .add).toBlocking().first()
    XCTAssertEqual(mapKitHandler.invocations.count, 1)
    XCTAssertEqual(mapKitHandler.invocations.first, MockMapKitHandler.Invocations.drawAndStartMonitorGeofence)
    XCTAssertEqual(geofenceStorage.invocations.last, MockGeofenceStorage.Invocations.saveGeofence)
    XCTAssertEqual(geofenceStorage.geofences.count, 1)
    XCTAssertTrue(geofenceStorage.geofences.first?.isEqual(mockGeofenceEntity) ?? false)
  }

  func test_removeGeofence() {
    let mockGeofenceEntity1 = MockObject.generateMockGeofenceEntity(id: "geofence1", zoneGeofence: mockZoneGeofence, wifiGeofence: mockWifiGeofence)
    let mockGeofenceEntity2 = MockObject.generateMockGeofenceEntity(id: "geofence2", zoneGeofence: mockZoneGeofence, wifiGeofence: mockWifiGeofence)
    let mockGeofenceEntity3 = MockObject.generateMockGeofenceEntity(id: "geofence3", zoneGeofence: mockZoneGeofence, wifiGeofence: mockWifiGeofence)
    let mockGeofences = [mockGeofenceEntity1, mockGeofenceEntity2, mockGeofenceEntity3]
    _ = try? geofenceStorage.saveGeofence(mockGeofences).toBlocking().first()

    let initialStorage = try? geofenceStorage.loadGeofence().toBlocking().first()
    XCTAssertEqual(initialStorage?.count, 3)

    _ = try? mapKitSynchronizer.updateGeofence(mockGeofenceEntity2, userAction: .remove).toBlocking().first()
    XCTAssertEqual(mapKitHandler.invocations.count, 1)
    XCTAssertEqual(mapKitHandler.invocations.first, MockMapKitHandler.Invocations.removeAndStopMonitorGeofence)
    XCTAssertEqual(geofenceStorage.invocations.last, MockGeofenceStorage.Invocations.saveGeofence)
    XCTAssertEqual(geofenceStorage.geofences.count, 2)
    XCTAssertFalse(geofenceStorage.geofences.contains(where: { geofence in
      return geofence.isEqualTo(mockGeofenceEntity2)
    }))
  }

  func test_removeGeofence_when_notFound() {
    let mockGeofenceEntity1 = MockObject.generateMockGeofenceEntity(id: "geofence1", zoneGeofence: mockZoneGeofence, wifiGeofence: mockWifiGeofence)
    let mockGeofenceEntity2 = MockObject.generateMockGeofenceEntity(id: "geofence2", zoneGeofence: mockZoneGeofence, wifiGeofence: mockWifiGeofence)
    let mockGeofenceEntity3 = MockObject.generateMockGeofenceEntity(id: "geofence3", zoneGeofence: mockZoneGeofence, wifiGeofence: mockWifiGeofence)
    let mockGeofences = [mockGeofenceEntity1, mockGeofenceEntity2]
    _ = try? geofenceStorage.saveGeofence(mockGeofences).toBlocking().first()

    XCTAssertThrowsError(try mapKitSynchronizer.updateGeofence(mockGeofenceEntity3, userAction: .remove).toBlocking().first())
  }

  func test_didEnterRegion() {
    let geofenceId = "geofence1"
    let mockGeofence = MockObject.generateMockGeofenceEntity(id: geofenceId, zoneGeofence: mockZoneGeofence, wifiGeofence: mockWifiGeofence)
    _ = try? geofenceStorage.saveGeofence([mockGeofence]).toBlocking().first()

    mapKitHandler.stub_filterSelectedGeofence = (mockGeofence, .zone)
    mapKitHandler.stub_shouldInsertInterceptedGeofence = true

    mapKitSynchronizer.didEnterRegion(regionId: geofenceId)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      let selectedGeofenceEntity = try? self.mapKitSynchronizer.currentGeofence.toBlocking().first()!
      XCTAssertNotNil(selectedGeofenceEntity)
      XCTAssertTrue(selectedGeofenceEntity?.geofence.isEqualTo(mockGeofence) ?? false)
      XCTAssertEqual(self.mapKitHandler.invocations.count, 2)
      XCTAssertEqual(self.mapKitHandler.invocations.first, MockMapKitHandler.Invocations.filterSelectedGeofence)
      XCTAssertEqual(self.mapKitHandler.invocations.last, MockMapKitHandler.Invocations.shouldInsertInterceptedGeofence)
    }
  }

//  func testasd() {
//    let geofenceId = "geofence1"
//    let mockGeofence = MockObject.generateMockGeofenceEntity(id: geofenceId, zoneGeofence: mockZoneGeofence, wifiGeofence: mockWifiGeofence)
//    geofenceStorage.saveGeofence([mockGeofence])
//
//    mapKitHandler.stub_filterSelectedGeofence = (mockGeofence, .zone)
//    mapKitHandler.stub_shouldInsertInterceptedGeofence = true
//
//    let scheduler = TestScheduler(initialClock: 0)
//    let disposeBag = DisposeBag()
//
//    let selectedGeofenceObserver = scheduler.createObserver(SelectedGeofenceEntity?.self)
//
//    mapKitSynchronizer.currentGeofence.bind(to: selectedGeofenceObserver).disposed(by: disposeBag)
//
//    scheduler.scheduleAt(20) {
//      self.mapKitSynchronizer.didEnterRegion(regionId: geofenceId)
//    }
//
//    scheduler.start()
//
//    XCTAssertEqual(selectedGeofenceObserver.events.map { Recorded.next($0.time, $0.value.element??.geofence.id ?? "") }, [
//      Recorded.next(0, ""),
//      Recorded.next(20, geofenceId),
//      ])
//  }


  let mockZoneGeofence: Geofence = GeofenceObj(radius: 100, geofenceType: .zone)
  let mockWifiGeofence: Geofence = GeofenceObj(radius: 200, geofenceType: .zone)
}
