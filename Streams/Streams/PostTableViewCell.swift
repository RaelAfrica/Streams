//
//  PostTableViewCell.swift
//  Streams
//
//  Created by Reinder de Vries on 03-05-15.
//  Copyright (c) 2015 LearnAppMaking. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class PostTableViewCell: PFTableViewCell
{
    @IBOutlet var userImageView:UIImageView?;
    @IBOutlet var userNameLabel:UILabel?;
    @IBOutlet var postTextLabel:UILabel?;
    @IBOutlet var postDateLabel:UILabel?;
    @IBOutlet var postImageView:UIImageView?;
    
    override func awakeFromNib()
    {
        super.awakeFromNib();        
    }

    override func prepareForReuse()
    {
        // The method prepareForReuse is called every time a cell is reused, 
        // resetting the labels to their initial values. Otherwise you could
        // end up with the image from another cell!
        
        userImageView?.image = nil;
        postImageView?.image = nil;
        userNameLabel?.text = "";
        postTextLabel?.text = "";
        postDateLabel?.text = "";
    }
}
