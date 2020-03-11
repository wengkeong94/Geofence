//
//  MapViewRouter.swift
//  Geofence
//
//  Created by Walter Wong on 04/03/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import Foundation
import UIKit

protocol MapViewRouterInput: class {
  func goToAddGeofenceVC()
}

public final class MapViewRouter: MapViewRouterInput {

  weak var viewController: MapViewController?
  init(viewController: MapViewInput) {
    self.viewController = viewController as? MapViewController
  }

  func goToAddGeofenceVC() {
    let controller = AddGeofenceViewController(nibName: "AddGeofenceViewController", bundle: nil)
    controller.delegate = viewController
    viewController?.navigationController?.pushViewController(controller, animated: true)
  }
}
