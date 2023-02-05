

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
}
