//
//  User.swift
//  NCMBRoomKeySampler
//
//  Created by Masuhara on 2019/01/06.
//  Copyright © 2019 Ylab, Inc. All rights reserved.
//

import UIKit
import NCMB

class User {
    var objectId: String!
    var uuid: String!
    var displayName: String!
    
    init() {
        // Initialize
    }
    
    static func register(displayName: String, uuid: String, completion: @escaping(Error?) -> ()) {
        let user = NCMBUser()
        user.userName = uuid
        user.password = uuid
        user.setObject(displayName, forKey: "displayName")
        user.setObject(uuid, forKey: "uuid")
        
        user.acl.setPublicReadAccess(true)
        user.acl.setPublicWriteAccess(true)
        
        user.signUpInBackground { (error) in
            completion(error)
        }
    }
    
    static func login(uuid: String, completion: @escaping(Error?) -> ()) {
        NCMBUser.logInWithUsername(inBackground: uuid, password: uuid) { (user, error) in
            completion(error)
        }
    }
    
    static func getUser(uuid: String, completion: @escaping(User?, Error?) -> ()) {
        let query = NCMBUser.query()
        query?.whereKey("uuid", equalTo: uuid)
        query?.getFirstObjectInBackground({ (result, error) in
            if let error = error {
                completion(nil, error)
            } else {
                if let object = result as? NCMBUser {
                    let user = User()
                    user.objectId = object.objectId
                    user.uuid = object.object(forKey: "uuid") as? String
                    user.displayName = object.object(forKey: "displayName") as? String
                    completion(user, nil)
                } else {
                    completion(nil, nil)
                }
            }
        })
    }
}
