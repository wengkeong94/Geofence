//
//  MapKitHandler.swift
//  MapKitService
//
//  Created by Walter Wong on 01/03/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import Foundation
import MapKit

protocol MapKitHandler {
  func drawAndStartMonitorGeofence(geofence: GeofenceEntity)
  func removeAndStopMonitorGeofence(geofence: GeofenceEntity)
  func filterSelectedGeofence(from geofences: [GeofenceEntity], basedOn regionId: String) throws -> SelectedGeofenceEntity
  func shouldInsertInterceptedGeofence(from geofences: [SelectedGeofenceEntity], selectedGeofence: SelectedGeofenceEntity) -> Bool
  func selectNextSelectedGeofence(from geofences: [SelectedGeofenceEntity], selectedGeofence: SelectedGeofenceEntity) -> SelectedGeofenceEntity
}

class DefaultMapKitHandler: MapKitHandler {

  private let mapView: MKMapView
  private let locationManager: CLLocationManager

  init(mapView: MKMapView,
       locationManager: CLLocationManager) {
    self.mapView = mapView
    self.locationManager = locationManager
  }

  func drawAndStartMonitorGeofence(geofence: GeofenceEntity) {
    DispatchQueue.main.async {
      let zoneRegion = geofence.convertToRegion(geofenceType: .zone)
      let wifiRegion = geofence.convertToRegion(geofenceType: .wifi)

      self.mapView.addAnnotation(geofence)
      self.mapView.addOverlay(MapCircle(id: geofence.id, geofenceType: .zone, coordinate: geofence.coordinate, radius: geofence.zoneGeofence.radius))
      self.mapView.addOverlay(MapCircle(id: geofence.id, geofenceType: .wifi, coordinate: geofence.coordinate, radius: geofence.wifiGeofence.radius))
      self.locationManager.startMonitoring(for: zoneRegion)
      self.locationManager.startMonitoring(for: wifiRegion)
    }
  }

  func removeAndStopMonitorGeofence(geofence: GeofenceEntity) {
    DispatchQueue.main.async {
      self.mapView.removeAnnotation(geofence)
      for overlay in self.mapView.overlays {
        guard let overlay = overlay as? MapCircle else { continue }
        if overlay.coordinate.latitude == geofence.coordinate.latitude
          && overlay.coordinate.longitude == geofence.coordinate.longitude
          && overlay.id == geofence.id {
          self.mapView.removeOverlay(overlay)
        }
      }

      self.locationManager.stopMonitoring(for: geofence.convertToRegion(geofenceType: .zone))
      self.locationManager.stopMonitoring(for: geofence.convertToRegion(geofenceType: .wifi))
    }
  }

  func filterSelectedGeofence(from geofences: [GeofenceEntity], basedOn regionId: String) throws -> SelectedGeofenceEntity {
    let type: GeofenceType = regionId.contains("_zone") ? .zone : .wifi
    let parsedId = regionId.replacingOccurrences(of: "_wifi", with: "").replacingOccurrences(of: "_zone", with: "")

    guard let geofence = geofences.first(where: { $0.id == parsedId }) else { throw MapKitSynchronizerError.geofenceNotFound }
    return (geofence, type)
  }

  func shouldInsertInterceptedGeofence(from geofences: [SelectedGeofenceEntity], selectedGeofence: SelectedGeofenceEntity) -> Bool {
    let geofenceExist = geofences.first(where: { (geofenceItem) -> Bool in
      return geofenceItem.geofence.isEqualTo(selectedGeofence.geofence) && geofenceItem.selectedType == selectedGeofence.selectedType
    })
    return (geofenceExist != nil) ? false : true
  }

  func selectNextSelectedGeofence(from geofences: [SelectedGeofenceEntity], selectedGeofence: SelectedGeofenceEntity) -> SelectedGeofenceEntity {
    let geofencesInSameGroup = geofences.filter { $0.geofence.isEqualTo(selectedGeofence.geofence) }
    if geofencesInSameGroup.count > 1, let zoneGeofence = geofencesInSameGroup.first(where: { $0.selectedType == .zone }) {
      return (geofence: zoneGeofence.geofence, selectedType: zoneGeofence.selectedType)
    } else {
      return selectedGeofence
    }
  }
}

