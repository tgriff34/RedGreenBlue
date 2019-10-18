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
                slider.setValue((Float(light.state.brightness!) / 2.54), animated: true)

                subView.backgroundColor = HueUtilities.colorFromXY(
                    CGPoint(x: light.state.xy![0], y: light.state.xy![1]),
                    forModel: "LCT016")
            } else {
                slider.setValue(1, animated: true)
                subView.backgroundColor = UIColor(named: "cellColor", in: nil, compatibleWith: traitCollection)
            }

            var colorForLabels: UIColor?
            if let backgroundColor = subView.backgroundColor, light.state.on! {
                colorForLabels = RGBCellUtilities.colorForLabel(from: [backgroundColor])
                label.textColor = colorForLabels!
            } else if #available(iOS 13, *) {
                label.textColor = UIColor.label
            } else {
                label.textColor = UIColor.black
            }

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
        subView.layer.cornerRadius = 20.0
        subView.layer.shadowColor = UIColor.black.cgColor
        subView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        subView.layer.shadowOpacity = 0.34
        subView.layer.shadowRadius = 4.3

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
