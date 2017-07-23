//
//  CreateRoomViewController.swift
//  CloudChatRoom
//
//  Created by 宮本一彦 on 2017/07/23.
//  Copyright © 2017年 宮本一彦. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

class CreateRoomViewController: UIViewController,CLLocationManagerDelegate {
    
    var posts = [Post]()
    
    var uid = FIRAuth.auth()?.currentUser?.uid
    
    var profileImage:NSURL!
    
    var locationManager: CLLocationManager!
    
    @IBOutlet var idoLabel: UILabel!
    @IBOutlet var keidoLabel: UILabel!
    
    
    var country:String = String()
    var administrativeArea:String = String()
    var subAdministrativeArea:String = String()
    var locality:String = String()
    var subLocality:String = String()
    var thoroughfare:String = String()
    var subThoroughfare:String = String()
    
    var address:String = String()
    
    var data:Data = Data()
    
    var imageString:String!
    
    @IBOutlet var inputRoomNameTextField: UITextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        catchLocationData()
        
    }
    
    /*******************************************
     
     //位置情報取得に関するアラートメソッド
     
     ********************************************/
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways, .authorizedWhenInUse:
            break
        }
    }
    
    /**********************************
     
     // 位置情報が更新されるたびに呼ばれるメソッド
     
     ***********************************/
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else {
            return
        }
        
        self.idoLabel.text = "".appendingFormat("%.4f", newLocation.coordinate.latitude)
        self.keidoLabel.text = "".appendingFormat("%.4f", newLocation.coordinate.longitude)
        self.reverseGeocode(latitude: Double(idoLabel.text!)!, longitude: Double(keidoLabel.text!)!)
        
    }
    // 逆ジオコーディング処理(緯度・経度を住所に変換)
    func reverseGeocode(latitude:CLLocationDegrees, longitude:CLLocationDegrees) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        // 住所を断片的に取得して行く(国,都道府県,区市町村......)
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemark, error) -> Void in
            let placeMark = placemark?.first
            if let country = placeMark?.country {
                
                
                //print("\(country)")
                
                self.country = country
            }
            if let administrativeArea = placeMark?.administrativeArea {
                //print("\(administrativeArea)")
                
                self.administrativeArea = administrativeArea
            }
            if let subAdministrativeArea = placeMark?.subAdministrativeArea {
                //print("\(subAdministrativeArea)")
                
                self.subAdministrativeArea = subAdministrativeArea
                
            }
            if let locality = placeMark?.locality {
                //print("\(locality)")
                
                self.locality = locality
            }
            if let subLocality = placeMark?.subLocality {
                //print("\(subLocality)")
                
                self.subLocality = subLocality
            }
            if let thoroughfare = placeMark?.thoroughfare {
                //print("\(thoroughfare)")
                
                self.thoroughfare = thoroughfare
            }
            if let subThoroughfare = placeMark?.subThoroughfare {
                //print("\(subThoroughfare)")
                
                self.subThoroughfare = subThoroughfare
            }
            
            // 全てを合わせて表示する
            self.address = self.country + self.administrativeArea + self.subAdministrativeArea
                + self.locality + self.subLocality
            
        })
    }
    
    // オーナー名、緯度経度、住所情報をFirebaseへデータとして入れる
    func postRoom(){
        
        AppDelegate.instance().showIndicator()
        reverseGeocode(latitude: Double(idoLabel.text!)!, longitude: Double(keidoLabel.text!)!)
        
        let ref = FIRDatabase.database().reference()
        let storage = FIRStorage.storage().reference(forURL: "gs://cloudchatroom-33a28.appspot.com/")
        let key = ref.child("Rooms").childByAutoId().key
        let imageRef = storage.child("Rooms").child(uid!).child("\(key).png")
        
        self.data = UIImageJPEGRepresentation(UIImage(named: "ownerImage.png")!, 0.6)!
        
        let uploadTask = imageRef.put(self.data, metadata: nil) { (metaData, error) in
            
            if error != nil {
                
                AppDelegate.instance().dismissActivityIndicator()
                return
            }
            
            //URLはストレージのURL
            imageRef.downloadURL(completion: { (url, error) in
                if let url = url {
                    
                    let feed = ["userID":self.uid,"pathToImage":self.profileImage.absoluteString,"ido":self.idoLabel.text,"keido":self.keidoLabel.text,"roomName":self.inputRoomNameTextField.text,"postID":key,"country":self.country,"administrativeArea":self.administrativeArea,"subAdministrativeArea":self.subAdministrativeArea,"locality":self.locality,"subLocality":self.subLocality,"thoroughfare":self.thoroughfare,"subThoroughfare":self.subThoroughfare] as [String:Any]
                    
                    
                    let postFeed = ["\(key)":feed]
                    self.imageString = self.profileImage.absoluteString
                    ref.child("Rooms").updateChildValues(postFeed)
                    AppDelegate.instance().dismissActivityIndicator()
                    self.performSegue(withIdentifier: "room", sender: nil)
                    
                }
                
            })
            
        }
        
        uploadTask.resume()
        
    }
    
    // ChatViewControllerに値を渡す
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let chatVC = segue.destination as! ChatViewController
        
        // 全ての住所を足し算する
        chatVC.roomName = inputRoomNameTextField.text!
        chatVC.address =  self.address
        chatVC.pathToImage = self.profileImage.absoluteString!
        
    }
    
    
    func catchLocationData(){
        
        if CLLocationManager.locationServicesEnabled() {
            
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
            
        }
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        inputRoomNameTextField.resignFirstResponder()
        
    }
    
    
    @IBAction func toTheChatRoom(_ sender: Any) {
        
        postRoom()
    }
    
    
    @IBAction func back(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
