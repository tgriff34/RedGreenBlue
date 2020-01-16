//
//  DynamicScenesColorsCollectionPickerViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/5/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit

class DynamicScenesColorsPickerViewController: UICollectionViewController {
    var colors = [UIColor]()

    var selectedColors: [UIColor]? {
        willSet(newColors) {
            for color in colors where newColors!.contains(where: { $0 == color }) {
                collectionView.selectItem(at: IndexPath(row: colors.firstIndex(of: color)!, section: 0),
                                          animated: true, scrollPosition: [])
            }
        }
    }

    var selectedColor: UIColor? {
        willSet(newColor) {
            for color in colors where color == newColor {
                    collectionView.selectItem(at: IndexPath(row: colors.firstIndex(of: color)!, section: 0),
                                              animated: true,
                                              scrollPosition: [])
            }
        }
    }

    weak var delegate: DynamicSceneCustomColorDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        colors.append(UIColor.red)
        colors.append(UIColor.systemRed)
        colors.append(UIColor.orange)
        colors.append(UIColor.systemOrange)
        colors.append(UIColor.yellow)
        colors.append(UIColor.systemYellow)
        colors.append(UIColor.green)
        colors.append(UIColor.systemGreen)
        colors.append(UIColor.blue)
        colors.append(UIColor.systemBlue)
        colors.append(UIColor.purple)
        if #available(iOS 13.0, *) {
            colors.append(UIColor.systemIndigo)
        } else {
            // Fallback on earlier versions
        }
        colors.append(UIColor.systemPink)
        colors.append(UIColor.white)
    }
}

// MARK: - CollectionView
extension DynamicScenesColorsPickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 2.0 - 8
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
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedColor != nil {
            delegate?.dynamicSceneColorEdited(colors[indexPath.row])
        } else {
            selectedColors?.append(colors[indexPath.row])
            delegate?.dynamicSceneColorAdded(selectedColors!)
        }
    }
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if selectedColor == nil {
            let index = selectedColors?.firstIndex(of: colors[indexPath.row])
            selectedColors?.remove(at: index!)
            delegate?.dynamicSceneColorAdded(selectedColors!)
        }
    }
}
