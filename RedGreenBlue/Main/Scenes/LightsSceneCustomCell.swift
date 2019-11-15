//
//  LightsSceneCustomCell.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/29/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue

class LightSceneCustomCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var subView: GradientLayerView!

    var group: RGBGroup! {
        didSet {
            setBackground()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        RGBCellUtilities.setCellLayerStyleAttributes(subView)
        subView.layer.startPoint = CGPoint(x: 0.0, y: 0.5)
        subView.layer.endPoint = CGPoint(x: 1.0, y: 0.5)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            UIView.animate(withDuration: 0.2, animations: {
                self.subView.transform = CGAffineTransform.init(scaleX: 0.95, y: 0.965)
            }, completion: { _ in
                UIView.animate(withDuration: 0.2, animations: {
                    self.subView.transform = CGAffineTransform.identity
                })
            })
        }
    }

    private func setBackground() {
        if self.isSelected {
            let colors = getColorsOfLightsOn()
            let colorForLabel = RGBCellUtilities.colorForLabel(from: colors)
            if colors.count > 1 {
                subView.layer.colors = colors.map({ return $0.cgColor })
                subView.backgroundColor = nil
            } else {
                subView.layer.colors = nil
                subView.backgroundColor = colors[0]
            }
            label.textColor = colorForLabel
        } else {
            subView.layer.colors = nil
            subView.backgroundColor = UIColor(named: "cellColor", in: nil, compatibleWith: traitCollection)
            if #available(iOS 13, *) {
                label.textColor = UIColor.label
            } else {
                label.textColor = UIColor.black
            }
        }
    }

    private func getColorsOfLightsOn() -> [UIColor] {
        // For every light that is on get the color of the light
        var colorsOfLightsOn = [UIColor]()
        for light in group.lights {
            let color = HueUtilities.colorFromXY(
                CGPoint(x: light.state.xy![0], y: light.state.xy![1]),
                forModel: "LCT016")
            if !colorsOfLightsOn.contains(color) {
                colorsOfLightsOn.append(color)
            }
        }
        colorsOfLightsOn.sort(by: { $0.hue < $1.hue })
        return colorsOfLightsOn
    }
}
