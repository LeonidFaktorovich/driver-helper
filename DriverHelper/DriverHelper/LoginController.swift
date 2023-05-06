

import Foundation
import UIKit

class LoginController : UIViewController {
    
    @IBOutlet weak var login_label: UILabel!
    @IBOutlet weak var password_label: UILabel!
    @IBOutlet weak var login_text: UITextField!
    @IBOutlet weak var password_text: UITextField!
    @IBOutlet weak var create_acc: UIButton!
    @IBOutlet weak var error_label: UILabel!
    @IBOutlet weak var sign_button: UIButton!
    override func loadView() {
        super.loadView()
        error_label.text = ""
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    @IBAction func create(_ sender: Any) {
        let reg_storyboard = UIStoryboard(name: "Registration", bundle: nil)
        let reg_controller = reg_storyboard.instantiateViewController(withIdentifier: "Registration") as! RegistrationController
        reg_controller.modalPresentationStyle = .fullScreen
        present(reg_controller, animated: true)
    }
    @IBAction func login(_ sender: Any) {
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
        if (password.count <= 3) {
            error_label.text = "Password len must be > 3 characters"
            error_label.textColor = UIColor.red
            return;
        }
        error_label.text = ""
        
        User.main_user = User(login:login, password:password)
        let error_msg = User.main_user?.Login()
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
