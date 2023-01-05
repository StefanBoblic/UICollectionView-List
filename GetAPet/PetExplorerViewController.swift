//
//  PetExplorerViewController.swift
//  GetAPet
//
//  Created by Stefan Boblic on 04.01.2023.
//

import UIKit

class PetExplorerViewController: UICollectionViewController {
  // MARK: - Properties
  var adoptions = Set<Pet>()
  lazy var dataSource = makeDataSource()

  // MARK: - Types
  enum Section: Int, CaseIterable, Hashable {
    case availablePets
    case adoptedPets
  }
  typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>

  // MARK: - Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "Pet Explorer"
    configureLayout()
    applyInitialSnapshots()
  }

  // MARK: - Functions

  func configureLayout() {
    let provider = {
      (_: Int, layoutEnv: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
      // 2
      let configuration = UICollectionLayoutListConfiguration(
        appearance: .grouped)
      // 3
      return NSCollectionLayoutSection.list(
        using: configuration,
        layoutEnvironment: layoutEnv)
    }
    // 4
    collectionView.collectionViewLayout =
    UICollectionViewCompositionalLayout(sectionProvider: provider)

  }

  func makeDataSource() -> DataSource {
    let categoryCellRegistration = UICollectionView.CellRegistration(handler: cellRegistrationHandler)
    let petCellRegistration = UICollectionView.CellRegistration(handler: petCellRegistrationHandler)
    let adoptedPetCellRegistration = UICollectionView.CellRegistration(handler: adoptedPetCellRegistrationHandler)

    return DataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell in
      if item.pet != nil {
        guard let section = Section(rawValue: indexPath.section) else {
          return UICollectionViewListCell()
        }
        switch section {
        case .availablePets:
          return collectionView.dequeueConfiguredReusableCell(using: petCellRegistration, for: indexPath, item: item)
        case .adoptedPets:
          return collectionView.dequeueConfiguredReusableCell(using: adoptedPetCellRegistration, for: indexPath, item: item)

        }
      } else {
        return collectionView.dequeueConfiguredReusableCell(using: categoryCellRegistration, for: indexPath, item: item)
      }
    }
  }

  func applyInitialSnapshots() {
    var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
    snapshot.appendSections(Section.allCases)
    dataSource.apply(snapshot, animatingDifferences: true)
    var categorySnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
    for category in Pet.Category.allCases {
      let categoryItem = Item(title: String(describing: category))
      categorySnapshot.append([categoryItem])
      let petItems = category.pets.map { Item(pet: $0, title: $0.name) }
      categorySnapshot.append(petItems, to: categoryItem)
    }
    dataSource.apply(
      categorySnapshot,
      to: .availablePets,
      animatingDifferences: false)
  }

  func updateDataSource(for pet: Pet) {
    var snapshot = dataSource.snapshot()
    let items = snapshot.itemIdentifiers

    let petItem = items.first { item in
      item.pet == pet
    }

    if let petItem = petItem {
      snapshot.reloadItems([petItem])
      dataSource.apply(snapshot, animatingDifferences: true)
    }
  }
}
// MARK: - CollectionView Cells
extension PetExplorerViewController {
}

// MARK: - UICollectionViewDelegate
extension PetExplorerViewController {
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let item = dataSource.itemIdentifier(for: indexPath) else {
      collectionView.deselectItem(at: indexPath, animated: true)
      return
    }

    guard let pet = item.pet else {
      return
    }

    pushDetailForPet(pet, withAdoptionStatus: adoptions.contains(pet))
  }

  func pushDetailForPet(_ pet: Pet, withAdoptionStatus isAdopted: Bool) {
    let storyboard = UIStoryboard(name: "Main", bundle: .main)
    let petDetailViewController =
    storyboard.instantiateViewController(identifier: "PetDetailViewController") { coder in
      return PetDetailViewController(coder: coder, pet: pet)
    }
    petDetailViewController.delegate = self
    petDetailViewController.isAdopted = isAdopted
    navigationController?.pushViewController(petDetailViewController, animated: true)
  }

  func cellRegistrationHandler(cell: UICollectionViewListCell, indexPath: IndexPath, item: Item) {
    var configuration = cell.defaultContentConfiguration()
    configuration.text = item.title
    cell.contentConfiguration = configuration
    let options = UICellAccessory.OutlineDisclosureOptions(style: .header)
    let disclosureAccessory = UICellAccessory.outlineDisclosure(options: options)
    cell.accessories = [disclosureAccessory]
  }

  func petCellRegistrationHandler(cell: UICollectionViewListCell, indexPath: IndexPath, item: Item) {
    guard let pet = item.pet else { return }
    var configuration = cell.defaultContentConfiguration()
    configuration.text = pet.name
    configuration.secondaryText = "\(pet.age) years old"
    configuration.image = UIImage(named: pet.imageName)
    configuration.imageProperties.maximumSize = CGSize(width: 40, height: 40)
    cell.contentConfiguration = configuration
    cell.accessories = [.disclosureIndicator()]
    if self.adoptions.contains(pet) {
      var backgroundConfig = UIBackgroundConfiguration.listPlainCell()
      backgroundConfig.backgroundColor = .systemBlue
      backgroundConfig.cornerRadius = 5
      backgroundConfig.backgroundInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)

      cell.backgroundConfiguration = backgroundConfig
    }
  }


  func adoptedPetCellRegistrationHandler(cell: UICollectionViewListCell, indexPath: IndexPath, item: Item) {
    guard let pet = item.pet else {
      return
    }
    var configuration = cell.defaultContentConfiguration()
    configuration.text = "Your pet: \(pet.name)"
    configuration.secondaryText = "\(pet.age) years old"
    configuration.image = UIImage(named: pet.imageName)
    configuration.imageProperties.maximumSize = CGSize(width: 40, height: 40)
    cell.contentConfiguration = configuration
    cell.accessories = [.disclosureIndicator()]
  }
}

// MARK: - PetDetailViewControllerDelegate
extension PetExplorerViewController: PetDetailViewControllerDelegate {
  func petDetailViewController(_ petDetailViewController: PetDetailViewController, didAdoptPet pet: Pet) {
    adoptions.insert(pet)
    var adoptedPetsSnapshot = dataSource.snapshot(for: .adoptedPets)
    let newItem = Item(pet: pet, title: pet.name)
    adoptedPetsSnapshot.append([newItem])

    dataSource.apply(adoptedPetsSnapshot,
                     to: .adoptedPets,
                     animatingDifferences: true
    )

    updateDataSource(for: pet)
  }
}
