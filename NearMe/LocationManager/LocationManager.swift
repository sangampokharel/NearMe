//
//  LocationManager.swift
//  NearMe
//
//  Created by EKbana on 13/05/2025.
//

import CoreLocation
import MapKit

enum LocationError:LocalizedError {
    case locationDenied,
         locationRestricted,
         locationNotFound,
         locationNetworkError
    
    var errorDescription: String? {
        switch self {
        case .locationDenied:
            return "Your have denied your location please enable it through settings"
        case .locationRestricted:
            return "Your location has been restricted please enable it through settings"
        case .locationNotFound:
            return "Your location is not accurate please enable it through settings"
        case .locationNetworkError:
            return "Something went wrong with location"
        }
    }
}

class LocationManager:NSObject,CLLocationManagerDelegate,ObservableObject {
    static let shared = LocationManager()
    
    let clManager = CLLocationManager()
   @Published var region:MKCoordinateRegion = MKCoordinateRegion()
    var error:LocationError? = nil
    
    private override init() {
        super.init()
        clManager.delegate = self
    }
}

extension LocationManager {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.last.map {
            region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
            
        case .notDetermined:
            clManager.requestWhenInUseAuthorization()
        case .restricted:
            error = .locationRestricted
        case .denied:
            error = .locationDenied
        case .authorizedAlways, .authorizedWhenInUse:
            clManager.requestLocation()
            
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                self.error = LocationError.locationDenied
            case .network:
                self.error = LocationError.locationNetworkError
            default:
                print(error)
            }
        }
        
    }
}
