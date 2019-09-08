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
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var subView: UIView!

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
            } else {
                self.slider.setValue(1, animated: true)
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
            case .moved:
                delegate?.lightGroupsTableViewCell(self, lightSliderMovedFor: self.group)
            case .ended:
                delegate?.lightGroupsTableViewCell(self, lightSliderEndedFor: self.group)
            default:
                break
            }
        }
    }
}
