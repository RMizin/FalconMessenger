//
//  SelectParticipantsViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/6/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import ARSLineProgress

class SelectParticipantsViewController: UIViewController {
  
  let falconUsersCellID = "falconUsersCellID"
  let selectedParticipantsCollectionViewCellID = "SelectedParticipantsCollectionViewCellID"
  
  var users = [User]()
  var filteredUsers = [User]()
  var selectedFalconUsers = [User]()
  var filteredUsersWithSection = [[User]]()
  
  var collation = UILocalizedIndexedCollation.current()
  var sectionTitles = [String]()
  var searchBar: UISearchBar?
  let tableView = UITableView()
  
  var selectedParticipantsCollectionView: UICollectionView = {
    var selectedParticipantsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    return selectedParticipantsCollectionView
  }()
  
  let alignedFlowLayout = CollectionViewLeftAlignFlowLayout()
  var collectionViewHeightAnchor: NSLayoutConstraint!

  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupSearchController()
    setupMainView()
    setupCollectionView()
    setupTableView()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if navigationController?.visibleViewController is GroupProfileTableViewController { return }
    deselectAll()
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    
    DispatchQueue.main.async {
      self.reloadCollectionView()
    }
  }

  fileprivate func deselectAll() {
    guard users.count > 0 else { return }
   _ = users.map { $0.isSelected = false }
    filteredUsers = users
    setUpCollation()
    DispatchQueue.main.async {
      self.tableView.reloadData()
    }
  }
  
  @objc func setUpCollation() {
    let (arrayContacts, arrayTitles) = collation.partitionObjects(array: self.filteredUsers, collationStringSelector: #selector(getter: User.name))
    filteredUsersWithSection = arrayContacts as! [[User]]
    sectionTitles = arrayTitles
  }

  fileprivate func setupMainView() {
    definesPresentationContext = true
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  func setupNavigationItemTitle(title: String) {
    navigationItem.title = title
  }
  
  func setupRightBarButton(with title: String) {
    if #available(iOS 11.0, *) {
      let rightBarButton = UIButton(type: .system)
      rightBarButton.setTitle(title, for: .normal)
      rightBarButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
      rightBarButton.addTarget(self, action: #selector(rightBarButtonTapped), for: .touchUpInside)
      navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton)
    } else {
      navigationItem.rightBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(rightBarButtonTapped))
    }
    navigationItem.rightBarButtonItem?.isEnabled = false
  }
  
  @objc func rightBarButtonTapped() {}

  func createGroup() {
    let destination = GroupProfileTableViewController()
    destination.selectedFlaconUsers = selectedFalconUsers
    navigationController?.pushViewController(destination, animated: true)
  }
  
  var chatIDForUsersUpdate = String()
  var informationMessageSender = InformationMessageSender()
  
  func addNewMembers() {
    
    ARSLineProgress.ars_showOnView(view)
    navigationController?.view.isUserInteractionEnabled = false
    
    let reference = Database.database().reference().child("groupChats").child(chatIDForUsersUpdate).child(messageMetaDataFirebaseFolder).child("chatParticipantsIDs")
    reference.observeSingleEvent(of: .value) { (snapshot) in
      
      guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
      guard var membersIDs = Array(dictionary.values) as? [String] else { return }
      
      var values = [String: AnyObject]()
      var selectedUserNames = [String]()
      
      for selectedUser in self.selectedFalconUsers {
        guard let selectedID = selectedUser.id, let selectedUserName = selectedUser.name else { continue }
        values.updateValue(selectedID as AnyObject, forKey: selectedID)
        selectedUserNames.append(selectedUserName)
        membersIDs.append(selectedID)
      }
      
      reference.updateChildValues(values, withCompletionBlock: { (_, _) in
        let userNamesString = selectedUserNames.joined(separator: ", ")
        let usersTitleString = selectedUserNames.count > 1 ? "users" : "user"
        let text = "Admin added \(usersTitleString) \(userNamesString) to the group"
        self.informationMessageSender.sendInformatoinMessage(chatID: self.chatIDForUsersUpdate, membersIDs: membersIDs, text: text)

        ARSLineProgress.showSuccess()
        self.navigationController?.view.isUserInteractionEnabled = true
        self.navigationController?.popViewController(animated: true)
      })
    }
  }
  
  fileprivate func setupTableView() {
  
    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .never
    }
    
    view.addSubview(tableView)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.topAnchor.constraint(equalTo: selectedParticipantsCollectionView.bottomAnchor).isActive = true
    
    if #available(iOS 11.0, *) {
      tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0).isActive = true
      tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0).isActive = true
      tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
    } else {
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    }
    
    tableView.delegate = self
    tableView.dataSource = self
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.sectionIndexBackgroundColor = view.backgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.allowsMultipleSelection = true
    tableView.allowsSelection = true
    tableView.allowsSelectionDuringEditing = true
    tableView.allowsMultipleSelectionDuringEditing = true
    tableView.setEditing(true, animated: false)
    tableView.register(ParticipantTableViewCell.self, forCellReuseIdentifier: falconUsersCellID)
    tableView.separatorStyle = .none
  }
  
  fileprivate func setupCollectionView() {

    selectedParticipantsCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: alignedFlowLayout)
    
    view.addSubview(selectedParticipantsCollectionView)
    selectedParticipantsCollectionView.translatesAutoresizingMaskIntoConstraints = false
    selectedParticipantsCollectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
    
    collectionViewHeightAnchor = selectedParticipantsCollectionView.heightAnchor.constraint(equalToConstant: 0)
    collectionViewHeightAnchor.priority = UILayoutPriority(rawValue: 999)
    collectionViewHeightAnchor.isActive = true
    
    if #available(iOS 11.0, *) {
      selectedParticipantsCollectionView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0).isActive = true
      selectedParticipantsCollectionView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0).isActive = true
    } else {
      selectedParticipantsCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
      selectedParticipantsCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
    }

    selectedParticipantsCollectionView.delegate = self
    selectedParticipantsCollectionView.dataSource = self
    selectedParticipantsCollectionView.showsVerticalScrollIndicator = true
    selectedParticipantsCollectionView.showsHorizontalScrollIndicator = false
    selectedParticipantsCollectionView.alwaysBounceVertical = true
    selectedParticipantsCollectionView.backgroundColor = .clear
    selectedParticipantsCollectionView.register(SelectedParticipantsCollectionViewCell.self, forCellWithReuseIdentifier: selectedParticipantsCollectionViewCellID)
		selectedParticipantsCollectionView.decelerationRate = UIScrollView.DecelerationRate.fast
    selectedParticipantsCollectionView.isScrollEnabled = true
    selectedParticipantsCollectionView.contentInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    
    alignedFlowLayout.minimumInteritemSpacing = 5
    alignedFlowLayout.minimumLineSpacing = 5
    alignedFlowLayout.estimatedItemSize = CGSize(width: 100, height: 32)
  }
 
  fileprivate func setupSearchController() {
    searchBar = UISearchBar()
    searchBar?.delegate = self
    searchBar?.searchBarStyle = .minimal
    searchBar?.changeBackgroundColor(to: ThemeManager.currentTheme().searchBarColor)
    searchBar?.placeholder = "Search"
    searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
    tableView.tableHeaderView = searchBar
  }
  
  func reloadCollectionView() {
    if #available(iOS 11.0, *) {
      DispatchQueue.main.async {
        self.selectedParticipantsCollectionView.reloadData()
      }
    } else {
      DispatchQueue.main.async {
        UIView.performWithoutAnimation {
          self.selectedParticipantsCollectionView.reloadSections([0])
        }
      }
    }
    
    if selectedFalconUsers.count == 0 {
       collectionViewHeightAnchor.constant = 0
      UIView.animate(withDuration: 0.3) {
        self.view.layoutIfNeeded()
      }
      self.navigationItem.rightBarButtonItem?.isEnabled = false
      return
    }
    navigationItem.rightBarButtonItem?.isEnabled = true
    
    if selectedFalconUsers.count == 1 {
      collectionViewHeightAnchor.constant = 75
      UIView.animate(withDuration: 0.3) {
        self.view.layoutIfNeeded()
      }
      return
    }
  }
  
  func didSelectUser(at indexPath: IndexPath) {
    
    let user = filteredUsersWithSection[indexPath.section][indexPath.row]
    
		if let filteredUsersIndex = filteredUsers.firstIndex(of: user) {
      filteredUsers[filteredUsersIndex].isSelected = true
    }
    
		if let usersIndex = users.firstIndex(of: user) {
      users[usersIndex].isSelected = true
    }
    
    filteredUsersWithSection[indexPath.section][indexPath.row].isSelected = true
    
    selectedFalconUsers.append(filteredUsersWithSection[indexPath.section][indexPath.row])
    
    DispatchQueue.main.async {
      self.reloadCollectionView()
    }
  }
  
  func didDeselectUser(at indexPath: IndexPath) {
    
    let user = filteredUsersWithSection[indexPath.section][indexPath.row]
    
		if let findex = filteredUsers.firstIndex(of: user) {
      filteredUsers[findex].isSelected = false
    }
    
		if let index = users.firstIndex(of: user) {
      users[index].isSelected = false
    }
    
		if let selectedFalconUserIndexInCollectionView = selectedFalconUsers.firstIndex(of: user) {
      selectedFalconUsers[selectedFalconUserIndexInCollectionView].isSelected = false
      selectedFalconUsers.remove(at: selectedFalconUserIndexInCollectionView)
      DispatchQueue.main.async {
         self.reloadCollectionView()
      }
    }
    filteredUsersWithSection[indexPath.section][indexPath.row].isSelected = false
  }
}
