//
//  AddGeofenceVCDataSource.swift
//  Geofence
//
//  Created by Walter Wong on 03/03/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import Foundation
import UIKit

class AddGeofenceVCDataSource: NSObject {

  fileprivate var _formObjects = [FormTVCViewModel]()
  let FormTableViewCellIdentifier = String(describing: FormTableViewCell.self)

  enum Section: Int, CaseIterable {
    case FormSection
  }

  func registerClasses(tableView: UITableView) {
    let formTVCellNib = UINib(nibName: FormTableViewCellIdentifier, bundle: nil)
    tableView.register(formTVCellNib, forCellReuseIdentifier: FormTableViewCellIdentifier)
  }

  func set(formObjects: [FormTVCViewModel]) {
    _formObjects = formObjects
  }

  func getFormObjects() -> [FormTVCViewModel] {
    return _formObjects
  }

  fileprivate func formCell(tableView: UITableView, for indexPath: IndexPath) -> FormTableViewCell? {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: FormTableViewCellIdentifier, for: indexPath) as? FormTableViewCell else {
      return nil
    }
    let formObject = _formObjects[indexPath.row]
    cell.configureWith(value: formObject)

    return cell
  }
}

extension AddGeofenceVCDataSource: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return Section.allCases.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let section = Section(rawValue: section)

    switch section {
    case .some(.FormSection):
      return _formObjects.count
    case .none:
      return 0
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let section = Section(rawValue: indexPath.section)

    switch section {
    case .some(.FormSection):
      if let cell = formCell(tableView: tableView, for: indexPath) {
        return cell
      }
    case .none:
      break
    }

    return UITableViewCell()
  }
}
