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
    @IBOutlet weak var lightImage: SVGView!

    weak var delegate: LightsCellDelegate?

    var light: Light! {
        didSet {
            label.text = light.name

            self.switch.setOn(light.state.on!, animated: true)

            if light.state.on! {
                slider.setValue(Float(light.state.brightness!) / 2.54, animated: true)
            } else {
                slider.setValue(1, animated: true)
            }

            let image = UIView(SVGNamed:
            RGBGroupsAndLightsHelper.shared.getLightImageName(modelId: light.modelId)) { (svgLayer) in
                if #available(iOS 13.0, *) {
                    svgLayer.fillColor = UIColor.label.cgColor
                } else {
                    // Fallback on earlier versions
                    svgLayer.fillColor = UIColor.black.cgColor
                }
                svgLayer.resizeToFit(self.lightImage.bounds)
            }

            lightImage.subviews.forEach({ $0.removeFromSuperview() })
            lightImage.addSubview(image)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        subView.layer.cornerRadius = 20.0
        if self.traitCollection.userInterfaceStyle != .dark {
            subView.layer.shadowColor = UIColor.gray.cgColor
            subView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
            subView.layer.shadowOpacity = 0.7
            subView.layer.shadowRadius = 4.7
        }
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
            case .moved:
                delegate?.lightsTableViewCell(self, lightSliderMovedFor: self.light)
            case .ended:
                delegate?.lightsTableViewCell(self, lightSliderEndedFor: self.light)
            default:
                break
            }
        }
    }
}
