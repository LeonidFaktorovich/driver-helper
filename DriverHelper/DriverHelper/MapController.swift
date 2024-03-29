import Foundation
import UIKit
import MapKit
import Contacts

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class MapController: UIViewController, MKMapViewDelegate, HandleMapSearch {
    private let bottomView = RouteView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height, width: UIScreen.main.bounds.width, height: 200))
    private let bottomViewController = RouteViewController()
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var bottom_field: UITabBarItem!
    let initialLocation = CLLocationCoordinate2D(latitude: 55.5, longitude: 37.5)
    let regionRadius: CLLocationDistance = 100000
    
    
    @IBOutlet weak var route_info: UILabel!
    var self_name: String = ""
    var self_color: UIColor = .systemRed
    
    var lastPressIsStart = false
    var lastStartCoordinate = CLLocationCoordinate2D()
    var lastStartPointMarkerView : PointMarkerView?
    
    let update_lock = NSLock()
    var need_to_update = false
    
    var resultSearchController:UISearchController? = nil
    
    var lastDate : String = ""
    
    override func loadView() {
        
        super.loadView()
        self_name = GetLogin()!
        self_color = ColorFromName(name: self_name)
        AddTapRecognizer()
        User.main_user?.routes_controller_.RepeatUpdateAndDraw(map_view: mapView, period: 10.0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(bottomViewController)
        bottomViewController.didMove(toParent: self)
        view.addSubview(bottomView)
        bottomViewController.SetRouteView(route_view: bottomView)
        // добавьте обработчик жеста свайпа вниз
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissBottomView))
        swipeGesture.direction = .down
        bottomView.addGestureRecognizer(swipeGesture)
        
        mapView.delegate = self
        mapView.setRegion(MKCoordinateRegion(center: initialLocation, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius), animated: true)
        
        let searchTable = storyboard!.instantiateViewController(withIdentifier: "SearchTableController") as! SearchTableController
        resultSearchController = UISearchController(searchResultsController: searchTable)
        resultSearchController?.searchResultsUpdater = searchTable
        
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Enter location"
        navigationItem.titleView = resultSearchController?.searchBar
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        searchTable.mapView = mapView
        searchTable.handleMapSearchDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {

        User.main_user?.routes_controller_.RepeatUpdateAndDraw(map_view: mapView, period: 10.0)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        User.main_user?.routes_controller_.CancelRepeatUpdateAndDraw()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var view: PointMarkerView
        view = PointMarkerView(annotation: annotation, reuseIdentifier: "point")

        if let annotation = annotation as? Point {

            view.addOwner(name: self_name)
            view.addDate(date: lastDate)
            if annotation.type == PointType.start {
                lastStartPointMarkerView = view
            } else {
                view.addStart(coordinate: lastStartCoordinate)
                lastStartPointMarkerView?.addFinish(coordinate: annotation.coordinate)
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
    
    // вызывается когда мы нажимаем на начало или на конец маршрута
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // here view.isSelected = true
        guard let marker_view = view as? MKMarkerAnnotationView else {
            return
        }
        UIView.animate(withDuration: 0.3) {
                    self.bottomView.frame.origin.y = UIScreen.main.bounds.height - self.bottomView.frame.height
        }
//        route_info.isHidden = false
        // marker_view.image = User.main_user?.avatar
    }
    
    // вызывается когда мы отпускаем начало или конец маршрута
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        // here view.isSelected = false
        guard let marker_view = view as? MKMarkerAnnotationView else {
            return
        }
        marker_view.image = nil
//        route_info.isHidden = true
    }
    
    @objc func dismissBottomView() {
        UIView.animate(withDuration: 0.3) {
            self.bottomView.frame.origin.y = UIScreen.main.bounds.height
            self.view.layoutIfNeeded()
        }
    }
    
    func getDateOfTrip() {
        
        let alertController = UIAlertController(title: "Enter the date and time of your trip", message: "\n\n\n", preferredStyle: .actionSheet)

        let datePicker = UIDatePicker(frame: CGRect(x: 50, y: 50, width: 270, height: 216))
        datePicker.datePickerMode = .dateAndTime
        alertController.view.addSubview(datePicker)

        let submitAction = UIAlertAction(title: "Submit", style: .cancel) { (action) in
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let date = dateFormatter.string(from: datePicker.date)
            self.lastDate = date
            print(self.lastDate)
        }
        
        alertController.addAction(submitAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func tapMap(_ sender: UITapGestureRecognizer) {

        if sender.state == .ended {
            let tappedCoordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
            let point: Point
            if lastPressIsStart {
                point = Point(initialType: PointType.finish, initialCoordinate: tappedCoordinate, initialColor: self_color, initialText: nil)
                
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: lastStartCoordinate))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: tappedCoordinate))
                request.transportType = .automobile
                
                let net_route = NetworkRoute(start: lastStartCoordinate, finish: tappedCoordinate, owner: self_name, date: Date())
                DispatchQueue.global().async {
                    User.main_user?.AddRoute(route: net_route)
                }
                let new_route = Route(name: self_name, startCoordinate: lastStartCoordinate, finishCoordinate: tappedCoordinate, initialColor: self_color)
                Routes.DrawOne(map_view: mapView, route: new_route)
                User.main_user?.routes_controller_.Insert(route: new_route)
                
                getDateOfTrip()
            } else {
                point = Point(initialType: PointType.start, initialCoordinate: tappedCoordinate, initialColor: self_color, initialText: String(self_name[self_name.startIndex]))
                lastStartCoordinate = tappedCoordinate
            }
            lastPressIsStart = !lastPressIsStart
            mapView.addAnnotation(point)
            
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
    
    func dropPinZoomIn(placemark:MKPlacemark){
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        let point: Point
        if lastPressIsStart {
            point = Point(initialType: PointType.finish, initialCoordinate: placemark.coordinate, initialColor: self_color, initialText: nil)
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: lastStartCoordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: placemark.coordinate))
            request.transportType = .automobile
            
            let net_route = NetworkRoute(start: lastStartCoordinate, finish: placemark.coordinate, owner: self_name, date: Date())
            DispatchQueue.global().async {
                User.main_user?.AddRoute(route: net_route)
            }
            let new_route = Route(name: self_name, startCoordinate: lastStartCoordinate, finishCoordinate: placemark.coordinate, initialColor: self_color)
            Routes.DrawOne(map_view: mapView, route: new_route)
            User.main_user?.routes_controller_.Insert(route: new_route)
            
            getDateOfTrip()
        } else {
            point = Point(initialType: PointType.start, initialCoordinate: placemark.coordinate, initialColor: self_color, initialText: String(self_name[self_name.startIndex]))
            lastStartCoordinate = placemark.coordinate
        }
        lastPressIsStart = !lastPressIsStart
        mapView.addAnnotation(point)
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

