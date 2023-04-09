//
//  DetailsViewController.swift
//  project_2
//
//  Created by Account on 2023-04-08.
//

import UIKit

class DetailsViewController: UIViewController, UITextFieldDelegate {
    
    weak var delegate: DetailsViewControllerDelegate?
    
    @IBOutlet weak var conditionsLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var tempratureLabel: UILabel!
    @IBOutlet weak var locationName: UILabel!
    
    var cel: Float = 0.00
    var far: Float = 0.00
    var toggle = true
    var responseData: WeatherResponse?
    let firstScreen = "firstScreen"

    override func viewDidLoad() {
        searchTextField.delegate = self

        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        loadWeather(search: searchTextField.text)
        textField.endEditing(true)
        return true
    }
    
    @IBAction func tempratureTypeBtn(_ sender: UIButton) {
        if toggle {
            tempratureLabel.text = "\(far)°F"
            toggle = false
        } else {
            tempratureLabel.text = "\(cel)°C"
            toggle = true
        }
    }
    
    
    @IBAction func search(_ sender: UIButton) {
        loadWeather(search: searchTextField.text)

    }
    
    @IBAction func cancelBtn(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func addWeatherLocationBtn(_ sender: Any) {
        
        if let responseData = self.responseData {
            delegate?.didAddWeatherData(responseData)
        }
        dismiss(animated: true)
    }
    
    func loadWeather(search: String?) {
        guard let search = search else {
            return
        }
        
        guard let url = getUrl(query: search) else {
            print("Could not get url")
            return
        }
        
        let urlSession = URLSession.shared
        
        let dataTask = urlSession.dataTask(with: url) { data, response, error in
            print("Network call complete")
            
            guard let data = data else {
                print("No data found")
                return
            }
            
            
            if let weatherResponse = self.parseJson(data: data) {
                
                self.responseData = weatherResponse
                
                self.cel = weatherResponse.current.temp_c
                self.far = weatherResponse.current.temp_f
                
                self.setImageFromUrl("https:\(weatherResponse.current.condition.icon)", on: self.weatherImage)
                DispatchQueue.main.async {
                    
                    if weatherResponse.current.is_day == 1 {
                        self.view.layer.contents = UIImage(named: "day_1")?.cgImage
                        self.tempratureLabel.textColor = UIColor.black
                        self.locationName.textColor = UIColor.black
                        self.searchTextField.backgroundColor = UIColor.white

                    } else {
                        self.view.layer.contents = UIImage(named: "urban")?.cgImage
                        self.tempratureLabel.textColor = UIColor.yellow
                        self.locationName.textColor = UIColor.white
                        self.searchTextField.backgroundColor = UIColor.gray
                    }
                    
                    self.locationName.text = weatherResponse.location.name
                    self.tempratureLabel.text = "\(weatherResponse.current.temp_c)°C"
                    self.conditionsLabel.text = weatherResponse.current.condition.text
                    
                }
            }
        }
        
        dataTask.resume()
        
    }
    
    
    func setImageFromUrl(_ urlString: String, on imageView: UIImageView) {
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                imageView.image = image
            }
        }
        
        task.resume()
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
    
}

protocol DetailsViewControllerDelegate: AnyObject {
    func didAddWeatherData(_ data: WeatherResponse)
}



