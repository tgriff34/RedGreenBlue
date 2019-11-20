//
//  DynamicScenesBrightnessOptionsViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/23/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import MARKRangeSlider

class DynamicScenesBrightnessViewController: UITableViewController {
    @IBOutlet weak var fluctuatingBrightnessSwitch: UISwitch!
    @IBOutlet weak var brightnessSlider: MARKRangeSlider!

    var fluctuatingBrightness: Bool = true
    var minBrightness: Int = 25
    var maxBrightness: Int = 75
    var brightnessTime: Int = 1

    weak var brightnessOptionsDelegate: DynamicSceneBrightnessOptionsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Option switch actions
        fluctuatingBrightnessSwitch.addTarget(
            self, action: #selector(fluctuatingBrightnessDidChange(_:)), for: .valueChanged)

        // Fluctuating brightness slider default values/init
        brightnessSlider.setMinValue(1, maxValue: 100)
        brightnessSlider.setLeftValue(CGFloat(minBrightness), rightValue: CGFloat(maxBrightness))
        brightnessSlider.minimumDistance = 1
        brightnessSlider.backgroundColor = tableView.cellForRow(at: IndexPath(row: 1, section: 4))?.backgroundColor

        // Set the track image on the fluctuating brightness color to blue
        guard let arrayOfImages = brightnessSlider.subviews as? [UIImageView],
            arrayOfImages.indices.contains(1) else { return }

        let trackImage = arrayOfImages[1]
        trackImage.image = trackImage.image?.withRenderingMode(.alwaysTemplate)
        trackImage.tintColor = view.tintColor

        // Set fluctating brightness slider action
        brightnessSlider.addTarget(
            self, action: #selector(brightnessSliderValueChange(_:)), for: .valueChanged)

        // Set switch to bool
        fluctuatingBrightnessSwitch.isOn = fluctuatingBrightness
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        brightnessOptionsDelegate?.minMaxBrightnessValues(minBrightness, maxBrightness)
        brightnessOptionsDelegate?.timeBetweenCycle(.brightness, brightnessTime)
        brightnessOptionsDelegate?.fluctuatingBrightnessEnabled(fluctuatingBrightnessSwitch.isOn)
    }

    @objc func fluctuatingBrightnessDidChange(_ sender: UISwitch) {
        tableView.reloadSections([1], with: .automatic)
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
    }

    @objc func brightnessSliderValueChange(_ sender: MARKRangeSlider) {
        minBrightness = Int(sender.leftValue)
        maxBrightness = Int(sender.rightValue)
        let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
        cell?.detailTextLabel?.text = "\(minBrightness)% - \(maxBrightness)%"
    }
}

extension DynamicScenesBrightnessViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 && !fluctuatingBrightnessSwitch.isOn {
            return 0
        } else if section == 1 {
            return 2
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 1 && !fluctuatingBrightnessSwitch.isOn {
            return 0.1
        }
        return super.tableView(tableView, heightForFooterInSection: section)
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && !fluctuatingBrightnessSwitch.isOn {
            return 0.1
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        switch indexPath.section {
        case 0:
            cell.detailTextLabel?.text = fluctuatingBrightnessSwitch.isOn ?
                "\(minBrightness)% - \(maxBrightness)%" : ""
        case 1:
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = brightnessTime > 1 ?
                    "\(brightnessTime) seconds" : "\(brightnessTime) second"
            }
        default:
            logger.info("No action for \(indexPath.section)")
        }
        return cell
    }
}

extension DynamicScenesBrightnessViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "TimeBetweenChangingBrightnessSegue":
            let viewController = segue.destination as? DynamicScenesAddTimeViewController
            viewController?.addTimeDelegate = self
            viewController?.title = "Brightness Timer"
            viewController?.type = .brightness
            viewController?.selectedTime = brightnessTime
        default:
            logger.error("segue identifier does not exist: \(segue.identifier ?? "nil")")
        }
    }
}

extension DynamicScenesBrightnessViewController: DynamicSceneAddTimeDelegate {
    func dynamicSceneTimeAdded(_ type: TimeType, _ time: Int) {
        self.brightnessTime = time
        tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
    }
}