enum PointType {
    case start
    case finish
}

class Point : NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let color: UIColor
    let text: String?
    let type: PointType

    init(initialType: PointType, initialCoordinate: CLLocationCoordinate2D, initialColor: UIColor, initialText: String?) {
        self.coordinate = initialCoordinate
        self.color = initialColor
        self.text = initialText
        self.type = initialType
        super.init()
    }
}

class PointMarkerView : MKMarkerAnnotationView {
    var owner : String?
    var start : String?
    var finish : String?
    var date : String?
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let point = newValue as? Point else {
                return
            }
            canShowCallout = true
            
            
            markerTintColor = point.color
            if point.type  == PointType.start {
                glyphText = point.text
                start = parseAddress(coordinate: point.coordinate)
            } else {
                glyphImage = UIImage(#imageLiteral(resourceName: "Attachments/flag"))
                finish = parseAddress(coordinate: point.coordinate)
            }
        }
    }
    
    func addStart(coordinate: CLLocationCoordinate2D) {
        start = parseAddress(coordinate: coordinate)
    }
    
    func addFinish(coordinate: CLLocationCoordinate2D) {
        finish = parseAddress(coordinate: coordinate)
    }
    
    func addOwner(name : String) {
        owner = name
    }
    
    func addDate(date : String) {
        self.date = date
    }
    
    func parseAddress(coordinate: CLLocationCoordinate2D) -> String {
        let placemark = MKPlacemark(coordinate: coordinate)
        let comma = (placemark.administrativeArea != nil && placemark.locality != nil) ? ", " : ""
        
        let addressLine = String(
            format:"%@%@%@",
            placemark.administrativeArea ?? "",
            comma,
            placemark.locality ?? ""
        )

        return addressLine
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
        start = Point(initialType: PointType.start, initialCoordinate: startCoordinate, initialColor: initialColor, initialText: String(name[name.startIndex]))
        finish = Point(initialType: PointType.finish, initialCoordinate: finishCoordinate, initialColor: initialColor, initialText: nil)
        color = initialColor
    }
}

