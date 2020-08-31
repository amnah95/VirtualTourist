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
    
    
    // Adding new pin
    @IBAction func longPressed(sender: UILongPressGestureRecognizer)
    {
        if sender.state == .began {
            
            // Fetch selected location info
            let longPressLocation = sender.location(in: mapView)
            let longPressCoordinate = mapView.convert(longPressLocation, toCoordinateFrom: mapView)
            
            // Add a pin to database
            addPin(coordinate: longPressCoordinate)
            
        }
    }
    
    // Checking photos of location
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        let coordinate = view.annotation?.coordinate
        performSegue(withIdentifier: "toCollectionViewController", sender: coordinate)
        mapView.deselectAnnotation(view.annotation, animated: true)
        
    }
}


// MARK: Prepare segue functions

extension MapViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? CollectionViewController {
            // Pin selected
            let tappedCoordinate = sender as! CLLocationCoordinate2D
            viewController.pin = getPinFromCoordinate(tappedCoordinate: tappedCoordinate)
            viewController.dataController = self.dataController
        }
    }
    
    
    // To obtain pin based on coordniate
    func getPinFromCoordinate (tappedCoordinate: CLLocationCoordinate2D) -> Pin? {
                
        if let pins = fetchedResultsController.fetchedObjects {
            for pin in pins {
                if (pin.coordinate.latitude == tappedCoordinate.latitude &&
                    pin.coordinate.longitude == tappedCoordinate.longitude)
                { return pin }
            }
        }
        return nil
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


// MARK: MapView related function
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
            print("No pins are fetched from fetchedResultsController")
            return
        }
        for pin in pins {
            // Create annotation for
            let coordinate = pin.coordinate
            addAnnotation(coordinate: coordinate)
        }
        print("all fetched pins are added to map")
    }
    
}

// MARK: Fetch results controller
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

