//
//  LightsCustomCell.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/22/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue
import SwiftSVG

class LightsCustomCell: UITableViewCell {
    @IBOutlet weak var `switch`: UISwitch!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var subView: UIView!
    @IBOutlet weak var lightImage: UIView!

    weak var delegate: LightsCellDelegate?

    var light: Light! {
        didSet {
            label.text = light.name

            self.switch.setOn(light.state.on!, animated: true)

            if light.state.on! {
                // Set slider value and make it appear
                slider.isHidden = false
                slider.setValue((Float(light.state.brightness!) / 2.54), animated: true)

                // Set the background color of the cell to the lights current color
                subView.backgroundColor = HueUtilities.colorFromXY(
                    CGPoint(x: light.state.xy![0], y: light.state.xy![1]),
                    forModel: "LCT016")
            } else {
                // Set slider value to 1 and hide slider
                slider.isHidden = true
                slider.setValue(1, animated: true)

                // Set the background color to the default cell color according to application theme (light / dark)
                subView.backgroundColor = UIColor(named: "cellColor", in: nil, compatibleWith: traitCollection)
            }

            // Change the color of the text labels based on the background color of the cell if the light is on,
            // or depending on which application theme is selected (light / dark) if the light is off.
            var colorForLabels: UIColor?
            if let backgroundColor = subView.backgroundColor, light.state.on! {
                colorForLabels = RGBCellUtilities.colorForLabel(from: [backgroundColor])
                label.textColor = colorForLabels!
            } else if #available(iOS 13, *) {
                label.textColor = UIColor.label
            } else {
                label.textColor = UIColor.black
            }

            // Get image of type of light, change the color according to cell background color if the light is on,
            // or whether on light / dark theme if the light is off. Then adjust the image's center and add it to view.
            let svgName = RGBGroupsAndLightsHelper.shared.getLightImageName(modelId: light.modelId)
            let image = UIView(SVGNamed: svgName) { (svgLayer) in
                if self.light.state.on! {
                    svgLayer.fillColor = colorForLabels!.cgColor
                } else if self.traitCollection.userInterfaceStyle == .dark {
                    svgLayer.fillColor = UIColor.white.cgColor
                } else {
                    svgLayer.fillColor = UIColor.black.cgColor
                }
            }
            image.bounds = CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0)
            image.center = CGPoint(x: 15.0, y: 15.0)

            lightImage.subviews.forEach({ $0.removeFromSuperview() })
            lightImage.addSubview(image)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        RGBCellUtilities.setCellLayerStyleAttributes(subView)

        RGBCellUtilities.setImagesForSlider(slider)

        self.switch.addTarget(self, action: #selector(lightSwitchTapped(_:)), for: .valueChanged)
        self.slider.addTarget(self, action: #selector(lightSliderMoved(_:_:)), for: .valueChanged)
    }

    @objc func lightSwitchTapped(_ sender: UISwitch!) {
        delegate?.lightsTableViewCell(self, lightSwitchTappedFor: self.light)
    }

    @objc func lightSliderMoved(_ sender: UISlider!, _ event: UIEvent!) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                delegate?.lightsTableViewCell(self, lightSliderStartedFor: self.light)
                self.label.text = "\(Int(sender.value))%"
            case .moved:
                delegate?.lightsTableViewCell(self, lightSliderMovedFor: self.light)
                self.label.text = "\(Int(sender.value))%"
            case .ended:
                delegate?.lightsTableViewCell(self, lightSliderEndedFor: self.light)
            default:
                break
            }
        }
    }
}