class Routes {
    init () {
        drawn_routes_ = Set<Route>()
        new_routes_ = Set<Route>()
        deleted_routes_ = Set<Route>()
    }
    func Insert(route: Route) {
        deleted_routes_.remove(route)
        
        new_routes_.insert(route)
    }
    func Erase(route: Route) {
        new_routes_.remove(route)
        
        deleted_routes_.insert(route)
    }
    func Assign(routes_set: Set<Route>) {
        
        let to_add = routes_set.subtracting(drawn_routes_)
        new_routes_ = new_routes_.union(to_add)
        deleted_routes_ = deleted_routes_.subtracting(to_add)
        
        let to_delete = drawn_routes_.subtracting(routes_set)
        deleted_routes_ = deleted_routes_.union(to_delete)
        new_routes_ = new_routes_.subtracting(to_delete)
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
            guard let route = response?.routes.first else {
                return
            }
            map_view.removeOverlay(route.polyline)
        }
    }
    func Draw(map_view: MKMapView) {
        for route in new_routes_ {
            Routes.DrawOne(map_view: map_view, route: route)
        }
        for route in deleted_routes_ {
            Routes.RemoveOne(map_view: map_view, route: route)
        }
        
        drawn_routes_ = drawn_routes_.union(new_routes_)
        drawn_routes_ = drawn_routes_.subtracting(deleted_routes_)
        new_routes_.removeAll()
        deleted_routes_.removeAll()
    }
    private var drawn_routes_: Set<Route>
    private var new_routes_: Set<Route>
    private var deleted_routes_: Set<Route>
}

class RoutesController {
    private var routes_: Routes
    private var need_update_and_draw_: Bool
    private var mutex_update_and_draw_: NSLock
    private var async_task_: Bool
    private var mutex_update_: NSLock
    init() {
        routes_ = Routes()
        need_update_and_draw_ = false
        async_task_ = false
        mutex_update_and_draw_ = NSLock()
        mutex_update_ = NSLock()
    }
    private func Update() -> Void {
        let net_routes = User.main_user!.GetMap()
        var routes_set = Set<Route>()
        for net_route in net_routes.routes {
            let route = Route(name: net_route.owner, startCoordinate: net_route.start, finishCoordinate: net_route.finish, initialColor: ColorFromName(name: net_route.owner))
            routes_set.insert(route)
        }
        routes_.Assign(routes_set: routes_set)
    }
    func Insert(route: Route) {
        mutex_update_.lock()
        routes_.Insert(route: route)
        mutex_update_.unlock()
    }
    func Erase(route: Route) {
        mutex_update_.lock()
        routes_.Erase(route: route)
        mutex_update_.unlock()
    }
    func StartRepeatAsyncUpdateAndDraw(map_view: MKMapView, period: Double) -> Void {
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + period) { [self] in
            self.mutex_update_.lock()
            self.Update()
            self.routes_.Draw(map_view: map_view)
            self.mutex_update_.unlock()
            
            self.mutex_update_and_draw_.lock()
            guard self.need_update_and_draw_ else {
                self.async_task_ = false
                self.mutex_update_and_draw_.unlock()
                return
            }
            self.mutex_update_and_draw_.unlock()
            self.StartRepeatAsyncUpdateAndDraw(map_view: map_view, period: period)
        }
    }
    private func Draw(map_view: MKMapView) -> Void {
        self.routes_.Draw(map_view: map_view)
    }
    func RepeatUpdateAndDraw(map_view: MKMapView, period: Double) -> Void {
        mutex_update_and_draw_.lock()
        need_update_and_draw_ = true
        if !async_task_ {
            self.async_task_ = true
            mutex_update_and_draw_.unlock()
            Update()
            Draw(map_view: map_view)
            StartRepeatAsyncUpdateAndDraw(map_view: map_view, period: period)
            return
        }
        
        mutex_update_and_draw_.unlock()
    }
    func CancelRepeatUpdateAndDraw() -> Void {
        mutex_update_and_draw_.lock()
        need_update_and_draw_ = false
        mutex_update_and_draw_.unlock()
    }
}

//var routes: [Route] = [Route(name: "Alina", startCoordinate:  CLLocationCoordinate2D(latitude: 55.1, longitude: 37.2), finishCoordinate: CLLocationCoordinate2D(latitude: 55.5, longitude: 37.3), initialColor: .systemPink),
//                       Route(name: "Maria", startCoordinate: CLLocationCoordinate2D(latitude: 55, longitude: 37), finishCoordinate: CLLocationCoordinate2D(latitude: 56, longitude: 38), initialColor: .purple),
//                       Route(name: "Leonid", startCoordinate: CLLocationCoordinate2D(latitude: 55.8, longitude: 37.6), finishCoordinate:  CLLocationCoordinate2D(latitude: 55.1, longitude: 37.4), initialColor: .systemBlue)]

