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
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        selectedIndexPath = indexPath
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
}

// MARK: - Delegate
extension DynamicScenesColorsCollectionViewController: DynamicSceneAddColorDelegate {
    func dynamicSceneColorAdded(_ color: XYColor) {
        if let selectedIndexPath = selectedIndexPath {
            colors[selectedIndexPath.row] = color
            collectionView.reloadItems(at: [selectedIndexPath])
        } else {
            colors.append(color)
            collectionView.insertItems(at: [IndexPath(row: colors.count - 1, section: 0)])
        }
        addColorsDelegate?.dynamicSceneColorsAdded(colors)
    }
}
