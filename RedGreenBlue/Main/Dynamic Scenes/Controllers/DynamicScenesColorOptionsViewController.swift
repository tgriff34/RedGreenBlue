//
//  DynamicScenesColorOptionsViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/21/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit

class DynamicScenesColorOptionsViewController: UITableViewController {

    @IBOutlet weak var changingLightColorsSwitch: UISwitch!
    @IBOutlet weak var displayMultiColorsSwitch: UISwitch!
    @IBOutlet weak var randomColorSwitch: UISwitch!
    @IBOutlet weak var shiftRightSwitch: UISwitch!

    var lightsChangeColor: Bool!
    var displayMultiColors: Bool!
    var randomColors: Bool!
    var shiftRight: Bool!

    var time: Int = 1

    weak var colorOptionsDelegate: DynamicSceneColorOptionsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set switches to bools
        changingLightColorsSwitch.isOn = lightsChangeColor
        displayMultiColorsSwitch.isOn = displayMultiColors
        randomColorSwitch.isOn = randomColors
        shiftRightSwitch.isOn = shiftRight

        changingLightColorsSwitch.addTarget(self, action: #selector(changingLightsDidChange(_:)), for: .valueChanged)
        displayMultiColorsSwitch.addTarget(self, action: #selector(displayMultiColorDidChange(_:)), for: .valueChanged)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        colorOptionsDelegate?.lightsChangeColor(changingLightColorsSwitch.isOn)
        colorOptionsDelegate?.lightsMultiColor(displayMultiColorsSwitch.isOn)
        colorOptionsDelegate?.lightsRandomColor(randomColorSwitch.isOn)
        colorOptionsDelegate?.lightsShiftRight(shiftRightSwitch.isOn)
        colorOptionsDelegate?.timeBetweenCycle(.color, self.time)
    }

    @objc func changingLightsDidChange(_ sender: UISwitch) {
        tableView.reloadSections([1, 2], with: .automatic)
    }

    @objc func displayMultiColorDidChange(_ sender: UISwitch) {
        tableView.reloadSections([2], with: .automatic)
    }
}

// MARK: - TableView
extension DynamicScenesColorOptionsViewController {
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return "When enabled, allows the lights to change colors on a timer."
        case 1:
            if changingLightColorsSwitch.isOn {
                return String(format: "%@%@%@",
                              "When enabled, lights will display different colors from each other. ",
                              "Otherwise, the lights will all display the same color and cycle through ",
                              "the list of colors.")
            }
        default:
            return nil
        }
        return nil
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 && changingLightColorsSwitch.isOn {
            return 2
        } else if section == 1 {
            return 0
        }
        if section == 2 && changingLightColorsSwitch.isOn && displayMultiColorsSwitch.isOn {
            return 2
        } else if section == 2 {
            return 0
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 1 && !changingLightColorsSwitch.isOn {
            return 0.1
        }
        if section == 2 && !changingLightColorsSwitch.isOn && !displayMultiColorsSwitch.isOn {
            return 0.1
        }
        return super.tableView(tableView, heightForFooterInSection: section)
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && !changingLightColorsSwitch.isOn {
            return 0.1
        }
        if section == 2 && !changingLightColorsSwitch.isOn && !displayMultiColorsSwitch.isOn {
            return 0.1
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        switch indexPath.section {
        case 1:
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = time > 1 ? "\(time) seconds" : "\(time) second"
            }
        default:
            break
        }
        return cell
    }
}

extension DynamicScenesColorOptionsViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "TimeBetweenChangingColorSegue":
            let viewController = segue.destination as? DynamicScenesAddTimeViewController
            viewController?.addTimeDelegate = self
            viewController?.type = .color
            viewController?.title = "Color Timer"
            viewController?.selectedTime = self.time
        default:
            logger.error("segue identifier does not exist: \(segue.identifier ?? "nil")")
        }
    }
}

extension DynamicScenesColorOptionsViewController: DynamicSceneAddTimeDelegate {
    func dynamicSceneTimeAdded(_ type: TimeType, _ time: Int) {
        self.time = time
        tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
    }
}
