//
//  MapViewInteractor.swift
//  Geofence
//
//  Created by Walter Wong on 04/03/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import Foundation
import MapKitService
import RxSwift

final class MapViewInteractor {

  var router: MapViewRouterInput
  var view: MapViewInput
  private let mapKit: MapKit
  private let disposeBag = DisposeBag()

  init(view: MapViewInput,
       mapKit: MapKit) {
    self.mapKit = mapKit
    self.view = view
    self.router = MapViewRouter(viewController: view)
  }
}

extension MapViewInteractor: MapViewOutput {
  func startService() {
    mapKit.startService()

    mapKit.currentGeofence
      .skip(1)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] geofenceEntity in
        guard let this = self else { return }

        let geofenceViewModel = GeofenceViewModel(geofenceEntity: geofenceEntity)
        this.view.showCurrentGeofence(geofenceViewModel: geofenceViewModel)
      })
      .disposed(by: disposeBag)

    mapKit.totalGeofencesStream
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] geofences in
        guard let this = self else { return }
        this.view.showTotalGeofences(count: geofences.count)
      })
      .disposed(by: disposeBag)
  }

  func didClickAlignButton() {
    mapKit.zoomToUserLocation()
  }

  func didClickAddButton() {
    router.goToAddGeofenceVC()
  }

  func submitAddGeofence(geofenceProperties: GeofenceProperties) {
    mapKit.addGeofence(longitude: geofenceProperties.longitude,
                       latitude: geofenceProperties.latitude,
                       radius: geofenceProperties.radius,
                       note: geofenceProperties.note,
                       wifiStrength: geofenceProperties.wifiStrength)
  }
}
