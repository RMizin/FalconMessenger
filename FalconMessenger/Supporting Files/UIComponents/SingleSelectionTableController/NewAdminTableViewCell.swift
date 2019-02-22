//
//  NewAdminTableViewCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/29/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class NewAdminTableViewCell: UITableViewCell {
  
  weak var selectNewAdminTableViewController: SelectNewAdminTableViewController!
  
  var gestureReconizer:UITapGestureRecognizer!
  
  var icon: UIImageView = {
    var icon = UIImageView()
    icon.translatesAutoresizingMaskIntoConstraints = false
    icon.contentMode = .scaleAspectFill
    icon.layer.cornerRadius = 25
    icon.layer.masksToBounds = true
    icon.image = UIImage(named: "UserpicIcon")
    
    return icon
  }()
  
  var title: UILabel = {
    var title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold)
    title.textColor = ThemeManager.currentTheme().generalTitleColor
    
    return title
  }()
  
  var subtitle: UILabel = {
    var subtitle = UILabel()
    subtitle.translatesAutoresizingMaskIntoConstraints = false
    subtitle.font = UIFont.systemFont(ofSize: 15)
    subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
    
    return subtitle
  }()
  
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    
    gestureReconizer = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
    addGestureRecognizer(gestureReconizer)
    
    backgroundColor = .clear
    title.backgroundColor = backgroundColor
    icon.backgroundColor = backgroundColor
    
    contentView.addSubview(icon)
    icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
    icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
    icon.widthAnchor.constraint(equalToConstant: 50).isActive = true
    icon.heightAnchor.constraint(equalToConstant: 50).isActive = true
    
    contentView.addSubview(title)
    title.topAnchor.constraint(equalTo: icon.topAnchor, constant: 0).isActive = true
    title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 15).isActive = true
    title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
    title.heightAnchor.constraint(equalToConstant: 23).isActive = true
    
    contentView.addSubview(subtitle)
    subtitle.bottomAnchor.constraint(equalTo: icon.bottomAnchor, constant: 0).isActive = true
    subtitle.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 15).isActive = true
    subtitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
    subtitle.heightAnchor.constraint(equalToConstant: 23).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @objc func cellTapped() {
    guard let indexPath = selectNewAdminTableViewController.tableView.indexPathForView(self) else { return }
    selectNewAdminTableViewController.deselectAll()
    selectNewAdminTableViewController.didSelectUser(at: indexPath)
    isSelected = true
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    icon.image = UIImage(named: "UserpicIcon")
    title.text = ""
    subtitle.text = ""
    title.textColor = ThemeManager.currentTheme().generalTitleColor
    subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
}
