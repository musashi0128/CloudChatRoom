//
//  ChatViewController.swift
//  CloudChatRoom
//
//  Created by 宮本一彦 on 2017/07/23.
//  Copyright © 2017年 宮本一彦. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase

class ChatViewController: JSQMessagesViewController {
    
    var decodedImage = UIImage()
    var iconImage = UIImage()
    
    
    var roomName = String()
    var address = String()
    var pathToImage = String()
    
    var messages:[JSQMessage]! = [JSQMessage]()
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    var incomingAvatar: JSQMessagesAvatarImage!
    var outgoingAvatar: JSQMessagesAvatarImage!
    
    var backGroundImage = UIImage()
    
    var aitenoImage:String!
    
    var uid = FIRAuth.auth()?.currentUser?.uid

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 右スワイプで戻る
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(sender:)))
        rightSwipe.direction = .right
        view.addGestureRecognizer(rightSwipe)
        
        
        if let imageData = UserDefaults.standard.object(forKey: "backGroundImage"){
            
            if (imageData as AnyObject).length != 0{
                backGroundImage = UIImage(data: imageData as! Data)!
                
            }else{
                backGroundImage = UIImage(named: "background.jpg")!
            }
        }
        
        
        self.collectionView.backgroundColor = UIColor.clear
        
        let backImageView = UIImageView()
        backImageView.image = backGroundImage
        backImageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        
        // ブラーエフェクトを生成（ここでエフェクトスタイルを指定する）
        let blurEffect = UIBlurEffect(style: .dark)
        
        // ブラーエフェクトからエフェクトビューを生成
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        
        // エフェクトビューのサイズを指定（オリジナル画像と同じサイズにする）
        visualEffectView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        
        let label = UILabel()
        label.frame = CGRect(x: 0, y: self.view.frame.size.height/2, width: self.view.frame.size.width, height: 100)
        label.text = roomName
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = UIColor.white
        visualEffectView.addSubview(label)
        self.collectionView.addSubview(visualEffectView)
        
         // 2秒後に中身を実行
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // ブラービューを消す
            visualEffectView.removeFromSuperview()
            
        }
        
        self.collectionView.insertSubview(backImageView, at: 0)
        
        self.getInfo()
        
        self.chatStart()

        
    }
    
    final func didSwipe(sender: UISwipeGestureRecognizer) {
        
        if sender.direction == .right {
            //print("Right")
            self.dismiss(animated: true, completion: nil)
        }
        else if sender.direction == .left {
            //print("Left")
        }
    }
    
    
    
    //メッセージの位置を決める
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath as IndexPath) as? JSQMessagesCollectionViewCell
        
        if messages[indexPath.row].senderId == senderId{
            
            cell?.textView.textColor = UIColor.white
        }else{
            
            cell?.textView?.textColor = UIColor.darkGray
        }
        
        return cell!
        
    }
    
    //参照するメッセージを返す
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        
        return self.messages?[indexPath.item]
        
    }
    
    //背景を返す
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let message = self.messages?[indexPath.row]
        
        if message?.senderId == senderId{
            
            return self.outgoingBubble
            
        }else{
            return self.incomingBubble
            
        }
        
    }
    
    //アバターを返す
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let message = self.messages?[indexPath.row]
        
        if message?.senderId == senderId{
            
            return self.outgoingAvatar
        }else{
            
            return self.incomingAvatar
        }
    }
    
    //メッセージの総数を返す
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.messages.count
        
    }
    
    func chatStart(){
        
        inputToolbar.contentView!.leftBarButtonItem = nil
        
        automaticallyAdjustsScrollViewInsets = true
        self.senderId = uid
        self.senderDisplayName = "自分"
        
        //0から4までの値を取得する
        let random = arc4random() % 5
        print(random)
        
        decodedImage = UIImage(named: "\(random).png")!
        
        let imageData2 :NSData = try! NSData(contentsOf: URL(string: pathToImage)!,options: NSData.ReadingOptions.mappedIfSafe)
        
        iconImage = UIImage(data:imageData2 as Data)!
        
        //吹き出しの設定
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        self.incomingBubble = bubbleFactory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        
        self.outgoingBubble = bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        
        self.incomingAvatar = JSQMessagesAvatarImageFactory.avatarImage(withPlaceholder:decodedImage, diameter: 64)
        
        
        self.outgoingAvatar = JSQMessagesAvatarImageFactory.avatarImage(withPlaceholder: iconImage, diameter: 64)
        //メッセージの配列の初期化
        self.messages = []
        
        
    }
    
    // メッセージをFirebase(DB)に入れる
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        // *URLを変更する
        let rootRef = FIRDatabase.database().reference(fromURL: "https://cloudchatroom-33a28.firebaseio.com/").child("message").child(address).child(roomName)
        
        let timestamp = Int(NSDate().timeIntervalSince1970)
        let post:Dictionary<String,Any>? = ["from":senderId,"name":senderDisplayName,"text":text,"timestamp":timestamp,"profileImage":pathToImage]
        
        let postRef = rootRef.childByAutoId()
        postRef.setValue(post)
        
        // 最後にテキスト入力欄を空にする
        self.inputToolbar.contentView.textView.text = ""
        
    }
    
    // メッセージをFirebase(DB)から取ってくる
    func getInfo(){
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let firebase = FIRDatabase.database().reference(fromURL: "https://cloudchatroom-33a28.firebaseio.com/").child("message").child(address).child(roomName)
        firebase.observe(.childAdded, with:{
            (snapshot) in
            if let dictionary = snapshot.value as? [String:AnyObject]{
                
                let snapshotValue = snapshot.value as! NSDictionary
                snapshotValue.setValuesForKeys(dictionary)
                let text = snapshotValue["text"] as! String
                let senderId = snapshotValue["from"] as! String
                let name = snapshotValue["name"] as! String
                self.aitenoImage = snapshotValue["profileImage"] as! String
                let message = JSQMessage(senderId:senderId,displayName: name,text: text)
                self.messages?.append(message!)
                
                self.finishReceivingMessage()
            }
        })
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
