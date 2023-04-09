//
//  ViewController.swift
//  project_2
//
//  Created by Account on 2023-04-06.
//

import UIKit
import MapKit

class ViewController: UIViewController, DetailsViewControllerDelegate {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    private let locationManager = CLLocationManager()
    
    @IBOutlet weak var mapView: MKMapView!
    
    var myData: WeatherResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        locationManager.requestWhenInUseAuthorization()
        mapSetup()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        addAnnotation(location: locationManager.location ?? getFanshaweLocation())
        
    }
    
    
    func getFanshaweLocation() -> CLLocation {
        return CLLocation(latitude: 43.0130, longitude: -81.1994)
    }
    
    
    func didAddWeatherData(_ data: WeatherResponse) {
        if let forecastDay = data.forecast.forecastday.first {
            let locationItem = LocationItem(locationName: data.location.name,
                                            temperature: "\(data.current.temp_c)C (H:\(forecastDay.day.maxtemp_c) L:\(forecastDay.day.mintemp_c))",
                                            weatherIconUrl: "https:\(data.current.condition.icon)",
                                            coordinate: CLLocationCoordinate2D(latitude: data.location.lat, longitude: data.location.lon),
                                            temperatureValue: data.current.temp_c,
                                            weatherData: data)
            locationItems.append(locationItem)
            tableView.reloadData()
        }
        
    }
    
    @IBAction func addBtn(_ sender: Any) {
        if let detailsViewController = storyboard?.instantiateViewController(withIdentifier: "goToDetailsScreen") as? DetailsViewController {
            detailsViewController.delegate = self
            detailsViewController.modalPresentationStyle = .fullScreen
            present(detailsViewController, animated: true, completion: nil)
        }
        
    }
    
    
    private func addAnnotation(location: CLLocation) {
        loadWeather(search: "\(location.coordinate.latitude),\(location.coordinate.longitude)") { weatherResponse in
            if let weather = weatherResponse {
                if let forecastDay = weather.forecast.forecastday.first {
                    let annotation = MyAnnotation(coordinate: location.coordinate, title: weather.current.condition.text, subtitle: "\(weather.current.temp_c)C (H:\(forecastDay.day.maxtemp_c) L:\(forecastDay.day.mintemp_c))", iconUrl: "https:\(weather.current.condition.icon)", temperature: weather.current.temp_c)
                    
                    self.mapView.addAnnotation(annotation)
                }
            } else {
                print("Cannot load weather")
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
        if let detailsViewController = storyboard?.instantiateViewController(withIdentifier: "goToWeatherDetail") as? WeatherDetailView {

            if let annotation = view.annotation as? MyAnnotation {
                detailsViewController.coordinate = "\(annotation.coordinate.latitude), \(annotation.coordinate.longitude)"
            }

            present(detailsViewController, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locationItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let locationItem = locationItems[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        
        content.text = locationItem.locationName
        content.secondaryText = locationItem.temperature
        
        setImageFromUrl(locationItem.weatherIconUrl) { image in
            DispatchQueue.main.async {
                content.image = image
                cell.contentConfiguration = content
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let locationItem = locationItems[indexPath.row]
        let region = MKCoordinateRegion(center: locationItem.coordinate,
                                        latitudinalMeters: 1000,
                                        longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
        
        let annotation = MyAnnotation(coordinate: locationItem.coordinate,
                                      title: locationItem.locationName,
                                      subtitle: locationItem.temperature,
                                      iconUrl: locationItem.weatherIconUrl,
                                      temperature: locationItem.temperatureValue)
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

var locationItems: [LocationItem] = []

class MyAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var glyphText: String?
    var iconUrl: String?
    var temperature: Float?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, glyphText: String? = nil, iconUrl: String? = nil, temperature: Float? = nil) {
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
    let endpoint = "/v1/forecast.json"
    let apiKey = "cf846bd7fcce44f797031444230904"
    guard let url = "\(baseUrl)\(endpoint)?key=\(apiKey)&q=\(query)&days=1"
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        return nil
    }
    
    print(url)
    
    return URL(string: url)
}
