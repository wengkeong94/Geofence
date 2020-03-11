//
//  GeofenceViewModel.swift
//  Geofence
//
//  Created by Walter Wong on 01/03/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import Foundation
import MapKitService
import MapKit

protocol GeofenceViewModelSpecs {
  var id: String { get }
  var selectedType: GeofenceType { get }
  var note: String { get }
  var coordinate: CLLocationCoordinate2D { get }
  func printCurrentStatus() -> String
}

struct GeofenceViewModel: GeofenceViewModelSpecs {
  let id: String
  let selectedType: GeofenceType
  let note: String
  let coordinate: CLLocationCoordinate2D

  init?(geofenceEntity: SelectedGeofenceEntity?) {
    guard let geofenceEntity = geofenceEntity else { return nil }
    self.id = geofenceEntity.geofence.id
    self.selectedType = geofenceEntity.selectedType
    self.note = geofenceEntity.geofence.note
    self.coordinate = geofenceEntity.geofence.coordinate
  }

  func printCurrentStatus() -> String {
    return "ID: \(id)\nCurrent Geofence Type: \(selectedType.rawValue)\nNote: \(note)\nCoordinate: \(coordinate.longitude), \(coordinate.latitude)"
  }
}
