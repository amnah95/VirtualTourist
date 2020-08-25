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
    
    var photosList: [FlickerPhoto] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        
        _ = FlickerClient.getPhotos(lat: 26.306343, lon: 50.167809, completion: { (results, error) in
            self.photosList = results
            print("Photos arra counnt: \(self.photosList.count)")
        })

        //User last map state
        if let region = loadUserLastMapState() {
            mapView.region = region
        }

        setupFetchResultsController { (fetchStatus) in
            if fetchStatus {self.loadPins()}
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchResultsController { (fetchStatus) in
            if fetchStatus {self.loadPins()}
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // set fetched results controller to nil
        fetchedResultsController = nil
     }
    
    @IBAction func longPressed(sender: UILongPressGestureRecognizer)
    {
        if sender.state == .began {
            print("longpressed")
            
            // Fetch selected location info
            let longPressLocation = sender.location(in: mapView)
            let longPressCoordinate = mapView.convert(longPressLocation, toCoordinateFrom: mapView)
            
            // Add a pin to database
            addPin(coordinate: longPressCoordinate)
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


// MARK: Map related function
extension MapViewController {
    
    
    func addAnnotation (coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    func addPin(coordinate: CLLocationCoordinate2D) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        
        do {
            try dataController.viewContext.save()
            print("new pin is save to database")
        } catch {
            print("new pin is NOT save to database")
        }
    }
    
    func loadPins() {
        guard let pins = fetchedResultsController.fetchedObjects else {
            print("No objectes are fetched from fetchedResultsController")
            return
        }
        for pin in pins {
            // Create annotation for
            let coordinate = pin.coordinate
            addAnnotation(coordinate: coordinate)
        }
        print("all fetched pins objectes are added to map")
    }
    
}

// MARK: Fetch Results Controller
extension MapViewController: NSFetchedResultsControllerDelegate {
    
    // Loading exsiting data in data base
    fileprivate func setupFetchResultsController(completionHandler: @escaping (Bool)->()) {
        
        // Assign Fetch request first
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [] //Needs to be there even if empty
        
        // Assign Fetch results controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "Pin")
        
        // Set fectch controller delegate
        fetchedResultsController.delegate = self
        
        // Perform Fetch
        do {
            try fetchedResultsController.performFetch()
            completionHandler(true)
        } catch {
            completionHandler(false)
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        guard let pin = anObject as? Pin else {
            print("no point to fetch")
            return
        }
        
        switch type {
        case .insert:
            addAnnotation(coordinate: pin.coordinate)
        default:
            break
        }
    }
    
    
    
}

