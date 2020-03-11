//
//  FormTableViewCell.swift
//  Geofence
//
//  Created by Walter Wong on 02/03/2020.
//  Copyright © 2020 Setel. All rights reserved.
//

import UIKit

struct FormTVCViewModel {
  var identifier: String
  var title: String
  var isRequired: Bool
  var keyboardType: UIKeyboardType
  var textContent: String? = nil
}

protocol FormTableViewCellDelegate: class {
  func textDidChange(
    _ viewModel: FormTVCViewModel
  )
}

class FormTableViewCell: UITableViewCell {

  @IBOutlet weak var titleLbl: UILabel!
  @IBOutlet weak var textField: UITextField!

  var timer: Timer? = nil
  var viewModel: FormTVCViewModel?
  weak var delegate: FormTableViewCellDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    setupView()
    setupListener()
    // Initialization code
  }

  private func setupView() {
    selectionStyle = .none
  }

  private func setupListener() {
    textField.delegate = self
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    // Configure the view for the selected state
  }

  private func updateUI() {
    guard let viewModel = viewModel else { return }
    titleLbl.text = viewModel.title
    textField.keyboardType = viewModel.keyboardType
  }

  @objc func textFieldDidChange() {
    viewModel?.textContent = textField.text
    guard let viewModel = viewModel else { return }
    delegate?.textDidChange(viewModel)
  }
}

extension FormTableViewCell: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                 replacementString string: String) -> Bool {
    timer?.invalidate()
    timer = Timer.scheduledTimer(
      timeInterval: 0.5,
      target: self,
      selector: #selector(textFieldDidChange),
      userInfo: nil,
      repeats: false)
    return true
  }

}

extension FormTableViewCell {
  func configureWith(value: FormTVCViewModel) {
    viewModel = value
    updateUI()
  }
}
