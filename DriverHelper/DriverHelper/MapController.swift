import Foundation
import UIKit
import MapKit
import Contacts

var routes: Set<Route> = Set<Route>()

let routes_lock = NSLock()


var routes_to_draw: Set<Route> = Set<Route>()

let routes_to_draw_lock = NSLock()


class MapController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var bottom_field: UITabBarItem!
    let initialLocation = CLLocationCoordinate2D(latitude: 55.5, longitude: 37.5)
    let regionRadius: CLLocationDistance = 100000
    
    
    var self_name: String = ""
    var self_color: UIColor = .systemRed
    
    var lastPressIsStart = false
    var lastStartCoordinate = CLLocationCoordinate2D()
    
    let update_lock = NSLock()
    var need_to_update = false
    
    override func loadView() {
        update_lock.lock()
        
        need_to_update = true
        
        update_lock.unlock()
        
        super.loadView()
        self_name = GetLogin()!
        self_color = ColorFromName(name: self_name)
        let net_routes = User.main_user!.GetMap()
        for net_route in net_routes.routes {
            let route = Route(name: net_route.owner, startCoordinate: net_route.start, finishCoordinate: net_route.finish, initialColor: ColorFromName(name: net_route.owner))

            routes_lock.lock()
            routes_to_draw_lock.lock()

            if !routes.contains(route) {
                routes_to_draw.insert(route)
            }

            routes_to_draw_lock.unlock()
            routes_lock.unlock()
        }
        DrawRoutes()
        AddTapRecognizer()
        RepeatUpdateMap()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        update_lock.lock()
        
        if !need_to_update {
            need_to_update = true
            update_lock.unlock()
            RepeatUpdateMap()
        } else {
            need_to_update = true
            update_lock.unlock()
        }
        
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        update_lock.lock()
        
        need_to_update = false
        
        update_lock.unlock()
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
        
        for route in routes_to_draw {
//            mapView.addAnnotation(route.start)
//            mapView.addAnnotation(route.finish)
//
//            let request = MKDirections.Request()
//            request.source = MKMapItem(placemark: MKPlacemark(coordinate: route.start.coordinate))
//            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: route.finish.coordinate))
//            request.transportType = .automobile
//            let direction = MKDirections(request: request)
//
//            direction.calculate { [self] response, error in
//                if let routeResponse = response?.routes {
//                    let polyline = PolylineWithColor(points: routeResponse[0].polyline.points(), count: routeResponse[0].polyline.pointCount)
//                    polyline.color = route.color
//                    self.mapView.addOverlay(polyline)
//                }
//            }
            Routes.DrawOne(map_view: mapView, route: route)
        }
        routes_lock.lock()
        routes_to_draw_lock.lock()
        
        routes.formUnion(routes_to_draw)
        routes_to_draw.removeAll()
        
        routes_lock.unlock()
        routes_to_draw_lock.unlock()
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
                
                let net_route = NetworkRoute(start: lastStartCoordinate, finish: tappedCoordinate, owner: self_name, date: Date())
                
                routes_lock.lock()
                
                routes.insert(Route(name: self_name, startCoordinate: lastStartCoordinate, finishCoordinate: tappedCoordinate, initialColor: self_color))
                
                routes_lock.unlock()
                
                User.main_user?.AddRoute(route: net_route)
                let direction = MKDirections(request: request)
                
                direction.calculate { [self] response, error in
                    if let routeResponse = response?.routes {
                        let polyline = PolylineWithColor(points: routeResponse[0].polyline.points(), count: routeResponse[0].polyline.pointCount)
                        polyline.color = self_color
                        self.mapView.addOverlay(polyline)
                    }
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
    func UpdateMap() {
        update_lock.lock()
        if !need_to_update {
            update_lock.unlock()
            return
        }
        update_lock.unlock()
        let net_routes = User.main_user!.GetMap()
        for net_route in net_routes.routes {
            let route = Route(name: net_route.owner, startCoordinate: net_route.start, finishCoordinate: net_route.finish, initialColor: ColorFromName(name: net_route.owner))
            
            routes_lock.lock()
            routes_to_draw_lock.lock()
            
            if !routes.contains(route) {
                routes_to_draw.insert(route)
            }
            
            routes_to_draw_lock.unlock()
            routes_lock.unlock()
        }
        DrawRoutes()
        RepeatUpdateMap()
    }
    func RepeatUpdateMap() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) // - выполнить через 15 сек.
        { [self] in
           UpdateMap()
        }
    }
}

