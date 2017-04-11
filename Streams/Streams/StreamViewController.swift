//
//  StreamViewController.swift
//  Streams
//
//  Created by Rael Kenny on 4/5/17.
//  Copyright © 2017 Rael Kenny. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import Bolts
import DateTools


class StreamViewController: PFQueryTableViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, UISearchResultsUpdating {

    let postCellIdentifier:String = "PostCell"
    let postCell_NoImageIdentifier:String = "PostCell_NoImage"
    let userCellIdentifier:String = "UserCell"

    var user:PFUser?

    var searchController = UISearchResultsUpdating?
    var isSearching:Bool = false
    
    override init(style: UITableViewStyle, className: String!)
    {
        super.init(style: style, className: className)
        
        _commonInit()
    }
    
    init(style: UITableViewStyle, className: String!, user: PFUser) {
        super.init(style: style, className: className)
        
        self.user = user
        
        _commonInit()
    }
    
    func _commonInit() {
        self.pullToRefreshEnabled = true
        self.paginationEnabled = false
        self.objectsPerPage = 25
        
        self.parseClassName = "Post"
        self.tableView.allowsSelection = false
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 400.0
    }
    
    required init(coder aDecoder:NSCoder)
    {
        fatalError("NSCoding not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: postCellIdentifier)
        tableView.register(UINib(nibName: "PostTableViewCell_NoImage", bundle: nil), forCellReuseIdentifier: postCell_NoImageIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: userCellIdentifier)

    }

    override func viewWillAppear(_ animated: Bool)
    {
        if let user = self.user
        {
            // ...
        }
        else
        {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "NewPostIcon"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(onNewPostButtonTapped(_:)))
            
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "UserIcon"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(onUserButtonTapped(_:)))
            
            searchController = UISearchController(searchResultsController: nil)
            searchController?.searchResultsUpdater = self
            searchController?.dimsBackgroundDuringPresentation = false
            
            tableView.tableHeaderView = searchController?.searchBar
            searchController?.searchBar.sizeToFit() // Bug
        }
    }

    func updateSearchResults(for searchController: UISearchController) {
        
        self.isSearching = searchController.searchBar.text?.characters.count ?? 0 > 0
        self.tableView.allowsSelection = isSearching
        
        self.loadObjects()
    }
    
    
    func onNewPostButtonTapped(sender:UIBarButtonItem)
    {
        let newPostVC:NewPostViewController = NewPostViewController(nibName: "NewPostViewController", bundle: nil)
        
        self.navigationController?.pushViewController(newPostVC, animated: true)
    }
    
    func onUserButtonTapped(_ sender:UIBarButtonItem)
    {
        if let currentUser = PFUser.current()
        {
            var streamVC:StreamViewController = StreamViewController(style: UITableViewStyle.plain, className: "Post", user: currentUser)
            self.navigationController?.pushViewController(streamVC, animated: true)
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        if PFUser.current() == nil
        {
            let loginVC:PFLogInViewController = PFLogInViewController()
            loginVC.fields = [PFLogInFields.usernameAndPassword, PFLogInFields.logInButton, PFLogInFields.signUpButton]
            loginVC.view.backgroundColor = UIColor.white
            
            loginVC.delegate = self
            
            let signupVC:PFSignUpViewController = PFSignUpViewController()
            signupVC.view.backgroundColor = UIColor.white
            
            signupVC.delegate = self
            
            loginVC.signUpController = signupVC
            
            self.present(loginVC, animated: true, completion: nil)
        }
        
        self.loadObjects()
    }

    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Log in with Parse
    
    func log(_ logInController: PFLogInViewController, shouldBeginLogInWithUsername username: String, password: String) -> Bool {
        if username.characters.count > 0 && password.characters.count > 0
        {
            return true
        }
        
        let alert:UIAlertController = UIAlertController(title: "ERROR", message: "Please fill all fields", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style:  UIAlertActionStyle.default, handler: nil))
        
        logInController.present(alert, animated: true, completion: nil)
        
        return false
    }
    
    func log(_ logInController: PFLogInViewController, didFailToLogInWithError error: Error?) {
        
        let alert:UIAlertController = UIAlertController(title: "ERROR", message: "Something went wrong, please try again.`", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        logInController.present(alert, animated: true, completion: nil)
    }
    
    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser) {
        
        self.loadObjects()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Sign up with Parse
    
    func signUpViewController(_ signUpController: PFSignUpViewController, shouldBeginSignUp info: [String : String]) -> Bool {
        
        var success = false
        
        for (key, value) in info
        {
            if value.characters.count > 0
            {
                success = true
                continue
            }
            
            success = false
            break
        }
        
        if success == false
        {
            let alert:UIAlertController = UIAlertController(title: "Error", message: "Please fill all the fields.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            signUpController.present(alert, animated: true, completion: nil)
        }
        
        return success
    }
    
    
    func signUpViewController(_ signUpController: PFSignUpViewController, didFailToSignUpWithError error: Error?) {
        
        let alert:UIAlertController = UIAlertController(title: "Error", message: "Something went wrong. Please try again.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        signUpController.present(alert, animated: true, completion: nil)
    }
    
    func signUpViewController(_ signUpController: PFSignUpViewController, didSignUp user: PFUser) {
        var user_follow:PFObject = PFObject(className: "User_Follow")
        user_follow["user"] = user
        user_follow["follower"] = user
        
        user_follow.saveInBackground() {
            (success, error) in
            
            self.dismiss(animated: true, completion: nil)
        }
        
        self.loadObjects()
    }
    
    
    //MARK: - Parse query
    
    override func queryForTable() -> PFQuery<PFObject> {
        
        if isSearching == true
        {
            var query:PFQuery = PFQuery(className:"_User")
            query.order(byAscending: "username")
            
            if let text:string = searchController?.searchBar.text
            {
                query.whereKey("username", matchRegex: text, modifiers: "i")
            }
            
            if objects != nil && objects!.count == 0
            {
                query.cachePolicy = PFCachePolicy.cacheThenNetwork
            }
            
            return query
        }
        
        var query:PFQuery = PFQuery(className: "Post")
        query.includeKey("user")
        query.order(byDescending: "createdAt")
        
        if objects != nil && objects!.count == 0
        {
            query.cachePolicy = PFCachePolicy.cacheThenNetwork
        }
        
        return query
    }
    
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, object: PFObject?) -> PFTableViewCell?
    {
        
        if isSearching == true
        {
            var cell:PFTableViewCell? = tableView.dequeueReusableCell(withIdentifier: userCellIdentifier, for: indexPath) as? PFTableViewCell
            
            if cell == nil {
                cell = PFTableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: userCellIdentifier)
            }
            
            cell?.textLabel?.text = object?["username"] as? String
            
            return cell
        }
        
        var cell:PostTableViewCell?
        var identifier:String = postCellIdentifier
        var nibName:String = "PostTableViewCell"
        
        if object?["image"] == nil
        {
            identifier = postCell_NoImageIdentifier
            nibName = "PostTableViewCell_NoImage"
        }
        
        cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? PostTableViewCell
        
        if cell == nil
        {
            cell = Bundle.main.loadNibNamed(nibName, owner: self, options: nil)?[0] as? PostTableViewCell
        }
        
        if let user:PFUser = object?["user"] as? PFUser
        {
            cell!.userNameLabel?.text = user["username"] as? String
            
            if  let file:PFFile = user["avatar"] as? PFFile
            {
                file.getDataInBackground() {
                    (data, error) in
                    
                    if data != nil
                    {
                        cell!.userImageView?.image = UIImage(data: data!)
                    }
                }
            }
        }
        
        cell!.postTextLabel?.text = object?["text"] as? String
        
        if let createdAt = object?.createdAt
        {
            cell!.postDateLabel?.text = createdAt.shortTimeAgoSinceNow
        }
        
        if let file:PFFile = object?["image"] as? PFFile
        {
            file.getDataInBackground() {
                (data, error) in
                
                if data != nil
                {
                    cell!.postImageView?.image = UIImage(data: data!)
                }
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if(isSearching == false)
        {
            return
        }
        
        searchController?.isActive = false
        
        if let user = self.object(at: indexPath) as? PFUser
        {
            var streamVC:StreamViewController = StreamViewController(style: UITableViewStyle.plain, className: "Post", user: user)
            
            self.navigationController?.pushViewController(streamVC, animated: true)
        }
    }
    
    
}
