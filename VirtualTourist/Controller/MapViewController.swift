//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Amnah on 8/24/20.
//  Copyright © 2020 Udacity. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController {
    
    // CoreData related Variables/Constats
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    // MapKit related Variables/Constats
    let mapStateKey = "MapStateKey"
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self

        //User last map state
        if let region = loadUserLastMapState() {
            mapView.region = region
        }
    }
}

// MARK: Mapview delgate for mapView state data
extension MapViewController: MKMapViewDelegate {
    // Save user state when  visiable region change
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        saveUserLastMapState()
    }

    // Save user last map state
    func saveUserLastMapState() {
        
        let mapStateCenter = mapView.region.center
        let mapSteteSpan = mapView.region.span
        
        let mapStateInfo = [mapStateCenter.latitude, mapStateCenter.longitude, mapSteteSpan.latitudeDelta, mapSteteSpan.longitudeDelta]
        
        UserDefaults.standard.set(mapStateInfo, forKey: mapStateKey)
    }
    
    // Load user last map state
    func loadUserLastMapState() -> MKCoordinateRegion? {
        
        guard let region = UserDefaults.standard.object(forKey: mapStateKey) as? [Double] else {return nil}
        
        let mapCenter = CLLocationCoordinate2D(latitude: region[0], longitude: region[1])
        let mapSpan = MKCoordinateSpan(latitudeDelta: region[2], longitudeDelta: region[3])
        
        return MKCoordinateRegion(center: mapCenter, span: mapSpan)
    }
}

