//
//  WeatherDetailView.swift
//  project_2
//
//  Created by Account on 2023-04-08.
//

import UIKit

class WeatherDetailView: UIViewController, UITableViewDelegate
, UITableViewDataSource
{
    var coordinate: String?
    
    
    @IBOutlet weak var locationNameLabel: UILabel!
    
    @IBOutlet weak var currentTemperature: UILabel!
    
    
    @IBOutlet weak var weatherCondition: UILabel!
    
    
    @IBOutlet weak var highTemperature: UILabel!
    
    
    @IBOutlet weak var lowTemperature: UILabel!
    @IBOutlet weak var forecastTable: UITableView!
    
    var forecastDays: [ForecastDay] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        loadWeather(search: coordinate) { weatherResponse in
            if let weatherData = weatherResponse {
                
                DispatchQueue.main.async {
                    self.locationNameLabel.text = weatherData.location.name
                    self.currentTemperature.text = "\(weatherData.current.temp_c)°C"
                    self.weatherCondition.text = weatherData.current.condition.text
                    if let forecastDay = weatherData.forecast.forecastday.first {
                        self.lowTemperature.text = "Low: \(forecastDay.day.mintemp_c)°C"
                        self.highTemperature.text = "High: \(forecastDay.day.maxtemp_c)°C"
                    }
                    
                    self.forecastDays = weatherData.forecast.forecastday
                    self.forecastTable.reloadData()
                }
                
            } else {
                print("Cannot load weather")
            }
        }
        
        forecastTable.delegate = self
        forecastTable.dataSource = self
        forecastTable.register(UITableViewCell.self, forCellReuseIdentifier: "forecastCell")
        
        
        // Do any additional setup after loading the view.
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
    
    
    private func getUrl(query: String) -> URL? {
        let baseUrl = "https://api.weatherapi.com"
        let endpoint = "/v1/forecast.json"
        let apiKey = "cf846bd7fcce44f797031444230904"
        guard let url = "\(baseUrl)\(endpoint)?key=\(apiKey)&q=\(query)&days=7"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        print(url)
        
        return URL(string: url)
    }
    
    
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forecastDays.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "forecastCell", for: indexPath)
        let forecastDay = forecastDays[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = forecastDay.date
        content.secondaryText = "High: \(forecastDay.day.maxtemp_c)°C, Low: \(forecastDay.day.mintemp_c)°C"
        
        setImageFromUrl("https:\(forecastDay.day.condition.icon)") { image in
            DispatchQueue.main.async {
                content.image = image
                cell.contentConfiguration = content
            }
        }
        
        return cell
    }

    func setImageFromUrl(_ urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
    }

}
