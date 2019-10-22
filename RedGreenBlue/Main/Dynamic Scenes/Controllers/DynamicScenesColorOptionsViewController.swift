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

        changingLightColorsSwitch.isOn = lightsChangeColor
        displayMultiColorsSwitch.isOn = displayMultiColors
        randomColorSwitch.isOn = randomColors
        shiftRightSwitch.isOn = shiftRight

        changingLightColorsSwitch.addTarget(self, action: #selector(changingLightsDidChange(_:)), for: .valueChanged)
        displayMultiColorsSwitch.addTarget(self, action: #selector(displayMultiColorDidChange(_:)), for: .valueChanged)
        randomColorSwitch.addTarget(self, action: #selector(randomColorDidChange(_:)), for: .valueChanged)
        shiftRightSwitch.addTarget(self, action: #selector(shiftRightDidChange(_:)), for: .valueChanged)
    }

    @objc func changingLightsDidChange(_ sender: UISwitch) {
        colorOptionsDelegate?.lightsChangeColor(sender.isOn)
        tableView.reloadSections([1, 2], with: .automatic)
    }

    @objc func displayMultiColorDidChange(_ sender: UISwitch) {
        colorOptionsDelegate?.lightsMultiColor(sender.isOn)
        tableView.reloadSections([2], with: .automatic)
    }

    @objc func randomColorDidChange(_ sender: UISwitch) {
        colorOptionsDelegate?.lightsRandomColor(sender.isOn)
    }

    @objc func shiftRightDidChange(_ sender: UISwitch) {
        colorOptionsDelegate?.lightsShiftRight(sender.isOn)
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
                              "When enabled, lights will display different colors from each other.",
                              "Otherwise, the lights will all display the same color and cycle through ",
                              "the list of colors.")
            }
        default:
            return nil
        }
        return nil
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1:
            if changingLightColorsSwitch.isOn {
                return 2
            }
            return 0
        case 2:
            if changingLightColorsSwitch.isOn && displayMultiColorsSwitch.isOn {
                return 2
            }
            return 0
        default:
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            if !changingLightColorsSwitch.isOn {
                return 0.1
            }
        case 2:
            if !changingLightColorsSwitch.isOn && !displayMultiColorsSwitch.isOn {
                return 0.1
            }
        default:
            return super.tableView(tableView, heightForFooterInSection: section)
        }
        return super.tableView(tableView, heightForFooterInSection: section)
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            if !changingLightColorsSwitch.isOn {
                return 0.1
            }
        case 2:
            if !changingLightColorsSwitch.isOn && !displayMultiColorsSwitch.isOn {
                return 0.1
            }
        default:
            return super.tableView(tableView, heightForHeaderInSection: section)
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
        colorOptionsDelegate?.timeBetweenCycle(self.time)
        tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
    }
}