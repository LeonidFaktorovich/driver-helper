import Foundation
import UIKit

class RegistrationController : UIViewController {

    @IBOutlet weak var error_label: UILabel!
    @IBOutlet weak var login_text: UITextField!
    @IBOutlet weak var password_label: UILabel!
    @IBOutlet weak var login_label: UILabel!
    @IBOutlet weak var password_text: UITextField!
    @IBOutlet weak var create_button: UIButton!
    override func loadView() {
        super.loadView()
        error_label.text = ""
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    @IBAction func create(_ sender: Any) {
        guard let login = login_text.text else {
            return;
        }
        guard let password = password_text.text else {
            return;
        }
        if (login.isEmpty) {
            error_label.text = "Login must be not empty"
            error_label.textColor = UIColor.red
            return;
        }
        if (password.count <= 5) {
            error_label.text = "Password len must be > 5 characters"
            error_label.textColor = UIColor.red
            return;
        }
        error_label.text = ""
        
        User.main_user = User(login:login, password:password)
        let error_msg = User.main_user?.Register()
        if error_msg != nil {
            error_label.text = error_msg
            error_label.textColor = UIColor.red
        } else {
            let main_storyboard = UIStoryboard(name: "MainBar", bundle: nil)
            let main_bar = main_storyboard.instantiateViewController(withIdentifier: "MainBar") as! MainBarController
            main_bar.modalPresentationStyle = .fullScreen
            present(main_bar, animated: true)
        }
    }
}
