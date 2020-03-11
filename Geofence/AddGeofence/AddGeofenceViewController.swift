//
//  AddGeofenceViewController.swift
//  Geofence
//
//  Created by Walter Wong on 03/03/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import MapKit

protocol AddGeofenceViewInput: class {
  // Define interface that enable router to interact with view controller.
  func isEnabledSubmitButton(_ flag : Bool)
  func populateForms(formsViewModel: [FormTVCViewModel])
  func dismissView()
}

protocol AddGeofenceViewOutput: class {
  func setupForms()
  func textDidChange(_ viewModel: FormTVCViewModel)
  func didClickSubmitButton(coordinate: CLLocationCoordinate2D)
  func didClickAlignButton(mapView: MKMapView)
}

protocol AddGeofenceViewDelegate: class {
  func submitAddGeofence(geofenceProperties: GeofenceProperties)
}

class AddGeofenceViewController: UIViewController, AddGeofenceViewInput {

  // MARK: - Cache
  private var cellHeightCache = [IndexPath: CGFloat]()

  private var formsRelay = PublishRelay<[FormTVCViewModel]>()
  private var forms: [FormTVCViewModel] = [] {
    didSet {
      formsRelay.accept(forms)
    }
  }

  lazy var interactor: AddGeofenceViewOutput = {
    return AddGeofenceInteractor(view: self, action: delegate)
  }()

  weak var delegate: AddGeofenceViewDelegate?

  let dataSource = AddGeofenceVCDataSource()
  private let disposeBag = DisposeBag()
  private let locationManager: CLLocationManager = CLLocationManager()

  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var submitButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    setupListener()
    setupData()
    setupNavigationBar()
    // Do any additional setup after loading the view.
  }

  private func setupView() {
    hideKeyboardWhenTapped()

    tableView.estimatedRowHeight = UITableView.automaticDimension
    tableView.rowHeight = UITableView.automaticDimension
    tableView.separatorStyle = .none

    submitButton.isEnabled = false
  }

  private func setupListener() {
    dataSource.registerClasses(tableView: tableView)
    tableView.delegate = self
    tableView.dataSource = dataSource

    formsRelay
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] formObjects in
        guard let this = self else { return }
        this.dataSource.set(formObjects: formObjects)
        this.tableView.reloadData()
      }).disposed(by: disposeBag)

    submitButton.rx.tap.subscribe(onNext: { [weak self] _ in
      guard let this = self else { return }
      let coordinate = this.mapView.centerCoordinate
      this.interactor.didClickSubmitButton(coordinate: coordinate)
    }).disposed(by: disposeBag)


  }

  private func setupData() {
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    interactor.setupForms()
  }

  private func setupNavigationBar() {
    let alignBtn = UIBarButtonItem(
      image: UIImage(named: "align")?.withRenderingMode(.alwaysOriginal),
      style: .plain,
      target: nil,
      action: nil
    )

    alignBtn.rx.tap.subscribe(onNext: { [weak self] _ in
      guard let this = self else { return }
      this.interactor.didClickAlignButton(mapView: this.mapView)
    }).disposed(by: disposeBag)

    navigationItem.rightBarButtonItems = [alignBtn]
  }

  func isEnabledSubmitButton(_ flag : Bool) {
    submitButton.isEnabled = flag
  }

  func populateForms(formsViewModel: [FormTVCViewModel]) {
    forms = formsViewModel
  }

  func dismissView() {
    navigationController?.popViewController(animated: true)
  }
}

extension AddGeofenceViewController: FormTableViewCellDelegate {
  func textDidChange(_ viewModel: FormTVCViewModel) {
    interactor.textDidChange(viewModel)
  }
}

extension AddGeofenceViewController: UITableViewDelegate {

  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    if let height = cellHeightCache[indexPath] {
      return height
    }

    return UITableView.automaticDimension
  }

  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if let cell = cell as? FormTableViewCell {
      cell.delegate = self
    }

    cellHeightCache[indexPath] = cell.frame.height
  }
}

extension AddGeofenceViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    mapView.showsUserLocation = status == .authorizedAlways
  }
}

extension UIViewController {
  func hideKeyboardWhenTapped() {
    let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
  }

  @objc func dismissKeyboard() {
    view.endEditing(true)
  }
}
