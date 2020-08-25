//
//  FlickerPhotosInfo.swift
//  VirtualTourist
//
//  Created by Amnah on 8/25/20.
//  Copyright © 2020 Udacity. All rights reserved.
//

import Foundation

struct FlickerPhotoInfo: Codable {
    
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [FlickerPhoto]
    
}


