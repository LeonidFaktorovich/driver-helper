import Foundation
import UIKit

class RegistrationController : UIViewController {

    @IBOutlet weak var login_text: UITextField!
    @IBOutlet weak var password_label: UILabel!
    @IBOutlet weak var login_label: UILabel!
    @IBOutlet weak var password_text: UITextField!
    @IBOutlet weak var create_button: UIButton!
    override func loadView() {
        super.loadView()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    @IBAction func create(_ sender: Any) {
        main_user = User(login:login_text.text!, password:password_text.text!)
        main_user!.Registration()
        
        let test = true
        if test {
            let main_storyboard = UIStoryboard(name: "MainBar", bundle: nil)
            let main_bar = main_storyboard.instantiateViewController(withIdentifier: "MainBar") as! MainBarController
            main_bar.modalPresentationStyle = .fullScreen
            present(main_bar, animated: true)
        }
    }
}
