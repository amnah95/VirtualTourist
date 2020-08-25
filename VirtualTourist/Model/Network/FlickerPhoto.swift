//
//  FlickerPhoto.swift
//  VirtualTourist
//
//  Created by Amnah on 8/25/20.
//  Copyright © 2020 Udacity. All rights reserved.
//

import Foundation

struct FlickerPhoto: Codable {
    
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
    
    var isPublic: Bool {
        return ispublic == 1
    }
    
    var isFriend: Bool {
        return isfriend == 1
    }
    
    var isFamily: Bool {
        return isfamily == 1
    }
}
