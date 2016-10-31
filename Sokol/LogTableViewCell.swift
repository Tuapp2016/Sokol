//
//  LogTableViewCell.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 30/10/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit

class LogTableViewCell: UITableViewCell {

    
    @IBOutlet weak var userIdText: UILabel!
    
    @IBOutlet weak var startTimeText: UILabel!
    
    @IBOutlet weak var finishTimeText: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
