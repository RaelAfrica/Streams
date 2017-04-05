//
//  UserHeaderView.swift
//  Streams
//
//  Created by Reinder de Vries on 04-05-15.
//  Copyright (c) 2015 LearnAppMaking. All rights reserved.
//

import UIKit

class UserHeaderView: UIView
{
    var imageView:UIImageView?;
    var userNameLabel:UILabel?;
    var numberPostsLabel:UILabel?;
    var numberFollowersLabel:UILabel?;
    var followButton:UIButton?;
    
    override init(frame: CGRect)
    {
        super.init(frame: frame);
        
        setupNib();
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder);
        
        setupNib();
    }
        
    func setupNib()
    {
        // Load the XIB from the file and add it as a subview to self
        let headerView:UIView = Bundle.main.loadNibNamed("UserHeaderView", owner: self, options: nil)?[0] as! UIView;
        
        // Instead of outlets, this connects the subviews to properties by their tag number
        imageView = headerView.viewWithTag(1) as? UIImageView;
        userNameLabel = headerView.viewWithTag(2) as? UILabel;
        numberPostsLabel = headerView.viewWithTag(3) as? UILabel;
        numberFollowersLabel = headerView.viewWithTag(4) as? UILabel;
        followButton = headerView.viewWithTag(5) as? UIButton;
        
        self.addSubview(headerView);
    }
}
