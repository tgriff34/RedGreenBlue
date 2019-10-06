//
//  DynamicScenesColorsCollectionPickerViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/5/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import RealmSwift

class DynamicScenesColorsCollectionPickerViewController: UICollectionViewController {
    var colors = [XYColor]()

    var selectedColor: XYColor? {
        willSet(newColor) {
            for color in colors where
                color.xvalue == newColor?.xvalue &&
                color.yvalue == newColor?.yvalue {
                collectionView.selectItem(at: IndexPath(row: colors.index(of: color)!,
                                                        section: 0), animated: true, scrollPosition: [])
            }
        }
    }

    weak var delegate: DynamicSceneAddColorDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        colors.append(XYColor([0.7, 0.3]))
        colors.append(XYColor([0.6, 0.37]))
        colors.append(XYColor([0.5, 0.5]))
        colors.append(XYColor([0.17, 0.72]))
        colors.append(XYColor([0.2, 0.33]))
        colors.append(XYColor([0.13, 0.044]))
        colors.append(XYColor([0.23, 0.084]))
        colors.append(XYColor([0.34, 0.13]))
        colors.append(XYColor([0.45, 0.19]))
        colors.append(XYColor([0.32, 0.32]))
    }
}

// MARK: - CollectionView
extension DynamicScenesColorsCollectionPickerViewController: UICollectionViewDelegateFlowLayout {
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
        delegate?.dynamicSceneColorAdded(colors[indexPath.row])
    }
}
