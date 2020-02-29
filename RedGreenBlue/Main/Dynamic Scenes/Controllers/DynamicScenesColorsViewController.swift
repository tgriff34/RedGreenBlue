//
//  DynamicScenesColorsTableViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/25/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue

class DynamicScenesColorsViewController: UICollectionViewController {
    var colors = [UIColor]()
    var selectedIndexPath: IndexPath?
    weak var addColorsDelegate: DynamicSceneAddAllColorsDelegate?

    var deleteButton: UIBarButtonItem?
    var spacer: UIBarButtonItem?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        deleteButton = UIBarButtonItem(title: "Delete", style: .plain, target: self,
                                       action: #selector(deleteTapped(_:)))
        spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)

        deleteButton?.isEnabled = false
        toolbarItems = [spacer!, editButtonItem]
        navigationController?.setToolbarHidden(false, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        if editing {
            toolbarItems = [deleteButton!, spacer!, editButtonItem]
            navigationItem.rightBarButtonItem?.isEnabled = false
        }

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
            toolbarItems = [spacer!, editButtonItem]
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }

    @objc func deleteTapped(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: "Delete Colors",
                                            message: "Are you sure you want to delete these colors?",
                                            preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            if let selectedCells = self.collectionView.indexPathsForSelectedItems {
                let items = selectedCells.map({ $0.item }).sorted().reversed()
                for item in items {
                    self.colors.remove(at: item)
                }
                self.collectionView.deleteItems(at: selectedCells)
                self.setEditing(false, animated: true)
                self.addColorsDelegate?.dynamicSceneColorsAdded(self.colors)
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAction)

        self.present(actionSheet, animated: true, completion: nil)
    }
}

// MARK: - CollectionView
extension DynamicScenesColorsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 3.0 - 8
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
extension DynamicScenesColorsViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "addColorSegue":
            let viewController = segue.destination as? DynamicScenesAddColorViewController
            viewController?.colorToEdit = nil
            viewController?.addColorDelegate = self
            viewController?.customColorDelegate = self
        case "EditingColorSegue":
            let viewController = segue.destination as? DynamicScenesAddColorViewController
            viewController?.colorToEdit = colors[selectedIndexPath!.row]
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
extension DynamicScenesColorsViewController: DynamicSceneColorDelegate, DynamicSceneCustomColorDelegate {
    func dynamicSceneColorAdded(_ colors: [UIColor]) {
        self.colors.append(contentsOf: colors)
        addColorsDelegate?.dynamicSceneColorsAdded(self.colors)
        collectionView.reloadData()
    }

    func dynamicSceneColorAdded(_ color: UIColor) {
        self.colors.append(color)
        addColorsDelegate?.dynamicSceneColorsAdded(self.colors)
        collectionView.reloadData()
    }

    func dynamicSceneColorEdited(_ color: UIColor) {
        if let selectedIndexPath = selectedIndexPath {
            colors[selectedIndexPath.row] = color
            collectionView.reloadItems(at: [selectedIndexPath])
            self.selectedIndexPath = nil
        }
        addColorsDelegate?.dynamicSceneColorsAdded(colors)
    }
}
