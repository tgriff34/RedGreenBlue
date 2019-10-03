//
//  ColorDynamicSceneCustomCell.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/3/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue

class ColorDynamicSceneCustomCell: UICollectionViewCell {
    @IBOutlet weak var subView: UIView!
    @IBOutlet weak var checkmark: UIImageView!

    var color: XYColor! {
        didSet {
            self.subView.backgroundColor = HueUtilities.colorFromXY(CGPoint(x: color.xvalue,
                                                                            y: color.yvalue),
                                                                    forModel: "LCT016")
        }
    }

    var isInEditingMode: Bool = false {
        didSet {
            checkmark.tintColor = .white
            if #available(iOS 13.0, *) {
                checkmark.image = UIImage(systemName: "circle")
            } else {
                checkmark.image = UIImage(named: "circle")
            }
            checkmark.isHidden = !isInEditingMode
        }
    }

    override var isSelected: Bool {
        didSet {
            if isInEditingMode {
                if #available(iOS 13.0, *) {
                    checkmark.image = isSelected ?
                        UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle")
                } else {
                    checkmark.image = isSelected ? UIImage(named: "checkmark") : UIImage(named: "circle")
                }
                checkmark.tintColor = isSelected ? self.tintColor : .white
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        subView.layer.cornerRadius = 20.0
        subView.layer.shadowColor = UIColor.black.cgColor
        subView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        subView.layer.shadowOpacity = 0.34
        subView.layer.shadowRadius = 4.3

        checkmark.layer.shadowColor = UIColor.gray.cgColor
        checkmark.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        checkmark.layer.shadowOpacity = 0.7
        checkmark.layer.shadowRadius = 1.5    }
}