func ColorFromName(name: String) -> UIColor {
    let name_to_color_table: [Character: UIColor] = [
        "a": UIColor(red: 4/255, green: 59/255, blue: 92/255, alpha: 1),
        "b": UIColor(red: 40/255, green: 67/255, blue: 135/255, alpha: 1),
        "c": UIColor(red: 205/255, green: 209/255, blue: 228/255, alpha: 1),
        "d": UIColor(red: 15/255, green: 10/255, blue: 222/255, alpha: 1),
        "e": UIColor(red: 82/255, green: 78/255, blue: 183/255, alpha: 1),
        "f": UIColor(red: 52/255, green: 45/255, blue: 113/255, alpha: 1),
        "g": UIColor(red: 1/255, green: 1/255, blue: 122/255, alpha: 1),
        "h": UIColor(red: 37/255, green: 41/255, blue: 88/255, alpha: 1),
        "i": UIColor.systemRed,
        "j": UIColor.systemPink,
        "k": UIColor.systemBlue,
        "l": UIColor.systemCyan,
        "m": UIColor.systemPink,
        "n": UIColor.systemTeal,
        "o": UIColor.systemMint,
        "p": UIColor.systemIndigo,
        "q": UIColor.systemOrange,
        "r": UIColor.systemPurple,
        "s": UIColor.systemGreen,
        "t": UIColor.red,
        "u": UIColor(red: 1/255, green: 1/255, blue: 122/255, alpha: 1),
        "v": UIColor.systemIndigo,
        "w": UIColor.systemOrange,
        "x": UIColor.systemRed,
        "y": UIColor(red: 1/255, green: 1/255, blue: 122/255, alpha: 1),
        "z": UIColor.systemGreen
    ]
    let lower_name = name.lowercased()
    let first_character: Character = lower_name[lower_name.startIndex]
    
    if name_to_color_table[first_character] != nil {
        return name_to_color_table[first_character]!
    }
    return UIColor.systemGreen
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

class Route : Hashable {
    static func == (lhs: Route, rhs: Route) -> Bool {
        return lhs.start.coordinate.latitude == rhs.start.coordinate.latitude &&
        lhs.start.coordinate.longitude == rhs.start.coordinate.longitude &&
        lhs.finish.coordinate.latitude == rhs.finish.coordinate.latitude &&
        lhs.finish.coordinate.longitude == rhs.finish.coordinate.longitude &&
        lhs.start.text == rhs.start.text
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(start.coordinate.latitude)
        hasher.combine(start.coordinate.longitude)
        hasher.combine(finish.coordinate.latitude)
        hasher.combine(finish.coordinate.longitude)
        hasher.combine(start.text)
    }
    
    let start: Point
    let finish: Point
    let color : UIColor
    
    init(name: String, startCoordinate: CLLocationCoordinate2D, finishCoordinate: CLLocationCoordinate2D, initialColor: UIColor) {
        start = Point(initialCoordinate: startCoordinate, initialColor: initialColor, initialText: String(name[name.startIndex]))
        finish = Point(initialCoordinate: finishCoordinate, initialColor: initialColor, initialText: nil)
        color = initialColor
    }
}

class Routes {
    init () {
        drawn_routes_ = Set<Route>()
        new_routes_ = Set<Route>()
        deleted_routes_ = Set<Route>()
        mutex_drawn_routes_ = NSLock()
        mutex_new_routes_ = NSLock()
        mutex_deleted_routes_ = NSLock()
    }
    func Insert(route: Route) {
        mutex_deleted_routes_.lock()
        deleted_routes_.remove(route)
        mutex_deleted_routes_.unlock()
        
        mutex_new_routes_.lock()
        new_routes_.insert(route)
        mutex_new_routes_.unlock()
    }
    func Erase(route: Route) {
        mutex_new_routes_.lock()
        new_routes_.remove(route)
        mutex_new_routes_.unlock()
        
        mutex_deleted_routes_.lock()
        deleted_routes_.insert(route)
        mutex_deleted_routes_.unlock()
    }
    func Assign(routes_set: Set<Route>) {
        mutex_new_routes_.lock()
        mutex_deleted_routes_.lock()
        mutex_drawn_routes_.lock()
        
        let to_add = routes_set.subtracting(drawn_routes_)
        new_routes_ = new_routes_.union(to_add)
        deleted_routes_ = deleted_routes_.subtracting(to_add)
        
        let to_delete = drawn_routes_.subtracting(routes_set)
        deleted_routes_ = deleted_routes_.union(to_delete)
        new_routes_ = new_routes_.subtracting(to_delete)

        mutex_drawn_routes_.unlock()
        mutex_deleted_routes_.unlock()
        mutex_new_routes_.unlock()
    }
    static func DrawOne(map_view: MKMapView, route: Route) {
        map_view.addAnnotation(route.start)
        map_view.addAnnotation(route.finish)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: route.start.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: route.finish.coordinate))
        request.transportType = .automobile
        let direction = MKDirections(request: request)
        
        direction.calculate { [] response, error in
            if let routeResponse = response?.routes {
                let polyline = PolylineWithColor(points: routeResponse[0].polyline.points(), count: routeResponse[0].polyline.pointCount)
                polyline.color = route.color
                map_view.addOverlay(polyline)
            }
        }
    }
    static func RemoveOne(map_view: MKMapView, route: Route) {
        map_view.removeAnnotation(route.start)
        map_view.removeAnnotation(route.finish)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: route.start.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: route.finish.coordinate))
        request.transportType = .automobile
        let direction = MKDirections(request: request)
        
        direction.calculate { [] response, error in
            if let routeResponse = response?.routes {
                let polyline = PolylineWithColor(points: routeResponse[0].polyline.points(), count: routeResponse[0].polyline.pointCount)
                polyline.color = route.color
                map_view.removeOverlay(polyline)
            }
        }
    }
    func Draw(map_view: MKMapView) {
        mutex_new_routes_.lock()
        for route in new_routes_ {
            Routes.DrawOne(map_view: map_view, route: route)
        }
        mutex_new_routes_.unlock()
        
        mutex_deleted_routes_.lock()
        for route in deleted_routes_ {
            Routes.RemoveOne(map_view: map_view, route: route)
        }
        mutex_deleted_routes_.unlock()
        
        mutex_new_routes_.lock()
        mutex_deleted_routes_.lock()
        mutex_drawn_routes_.lock()
        
        drawn_routes_ = drawn_routes_.union(new_routes_)
        drawn_routes_ = drawn_routes_.subtracting(deleted_routes_)
        new_routes_.removeAll()
        deleted_routes_.removeAll()
        
        mutex_drawn_routes_.unlock()
        mutex_deleted_routes_.unlock()
        mutex_new_routes_.unlock()
    }
    private var mutex_drawn_routes_: NSLock
    private var drawn_routes_: Set<Route>
    private var mutex_new_routes_: NSLock
    private var new_routes_: Set<Route>
    private var mutex_deleted_routes_: NSLock
    private var deleted_routes_: Set<Route>
}

