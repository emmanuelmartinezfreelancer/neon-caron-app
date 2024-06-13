//
//  HomeTableCell.swift
//  Neon Caron
//
//  Created by Pablo Ruiz on 3/1/21.
//

import Foundation
import UIKit

class HomeTableCell: UITableViewCell {
  
  @IBOutlet weak var thumbnail: UIImageView!
  @IBOutlet weak var collectionNameLabel: UILabel!
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    selectionStyle = .none
  }
  
  func configure(with name: String, image: UIImage?) {
    thumbnail.image = image
    collectionNameLabel.text = name
  }
}
