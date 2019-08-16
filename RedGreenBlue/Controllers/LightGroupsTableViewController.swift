//
//  LightGroupsTableViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/16/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue

class LightGroupsTableViewController: UITableViewController {
    
    var rgbBridge: RGBHueBridge?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        print(rgbBridge)
        
        let swiftyHue = SwiftyHue()
        //swiftyHue.
        
    }
}

extension LightGroupsTableViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupsCellIdentifier", for: indexPath)
        
        //cell.textLabel?.text =
        
        return cell
    }
}
