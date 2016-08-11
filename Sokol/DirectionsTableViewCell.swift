//
//  DirectionsTableViewCell.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 11/08/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit

class DirectionsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var direction: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
