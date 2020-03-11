//
//  MapKitSynchronizer.swift
//  MapKitService
//
//  Created by Walter Wong on 29/02/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import MapKit
import CoreLocation

enum MapKitSynchronizerError: Error {
  case unknownError
  case geofenceNotFound
}

protocol MapKitSynchronizer {
  func didEnterRegion(regionId: String)
  func didExitRegion(regionId: String)
  func updateGeofence(_ geofence: GeofenceEntity, userAction: UserAction) -> Completable
  func getAllGeofenceArea() -> Single<[GeofenceEntity]>
  func zoomToUserLocation()
  var totalGeofences: Observable<[GeofenceEntity]> { get }
  var currentGeofence: Observable<SelectedGeofenceEntity?> { get }
}

class DefaultMapKitSynchronizer: NSObject, MapKitSynchronizer {
  private var currentGeofenceRelay = BehaviorRelay<SelectedGeofenceEntity?>(value: nil)
  var currentGeofence: Observable<SelectedGeofenceEntity?> {
    return currentGeofenceRelay.asObservable()
  }

  private var totalGeofences_subject = PublishSubject<[GeofenceEntity]>()
  var totalGeofences: Observable<[GeofenceEntity]> {
    return totalGeofences_subject.asObservable()
  }

  private var didEnterRegion_subject = PublishSubject<String?>()
  private var didEnterRegion: Observable<String?> {
    return didEnterRegion_subject.asObservable()
  }

  private var didExitRegion_subject = PublishSubject<String?>()
  private var didExitRegion: Observable<String?> {
    return didExitRegion_subject.asObservable()
  }

  private var interceptedGeofences: [SelectedGeofenceEntity] = []
  private let mapView: MKMapView
  private let locationManager: CLLocationManager
  private let geofenceStorage: GeofenceStorage
  private let mapKitHandler: MapKitHandler
  private let mapKitSynchronizerScheduler: SchedulerType
  private let disposeBag = DisposeBag()

  init(mapView: MKMapView,
       locationManager: CLLocationManager,
       mapKitHandler: MapKitHandler,
       geofenceStorage: GeofenceStorage = GeofenceStorageImp(),
       mapKitSynchronizerScheduler: SchedulerType = SerialDispatchQueueScheduler(internalSerialQueueName: "com.setel.mapKitSynchronizerScheduler") ) {
    self.mapView = mapView
    self.locationManager = locationManager
    self.mapKitHandler = mapKitHandler
    self.geofenceStorage = geofenceStorage
    self.mapKitSynchronizerScheduler = mapKitSynchronizerScheduler
    super.init()
    setupData()
    setupListener()
  }

  private func setupData() {
    mapView.delegate = self
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
  }

  private func setupListener() {
    Observable.combineLatest(didEnterRegion, currentGeofence)
      .observeOn(mapKitSynchronizerScheduler)
      .filter({ (regionId, _) -> Bool in
        guard let _ = regionId else { return false }
        return true
      })
      .distinctUntilChanged({ (oldData, newData) -> Bool in
        return oldData.0 == newData.0 && oldData.1?.geofence.id == newData.1?.geofence.id
      })
      .flatMap { [weak self] regionId, previousSelectedGeofence -> Single<(String?, SelectedGeofenceEntity?, [GeofenceEntity])> in
        guard let this = self else { return .error(MapKitSynchronizerError.unknownError) }
        return this.geofenceStorage.loadGeofence().map({ (regionId, previousSelectedGeofence, $0) })
      }
      .map { [weak self] regionId, previousSelectedGeofence, allGeofenceArea -> (Bool, SelectedGeofenceEntity) in
        guard let this = self, let regionId = regionId else { throw MapKitSynchronizerError.unknownError }
        this.didEnterRegion_subject.onNext(nil)
        let currentSelectedGeofence = try this.mapKitHandler.filterSelectedGeofence(from: allGeofenceArea, basedOn: regionId)

        guard let previousSelectedGeofence = previousSelectedGeofence else {
          return (true, currentSelectedGeofence)
        }

        if previousSelectedGeofence.geofence.isEqualTo(currentSelectedGeofence.geofence),
          previousSelectedGeofence.selectedType != currentSelectedGeofence.selectedType {
          return (true, currentSelectedGeofence)
        }

        return (false, currentSelectedGeofence)
      }
      .subscribe(onNext: { [weak self] flag, currentSelectedGeofence in
        guard let this = self else { return }
        if this.mapKitHandler.shouldInsertInterceptedGeofence(from: this.interceptedGeofences, selectedGeofence: currentSelectedGeofence) {
          this.interceptedGeofences.append(currentSelectedGeofence)
        }

        if flag {
          this.currentGeofenceRelay.accept(currentSelectedGeofence)
        }
      }).disposed(by: disposeBag)

    Observable.combineLatest(didExitRegion, currentGeofence)
      .observeOn(mapKitSynchronizerScheduler)
      .filter({ (regionId, _) -> Bool in
        guard let _ = regionId else { return false }
        return true
      })
      .distinctUntilChanged({ (oldData, newData) -> Bool in
        return oldData.0 == newData.0 && oldData.1?.geofence.id == newData.1?.geofence.id
      })
      .flatMap { [weak self] regionId, previousSelectedGeofence -> Single<(String?, SelectedGeofenceEntity?, [GeofenceEntity])> in
        guard let this = self else { return .error(MapKitSynchronizerError.unknownError) }
        return this.geofenceStorage.loadGeofence().map({ (regionId, previousSelectedGeofence, $0) })
      }
      .map { [weak self] regionId, previousSelectedGeofence, allGeofenceArea -> (Bool, SelectedGeofenceEntity) in
        guard let this = self, let regionId = regionId else { throw MapKitSynchronizerError.unknownError }
        this.didExitRegion_subject.onNext(nil)
        let currentSelectedGeofence = try this.mapKitHandler.filterSelectedGeofence(from: allGeofenceArea, basedOn: regionId)
        if let previousSelectedGeofence = previousSelectedGeofence,
          previousSelectedGeofence.geofence.isEqualTo(currentSelectedGeofence.geofence),
          previousSelectedGeofence.selectedType == currentSelectedGeofence.selectedType {
          return (true, currentSelectedGeofence)
        }
        return (false, currentSelectedGeofence)
      }
      .subscribe(onNext: { [weak self] flag, currentSelectedGeofence in
        guard let this = self else { return }
        this.interceptedGeofences.removeAll(where: {
          $0.geofence.isEqualTo(currentSelectedGeofence.geofence) && $0.selectedType == currentSelectedGeofence.selectedType
        })
        if flag {
          if let nextSelectedGeofence = this.interceptedGeofences.first {
            let chosenGeofence = this.mapKitHandler.selectNextSelectedGeofence(from: this.interceptedGeofences, selectedGeofence: nextSelectedGeofence)
            this.currentGeofenceRelay.accept(chosenGeofence)
          } else {
            this.currentGeofenceRelay.accept(nil)
          }
        }
      }).disposed(by: disposeBag)
  }

