//
//  LogByUserTableViewCell.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 31/10/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit

class LogByUserTableViewCell: UITableViewCell {

    @IBOutlet weak var nameText: UILabel!
    
    @IBOutlet weak var latitudeText: UILabel!
    
    @IBOutlet weak var lifespanText: UILabel!
    @IBOutlet weak var longitudeText: UILabel!
    
    
    @IBOutlet weak var showLess: UIButton!
    @IBOutlet weak var dateText: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
