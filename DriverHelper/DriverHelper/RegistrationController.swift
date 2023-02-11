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
        if login_text.text == nil || login_text.text == "" {
            error_label.text = "Login must be not empty"
            error_label.textColor = UIColor.red
            return;
        }
        if password_text.text == nil || password_text.text!.count <= 3 {
            error_label.text = "Password len must be > 3 characters"
            error_label.textColor = UIColor.red
            return;
        }
        error_label.text = ""
        
        main_user = User(login:login_text.text!, password:password_text.text!)
        let error_msg = main_user!.Register()
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