class RoutesController {
    private var routes_: Routes
    private var need_to_update_: Bool
    private var mutex_update_: NSLock
    private var need_to_draw_: Bool
    private var mutex_draw_: NSLock
    init() {
        routes_ = Routes()
        need_to_update_ = false
        mutex_update_ = NSLock()
        need_to_draw_ = false
        mutex_draw_ = NSLock()
    }
    func Update() -> Void {
        let net_routes = User.main_user!.GetMap()
        var routes_set = Set<Route>()
        for net_route in net_routes.routes {
            let route = Route(name: net_route.owner, startCoordinate: net_route.start, finishCoordinate: net_route.finish, initialColor: ColorFromName(name: net_route.owner))
            routes_set.insert(route)
        }
        routes_.Assign(routes_set: routes_set)
    }
    func StartRepeatAsyncUpdate(period: Double) -> Void {
        DispatchQueue.main.asyncAfter(deadline: .now() + period) { [self] in
            self.Update()
            
            var need_to_update = false
            self.mutex_update_.lock()
            need_to_update = self.need_to_update_
            self.mutex_update_.unlock()
            
            if need_to_update {
                self.StartRepeatAsyncUpdate(period: period)
            }
        }
    }
    func RepeatUpdate(period: Double) -> Void {
        need_to_update_ = true
        StartRepeatAsyncUpdate(period: period)
    }
    func StartRepeatAsyncDraw(map_view: MKMapView, period: Double) -> Void {
        DispatchQueue.main.asyncAfter(deadline: .now() + period) { [self] in
            self.routes_.Draw(map_view: map_view)
            
            var need_to_draw = false
            self.mutex_draw_.lock()
            need_to_draw = self.need_to_draw_
            self.mutex_draw_.unlock()
            
            if need_to_draw {
                self.StartRepeatAsyncDraw(map_view: map_view, period: period)
            }
        }
    }
    func RepeatDraw(map_view: MKMapView, period: Double) -> Void {
        need_to_draw_ = true
        StartRepeatAsyncDraw(map_view: map_view, period: period)
    }
}

//var routes: [Route] = [Route(name: "Alina", startCoordinate:  CLLocationCoordinate2D(latitude: 55.1, longitude: 37.2), finishCoordinate: CLLocationCoordinate2D(latitude: 55.5, longitude: 37.3), initialColor: .systemPink),
//                       Route(name: "Maria", startCoordinate: CLLocationCoordinate2D(latitude: 55, longitude: 37), finishCoordinate: CLLocationCoordinate2D(latitude: 56, longitude: 38), initialColor: .purple),
//                       Route(name: "Leonid", startCoordinate: CLLocationCoordinate2D(latitude: 55.8, longitude: 37.6), finishCoordinate:  CLLocationCoordinate2D(latitude: 55.1, longitude: 37.4), initialColor: .systemBlue)]

