//
//  FlickerResponse.swift
//  VirtualTourist
//
//  Created by Amnah on 8/25/20.
//  Copyright © 2020 Udacity. All rights reserved.
//

import Foundation

struct FlickerResponse: Codable {
    let stat: String
    let code: Int
    let message: String
}

extension FlickerResponse: LocalizedError {
    var errorDescription: String? {
        return message
    }
}
