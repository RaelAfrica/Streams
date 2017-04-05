//
//  NewPostViewController.swift
//  Streams
//
//  Created by Reinder de Vries on 03-05-15.
//  Copyright (c) 2015 LearnAppMaking. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import MBProgressHUD

class NewPostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    @IBOutlet var textView:UITextView?;
    @IBOutlet var imageView:UIImageView?;
    @IBOutlet var cameraButton:UIButton?;
    @IBOutlet var libraryButton:UIButton?;
    
    override func viewDidLoad()
    {
        super.viewDidLoad();

        // Add the right navigation item, with action
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: UIBarButtonItemStyle.done, target: self, action: #selector(onSendTapped(_:)));
        
        // Add the method onAddImageTapped: to both the buttons
        cameraButton?.addTarget(self, action: #selector(onAddImageTapped(_:)), for: UIControlEvents.touchUpInside);
        libraryButton?.addTarget(self, action: #selector(onAddImageTapped(_:)), for: UIControlEvents.touchUpInside);
        
        // Add the delegate, then make the textView focused, i.e. the cursor and keyboard will show up
        textView?.becomeFirstResponder();
    }
    
    func onSendTapped(_ sender:UIBarButtonItem)
    {
        if  let text:String = textView?.text,
            let currentUser:PFUser = PFUser.current()
        {
            if text.characters.count > 0
            {
                var post:PFObject = PFObject(className: "Post");
                post.setObject(text, forKey: "text");
                post.setObject(currentUser, forKey: "user");
                
                if  let image:UIImage       = imageView?.image,
                    let data:Data           = UIImagePNGRepresentation(image),
                    let imageFile:PFFile    = PFFile(data: data)
                {
                    post.setObject(imageFile, forKey: "image");
                }
                
                let hud:MBProgressHUD = MBProgressHUD.showAdded(to: self.view, animated: true);
                hud.mode = MBProgressHUDMode.indeterminate;
                hud.label.text = "Sending...";
                
                post.saveInBackground() {
                    (success, error) in
                    
                    hud.hide(animated: true);
                    self.navigationController?.popViewController(animated: true);
                }
                
                return;
            }
        }
        
        let alert:UIAlertController = UIAlertController(title: "Error", message: "Please enter a text for your post.", preferredStyle: UIAlertControllerStyle.alert);
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
        
        self.present(alert, animated: true, completion: nil);
    }
    
    func onAddImageTapped(_ sender:UIButton)
    {
        // Create a picker view and set its type (camera, or library) according
        // to the type the iPhone supports (Simulator has no camera) and what button was tapped
        
        var picker:UIImagePickerController = UIImagePickerController();
        picker.delegate = self;
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) && sender == cameraButton
        {
            picker.sourceType = UIImagePickerControllerSourceType.camera;
        }
        else if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) && sender == libraryButton
        {
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
        } else {
            return;
        }
        
        self.present(picker, animated: true, completion: nil);
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        // Remove the modal view
        picker.dismiss(animated: true, completion: nil);
        
        // Set the captured image to display in the image view
        imageView?.image = info[UIImagePickerControllerOriginalImage] as? UIImage;
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
