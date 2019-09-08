//
//  GroupCellProtocol.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/8/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation

protocol LightsGroupsCellDelegate: AnyObject {
    func lightGroupsTableViewCell(_ lightGroupsTableViewCell: LightsGroupCustomCell,
                                  lightSwitchTappedFor group: RGBGroup)
    func lightGroupsTableViewCell(_ lightGroupTableViewCell: LightsGroupCustomCell,
                                  lightSliderStartedFor group: RGBGroup)
    func lightGroupsTableViewCell(_ lightGroupsTableViewCell: LightsGroupCustomCell,
                                  lightSliderMovedFor group: RGBGroup)
    func lightGroupsTableViewCell(_ lightGroupTableViewCell: LightsGroupCustomCell,
                                  lightSliderEndedFor group: RGBGroup)
}
