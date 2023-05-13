import Foundation
import UIKit
import MapKit

class SearchTableController : UITableViewController, UISearchResultsUpdating {
    var matchingItems:[MKMapItem] = []
    var mapView: MKMapView? = nil
    var handleMapSearchDelegate:HandleMapSearch? = nil
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView,
            let searchBarText = searchController.searchBar.text else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)

        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = parseAddress(selectedItem: selectedItem)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingItems[indexPath.row].placemark
        handleMapSearchDelegate?.dropPinZoomIn(placemark: selectedItem)
        dismiss(animated: true, completion: nil)
    }
    
    func parseAddress(selectedItem:MKPlacemark) -> String {
        let firstComma = (selectedItem.administrativeArea != nil && (selectedItem.locality != nil || selectedItem.locality != nil  || selectedItem.administrativeArea != nil)) ? ", " : ""
        let secondComma = (selectedItem.locality != nil && (selectedItem.locality != nil  || selectedItem.administrativeArea != nil)) ? ", " : ""
        let thirdComma = (selectedItem.thoroughfare != nil && selectedItem.subThoroughfare != nil) ? ", " : ""
        
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            selectedItem.administrativeArea ?? "",
            firstComma,
            selectedItem.locality ?? "",
            secondComma,
            selectedItem.thoroughfare ?? "",
            thirdComma,
            selectedItem.subThoroughfare ?? ""
        )

        return addressLine
    }
}
