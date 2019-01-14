//
//  Error+Extension.swift
//  NCMBRoomKeySampler
//
//  Created by Masuhara on 2019/01/06.
//  Copyright © 2019 Ylab, Inc. All rights reserved.
//

import UIKit

extension Error {
    var code: Int {
        return (self as NSError).code
    }
}
