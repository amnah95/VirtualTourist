//
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Amnah on 8/30/20.
//  Copyright © 2020 Udacity. All rights reserved.
//

import UIKit
import CoreData
import MapKit



class CollectionViewController: UIViewController {
    
    // CoreData related Variables/Constats
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setUpMapView()
        setCollectionViewFlow()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupFetchResultsController { (fetchStatus) in
            if fetchStatus {
                if self.fetchedResultsController.fetchedObjects?.count == 0 {
                    print("No exsiting photos")
                    self.getAllPhotosData()
                } else {
                    print("There should be exsiting photos")
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // set fetched results controller to nil
        fetchedResultsController = nil
    }
}

// MARK: MapView related functions
extension CollectionViewController: MKMapViewDelegate {
    
    func setUpMapView () {
        
        mapView.delegate = self
        
        // set annotaion
        let annotation = MKPointAnnotation()
        annotation.coordinate = pin.coordinate
        mapView.addAnnotation(annotation)
        
        // Recenter based on current pin coordniate
        let region = MKCoordinateRegion(center: pin.coordinate, span: mapView.region.span)
        mapView.setRegion(region, animated: true)
    }
}


// MARK: Collection view data source
extension CollectionViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let aPhoto = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCollectionViewCellID, for: indexPath) as! CollectionViewCell
        
        cell.imageView.image = UIImage(data: aPhoto.imageData!)
        
        return cell
    }
    
}

// MARK: Collection View Flow Setup
extension CollectionViewController {
    
    func setCollectionViewFlow() {
        let space: CGFloat = 3.0
        let widthDimension = (view.frame.size.width - 2 * space ) / 3.0
        let heightDimension = (view.frame.size.width - 2 * space ) / 5.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: widthDimension, height: heightDimension)
    }
}

// MARK: Fetch results controller
extension CollectionViewController: NSFetchedResultsControllerDelegate {
    
    // Loading exsiting data in data base
    fileprivate func setupFetchResultsController(completionHandler: @escaping (Bool)->()) {
        
        print("Fetching Photos from data base")
        
        // Assign Fetch request first
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [] //Needs to be there even if empty
        
        // Assign Fetch results controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin)-photo")
        
        // Set fectch controller delegate
        fetchedResultsController.delegate = self
        
        // Perform Fetch
        do {
            try fetchedResultsController.performFetch()
            print("Fetching is done")
            completionHandler(true)
        } catch {
            print("The fetch could not be performed")
            completionHandler(false)
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        print("NS Controller for insert")
        
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
            break
        default:
            break
        }
    }
}


// MARK: Photos requesting from network
extension CollectionViewController {
    
    // Adding photo to data base
    func addPhotoData (data: Data) {
        let photo = Photo(context: dataController.viewContext)
        photo.imageData = data
        do {
            try dataController.viewContext.save()
            print("a photo data has been added to database")
        } catch {
            print("a photo data was NOT added to database")
        }
    }
    
    // Get photos data from network
    func getAllPhotosData() {
        
        var photosList: [FlickerPhotoDetails] = []
        
        print("Requsting all new photos")
        
        _ = FlickerClient.getPhotos(pinCoordinate: pin.coordinate, completion: { (results, error) in
            photosList = results
            print("Number of photos for this point:")
            print(String(describing: photosList.count))
            
            for photo in photosList {
                FlickerClient.requestImageFile(photo.imageURL()) { (data, error) in
                    guard let data = data else { return }
                    self.addPhotoData(data: data)
                }
            }
        })
    }
}
