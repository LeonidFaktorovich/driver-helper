import Foundation
import UIKit
import MapKit
import Contacts

struct MapPoint : Codable {
    let x: Double
    let y: Double
    
    enum CodingKeys: String, CodingKey {
        case x = "x"
        case y = "y"
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
    }
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

struct NetworkRoute : Codable {
    let start: MapPoint
    let finish: MapPoint
    let owner: String
    let date_start: String
    let time_start: String
    
    enum CodingKeys: String, CodingKey {
        case start = "start"
        case finish = "finish"
        case owner = "owner"
        case date_start = "date_start"
        case time_start = "time_start"
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(start, forKey: .start)
        try container.encode(finish, forKey: .finish)
        
        let base_owner: String = owner.base64Encoded()
        try container.encode(base_owner, forKey: .owner)
        
        let base_date_start: String = date_start.base64Encoded()
        try container.encode(base_date_start, forKey: .date_start)
        
        let base_time_start: String = time_start.base64Encoded()
        try container.encode(base_time_start, forKey: .time_start)
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        start = try container.decode(MapPoint.self, forKey: .start)
        finish = try container.decode(MapPoint.self, forKey: .finish)
        owner = try container.decode(String.self, forKey: .owner).base64Decoded()
        date_start = try container.decode(String.self, forKey: .date_start).base64Decoded()
        time_start = try container.decode(String.self, forKey: .time_start).base64Decoded()
    }
    init(start: MapPoint, finish: MapPoint, owner: String, date: Date) {
        self.start = start
        self.finish = finish
        self.owner = owner
        
        let date_formatter = DateFormatter()
        date_formatter.dateFormat = "yyyy-MM-dd"
        self.date_start = date_formatter.string(from: date)
        let time_formatter = DateFormatter()
        time_formatter.dateFormat = "HH:mm"
        self.time_start = time_formatter.string(from: date)
    }
}

class MapController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    let initialLocation = CLLocationCoordinate2D(latitude: 55.5, longitude: 37.5)
    let regionRadius: CLLocationDistance = 100000
    
    
    let self_name = "Alina"
    let self_color: UIColor = .systemPink
    
    var lastPressIsStart = false
    var lastStartCoordinate = CLLocationCoordinate2D()
    
    override func loadView() {
        super.loadView()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DrawRoutes()
        AddTapRecognizer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKMarkerAnnotationView
        view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "point")
        
        if let annotation = annotation as? Point {
            view.markerTintColor = annotation.color
            if annotation.text != nil {
                view.glyphText = annotation.text
            } else {
                view.glyphImage = UIImage(#imageLiteral(resourceName: "Attachments/flag"))
            }
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let pr = MKPolylineRenderer(overlay: overlay)
        pr.lineWidth = 6
        
        if let polyline = overlay as? PolylineWithColor {
            pr.strokeColor = polyline.color
        }
        return pr
    }
    
    func DrawRoutes() {
        mapView.delegate = self
        mapView.setRegion(MKCoordinateRegion(center: initialLocation, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius), animated: true)
        
        for route in routes {
            mapView.addAnnotation(route.start)
            mapView.addAnnotation(route.finish)
            
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: route.start.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: route.finish.coordinate))
            request.transportType = .automobile
            let direction = MKDirections(request: request)
            
            direction.calculate { [self] response, error in
                if let routeResponse = response?.routes {
                    let polyline = PolylineWithColor(points: routeResponse[0].polyline.points(), count: routeResponse[0].polyline.pointCount)
                    polyline.color = route.color
                    self.mapView.addOverlay(polyline)
                }
            }
        }
    }
    
    @IBAction func tapMap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            let tappedCoordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
            let point: Point
            if lastPressIsStart {
                point = Point(initialCoordinate: tappedCoordinate, initialColor: self_color, initialText: nil)
                
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: lastStartCoordinate))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: tappedCoordinate))
                request.transportType = .automobile
                
                let x_start: Double = lastStartCoordinate.latitude
                let y_start: Double = lastStartCoordinate.longitude
                let x_finish: Double = tappedCoordinate.latitude
                let y_finish: Double = tappedCoordinate.longitude
                let start_point = MapPoint(x: x_start, y: y_start)
                let finish_point = MapPoint(x: x_finish, y: y_finish)
                let net_route = NetworkRoute(start: start_point, finish: finish_point, owner: self_name, date: Date())
                main_user?.AddRoute(route: net_route)
                
                let direction = MKDirections(request: request)
                
                direction.calculate { [self] response, error in
                    if let routeResponse = response?.routes {
                        let polyline = PolylineWithColor(points: routeResponse[0].polyline.points(), count: routeResponse[0].polyline.pointCount)
                        polyline.color = self_color
                        self.mapView.addOverlay(polyline)
                    }
                    //guard let route = response?.routes.first else { return }
                }
            } else {
                point = Point(initialCoordinate: tappedCoordinate, initialColor: self_color, initialText: String(self_name[self_name.startIndex]))
                lastStartCoordinate = tappedCoordinate
            }
            lastPressIsStart = !lastPressIsStart
            mapView.addAnnotation(point)
            
            
            /*let address = CLGeocoder.init()
            address.reverseGeocodeLocation(CLLocation(latitude: point.coordinate.latitude, longitude: point.coordinate.longitude)) { (places, error) in
                    if error == nil{
                        if let place = places{
                            let address = place[0].postalAddress
                            if ((address) != nil) {
                                print(CNPostalAddressFormatter.string(from: address!, style: .mailingAddress))
                            }
                        }
                    }
                }*/
        }
    }
    
    func AddTapRecognizer() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapMap(_:)))
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.numberOfTapsRequired = 1
        mapView.addGestureRecognizer(tapRecognizer)
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: nil)
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        mapView.addGestureRecognizer(doubleTapRecognizer)

        tapRecognizer.require(toFail: doubleTapRecognizer)
    }
}

class Point : NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let color: UIColor
    let text: String?
    
    init(initialCoordinate: CLLocationCoordinate2D, initialColor: UIColor, initialText: String?) {
        self.coordinate = initialCoordinate
        self.color = initialColor
        self.text = initialText
        super.init()
    }
}

class PolylineWithColor : MKPolyline {
    var color : UIColor = .blue
}

class Route {
    let start: Point
    let finish: Point
    let color : UIColor
    
    init(name: String, startCoordinate: CLLocationCoordinate2D, finishCoordinate: CLLocationCoordinate2D, initialColor: UIColor) {
        start = Point(initialCoordinate: startCoordinate, initialColor: initialColor, initialText: String(name[name.startIndex]))
        finish = Point(initialCoordinate: finishCoordinate, initialColor: initialColor, initialText: nil)
        color = initialColor
    }
}

var routes: [Route] = [Route(name: "Alina", startCoordinate:  CLLocationCoordinate2D(latitude: 55.1, longitude: 37.2), finishCoordinate: CLLocationCoordinate2D(latitude: 55.5, longitude: 37.3), initialColor: .systemPink),
                       Route(name: "Maria", startCoordinate: CLLocationCoordinate2D(latitude: 55, longitude: 37), finishCoordinate: CLLocationCoordinate2D(latitude: 56, longitude: 38), initialColor: .purple),
                       Route(name: "Leonid", startCoordinate: CLLocationCoordinate2D(latitude: 55.8, longitude: 37.6), finishCoordinate:  CLLocationCoordinate2D(latitude: 55.1, longitude: 37.4), initialColor: .systemBlue)]
