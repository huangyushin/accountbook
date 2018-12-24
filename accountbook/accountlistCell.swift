//
//  accountlistCell.swift
//  accountbook
//
//  Created by huangyuhsin on 2018/12/12.
//  Copyright © 2018 huangyuhsin All rights reserved.
//

import UIKit

class accountlistCell: UITableViewCell {

    @IBOutlet weak var lblItem2: UILabel!
    
    @IBOutlet weak var lblDate2: UILabel!
    
    @IBOutlet weak var lblAmount2: UILabel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
