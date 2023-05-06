import UIKit

class MainBarController : UITabBarController {
    
    override func loadView() {
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print(1)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print(2)
    }
}
