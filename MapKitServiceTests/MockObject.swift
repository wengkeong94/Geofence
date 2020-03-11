//
//  MockObject.swift
//  MapKitServiceTests
//
//  Created by Walter Wong on 29/02/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import RxSwift
import MapKit
@testable import MapKitService

class MockGeofenceStorage: GeofenceStorage {
  enum Invocations: Equatable {
    case loadGeofence
    case saveGeofence
  }

  var invocations: [Invocations] = []
  var geofences: [GeofenceEntity] = []

  var loadGeofence_subject = BehaviorSubject<[GeofenceEntity]>(value: [])
  func loadGeofence() -> Single<[GeofenceEntity]> {
    invocations.append(.loadGeofence)
    return loadGeofence_subject.take(1).asSingle()
  }

  func saveGeofence(_ geofences: [GeofenceEntity]) -> Completable {
    invocations.append(.saveGeofence)
    self.geofences = geofences
    loadGeofence_subject.onNext(geofences)
    return .empty()
  }
}

class MockMapKitHandler: MapKitHandler {
  enum Invocations: Equatable {
    case drawAndStartMonitorGeofence
    case removeAndStopMonitorGeofence
    case filterSelectedGeofence
    case shouldInsertInterceptedGeofence
    case selectNextSelectedGeofence
  }

  var invocations: [Invocations] = []

  func drawAndStartMonitorGeofence(geofence: GeofenceEntity) {
    invocations.append(.drawAndStartMonitorGeofence)
  }

  func removeAndStopMonitorGeofence(geofence: GeofenceEntity) {
    invocations.append(.removeAndStopMonitorGeofence)
  }

  var stub_filterSelectedGeofence: SelectedGeofenceEntity?
  func filterSelectedGeofence(from geofences: [GeofenceEntity], basedOn regionId: String) throws -> SelectedGeofenceEntity {
    invocations.append(.filterSelectedGeofence)
    if let geofence = stub_filterSelectedGeofence {
      return geofence
    }
    throw MapKitSynchronizerError.geofenceNotFound
  }

  var stub_shouldInsertInterceptedGeofence: Bool = false
  func shouldInsertInterceptedGeofence(from geofences: [SelectedGeofenceEntity], selectedGeofence: SelectedGeofenceEntity) -> Bool {
    invocations.append(.shouldInsertInterceptedGeofence)
    return stub_shouldInsertInterceptedGeofence
  }

  var stub_selectNextSelectedGeofence: SelectedGeofenceEntity?
  func selectNextSelectedGeofence(from geofences: [SelectedGeofenceEntity], selectedGeofence: SelectedGeofenceEntity) -> SelectedGeofenceEntity {
    invocations.append(.selectNextSelectedGeofence)
    if let geofence = stub_selectNextSelectedGeofence {
      return geofence
    }
    return selectedGeofence
  }
}

class MockObject {
  static func generateMockGeofenceEntity(id: String,
                                         longitude: Double = 1.0,
                                         latitude: Double = 1.0,
                                         zoneGeofence: Geofence,
                                         wifiGeofence: Geofence,
                                         note: String = "note") -> GeofenceEntity {
    return GeofenceArea(id: id,
                        coordinate: CLLocationCoordinate2DMake(latitude, longitude),
                        zoneGeofence: zoneGeofence,
                        wifiGeofence: wifiGeofence,
                        note: note)
  }
}
