//
//  NewPostViewController.swift
//  Streams
//
//  Created by Rael Kenny on 4/11/17.
//  Copyright © 2017 Rael Kenny. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import MBProgressHUD

class NewPostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet var textView:UITextView?
    @IBOutlet var imageView:UIImageView?
    @IBOutlet var cameraButton:UIButton?
    @IBOutlet var libraryButton:UIButton?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: UIBarButtonItemStyle.done, target: self, action: #selector(onSendTapped(_:)))
        
        cameraButton?.addTarget(self, action: #selector(onAddImageTapped(_:)), for: UIControlEvents.touchUpInside)
        libraryButton?.addTarget(self, action: #selector(onAddImageTapped(_:)), for: UIControlEvents.touchUpInside)
        
        textView?.becomeFirstResponder()
        
    }
    
    func onAddImageTapped(_ sender:UIButton)
    {
        var picker:UIImagePickerController = UIImagePickerController()
        picker.delegate = self
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) && sender == cameraButton
        {
            picker.sourceType = UIImagePickerControllerSourceType.camera
        
        }
        
        else if
            UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) && sender == libraryButton
        {
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            
        } else {
            
            return
        }
        
        self.present(picker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        imageView?.image = info[UIImagePickerControllerOriginalImage] as? UIImage
    }
    
    func onSendTapped(_ sender:UIBarButtonItem)
    {
        if  let text:String = textView?.text,
            let currentUser:PFUser = PFUser.current()
        {
            if text.characters.count > 0
        {
            var post:PFObject = PFObject(className: "Post")
            post.setObject(text, forKey: "text")
            post.setObject(currentUser, forKey: "user")
    
            if  let image:UIImage       = imageView?.image,
                let data:Data           = UIImagePNGRepresentation(image),
                let imageFile:PFFile    = PFFile(data: data)
            {
                post.setObject(imageFile, forKey: "image")
            }
    
        let hud:MBProgressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = MBProgressHUDMode.indeterminate
        hud.label.text = "Sending..."
        
        post.saveInBackground() {
        (success, error) in
    
            hud.hide(animated: true)
            self.navigationController?.popViewController(animated: true)
            }
    
            return
        }
    }
    
    let alert:UIAlertController = UIAlertController(title: "Error", message: "Please enter a text for your post.", preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    
        self.present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    

}
