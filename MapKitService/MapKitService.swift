//
//  MapKitService.swift
//  MapKitService
//
//  Created by Walter Wong on 29/02/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit
import MapKit
import CoreLocation

enum UserAction {
  case add
  case remove
  case refresh
}

public final class MapKitService: MapKit {
  lazy public var currentGeofence: Observable<SelectedGeofenceEntity?> = {
    return mapKitSynchronizer.currentGeofence
  }()

  lazy public var totalGeofencesStream: Observable<[GeofenceEntity]> = {
    return mapKitSynchronizer.totalGeofences
  }()

  private let mapView: MKMapView
  private var locationManager = CLLocationManager()
  private var mapKitSynchronizer: MapKitSynchronizer
  private let mapKitScheduler: SchedulerType
  private let disposeBag = DisposeBag()

  public init(mapView: MKMapView,
              mapKitScheduler: SchedulerType = SerialDispatchQueueScheduler(internalSerialQueueName: "com.setel.mapKitScheduler")) {
    self.mapView = mapView
    self.mapKitScheduler = mapKitScheduler

    let mapKitHandler: MapKitHandler = DefaultMapKitHandler(mapView: mapView, locationManager: locationManager)
    self.mapKitSynchronizer = DefaultMapKitSynchronizer(mapView: mapView,
                                                        locationManager: locationManager,
                                                        mapKitHandler: mapKitHandler)
  }

  private func setupData() {
    mapKitSynchronizer.getAllGeofenceArea()
    .observeOn(mapKitScheduler)
      .flatMap { [weak self] geofences -> Single<[Void]> in
        guard let this = self else { return .error(MapKitSynchronizerError.unknownError) }
        return this.refreshGeofence(geofences)
    }
    .subscribe().disposed(by: disposeBag)
  }

  private func refreshGeofence(_ geofences: [GeofenceEntity]) -> Single<[Void]> {
    return Observable.from(geofences)
    .observeOn(mapKitScheduler)
      .flatMap({ [weak self] geofence -> Single<Void> in
        guard let this = self else { return .error(MapKitSynchronizerError.unknownError) }
        return this.mapKitSynchronizer.updateGeofence(geofence, userAction: .refresh).andThen(.just(()))
      })
    .toArray()
  }

  public func startService() {
    setupData()
  }

  public func addGeofence(longitude: Double, latitude: Double, radius: Double, note: String, wifiStrength: Double) {
    let zoneGeofence = GeofenceObj(radius: radius,
                                   geofenceType: .zone)
    let wifiGeofence = GeofenceObj(radius: (radius + wifiStrength),
                                   geofenceType: .wifi)
    let geofence = GeofenceArea(coordinate: CLLocationCoordinate2DMake(latitude, longitude),
                                zoneGeofence: zoneGeofence,
                                wifiGeofence: wifiGeofence,
                                note: note)
    mapKitSynchronizer.updateGeofence(geofence, userAction: .add).observeOn(mapKitScheduler).subscribe().disposed(by: disposeBag)
  }

  public func removeGeofence(geofence: GeofenceEntity) {
    mapKitSynchronizer.updateGeofence(geofence, userAction: .remove).observeOn(mapKitScheduler).subscribe().disposed(by: disposeBag)
  }

  public func zoomToUserLocation() {
    mapKitSynchronizer.zoomToUserLocation()
  }
}
