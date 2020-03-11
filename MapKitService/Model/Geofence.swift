//
//  Geofence.swift
//  MapKitService
//
//  Created by Walter Wong on 29/02/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import Foundation
import MapKit

enum GeofenceCodingKeys: String, CodingKey {
  case latitude, longitude, radius, id, note, zoneGeofence, wifiGeofence, geofenceType
}

public enum GeofenceType: String {
  case zone = "zone"
  case wifi = "wifi"
}

public typealias WifiProperties = (coordinate: CLLocationCoordinate2D, radius: Double, outerRadiusConnectivity: Double?)

public protocol Geofence {
  var radius: CLLocationDistance { get }
  var geofenceType: GeofenceType { get }
}

public protocol GeofenceEntity: MKAnnotation {
  var id: String { get }
  var coordinate: CLLocationCoordinate2D { get }
  var zoneGeofence: Geofence { get }
  var wifiGeofence: Geofence { get }
  var note: String { get }
  func isEqualTo(_ otherGeofenceEntity: GeofenceEntity) -> Bool
  func convertToRegion(geofenceType: GeofenceType) -> CLCircularRegion
}

extension GeofenceEntity {
  func isEqualTo(_ otherGeofenceEntity: GeofenceEntity) -> Bool {
    return self.id == otherGeofenceEntity.id
  }
}

class GeofenceObj: Geofence, Codable {
  var radius: CLLocationDistance
  var geofenceType: GeofenceType

  init(radius: CLLocationDistance,
       geofenceType: GeofenceType) {
    self.radius = radius
    self.geofenceType = geofenceType
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: GeofenceCodingKeys.self)
    radius = try values.decode(Double.self, forKey: .radius)
    let rawGeofenceType = try values.decode(String.self, forKey: .geofenceType)
    geofenceType = GeofenceType(rawValue: rawGeofenceType) ?? .wifi
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: GeofenceCodingKeys.self)
    try container.encode(radius, forKey: .radius)
    try container.encode(geofenceType.rawValue, forKey: .geofenceType)
  }
}

class GeofenceArea: NSObject, GeofenceEntity, Codable {
  var id: String
  var coordinate: CLLocationCoordinate2D
  var zoneGeofence: Geofence
  var wifiGeofence: Geofence
  var note: String

  var title: String? {
    let defaultNote = "Id: \(id)"

    if note.isEmpty { return defaultNote }
    return "\(defaultNote). \(note)"
  }

  var subtitle: String? {
    return "Zone radius: \(zoneGeofence.radius)m. Wifi radius: \(wifiGeofence.radius)."
  }

  init(id: String = UUID().uuidString,
       coordinate: CLLocationCoordinate2D,
       zoneGeofence: Geofence,
       wifiGeofence: Geofence,
       note: String) {
    self.id = id
    self.coordinate = coordinate
    self.zoneGeofence = zoneGeofence
    self.wifiGeofence = wifiGeofence
    self.note = note
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: GeofenceCodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    let latitude = try values.decode(Double.self, forKey: .latitude)
    let longitude = try values.decode(Double.self, forKey: .longitude)
    coordinate = CLLocationCoordinate2DMake(latitude, longitude)
    let zoneGeofenceData = try values.decode(Data.self, forKey: .zoneGeofence)
    zoneGeofence = try JSONDecoder().decode(GeofenceObj.self, from: zoneGeofenceData)
    let wifiGeofenceData = try values.decode(Data.self, forKey: .wifiGeofence)
    wifiGeofence = try JSONDecoder().decode(GeofenceObj.self, from: wifiGeofenceData)
    note = try values.decode(String.self, forKey: .note)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: GeofenceCodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(coordinate.latitude, forKey: .latitude)
    try container.encode(coordinate.longitude, forKey: .longitude)
    let zoneGeofenceData = try JSONEncoder().encode(convertToGeofenceObj(zoneGeofence))
    try container.encode(zoneGeofenceData, forKey: .zoneGeofence)
    let wifiGeofenceData = try JSONEncoder().encode(convertToGeofenceObj(wifiGeofence))
    try container.encode(wifiGeofenceData, forKey: .wifiGeofence)
    try container.encode(note, forKey: .note)
  }

  func convertToRegion(geofenceType: GeofenceType) -> CLCircularRegion {
    var radius: Double = 0.0
    var identifier: String = ""

    switch geofenceType {
    case .zone:
      radius = zoneGeofence.radius
      identifier = "\(id)_zone"
    case .wifi:
      radius = wifiGeofence.radius
      identifier = "\(id)_wifi"
    }

    let region = CLCircularRegion(center: coordinate, radius: radius, identifier: identifier)
    region.notifyOnEntry = true
    region.notifyOnExit = true
    return region
  }

  private func convertToGeofenceObj(_ geofence: Geofence) -> GeofenceObj {
    return GeofenceObj(radius: geofence.radius, geofenceType: geofence.geofenceType)
  }
}
