//
//  GeofenceStorage.swift
//  MapKitService
//
//  Created by Walter Wong on 29/02/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import Foundation
import RxSwift

struct GeofenceConstant {
  static let geofenceListKey = "geofenceListKey"
}

protocol GeofenceStorage {
  func loadGeofence() -> Single<[GeofenceEntity]>
  func saveGeofence(_ geofences: [GeofenceEntity]) -> Completable
}

class GeofenceStorageImp: GeofenceStorage {
  private let geofenceStorageScheduler: SchedulerType

  init(geofenceStorageScheduler: SchedulerType = SerialDispatchQueueScheduler(internalSerialQueueName: "com.setel.geofenceStorageScheduler")) {
    self.geofenceStorageScheduler = geofenceStorageScheduler
  }

  func loadGeofence() -> Single<[GeofenceEntity]> {
    return Single.create { single in
      let decoder = JSONDecoder()
      guard let savedData = UserDefaults.standard.data(forKey: GeofenceConstant.geofenceListKey),
        let geofenceAreas = try? decoder.decode(Array.self, from: savedData) as [GeofenceArea] else {
          single(.success([]))
          return Disposables.create()
      }
        single(.success(geofenceAreas))

      return Disposables.create()
      }.subscribeOn(geofenceStorageScheduler)
  }

  func saveGeofence(_ geofences: [GeofenceEntity]) -> Completable {
    return Completable.create { single in
      let encoder = JSONEncoder()
      do {
        let geofences = geofences.map { (geofence) -> GeofenceArea in
          return GeofenceArea.init(id: geofence.id,
                                   coordinate: geofence.coordinate,
                                   zoneGeofence: geofence.zoneGeofence,
                                   wifiGeofence: geofence.wifiGeofence,
                                   note: geofence.note)
        }
        let data = try encoder.encode(geofences)
        UserDefaults.standard.set(data, forKey: GeofenceConstant.geofenceListKey)
        single(.completed)
      } catch let error {
        #if DEBUG
        fatalError("Failed in saving geofence locations: \(error.localizedDescription)")
        #else
        single(.error(MapKitSynchronizerError.unknownError))
        #endif
      }
      return Disposables.create()
      }.subscribeOn(geofenceStorageScheduler)
  }
}
