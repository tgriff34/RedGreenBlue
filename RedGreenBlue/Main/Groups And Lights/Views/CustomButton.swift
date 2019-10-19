//
//  CustomButton.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/10/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

// Custom button that is used within light groups for the Scene, Dynamic Scene, Color Wheel buttons.
// It applies a shadow similar to the cells of each tableview.  It also makes sure that images inside
// are the correct color depending on application theme (light / dark).  It makes sure to not color
// the color wheel image since it is already colored.

import UIKit

class CustomButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        self.layer.shadowOpacity = 0.34
        self.layer.shadowRadius = 4.3

        let image = self.image(for: .normal)!.withRenderingMode(.alwaysTemplate)
        let colorWheelImage = UIImage(named: "colorWheel")!
        let data: Data = image.pngData()!
        let data2: Data = colorWheelImage.pngData()!
        if data != data2 {
            self.setImage(image, for: .normal)
            self.tintColor = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        }
    }
}