  func updateGeofence(_ geofence: GeofenceEntity, userAction: UserAction) -> Completable {
    return geofenceStorage.loadGeofence()
      .observeOn(mapKitSynchronizerScheduler)
      .map({ [weak self] geofences -> (flag: Bool, geofences: [GeofenceEntity]) in
        guard let this = self else { throw MapKitSynchronizerError.unknownError }
        var tempGeofences = geofences
        var changesMade = false
        switch userAction {
        case .add:
          tempGeofences.append(geofence)
          this.mapKitHandler.drawAndStartMonitorGeofence(geofence: geofence)
          changesMade = true
        case .remove:
          guard let deleteIndex = geofences.firstIndex(where: { $0.isEqualTo(geofence) }) else {
            throw MapKitSynchronizerError.geofenceNotFound
          }
          tempGeofences.remove(at: deleteIndex)
          this.mapKitHandler.removeAndStopMonitorGeofence(geofence: geofence)
          changesMade = true
        case .refresh:
          this.mapKitHandler.drawAndStartMonitorGeofence(geofence: geofence)
        }
        return (flag: changesMade, geofences: tempGeofences)
      })
      .flatMapCompletable({ [weak self] flag, geofences -> Completable in
        guard let this = self else { return .error(MapKitSynchronizerError.unknownError) }
        this.totalGeofences_subject.onNext(geofences)
        if flag {
          return this.geofenceStorage.saveGeofence(geofences)
        } else {
          return .empty()
        }
      })
  }

  func getAllGeofenceArea() -> Single<[GeofenceEntity]> {
    return geofenceStorage.loadGeofence()
  }

  func didEnterRegion(regionId: String) {
    didEnterRegion_subject.onNext(regionId)
  }

  func didExitRegion(regionId: String) {
    didExitRegion_subject.onNext(regionId)
  }

  func zoomToUserLocation() {
    guard let coordinate = mapView.userLocation.location?.coordinate else { return }
    let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
    mapView.setRegion(region, animated: true)
  }
}

extension DefaultMapKitSynchronizer: CLLocationManagerDelegate {

  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    if region is CLCircularRegion {
      didEnterRegion(regionId: region.identifier)
    }
  }

  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    if region is CLCircularRegion {
      didExitRegion(regionId: region.identifier)
    }
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    mapView.showsUserLocation = status == .authorizedAlways
  }
}

extension DefaultMapKitSynchronizer: MKMapViewDelegate {

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    let identifier = "geofence"
    if annotation is GeofenceEntity {
      var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
      if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView?.canShowCallout = true
        let removeButton = UIButton(type: .custom)
        removeButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        removeButton.setImage(UIImage(named: "cross")!, for: .normal)
        annotationView?.leftCalloutAccessoryView = removeButton
      } else {
        annotationView?.annotation = annotation
      }
      return annotationView
    }
    return nil
  }

  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let overlay = overlay as? MapCircle {
      return overlay.convertToCircleRenderer()
    }
    return MKOverlayRenderer(overlay: overlay)
  }

  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    guard let geofence = view.annotation as? GeofenceEntity else { return }
    updateGeofence(geofence, userAction: .remove).observeOn(mapKitSynchronizerScheduler).subscribe().disposed(by: disposeBag)
  }
}
