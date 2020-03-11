//
//  MapKit.swift
//  MapKitService
//
//  Created by Walter Wong on 29/02/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import Foundation
import RxSwift

public enum MapKitType {
  case addMode
  case viewMode
}

public typealias SelectedGeofenceEntity = (geofence: GeofenceEntity, selectedType: GeofenceType)

public protocol MapKit {
  func startService()
  func zoomToUserLocation()
  func addGeofence(longitude: Double,
                   latitude: Double,
                   radius: Double,
                   note: String,
                   wifiStrength: Double)
  func removeGeofence(geofence: GeofenceEntity)
  var totalGeofencesStream: Observable<[GeofenceEntity]> { get }
  var currentGeofence: Observable<SelectedGeofenceEntity?> { get }
}
