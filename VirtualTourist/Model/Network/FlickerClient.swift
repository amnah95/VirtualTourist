//
//  FlickerClient.swift
//  VirtualTourist
//
//  Created by Amnah on 8/25/20.
//  Copyright © 2020 Udacity. All rights reserved.
//

import Foundation

class FlickerClient {
    
    static let apiKey = "dae024279be96c3750f1fc88595f9a97"
    
    struct Coordinates {
        static var latitude = 0.0
        static var longitude = 0.0
    }
    
    static let searchRaduis = 10
    static let numberOfResults = 10
    
    
    enum Endpoints: String {
        static let base = "https://api.flickr.com/services/rest/"
        static let apiKeyParameter = "?api_key=\(FlickerClient.apiKey)"
        static let radiusParameter = "&radius=\(FlickerClient.searchRaduis)"
        static let perPageParameter = "&per_page=\(FlickerClient.numberOfResults)"
        
        
        
        case searchPhotos
        
        var stringValue: String {
            switch self {
            case .searchPhotos:
                return Endpoints.base + Endpoints.apiKeyParameter + "&method=flickr.photos.search" + "&format=json" + Endpoints.radiusParameter + Endpoints.perPageParameter + "&per_page=\(FlickerClient.numberOfResults)" + "&lat=\(Coordinates.latitude)" + "&lon=\(Coordinates.longitude)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    
    // This is a genreal get request, it either returns a responseObject or an error
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                    print("Task: no data found")
                }
                return
            }
            
            let newData = subsetResponseData(data: data)
            
            let decoder = JSONDecoder()
            do {
                
                let responseObject = try decoder.decode(ResponseType.self, from: newData)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                    print("Task: response is there")
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(FlickerResponse.self, from: newData) as Error
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                        print("Task: cast error")
                        
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                        print("Task: could not handle error")
                    }
                }
            }
        }
        task.resume()
        
        return task
    }
    
    static func getPhotos(lat: Double, lon: Double, completion: @escaping ([FlickerPhoto], Error?) -> Void) {
        
        print("GetPhotos: Accessed")
        FlickerClient.Coordinates.latitude = lat
        FlickerClient.Coordinates.longitude = lon
        
        print("URL: \(Endpoints.searchPhotos.url)")
        
        _ = taskForGETRequest(url: Endpoints.searchPhotos.url, responseType: FlickerPhotoResults.self) { response, error in
            if let response = response {
                completion(response.photos.photo , nil)
                print("GetPhotos: Sucessed")
                
            } else {
                print("GetPhotos: Faild")
                completion([], error)
            }
        }
    }
}


// Helper method
extension FlickerClient {
    
    // Subset first 5 charachters of response data
    class func subsetResponseData (data: Data) -> Data {
        
        let range = Range(uncheckedBounds: (14, data.count - 1))
        let newData = data.subdata(in: range)
        
        print(String(data: newData, encoding: .utf8)!)
        return newData
    }
    
}
