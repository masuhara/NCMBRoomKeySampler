//
//  ViewController.swift
//  NCMBRoomKeySampler
//
//  Created by Masuhara on 2019/01/06.
//  Copyright © 2019 Ylab, Inc. All rights reserved.
//

import UIKit
import NCMB
import MBProgressHUD
import KafkaRefresh

class ViewController: UIViewController {
    
    let uuid = UIDevice.current.identifierForVendor!.uuidString
    var currentRoom: Room?
    
    @IBOutlet weak var userCollectionView: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        
        login()
    }
    
    func configureCollectionView() {
        // CollectionViewのデリゲート
        userCollectionView.dataSource = self
        userCollectionView.delegate = self
        
        // カスタムセルの登録
        let nib = UINib(nibName: "UserCollectionViewCell", bundle: Bundle.main)
        userCollectionView.register(nib, forCellWithReuseIdentifier: "UserCollectionViewCell")
        
        // 引っ張って更新
        userCollectionView.bindHeadRefreshHandler({
            self.loadRoom()
        }, themeColor: UIColor.white, refreshStyle: .native)
    }
    
    func login() {
        // 自動ログイン -> 登録されていない場合は新規登録を促す
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        User.login(uuid: uuid) { (error) in
            hud.hide(animated: true)
            if let error = error {
                // 未登録の場合
                if error.code == 401002 {
                    self.showRegisterAlert()
                } else {
                    // その他のエラー
                    let alert = UIAlertController(title: "ログインエラー", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                    let retryAction = UIAlertAction(title: "リトライ", style: .default, handler: { (action) in
                        // 再読込
                        self.login()
                    })
                    alert.addAction(retryAction)
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                // 部屋情報読み込み
                self.loadRoom()
            }
        }
    }
    
    func showRegisterAlert() {
        let alert = UIAlertController(title: "新規登録", message: "名前を入力してください", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (textField) in
            textField.delegate = self
        })
        let registerAction = UIAlertAction(title: "登録", style: .default, handler: { (action) in
            let displayName = alert.textFields![0].text ?? ""
            User.register(displayName: displayName, uuid: self.uuid, completion: { (error) in
                if let error = error {
                    // 新規登録エラー
                    let alert = UIAlertController(title: "登録エラー", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                    let retryAction = UIAlertAction(title: "リトライ", style: .default, handler: { (action) in
                        self.login()
                    })
                    alert.addAction(retryAction)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    // 新規登録完了
                    self.loadRoom()
                }
            })
        })
        alert.addAction(registerAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showRoomSelectAlert() {
        let alert = UIAlertController(title: "ルーム選択", message: "誰かが作成したルームに入る場合は「ルームに入る」を、自分でルームを作成する場合は「ルームの新規作成」を選択してください", preferredStyle: .alert)
        let loginRoomAction = UIAlertAction(title: "ルームに入る", style: .default) { (action) in
            self.showInputRoomKeyAlert()
        }
        let createRoomAction = UIAlertAction(title: "ルームの新規作成", style: .default) { (action) in
            self.showCreateNewRoomAlert()
        }
        alert.addAction(loginRoomAction)
        alert.addAction(createRoomAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showInputRoomKeyAlert() {
        let alert = UIAlertController(title: "キー入力", message: "キーを入力してください", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.delegate = self
        }
        let loginAction = UIAlertAction(title: "入室", style: .default) { (action) in
            Room.getUserRooms(user: NCMBUser.current(), completion: { (rooms, error) in
                if let error = error {
                    let alert = UIAlertController(title: "エラー", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                    let retryAction = UIAlertAction(title: "リトライ", style: .default, handler: { (action) in
                        self.showInputRoomKeyAlert()
                    })
                    alert.addAction(retryAction)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    if let rooms = rooms {
                        if rooms.count > 0 {
                            self.currentRoom = rooms[0]
                            self.userCollectionView.reloadData()
                        } else {
                            self.showRoomSelectAlert()
                        }
                    } else {
                        self.showRoomSelectAlert()
                    }
                }
            })
        }
        let cancelAction = UIAlertAction(title: "戻る", style: .default) { (action) in
            self.showRoomSelectAlert()
        }
        alert.addAction(loginAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showCreateNewRoomAlert() {
        let alert = UIAlertController(title: "ルーム作成", message: "ルームを作成します", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.delegate = self
        }
        let loginRoomAction = UIAlertAction(title: "作成", style: .default) { (action) in
            let roomKey = alert.textFields![0].text ?? "" // ルームキーはN文字以上、のようなルールがあったほうがよい
            Room.registerRoom(roomKey: roomKey, completion: { (error) in
                if let error = error {
                    let alert = UIAlertController(title: "読み込みエラー", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                    let retryAction = UIAlertAction(title: "リトライ", style: .default, handler: { (action) in
                        self.showCreateNewRoomAlert()
                    })
                    alert.addAction(retryAction)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    // ルーム登録成功
                    self.loadRoom()
                }
            })
        }
        let cancelAction = UIAlertAction(title: "戻る", style: .default) { (action) in
            self.showRoomSelectAlert()
        }
        alert.addAction(loginRoomAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func loadRoom() {
        if let currentUser = NCMBUser.current() {
            Room.getUserRooms(user: currentUser, completion: { (rooms, error) in
                if let error = error {
                    let alert = UIAlertController(title: "エラー", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                    let retryAction = UIAlertAction(title: "リトライ", style: .default, handler: { (action) in
                        self.showCreateNewRoomAlert()
                    })
                    alert.addAction(retryAction)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    if let rooms = rooms {
                        if rooms.count > 0 {
                            self.currentRoom = rooms[0]
                            // ルーム名 = ルームキーの場合
                            self.navigationItem.title = self.currentRoom?.roomKey ?? "キー未設定"
                            // ルーム名を決める形式の場合
                            // self.navigationItem.title = self.currentRoom?.roomName ?? "ルーム名未設定"
                            self.userCollectionView.reloadData()
                        } else {
                            self.showRoomSelectAlert()
                        }
                    } else {
                        // roomが無いということなので、ルーム作成のアラートを再表示
                        self.showRoomSelectAlert()
                    }
                }
            })
        } else {
            self.login()
        }
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentRoom?.users.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCollectionViewCell", for: indexPath) as! UserCollectionViewCell
        cell.userImageView.image = UIImage(named: "placeholder-human")
        cell.userNameLabel.text = currentRoom?.users[indexPath.row].displayName
        return cell
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
