//
//  HeaderLogTableViewCell.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 06/11/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit

class HeaderLogTableViewCell: UITableViewCell {

    @IBOutlet weak var startDateText: UILabel!
    
    @IBOutlet weak var finishDateText: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
