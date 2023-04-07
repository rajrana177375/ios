//
//  ViewController.swift
//  project_2
//
//  Created by Account on 2023-04-06.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    private let locationManager = CLLocationManager()
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        locationManager.requestWhenInUseAuthorization()
        mapSetup()
        addAnnotation(location: getFanshaweLocation())
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

    }
    
    func getFanshaweLocation() -> CLLocation {
        return CLLocation(latitude: 43.0130, longitude: -81.1994)
    }
    
    private func addAnnotation(location: CLLocation) {
        
        let annotation = MyAnnotation(coordinate: location.coordinate, title: "vsvs", subtitle: "any subtitile",  glyphText: "F")
        
        mapView.addAnnotation(annotation)
    }

    private func mapSetup() {
        mapView.delegate = self
        
        mapView.showsUserLocation = true
        let location = getFanshaweLocation()
        
        let radiusInMetres: CLLocationDistance = 1000
        
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: radiusInMetres, longitudinalMeters: radiusInMetres)
        
        mapView.setRegion(region, animated: true)
        
        //camera boundries
        let cameraBoundry = MKMapView.CameraBoundary(coordinateRegion: region)
        mapView.setCameraBoundary(cameraBoundry, animated: true)
        
        //control zooming
        let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 100000)
        mapView.setCameraZoomRange(zoomRange, animated: true)
    }

}

extension ViewController: MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let identifier = "what is this?"
        var view : MKMarkerAnnotationView
        
       if let dequedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            dequedView.annotation = annotation
            view = dequedView
       } else {
           view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
           view.canShowCallout = true
           
           // set the position of the callout
           view.calloutOffset = CGPoint(x: 0, y: 10)
           
           let button = UIButton(type: .detailDisclosure)
           button.tag = 10000
           view.rightCalloutAccessoryView = button
           
           //add image left to the callout
           let image = UIImage(systemName: "graduationcap.circle.fill")
           view.leftCalloutAccessoryView = UIImageView(image: image)
           
           // change colour of pin/marker
           view.markerTintColor = UIColor.purple

           // change colour of accssories
           view.tintColor = UIColor.systemRed
           
           if let myAnnotation = annotation as? MyAnnotation {
               view.glyphText = myAnnotation.glyphText

           }
           
       }
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let coordinates = view.annotation?.coordinate else {
            return
        }
        
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ]
        
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinates))
        
        mapItem.openInMaps(launchOptions: launchOptions)
        print("I am pressed \(control.tag)")
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return listItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
      let listItem = listItems[indexPath.row]
      cell.textLabel?.text = listItem.title
      cell.detailTextLabel?.text = listItem.description
      return cell
    }
    
    
}

var listItems = [
  ListItem(title: "Item 1", description: "This is the first item"),
  ListItem(title: "Item 2", description: "This is the second item"),
  ListItem(title: "Item 3", description: "This is the third item")
]


class MyAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var glyphText: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, glyphText: String? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.glyphText = glyphText
        
        super.init()
    }
}

struct ListItem {
  var title: String
  var description: String
}
