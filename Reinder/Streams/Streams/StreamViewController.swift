//
//  StreamViewController.swift
//  Streams
//
//  Created by Reinder de Vries on 03-05-15.
//  Copyright (c) 2015 LearnAppMaking. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import DateTools
import MBProgressHUD
import Bolts

class StreamViewController: PFQueryTableViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, UISearchResultsUpdating, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    // Identifiers to denote the 3 different table view cells
    let postCellIdentifier:String = "PostCell";
    let postCell_NoImageIdentifier:String = "PostCell_NoImage";
    let userCellIdentifier:String = "UserCell";
    
    // Search controller
    var searchController:UISearchController?;
    var isSearching:Bool = false;
    
    // User property -- if it's empty, we'll use the current user
    var user:PFUser?;
    
    // Header view, shown up top when property user is set
    var userHeaderView:UserHeaderView?;
    
    override init(style: UITableViewStyle, className: String!)
    {
        super.init(style: style, className: className);
        
        _commonInit();
    }
    
    init(style: UITableViewStyle, className: String!, user: PFUser)
    {
        super.init(style: style, className: className);
        
        self.user = user;
        
        _commonInit();
    }
    
    func _commonInit()
    {
        print(#function);
        
        // The _commonInit is used to share the same code
        // between the two initializers of this class.
        
        self.pullToRefreshEnabled = true;
        self.paginationEnabled = false;
        self.objectsPerPage = 25;
        
        self.parseClassName = "Post";
        self.tableView.allowsSelection = false;
        
        // UITableViewAutomaticDimension is a magic constant that
        // denotes no table view cell has a fixed value
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 400.0;
    }
    
    required init(coder aDecoder:NSCoder)
    {
        fatalError("NSCoding not supported")
    }
    
    /**
    
    viewDidLoad() is called when the XIB is loaded
     
    */
    
    override func viewDidLoad()
    {
        super.viewDidLoad();
        
        // Register the 3 cells, for 2 just the XIB and for the user cell the ordinary UITableViewCell
        tableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: postCellIdentifier);
        tableView.register(UINib(nibName: "PostTableViewCell_NoImage", bundle: nil), forCellReuseIdentifier: postCell_NoImageIdentifier);
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: userCellIdentifier);
    }
    
    /**
    
    viewWillAppear() is called before the view appears
    
    */
    
    override func viewWillAppear(_ animated: Bool)
    {
        if let user = self.user
        {
            // If a user is set, prepare the table header view
            
            self.title = user.username;
            
            userHeaderView = UserHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 135));
            userHeaderView?.userNameLabel?.text = user.username;
            
            if let file:PFFile = user["avatar"] as? PFFile
            {
                file.getDataInBackground() {
                    (data, error) in
                    
                    if data != nil
                    {
                        self.userHeaderView?.imageView?.image = UIImage(data: data!);
                    }
                }
            }
            
            if user == PFUser.current()
            {
                userHeaderView!.followButton?.isHidden = true;
                
                var tapRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onUserAvatarTapped(_:)));
                userHeaderView?.imageView?.addGestureRecognizer(tapRecognizer);
            }
            else
            {
                userHeaderView?.followButton?.addTarget(self, action: #selector(onFollowButtonTapped(_:)), for: UIControlEvents.touchUpInside);
            }
            
            DispatchQueue.global(qos: .background).async {

                if let currentUser = PFUser.current()
                {
                    var error:NSError?;
                    
                    var postCount:Int = PFQuery(className: "Post").whereKey("user", equalTo: user).countObjects(&error);
                    var followerCount:Int = PFQuery(className: "User_Follow").whereKey("user", equalTo: user).countObjects(&error);
                    var isFollowing:Bool = PFQuery(className: "User_Follow").whereKey("user", equalTo: user).whereKey("follower", equalTo: PFUser.current()!).countObjects(&error) > 0;
                    
                    if error != nil
                    {
                        print("Error: \(error)");
                    }
                    
                    DispatchQueue.main.async {
                        
                        self.userHeaderView?.numberPostsLabel?.text = "Posts: \(postCount)";
                        self.userHeaderView?.numberFollowersLabel?.text = "Followers: \(followerCount)";
                        
                        self.userHeaderView?.followButton?.setTitle(isFollowing ? "Unfollow" : "Follow", for: UIControlState.normal);
                    }
                }
                
            }
            
            tableView.tableHeaderView = userHeaderView;
        }
        else
        {
            // If a user isn't set, show the search bar in the table header view
            // And, since the stream view now shows the current users timeline, add a user and new post icon
            
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "UserIcon"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(onUserButtonTapped(_:)));
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "NewPostIcon"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(onNewPostButtonTapped(_:)));
            
            searchController = UISearchController(searchResultsController: nil);
            searchController?.searchResultsUpdater = self;
            searchController?.dimsBackgroundDuringPresentation = false;
            
            tableView.tableHeaderView = searchController?.searchBar;
            searchController?.searchBar.sizeToFit(); // Bug
        }
    }
    
    /**
    
    viewDidAppear() is called when the view has appeared on screen
    
    */
    
    override func viewDidAppear(_ animated: Bool)
    {
        // When the stream view appears and no user has logged in,
        // prepare the Parse login and signup controllers to display
        
        if PFUser.current() == nil
        {
            let loginVC:PFLogInViewController = PFLogInViewController();
            loginVC.fields = [PFLogInFields.usernameAndPassword, PFLogInFields.logInButton, PFLogInFields.signUpButton];
            loginVC.view.backgroundColor = UIColor.white;
            
            loginVC.delegate = self;
            
            let signupVC:PFSignUpViewController = PFSignUpViewController();
            signupVC.view.backgroundColor = UIColor.white;
            
            signupVC.delegate = self;
            
            loginVC.signUpController = signupVC;
            
            self.present(loginVC, animated: true, completion: nil);
        }
        
        self.loadObjects();
    }
    
    /**
    
    loginViewController:shouldBeginLogInWithUsername:
    is called when the Parse login controller should or should not continue to log in
    
    */
    
    func log(_ logInController: PFLogInViewController, shouldBeginLogInWithUsername username: String, password: String) -> Bool
    {
        if username.characters.count > 0 && password.characters.count > 0
        {
            return true;
        }
        
        let alert:UIAlertController = UIAlertController(title: "Error", message: "Please fill all fields.", preferredStyle: UIAlertControllerStyle.alert);
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
        
        logInController.present(alert, animated: true, completion: nil);
        
        return false;
    }
    
    /**
    
    loginViewController:didFailToLogInWithError:
    is called when logging in has failed
    
    */
    
    func log(_ logInController: PFLogInViewController, didFailToLogInWithError error: Error?)
    {
        let alert:UIAlertController = UIAlertController(title: "Error", message: "Something went wrong. Please try again.", preferredStyle: UIAlertControllerStyle.alert);
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
        
        logInController.present(alert, animated: true, completion: nil);
    }
    
    /**
    
    loginViewController:didLogInUser:
    is called when logging in has succeeded
    
    */
    
    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser)
    {
        self.loadObjects();
        
        self.dismiss(animated: true, completion: nil);
    }
    
    /**
    
    signUpViewController:shouldBeginSignUp
    is called when Parse sign up should or should not continue
    
    */
    
    func signUpViewController(_ signUpController: PFSignUpViewController, shouldBeginSignUp info: [String : String]) -> Bool
    {
        var success = false;
        
        for (key, value) in info
        {
            if value.characters.count > 0
            {
                success = true;
                continue;
            }

            success = false;
            break;
        }
        
        if success == false
        {
            let alert:UIAlertController = UIAlertController(title: "Error", message: "Please fill all fields.", preferredStyle: UIAlertControllerStyle.alert);
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
            
            signUpController.present(alert, animated: true, completion: nil);
        }
        
        return success;
    }
    
    /**
    
    signUpViewController:didFailToSignUpWithError:
    is called when Parse sign up has failed
    
    */
    
    func signUpViewController(_ signUpController: PFSignUpViewController, didFailToSignUpWithError error: Error?)
    {
        let alert:UIAlertController = UIAlertController(title: "Error", message: "Something went wrong. Please try again.", preferredStyle: UIAlertControllerStyle.alert);
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
        
        signUpController.present(alert, animated: true, completion: nil);
    }
    
    /**
    
    signUpViewController:didSignUpUser:
    is called when signing up has succeeded
    
    */
    
    func signUpViewController(_ signUpController: PFSignUpViewController, didSignUp user: PFUser)
    {
        var user_follow:PFObject = PFObject(className: "User_Follow");
        user_follow["user"] = user;
        user_follow["follower"] = user;
                
        user_follow.saveInBackground() {
            (success, error) in
            
            self.dismiss(animated: true, completion: nil);
        }
        
        self.loadObjects();
    }
    
    /**
    
    onFollowButtonTapped:
    is called when, inside the table header view, the follow button has been tapped
    it can denote both a follow and unfollow action
    
    */
    
    func onFollowButtonTapped(_ sender:UIButton)
    {
        if  let user = self.user,
            let currentUser = PFUser.current()
        {
            DispatchQueue.global(qos: .background).async {
                
                var error:NSError?;
                
                var query:PFQuery = PFQuery(className: "User_Follow").whereKey("user", equalTo: user).whereKey("follower", equalTo: currentUser);
                var followerCount:Int = PFQuery(className: "User_Follow").whereKey("user", equalTo: user).countObjects(&error);
                var isFollowing:Bool = query.countObjects(&error) > 0;
                
                if error != nil
                {
                    print("Error: \(error)");
                }
                
                if isFollowing == true
                {
                    do {
                        
                        let user_follow:PFObject = try query.getFirstObject()
                        
                        try user_follow.delete();
                        
                        followerCount -= 1;
                        isFollowing = false;
                    }
                    catch(let e)
                    {
                        print("Exception: \(e)");
                    }
                }
                else
                {
                    do {
                        var user_follow:PFObject = PFObject(className: "User_Follow");
                        user_follow["user"] = user;
                        user_follow["follower"] = currentUser;
                        
                        try user_follow.save();
                        
                        followerCount += 1;
                        isFollowing = true;
                    }
                    catch(let e)
                    {
                        print("Exception: \(e)");
                    }
                }
                
                DispatchQueue.main.async {
                    self.userHeaderView?.numberFollowersLabel?.text = "Followers: \(followerCount)";
                    
                    self.userHeaderView?.followButton?.setTitle(isFollowing ? "Unfollow" : "Follow", for: UIControlState.normal);
                }
            }
        }
    }
    
    /**
    
    onUserButtonTapped:
    is called when the user taps the "current user button" left on the navigation bar
    it brings him or her to their own profile view
    
    */
    
    func onUserButtonTapped(_ sender:UIBarButtonItem)
    {
        if let currentUser = PFUser.current()
        {
            var streamVC:StreamViewController = StreamViewController(style: UITableViewStyle.plain, className: "Post", user: currentUser);
            self.navigationController?.pushViewController(streamVC, animated: true);
        }
    }
    
    /**
    
    onNewPostButtonTapped:
    puts a new post view controller on screen
    
    */
    
    func onNewPostButtonTapped(_ sender:UIBarButtonItem)
    {
        let newPostVC:NewPostViewController = NewPostViewController(nibName: "NewPostViewController", bundle: nil);
        
        self.navigationController?.pushViewController(newPostVC, animated: true);
    }
    
    /**
    
    onUserAvatarTapped:
    is called when the current user taps on his or hers own avatar image view
    in their profile view, changing the image
    
    */
    
    func onUserAvatarTapped(_ sender:UITapGestureRecognizer)
    {
        let alertController = UIAlertController(title: nil, message: "Do you want to change your user profile avatar?", preferredStyle: UIAlertControllerStyle.actionSheet);
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (action) in
            // Do nothing ...
        }
        
        alertController.addAction(cancelAction);
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)
        {
            let libraryAction = UIAlertAction(title: "Add From Photo Library", style: UIAlertActionStyle.default) {
                (action) in
                
                let picker:UIImagePickerController = UIImagePickerController();
                picker.delegate = self;
                picker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
                
                self.present(picker, animated: true, completion: nil);
            }
            
            alertController.addAction(libraryAction);
        }
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
        {
            let cameraAction = UIAlertAction(title: "Take Photo With Camera", style: UIAlertActionStyle.default) {
                (action) in
                
                let picker:UIImagePickerController = UIImagePickerController();
                picker.delegate = self;
                picker.sourceType = UIImagePickerControllerSourceType.camera;
                
                self.present(picker, animated: true, completion: nil);
            }
            
            alertController.addAction(cameraAction);
        }
        
        self.present(alertController, animated: true, completion: nil);
    }
    
    /**
    
    imagePickerController:didFinishPickingMediaWithInfo:
    called when finished picking an image, either from the camera or the library, after tapping
    the image view on the users own profile page

    */
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        if  let currentUser:PFUser      = PFUser.current(),
            let image:UIImage           = info[UIImagePickerControllerOriginalImage] as? UIImage,
            let data:Data               = UIImagePNGRepresentation(image),
            let imageFile:PFFile        = PFFile(data: data)
        {
            currentUser.setObject(imageFile, forKey: "avatar");
            
            picker.dismiss(animated: true, completion: nil);
            
            let hud:MBProgressHUD = MBProgressHUD.showAdded(to: self.view, animated: true);
            hud.mode = MBProgressHUDMode.indeterminate;
            
            currentUser.saveInBackground() {
                (success, error) in
                
                hud.hide(animated: true);
                
                self.userHeaderView?.imageView?.image = image;
            }
        }
    }
    
    /**
    
    updateSearchResultsForSearchController:
    is called when something in the search text field happens, i.e. a cancel or input of text
    
    */
    
    func updateSearchResults(for searchController: UISearchController)
    {
        self.isSearching = searchController.searchBar.text?.characters.count ?? 0 > 0;
        self.tableView.allowsSelection = isSearching;
        
        self.loadObjects();
    }
    
    /**
    
    queryForTable:
    is called when the table view needs a query, to get data
    this method doesn't download the data, it only configures the query
    
    it either:
    
    1. sets up a query for users according to search text (search bar)
    2. shows the posts for 1 particular user
    3. shows a timeline of the current user, i.e. all posts from all users the current user follows
    
    */
    
    override func queryForTable() -> PFQuery<PFObject>
    {
        if isSearching == true
        {
            var query:PFQuery = PFQuery(className: "_User");
            query.order(byAscending: "username");
            
            if let text:String = searchController?.searchBar.text
            {
                query.whereKey("username", matchesRegex: text, modifiers: "i");
            }
            
            if objects != nil && objects!.count == 0
            {
                query.cachePolicy = PFCachePolicy.cacheThenNetwork;
            }
            
            return query;
        }
        
        var query:PFQuery = PFQuery(className:"Post");
        query.includeKey("user");
        query.order(byDescending: "createdAt");
        
        if let user = self.user
        {
            query.whereKey("user", equalTo: user);
        }
        else
        {
            if let currentUser = PFUser.current()
            {
                var followerQuery:PFQuery = PFQuery(className: "User_Follow");
                followerQuery.whereKey("follower", equalTo: currentUser);
                
                query.whereKey("user", matchesKey: "user", in: followerQuery);
            }
        }
        
        if objects != nil && objects!.count == 0
        {
            query.cachePolicy = PFCachePolicy.cacheThenNetwork;
        }
        
        return query;
    }
    
    
    /**
    
    tableView:cellForRowAtIndexPath:
    
    returns cells for the table view
    
    */
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, object: PFObject?) -> PFTableViewCell?
    {
        // If the search bar is showing and more than zero text characters have been entered, isSearch = true
        // When it is true, the table view will only show plain text cells with all the users that conform to the search text
        
        if isSearching == true
        {
            var cell:PFTableViewCell? = tableView.dequeueReusableCell(withIdentifier: userCellIdentifier, for: indexPath) as? PFTableViewCell;
            
            if cell == nil {
                cell = PFTableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: userCellIdentifier);
            }
            
            cell?.textLabel?.text = object?["username"] as? String;
            
            return cell; // -> return exits the current method, not executing everything below
        }
        
        var cell:PostTableViewCell?;
        var identifier:String = postCellIdentifier;
        var nibName:String = "PostTableViewCell";
        
        if object?["image"] == nil
        {
            // When there is no image set for this Post object,
            // quickly switch the type of this cell to "no image cell"
            
            identifier = postCell_NoImageIdentifier;
            nibName = "PostTableViewCell_NoImage";
        }
        
        cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? PostTableViewCell;
        
        if cell == nil
        {
            cell = Bundle.main.loadNibNamed(nibName, owner: self, options: nil)?[0] as? PostTableViewCell;
        }
        
        if let user:PFUser = object?["user"] as? PFUser
        {
            cell!.userNameLabel?.text = user["username"] as? String;
            
            if  let file:PFFile = user["avatar"] as? PFFile
            {
                file.getDataInBackground() {
                    (data, error) in
                    
                    if data != nil
                    {
                        cell!.userImageView?.image = UIImage(data: data!);
                    }
                }
            }
        }
                
        cell!.postTextLabel?.text = object?["text"] as? String;
        
        if let createdAt = object?.createdAt
        {
            cell!.postDateLabel?.text = createdAt.shortTimeAgoSinceNow;
        }
        
        if let file:PFFile = object?["image"] as? PFFile
        {
            file.getDataInBackground() {
                (data, error) in
                
                if data != nil
                {
                    cell!.postImageView?.image = UIImage(data: data!);
                }
            }
        }
        
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if isSearching == false
        {
            // When a user taps on a Post cell, do nothing
            
            return;
        }
        
        searchController?.isActive = false;
        
        if let user = self.object(at: indexPath) as? PFUser
        {
            var streamVC:StreamViewController = StreamViewController(style: UITableViewStyle.plain, className: "Post", user: user);
            
            self.navigationController?.pushViewController(streamVC, animated: true);
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }

}
