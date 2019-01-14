//
//  Room.swift
//  NCMBRoomKeySampler
//
//  Created by Masuhara on 2019/01/06.
//  Copyright © 2019 Ylab, Inc. All rights reserved.
//

import UIKit
import NCMB

class Room {
    var objectId: String!
    var roomKey: String!
    var roomName: String?
    var users = [User]()
    
    // 自分が所属しているルーム一覧の取得
    static func getUserRooms(user: NCMBUser, completion: @escaping([Room]?, Error?) -> ()) {
        let query = NCMBQuery(className: "Room")
        query?.includeKey("users")
        query?.whereKey("users", containedIn: [user])
        query?.findObjectsInBackground({ (result, error) in
            if let error = error {
                completion(nil, error)
            } else {
                if let objects = result as? [NCMBObject] {
                    
                    let dispatchGroup = DispatchGroup()
                    let dispatchQueue = DispatchQueue(label: "queue")
                    
                    var rooms = [Room]()
                    for object in objects {
                        let room = Room()
                        room.objectId = object.objectId
                        room.roomKey = object.object(forKey: "roomKey") as? String
                        room.roomName = object.object(forKey: "roomName") as? String
                        
                        // ルーム内のユーザー
                        if let userRelation = object.object(forKey: "users") as? NCMBRelation {
                            dispatchGroup.enter()
                            dispatchQueue.async(group: dispatchGroup) {
                                userRelation.query()?.findObjectsInBackground({ (result, error) in
                                    if let error = error {
                                        completion(nil, error)
                                    } else {
                                        if let userObjects = result as? [NCMBUser] {
                                            var users = [User]()
                                            for userObject in userObjects {
                                                let user = User()
                                                user.objectId = userObject.objectId
                                                user.uuid = userObject.object(forKey: "uuid") as? String
                                                user.displayName = userObject.object(forKey: "displayName") as? String
                                                users.append(user)
                                            }
                                            room.users = users
                                        }
                                    }
                                    dispatchGroup.leave()
                                })
                            }
                        }
                        rooms.append(room)
                    }
                    dispatchGroup.notify(queue: .main) {
                        print("All Process Done!")
                        completion(rooms, nil)
                    }
                } else {
                    completion(nil, nil)
                }
            }
        })
    }
    
    // ルーム登録(キーのみ)
    static func registerRoom(roomKey: String, completion: @escaping(Error?) -> ()) {
        let query = NCMBQuery(className: "Room")
        query?.whereKey("roomKey", equalTo: roomKey)
        query?.findObjectsInBackground({ (result, error) in
            if let error = error {
                completion(error)
            } else {
                if let rooms = result as? [NCMBObject] {
                    if rooms.count > 0 {
                        // すでにそのルームキーが使用済みだった場合
                        let nsError = NSError(domain: "Error: This roomKey is already used.", code: -999, userInfo: nil)
                        completion(nsError)
                    } else {
                        let object = NCMBObject(className: "Room")
                        object?.setObject(roomKey, forKey: "roomKey")
                        object?.addUniqueObject(NCMBUser.current(), forKey: "users")
                        object?.saveInBackground({ (error) in
                            completion(error)
                        })
                    }
                } else {
                    let object = NCMBObject(className: "Room")
                    object?.setObject(roomKey, forKey: "roomKey")
                    object?.addUniqueObject(NCMBUser.current(), forKey: "users")
                    object?.saveInBackground({ (error) in
                        completion(error)
                    })
                }
            }
        })
    }
    
    // ルーム登録(ルーム名も同時)
    static func registerRoom(roomKey: String, roomName: String, completion: @escaping(Error?) -> ()) {
        let query = NCMBQuery(className: "Room")
        query?.whereKey("roomKey", equalTo: roomKey)
        query?.findObjectsInBackground({ (result, error) in
            if let error = error {
                completion(error)
            } else {
                if let rooms = result as? [NCMBObject] {
                    if rooms.count > 0 {
                        // すでにそのルームキーが使用済みだった場合
                        let nsError = NSError(domain: "Error: This roomKey is already used.", code: -999, userInfo: nil)
                        completion(nsError)
                    } else {
                        let object = NCMBObject(className: "Room")
                        object?.setObject(roomKey, forKey: "roomKey")
                        object?.setObject(roomName, forKey: "roomName")
                        object?.addUniqueObject(NCMBUser.current(), forKey: "users")
                        object?.saveInBackground({ (error) in
                            completion(error)
                        })
                    }
                } else {
                    let object = NCMBObject(className: "Room")
                    object?.setObject(roomKey, forKey: "roomKey")
                    object?.setObject(roomName, forKey: "roomName")
                    object?.addUniqueObject(NCMBUser.current(), forKey: "users")
                    object?.saveInBackground({ (error) in
                        completion(error)
                    })
                }
            }
        })
    }
}
