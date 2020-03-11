//
//  AddGeofenceInteractor.swift
//  Geofence
//
//  Created by Walter Wong on 04/03/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import Foundation
import MapKit
import RxSwift

struct GeofenceProperties {
  var longitude: Double
  var latitude: Double
  var note: String
  var radius: Double
  var wifiStrength: Double
}

enum FormType: String {
  case radius
  case note
  case wifiStrength
}

final class AddGeofenceInteractor {
  var view: AddGeofenceViewInput
  weak var action: AddGeofenceViewDelegate?
  private var formsViewModel: [FormTVCViewModel]?

  init(view: AddGeofenceViewInput,
       action: AddGeofenceViewDelegate?) {
    self.view = view
    self.action = action
  }

  private func createForms() -> [FormTVCViewModel] {
    let radiusForm = FormTVCViewModel(identifier: FormType.radius.rawValue, title: "Radius", isRequired: true, keyboardType: .numberPad)
    let noteForm = FormTVCViewModel(identifier: FormType.note.rawValue, title: "Note", isRequired: true, keyboardType: .asciiCapable)
    let wifiStrengthForm = FormTVCViewModel(identifier: FormType.wifiStrength.rawValue, title: "Wifi Strength", isRequired: true, keyboardType: .numberPad)
    formsViewModel = [radiusForm, wifiStrengthForm, noteForm]
    return formsViewModel ?? []
  }

  private func checkEnableToSubmit() -> Bool {
    guard let formsViewModel = formsViewModel else { return false }
    var enableFlag = true

    let requiredForms = formsViewModel.filter({ $0.isRequired })

    for form in requiredForms {
      guard let textContent = form.textContent, textContent.trimmingCharacters(in: .whitespaces).count > 0 else {
        enableFlag = false
        break
      }
    }

    return enableFlag
  }

  private func getGeofenceProperties(_ coordinate: CLLocationCoordinate2D) -> GeofenceProperties {
    let note = formsViewModel?.first(where: { $0.identifier == FormType.note.rawValue })?.textContent
    let radius = Double(formsViewModel?.first(where: { $0.identifier == FormType.radius.rawValue })?.textContent ?? "0")
    let wifiStrength = Double(formsViewModel?.first(where: { $0.identifier == FormType.wifiStrength.rawValue })?.textContent ?? "0")

    return GeofenceProperties(longitude: coordinate.longitude,
                              latitude: coordinate.latitude,
                              note: note ?? "",
                              radius: radius ?? 0,
                              wifiStrength: wifiStrength ?? 0)
  }
}

extension AddGeofenceInteractor: AddGeofenceViewOutput {
  func setupForms() {
    view.populateForms(formsViewModel: formsViewModel ?? createForms())
  }

  func textDidChange(_ viewModel: FormTVCViewModel) {
    if let index = formsViewModel?.firstIndex(where: {$0.identifier == viewModel.identifier}) {
      formsViewModel?[index] = viewModel
    }
    let isEnabled = checkEnableToSubmit()
    view.isEnabledSubmitButton(isEnabled)
  }

  func didClickSubmitButton(coordinate: CLLocationCoordinate2D) {
    view.dismissView()
    action?.submitAddGeofence(geofenceProperties: getGeofenceProperties(coordinate))
  }

  func didClickAlignButton(mapView: MKMapView) {
    guard let coordinate = mapView.userLocation.location?.coordinate else { return }
    let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
    mapView.setRegion(region, animated: true)
  }
}
