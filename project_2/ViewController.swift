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

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        addAnnotation()
        
    }
    
    
    @IBAction func addBtn(_ sender: Any) {
        performSegue(withIdentifier: "goToDetailsScreen", sender: self)

    }
    
    private func addAnnotation() {

        guard let location = locationManager.location else {
            return
        }

        loadWeather(search: "\(location.coordinate.latitude),\(location.coordinate.longitude)") { weatherResponse in
            if let weather = weatherResponse {
                let annotation = MyAnnotation(coordinate: location.coordinate, title: weather.current.condition.text, subtitle: "Temperature: \(weather.current.temp_c)°C", iconUrl: "https:\(weather.current.condition.icon)", temperature: weather.current.temp_c)

                self.mapView.addAnnotation(annotation)


            } else {

            }
        }

    }

    

    private func mapSetup() {
        mapView.delegate = self
        
        guard let location = locationManager.location else {
            return
        }
        
        let radiusInMetres: CLLocationDistance = 1000
        
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: radiusInMetres, longitudinalMeters: radiusInMetres)
        
        mapView.setRegion(region, animated: true)
        
        //camera boundries
        let cameraBoundry = MKMapView.CameraBoundary(coordinateRegion: region)
        mapView.setCameraBoundary(cameraBoundry, animated: true)
        
        //control zooming
        let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 1000)
        mapView.setCameraZoomRange(zoomRange, animated: true)
    }
    
}

extension ViewController: MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    func parseJson(data: Data) -> WeatherResponse? {
        let decoder = JSONDecoder()
        var weather: WeatherResponse?
        do {
            weather = try decoder.decode(WeatherResponse.self, from: data)
        } catch {
            print("Error decoding: \(error)")
        }
        return weather
    }
    
    func loadWeather(search: String?, completion: @escaping (WeatherResponse?) -> Void) {
        guard let search = search else {
            completion(nil)
            return
        }
        
        guard let url = getUrl(query: search) else {
            print("Could not get url")
            completion(nil)
            return
        }
        
        let urlSession = URLSession.shared
        
        let dataTask = urlSession.dataTask(with: url) { data, response, error in
            print("Network call complete")
            
            guard let data = data else {
                print("No data found")
                completion(nil)
                return
            }
            
            if let weatherResponse = self.parseJson(data: data) {
                completion(weatherResponse)
            } else {
                completion(nil)
            }
        }
        
        dataTask.resume()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "what is this?"
        var view: MKMarkerAnnotationView

        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: 0, y: 1)

            let button = UIButton(type: .detailDisclosure)
            button.tag = 10000
            
            view.rightCalloutAccessoryView = button

            view.tintColor = UIColor.systemRed
        }

        if let myAnnotation = annotation as? MyAnnotation {
            view.glyphText = myAnnotation.glyphText

            if let iconUrl = myAnnotation.iconUrl {
                setImageFromUrl(iconUrl) { image in
                    DispatchQueue.main.async {
                        view.leftCalloutAccessoryView = UIImageView(image: image)
                        view.markerTintColor = self.markerTintColor(for: myAnnotation.temperature!)
                    }
                }
            }
        }

        return view
    }

    private func markerTintColor(for temperature: Float) -> UIColor {
        switch temperature {
        case ...0: return .green
        case 0...16: return .cyan
        case 16...24: return .blue
        case 24...30: return .yellow
        case 30...35: return .orange
        default: return .red
        }
    }
    
    func setImageFromUrl(_ urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
        
        task.resume()
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
    var iconUrl: String?
    var temperature: Float?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, glyphText: String? = nil, iconUrl: String? = nil, temperature: Float?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.glyphText = glyphText
        self.iconUrl = iconUrl
        self.temperature = temperature
        
        super.init()
    }
}

private func getUrl(query: String) -> URL? {
    let baseUrl = "https://api.weatherapi.com"
    let endpoint = "/v1/current.json"
    let apiKey = "13c1c685a3a74754bab182229232003"
    guard let url = "\(baseUrl)\(endpoint)?key=\(apiKey)&q=\(query)"
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        return nil
    }
    
    print(url)
    
    return URL(string: url)
}

struct ListItem {
    var title: String
    var description: String
}


struct WeatherResponse: Decodable {
    let location: Location
    let current: Weather
}

struct Location: Decodable {
    let name: String
}

struct Weather: Decodable {
    let temp_c: Float
    let temp_f: Float
    let is_day: Int
    let condition: Conditions
}

struct Conditions: Decodable {
    let code: Int
    let text: String
    let icon: String
}
