

import Foundation
import UIKit

class LoginController : UIViewController {
    
    @IBOutlet weak var login_label: UILabel!
    @IBOutlet weak var password_label: UILabel!
    @IBOutlet weak var login_text: UITextField!
    @IBOutlet weak var password_text: UITextField!
    @IBOutlet weak var create_acc: UIButton!
    @IBOutlet weak var sign_button: UIButton!
    override func loadView() {
        super.loadView()
        
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
        if login_text.text == nil || login_text.text == "" {
//            error_label.text = "Login must be not empty"
//            error_label.textColor = UIColor.red
            return;
        }
        if password_text.text == nil || password_text.text!.count <= 3 {
//            error_label.text = "Password len must be > 3 characters"
//            error_label.textColor = UIColor.red
            return;
        }
//        error_label.text = ""
        
        main_user = User(login:login_text.text!, password:password_text.text!)
        let error_msg = main_user!.Login()
        if error_msg != nil {
//            error_label.text = error_msg
//            error_label.textColor = UIColor.red
        } else {
            let main_storyboard = UIStoryboard(name: "MainBar", bundle: nil)
            let main_bar = main_storyboard.instantiateViewController(withIdentifier: "MainBar") as! MainBarController
            main_bar.modalPresentationStyle = .fullScreen
            present(main_bar, animated: true)
        }
    }
}
