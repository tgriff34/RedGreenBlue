//
//  DynamicScenesColorsTableViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/25/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyHue

class DynamicScenesColorsCollectionViewController: UICollectionViewController {
    var colors = List<XYColor>()
    var selectedIndexPath: IndexPath?
    weak var addColorsDelegate: DynamicSceneAddAllColorsDelegate?

    var deleteButton: UIBarButtonItem?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let editButton = editButtonItem
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteTapped(_:)))
        deleteButton?.isEnabled = false
        toolbarItems = [editButton, spacer, deleteButton!]
        navigationController?.setToolbarHidden(false, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        collectionView.allowsMultipleSelection = editing
        let indexPaths = collectionView.indexPathsForVisibleItems
        for indexPath in indexPaths {
            //swiftlint:disable:next force_cast
            let cell = collectionView.cellForItem(at: indexPath) as! ColorDynamicSceneCustomCell
            cell.isInEditingMode = editing
        }

        if !editing, let indexPaths = collectionView.indexPathsForSelectedItems {
            for index in indexPaths {
                collectionView.deselectItem(at: index, animated: false)
            }
            deleteButton?.isEnabled = false
        }
    }

    @objc func deleteTapped(_ sender: UIBarButtonItem) {
        if let selectedCells = collectionView.indexPathsForSelectedItems {
            let items = selectedCells.map({ $0.item }).sorted().reversed()
            for item in items {
                colors.remove(at: item)
            }
            collectionView.deleteItems(at: selectedCells)
            deleteButton?.isEnabled = false
            addColorsDelegate?.dynamicSceneColorsAdded(colors)
        }
    }
}

// MARK: - CollectionView
extension DynamicScenesColorsCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 3.0
        return CGSize(width: width, height: width)
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "colorCell", for: indexPath)
            as! ColorDynamicSceneCustomCell //swiftlint:disable:this force_cast
        cell.color = colors[indexPath.row]
        cell.isInEditingMode = isEditing
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !isEditing {
            deleteButton?.isEnabled = false
        } else {
            deleteButton?.isEnabled = true
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let selectedItems = collectionView.indexPathsForSelectedItems, selectedItems.count == 0 {
            deleteButton?.isEnabled = false
        }
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if !isEditing {
            selectedIndexPath = indexPath
        }
        return true
    }
}

// MARK: - Navigation
extension DynamicScenesColorsCollectionViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "addColorSegue":
            let viewController = segue.destination as? DynamicScenesAddColorViewController
            viewController?.color = nil
            viewController?.addColorDelegate = self
        case "EditingColorSegue":
            let viewController = segue.destination as? DynamicScenesAddColorViewController
            viewController?.color = colors[selectedIndexPath!.row]
            viewController?.addColorDelegate = self
        default:
            logger.error("No such segue identifier: \(String(describing: segue.identifier))")
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return !isEditing
    }
}

// MARK: - Delegate
extension DynamicScenesColorsCollectionViewController: DynamicSceneAddColorDelegate {
    func dynamicSceneColorAdded(_ color: XYColor) {
        if let selectedIndexPath = selectedIndexPath {
            colors[selectedIndexPath.row] = color
            collectionView.reloadItems(at: [selectedIndexPath])
            self.selectedIndexPath = nil
        } else {
            colors.append(color)
            collectionView.insertItems(at: [IndexPath(row: colors.count - 1, section: 0)])
        }
        addColorsDelegate?.dynamicSceneColorsAdded(colors)
    }
}
