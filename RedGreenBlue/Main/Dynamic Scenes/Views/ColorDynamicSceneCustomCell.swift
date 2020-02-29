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
    @IBOutlet weak var checkmarkView: SSCheckMark!

    var color: UIColor! {
        didSet {
            self.subView.backgroundColor = color
        }
    }

    var isInEditingMode: Bool = false {
        didSet {
            checkmarkView.isHidden = !isInEditingMode
        }
    }

    override var isSelected: Bool {
        didSet {
            checkmarkView.checked = isSelected
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        RGBCellUtilities.setCellLayerStyleAttributes(subView)
    }
}
