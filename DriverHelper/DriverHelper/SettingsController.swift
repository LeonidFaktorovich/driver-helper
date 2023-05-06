import UIKit

class SettingsController: UIViewController {
    
    @IBOutlet weak var log_out_button: UIButton!
    override func loadView() {
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func LogOut(_ sender: Any) {
        UserExit()
        
//        routes_lock.lock()
//        routes_to_draw_lock.lock()
//
//        routes.removeAll()
//        routes_to_draw.removeAll()
//
//        routes_lock.unlock()
//        routes_to_draw_lock.unlock()
        
        let reg_storyboard = UIStoryboard(name: "Login", bundle: nil)
        let reg_controller = reg_storyboard.instantiateViewController(withIdentifier: "Login") as! LoginController
        reg_controller.modalPresentationStyle = .fullScreen
        self.present(reg_controller, animated: true)
        
//        self.dismiss(animated: true, completion: nil)

//        UIApplication.shared.windows.first?.rootViewController = reg_controller
//        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
}

