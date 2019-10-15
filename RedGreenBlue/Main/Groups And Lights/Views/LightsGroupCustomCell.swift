//
//  LightsGroupCustomCell.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/16/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue

class LightsGroupCustomCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var numberOfLightsLabel: UILabel!
    @IBOutlet weak var `switch`: UISwitch!
    @IBOutlet weak var slider: CustomUISlider!
    @IBOutlet weak var subView: GradientLayerView!

    weak var delegate: LightsGroupsCellDelegate?

    var group: RGBGroup! {
        didSet {
            self.label.text = group.name

            let numberOfLightsOn = RGBGroupsAndLightsHelper.shared.getNumberOfLightsOnInGroup(group.lights)
            let avgBrightness = RGBGroupsAndLightsHelper.shared.getAverageBrightnessOfLightsInGroup(group.lights)

            self.numberOfLightsLabel.text = parseNumberOfLightsOn(for: group, numberOfLightsOn)

            numberOfLightsOn > 0 ? self.switch.setOn(true, animated: true) : self.switch.setOn(false, animated: true)

            if numberOfLightsOn > 0 {
                self.slider.setValue(Float(avgBrightness / numberOfLightsOn) / 2.54, animated: true)

                // For every light that is on get the color of the light
                var colorsOfLightsOn = [UIColor]()
                for light in group.lights where light.state.on! {
                    let color = HueUtilities.colorFromXY(
                        CGPoint(x: light.state.xy![0], y: light.state.xy![1]),
                        forModel: "LCT016")
                    if !colorsOfLightsOn.contains(color) {
                        colorsOfLightsOn.append(color)
                    }
                }

                // Sort colors based on hue and set them to gradient colors
                colorsOfLightsOn.sort(by: { $0.hue < $1.hue })
                if colorsOfLightsOn.count > 1 {
                    subView.backgroundColor = nil
                    subView.layer.colors = colorsOfLightsOn.map({ return $0.cgColor })
                } else {
                    subView.layer.colors = nil
                    subView.backgroundColor = colorsOfLightsOn[0]
                }

                // Set colors for text labels
                let textColor = RGBColorUtilities.colorForLabel(from: colorsOfLightsOn)
                self.label.textColor = textColor
                self.numberOfLightsLabel.textColor = textColor
            } else {
                self.slider.setValue(1, animated: true)

                // Set colors for layer and labels
                subView.layer.colors = nil
                subView.backgroundColor = UIColor(named: "cellColor", in: nil, compatibleWith: traitCollection)
                if #available(iOS 13.0, *) {
                    self.label.textColor = UIColor.label
                    self.numberOfLightsLabel.textColor = UIColor.label
                } else {
                    self.label.textColor = UIColor.black
                    self.numberOfLightsLabel.textColor = UIColor.black
                }
            }
        }
    }

    private func parseNumberOfLightsOn(for group: RGBGroup, _ number: Int) -> String {
        // Displays how many lights currently on in group
        if number == group.lightIdentifiers.count {
            return "All lights are on"
        } else if number == 0 {
            return "All lights are off"
        } else {
            let middleString = number == 1 ? " light" : " lights"
            let endString = number == 1 ? " is on" : " are on"
            return String(format: "%@%@%@", "\(number)", middleString, endString)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        subView.layer.cornerRadius = 20.0
        subView.layer.shadowColor = UIColor.black.cgColor
        subView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        subView.layer.shadowOpacity = 0.34
        subView.layer.shadowRadius = 4.3

        subView.layer.startPoint = CGPoint(x: 0.0, y: 0.5)
        subView.layer.endPoint = CGPoint(x: 1.0, y: 0.5)
        
        self.slider.addTarget(self, action: #selector(lightSliderMoved(_:_:)), for: .valueChanged)
        self.switch.addTarget(self, action: #selector(lightSwitchTapped(_:)), for: .valueChanged)
    }

    @objc func lightSwitchTapped(_ sender: UISwitch!) {
        delegate?.lightGroupsTableViewCell(self, lightSwitchTappedFor: self.group)
    }

    @objc func lightSliderMoved(_ sender: UISlider!, _ event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                delegate?.lightGroupsTableViewCell(self, lightSliderStartedFor: self.group)
                self.label.text = "\(Int(sender.value))%"
            case .moved:
                delegate?.lightGroupsTableViewCell(self, lightSliderMovedFor: self.group)
                self.label.text = "\(Int(sender.value))%"
            case .ended:
                delegate?.lightGroupsTableViewCell(self, lightSliderEndedFor: self.group)
            default:
                break
            }
        }
    }
}
