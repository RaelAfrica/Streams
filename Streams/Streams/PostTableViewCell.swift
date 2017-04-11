//
//  PostTableViewCell.swift
//  Streams
//
//  Created by Rael Kenny on 4/10/17.
//  Copyright © 2017 Rael Kenny. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class PostTableViewCell: PFTableViewCell {

    @IBOutlet var userImageView:UIImageView?
    @IBOutlet var userNameLabel:UILabel?
    @IBOutlet var postTextLabel:UILabel?
    @IBOutlet var postDateLabel:UILabel?
    @IBOutlet var postImageView:UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        userImageView?.image = nil
        postImageView?.image = nil
        userNameLabel?.text = ""
        postTextLabel?.text = ""
        postDateLabel?.text = ""
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
