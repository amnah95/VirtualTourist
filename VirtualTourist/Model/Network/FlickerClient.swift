//
//  FlickerClient.swift
//  VirtualTourist
//
//  Created by Amnah on 8/25/20.
//  Copyright © 2020 Udacity. All rights reserved.
//

import Foundation
import MapKit

class FlickerClient {
    
    static let apiKey = "dae024279be96c3750f1fc88595f9a97"
    
    struct Coordinates {
        static var latitude = 0.0
        static var longitude = 0.0
    }
    
    static let searchRaduis = 10
    static let numberOfResults = 24
    static var page = 1
    
    
    enum Endpoints: String {
        static let base = "https://api.flickr.com/services/rest/"
        static let apiKeyParameter = "?api_key=\(FlickerClient.apiKey)"
        static let radiusParameter = "&radius=\(FlickerClient.searchRaduis)"
        static let perPageParameter = "&per_page=\(FlickerClient.numberOfResults)"
        static let pageParameter = "&page=\(FlickerClient.page)"
        
        
        
        
        case searchPhotos
        
        var stringValue: String {
            switch self {
            case .searchPhotos:
                return Endpoints.base + Endpoints.apiKeyParameter + "&method=flickr.photos.search" + "&format=json" + Endpoints.radiusParameter + Endpoints.perPageParameter + "&per_page=\(FlickerClient.numberOfResults)" + "&page=\(FlickerClient.page)" + "&lat=\(Coordinates.latitude)" + "&lon=\(Coordinates.longitude)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    
    //This is a genreal get request, it either returns a responseObject or an error
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let newData = subsetResponseData(data: data)
            
            let decoder = JSONDecoder()
            do {
                
                let responseObject = try decoder.decode(ResponseType.self, from: newData)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(FlickerResponse.self, from: newData) as Error
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
        
        return task
    }
    
    
    //Get searched location photos
    static func getPhotos(pinCoordinate: CLLocationCoordinate2D, completion: @escaping ([FlickerPhotoDetails], Error?) -> Void) {
        
        self.page = Int.random(in: 0...10)
        
        FlickerClient.Coordinates.latitude = pinCoordinate.latitude
        FlickerClient.Coordinates.longitude = pinCoordinate.longitude
                
        _ = taskForGETRequest(url: Endpoints.searchPhotos.url, responseType: FlickerPhotoResults.self) { response, error in
            if let response = response {
                completion(response.photos.photo , nil)
            } else {
                completion([], error)
            }
        }
    }
    
    
    // Load image using its URL
    class func requestImageFile(_ url : URL, completion: @escaping (Data?,Error?) -> Void){
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else
            {
                print("no data were obtaind for photo")
                completion(nil, error)
                return
            }
            print("photo data from link: \(url)")
            print(data)

            completion(data, nil)
        }
        task.resume()
    }
}


// Helper method
extension FlickerClient {
    
    // Subset first 5 charachters of response data
    class func subsetResponseData (data: Data) -> Data {
        
        let range = Range(uncheckedBounds: (14, data.count - 1))
        let newData = data.subdata(in: range)

        return newData
    }
    
}
