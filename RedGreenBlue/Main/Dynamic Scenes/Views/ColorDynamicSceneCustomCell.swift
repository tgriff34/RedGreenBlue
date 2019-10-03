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

    var color: XYColor! {
        didSet {
            self.subView.backgroundColor = HueUtilities.colorFromXY(CGPoint(x: color.xvalue,
                                                                            y: color.yvalue),
                                                                    forModel: "LCT016")
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
        subView.layer.cornerRadius = 20.0
        subView.layer.shadowColor = UIColor.black.cgColor
        subView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        subView.layer.shadowOpacity = 0.34
        subView.layer.shadowRadius = 4.3
    }
}
