import Foundation
import UIKit
import MapKit

class RouteInfoController : UIViewController {
    let height: CGFloat = 25
    let width: CGFloat = UIScreen.main.bounds.width / 4
    
    func addAddressLabel(text: String, coordinates: CLLocationCoordinate2D, rowIndex: Int) {
        let loc: CLLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let ceo: CLGeocoder = CLGeocoder()
        
        ceo.reverseGeocodeLocation(loc, completionHandler:
            {(placemarks, error) in
                let pm = placemarks! as [CLPlacemark]

                if pm.count > 0 {
                    let pm = placemarks![0]
                    
                    let firstComma = (pm.administrativeArea != nil && (pm.locality != nil || pm.thoroughfare != nil || pm.subThoroughfare != nil)) ? ", " : ""
                    let secondComma = (pm.locality != nil && (pm.thoroughfare != nil  || pm.subThoroughfare != nil)) ? ", " : ""
                    let thirdComma = (pm.thoroughfare != nil && pm.subThoroughfare != nil) ? ", " : ""
                    
                    let addressString = String(
                        format:"%@%@%@%@%@%@%@",
                        pm.administrativeArea ?? "",
                        firstComma,
                        pm.locality ?? "",
                        secondComma,
                        pm.thoroughfare ?? "",
                        thirdComma,
                        pm.subThoroughfare ?? ""
                    )
                    
                    let labelLeft = UILabel(frame: CGRect(x: 50, y: 50 + CGFloat(rowIndex) * self.height, width: self.width, height: self.height))
                    labelLeft.text = text
                    self.view.addSubview(labelLeft)
                    
                    let labelRight = UILabel(frame: CGRect(x: 50 + self.width, y: 50 + CGFloat(rowIndex) * self.height, width: 2 * self.width, height: 3 * self.height))
                    labelRight.text = addressString
                    labelRight.lineBreakMode = .byWordWrapping
                    labelRight.numberOfLines = 0
                    self.view.addSubview(labelRight)
              }
        })
    }
    
    func addTwoLabels(textLeft: String?, textRight: String?, rowIndex: inout Int) {
       let labelLeft = UILabel(frame: CGRect(x: 50, y: 50 + CGFloat(rowIndex) * height, width: width, height: height))
        labelLeft.text = textLeft
        view.addSubview(labelLeft)
        
        let labelRight = UILabel(frame: CGRect(x: 50 + width, y: 50 + CGFloat(rowIndex) * height, width: 2 * width, height: height))
        labelRight.text = textRight
        labelRight.lineBreakMode = .byWordWrapping
        labelRight.numberOfLines = 0
        view.addSubview(labelRight)
        
        rowIndex += 1
    }
    
    func addOneLabel(text: String?, rowIndex: inout Int) {
        let label = UILabel(frame: CGRect(x: 50, y: 50 + CGFloat(rowIndex) * height, width: width * 3, height: height))
        label.text = text
        view.addSubview(label)
       
        rowIndex += 1
    }
    
    func addRouteInfo(routeData: RouteData) {
        let title = UILabel(frame: CGRect(x: 0, y: 30, width: width * 4, height: height))
        title.textAlignment = .center
        title.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        title.textColor = .systemBlue
        title.text = "Route Information"
        view.addSubview(title)
        
        var curRow = 1
        
        addTwoLabels(textLeft: "Owner:", textRight: routeData.owner, rowIndex: &curRow)
        
        addAddressLabel(text: "Start:", coordinates: routeData.start, rowIndex: curRow)
        curRow += 3
        
        addAddressLabel(text: "Finish:", coordinates: routeData.finish, rowIndex: curRow)
        curRow += 3
        
        addTwoLabels(textLeft: "Date:", textRight: routeData.date_start, rowIndex: &curRow)
        addTwoLabels(textLeft: "Time:", textRight: routeData.time_start, rowIndex: &curRow)
        
        curRow += 2
        let title2 = UILabel(frame: CGRect(x: 0, y:  50 + CGFloat(curRow) * height, width: width * 4, height: height))
        title2.textAlignment = .center
        title2.font = UIFont.preferredFont(forTextStyle: .title2)
        title2.textColor = .systemBlue
        title2.text = "Fellows"
        view.addSubview(title2)
        curRow += 2
        
        let fellows = routeData.members

        for i in 0..<fellows.count {
            let index = fellows.index(fellows.startIndex, offsetBy: i)
            addOneLabel(text: fellows[index], rowIndex: &curRow)
        }
        
        view.backgroundColor = .white
    }
    
}
