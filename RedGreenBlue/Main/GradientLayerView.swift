//
//  GradientLayerView.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/9/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit

class GradientLayerView: UIView {
    override public class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    override var layer: CAGradientLayer {
        //swiftlint:disable:next force_cast
        return super.layer as! CAGradientLayer
    }
}
