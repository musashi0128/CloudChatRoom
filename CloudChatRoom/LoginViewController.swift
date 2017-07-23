//
//  LoginViewController.swift
//  CloudChatRoom
//
//  Created by 宮本一彦 on 2017/07/23.
//  Copyright © 2017年 宮本一彦. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import CoreLocation

class LoginViewController: UIViewController,GIDSignInDelegate,GIDSignInUIDelegate,CLLocationManagerDelegate {
    
    var profileImage:URL!
    
    var locationManager:CLLocationManager!
    
    var uid = FIRAuth.auth()?.currentUser?.uid

    override func viewDidLoad() {
        super.viewDidLoad()

        //　位置情報取得の呼び出し
        catchLocationData()
        
        let googleButton = GIDSignInButton()
        googleButton.frame = CGRect(x: 20, y: 250, width: self.view.frame.size.width-40, height: 60)
        view.addSubview(googleButton)
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        let selectVC = segue.destination as! SelectViewController
        selectVC.uid = uid
        selectVC.profileImage = self.profileImage! as NSURL
        
    }
    
    
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if let err = error {
            print("エラーです。",err)
            return
        }
        
        print("成功しました！")
        UserDefaults.standard.set(0, forKey: "login")
        
        guard let idToken = user.authentication.idToken else {
            return
        }
        
        guard let accessToken = user.authentication.accessToken else{
            return
        }
        
        let credential = FIRGoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        
        FIRAuth.auth()?.signIn(with: credential, completion: { (user,error) in
            
            if let err = error{
                print("エラー",err)
                return
            }
            
            // Image画像を格納
            let imageUrl = signIn.currentUser.profile.imageURL(withDimension: 100)
            self.profileImage = imageUrl
            
            // Firebaseに情報を飛ばす
            self.postMyProfile()
            self.performSegue(withIdentifier: "next", sender: nil)
            
        })
    }
    
    func postMyProfile(){
        
        AppDelegate.instance().showIndicator()
        
        uid = FIRAuth.auth()?.currentUser?.uid
        let ref = FIRDatabase.database().reference()
        let storage = FIRStorage.storage().reference(forURL: "gs://cloudchatroom-33a28.appspot.com/")
        let key = ref.child("Users").childByAutoId().key
        let imageRef = storage.child("Users").child(uid!).child("\(key).jpg")
        
        let imageData:NSData = try! NSData(contentsOf: self.profileImage)
        let uploadTask = imageRef.put(imageData as Data, metadata: nil) { (metaData, error) in
            if error != nil {
                
                AppDelegate.instance().dismissActivityIndicator()
                return
            }
            
            imageRef.downloadURL(completion: { (url, error) in
                if url != nil {
                    let feed = ["userID":self.uid,"pathToImage":self.profileImage.absoluteString,"postID":key] as [String:Any]
                    let postFeed = ["\(key)":feed]
                    
                    ref.child("Users").updateChildValues(postFeed)
                    AppDelegate.instance().dismissActivityIndicator()
                    
                }
                
            })
            
        }
        
        uploadTask.resume()
        
    }
    
    // 位置情報を取得するメソッド
    func catchLocationData(){
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
