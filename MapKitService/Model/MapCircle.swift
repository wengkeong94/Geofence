//
//  MapCircle.swift
//  MapKitService
//
//  Created by Walter Wong on 29/02/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import Foundation
import MapKit

class MapCircle: NSObject, MKOverlay {
  var id: String
  var color: UIColor
  var geofenceType: GeofenceType
  var boundingMapRect: MKMapRect
  var coordinate: CLLocationCoordinate2D
  var radius: CLLocationDistance
  var alpha: CGFloat

  init(id: String, geofenceType: GeofenceType, coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) {
    self.id = id
    self.geofenceType = geofenceType
    color = .red
    alpha = 0.4
    if geofenceType == .wifi {
      color = .blue
      alpha = 0.2
    }
    self.coordinate = coordinate
    self.radius = radius
    self.boundingMapRect = MKMapRect(origin: MKMapPoint(coordinate), size: MKMapSize(width: radius, height: radius))
  }

  func convertToCircleRenderer() -> MKCircleRenderer {
    let mkCircle = MKCircle(center: coordinate, radius: radius)
    let circleRenderer = MKCircleRenderer(overlay: mkCircle)
    circleRenderer.lineWidth = 1.0
    circleRenderer.strokeColor = color
    circleRenderer.fillColor = color.withAlphaComponent(0.4)
    return circleRenderer
  }
}
