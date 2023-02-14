import UIKit

class FriendsController: UIViewController {
    
    @IBOutlet weak var add_friend_but: UIButton!
    @IBOutlet weak var friend_login: UITextField!
    override func loadView() {
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func AddFriend(_ sender: Any) {
        if (friend_login.text != nil && !friend_login.text!.isEmpty) {
            main_user!.AddFriend(friend_login: friend_login.text!)
            friend_login.text = ""
        }
    }
    
}

