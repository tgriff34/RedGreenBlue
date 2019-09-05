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
                    svgLayer.fillColor = UIColor.white.cgColor
                    svgLayer.resizeToFit(self.lightImage.bounds)
            }

            lightImage.subviews.forEach({ $0.removeFromSuperview() })
            lightImage.addSubview(image)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        subView.layer.cornerRadius = 20.0
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
                print("slider started")
                delegate?.lightsTableViewCell(self, lightSliderStartedFor: self.light)
            case .moved:
                delegate?.lightsTableViewCell(self, lightSliderMovedFor: self.light)
            case .ended:
                print("slider ended")
                delegate?.lightsTableViewCell(self, lightSliderEndedFor: self.light)
            default:
                break
            }
        }
    }
}

protocol LightsCellDelegate: AnyObject {
    func lightsTableViewCell(_ lightsTableViewCell: LightsCustomCell, lightSwitchTappedFor light: Light)
    func lightsTableViewCell(_ lightsTabelViewCell: LightsCustomCell, lightSliderStartedFor light: Light)
    func lightsTableViewCell(_ lightsTableViewCell: LightsCustomCell, lightSliderMovedFor light: Light)
    func lightsTableViewCell(_ lightsTableViewCell: LightsCustomCell, lightSliderEndedFor light: Light)
}
