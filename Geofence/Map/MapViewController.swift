//
//  MapViewController.swift
//  Geofence
//
//  Created by Walter Wong on 29/02/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import MapKit
import MapKitService

protocol MapViewInput: class {
  func showCurrentGeofence(geofenceViewModel: GeofenceViewModelSpecs?)
  func showTotalGeofences(count: Int)
}

protocol MapViewOutput: class {
  func didClickAlignButton()
  func didClickAddButton()
  func startService()
  func submitAddGeofence(geofenceProperties: GeofenceProperties)
}

class MapViewController: UIViewController, MapViewInput {

  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var geofenceStatusLbl: UILabel!

  var disposeBag = DisposeBag()

  lazy var interactor: MapViewOutput = {
    let mapKit = MapKitService(mapView: mapView)

    return MapViewInteractor(view: self, mapKit: mapKit)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    setupNavigationBar()
    setupData()
  }

  func setupNavigationBar() {
    let alignBtn = UIBarButtonItem(
      image: UIImage(named: "align")?.withRenderingMode(.alwaysOriginal),
      style: .plain,
      target: nil,
      action: nil
    )

    alignBtn.rx.tap.subscribe(onNext: { [weak self] _ in
      self?.interactor.didClickAlignButton()
    }).disposed(by: disposeBag)

    let addBtn = UIBarButtonItem(
      image: UIImage(named: "add")?.withRenderingMode(.alwaysOriginal),
      style: .plain,
      target: nil,
      action: nil
    )

    addBtn.rx.tap.subscribe(onNext: { [weak self] _ in
      self?.interactor.didClickAddButton()
    }).disposed(by: disposeBag)

    navigationItem.rightBarButtonItems = [alignBtn, addBtn]
  }

  func setupData() {
    interactor.startService()
  }

  func showCurrentGeofence(geofenceViewModel: GeofenceViewModelSpecs?) {
    if let geofenceViewModel = geofenceViewModel {
      geofenceStatusLbl.text = geofenceViewModel.printCurrentStatus()
    } else {
       geofenceStatusLbl.text = "OUTSIDE"
    }
  }

  func showTotalGeofences(count: Int) {
    navigationItem.title = "Geofences: \(count)"
  }
}

extension MapViewController: AddGeofenceViewDelegate {
  func submitAddGeofence(geofenceProperties: GeofenceProperties) {
    interactor.submitAddGeofence(geofenceProperties: geofenceProperties)
  }
}
