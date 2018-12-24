//
//  PieChartsViewCell.swift
//  accountbook
//
//  Created by huangyuhsin on 2018/12/12.
//  Copyright © 2018 huangyuhsin All rights reserved.
//

import UIKit

class PieChartsViewCell: UITableViewCell {

    
    @IBOutlet weak var lblDate: UILabel!
    
    @IBOutlet weak var lblItem: UILabel!
    
    @IBOutlet weak var lblAmount: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
