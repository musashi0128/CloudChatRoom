//
//  SelectViewController.swift
//  CloudChatRoom
//
//  Created by 宮本一彦 on 2017/07/23.
//  Copyright © 2017年 宮本一彦. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

class SelectViewController: UIViewController,CLLocationManagerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        catchLocationData()
        
    }

    
    func catchLocationData(){
        
        if CLLocationManager.locationServicesEnabled() {
            
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
            
        }
        
        
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
    
    // CreateRoomViewControllerに値を渡す
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "createroom"{
            
            let createRoomVC = segue.destination as! CreateRoomViewController
            createRoomVC.uid = uid
            createRoomVC.profileImage = profileImage
            
            
        }else if segue.identifier == "roomsList"{
            
            let roomsVC = segue.destination as! RoomsViewController
            roomsVC.uid = uid
            roomsVC.profileImage = profileImage
            address = self.country + self.administrativeArea + self.subAdministrativeArea
                + self.locality + self.subLocality
            
            roomsVC.address = address
            
        }
        
        
    }
    
    // ルーム作成
    @IBAction func goCreateRoomView(_ sender: Any) {
        
        // 現在地を取得している途中であれば止める
        if CLLocationManager.locationServicesEnabled(){
            
            locationManager.stopUpdatingLocation()
            
        }
        // 画面遷移
        self.performSegue(withIdentifier: "createroom", sender: nil)
    }
    
    // ルーム検索
    @IBAction func searchRooms(_ sender: Any) {
        
        // 現在地を取得している途中であれば止める
        if CLLocationManager.locationServicesEnabled(){
            
            locationManager.stopUpdatingLocation()
            
        }
        // 画面遷移
        self.performSegue(withIdentifier: "roomsList", sender: nil)
    }
    
    // 背景の設定
    @IBAction func backGroundPhoto(_ sender: Any) {
        
        showAlertViewController()
    }
    
    
    //アラート
    func showAlertViewController(){
        
        let alertController = UIAlertController(title: "選択してください。", message: "チャットの背景画像を変更します。", preferredStyle: .actionSheet)
        
        let cameraButton:UIAlertAction = UIAlertAction(title: "カメラから", style: UIAlertActionStyle.default,handler: { (action:UIAlertAction!) in
            
            let sourceType:UIImagePickerControllerSourceType = UIImagePickerControllerSourceType.camera
            // カメラが利用可能かチェック
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
                // インスタンスの作成
                let cameraPicker = UIImagePickerController()
                cameraPicker.sourceType = sourceType
                cameraPicker.delegate = self
                cameraPicker.allowsEditing = true
                self.present(cameraPicker, animated: true, completion: nil)
                
            }
            
        })
        
        let albumButton:UIAlertAction = UIAlertAction(title: "アルバムから", style: UIAlertActionStyle.default,handler: { (action:UIAlertAction!) in
            
            let sourceType:UIImagePickerControllerSourceType = UIImagePickerControllerSourceType.photoLibrary
            // アルバムが利用可能かチェック
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary){
                // インスタンスの作成
                let cameraPicker = UIImagePickerController()
                cameraPicker.sourceType = sourceType
                cameraPicker.delegate = self
                self.present(cameraPicker, animated: true, completion: nil)
                
            }
            
        })
        
        let cancelButton:UIAlertAction = UIAlertAction(title: " キャンセル", style: UIAlertActionStyle.cancel,handler: { (action:UIAlertAction!) in
            
            //キャンセル
            
        })
        
        alertController.addAction(cameraButton)
        alertController.addAction(albumButton)
        alertController.addAction(cancelButton)
        
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            //Userdefaultsへ保存
            UserDefaults.standard.set(UIImagePNGRepresentation(pickedImage), forKey: "backGroundImage")
            
            
        }
        
        //カメラ画面(アルバム画面)を閉じる処理
        picker.dismiss(animated: true, completion: nil)
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
