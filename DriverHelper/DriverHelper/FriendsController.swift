import UIKit

class FriendsController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var add_friend_but: UIButton!
    @IBOutlet weak var friend_login: UITextField!
    @IBOutlet var friendsTableView: UITableView!
    
    var friends_list = ["Maria", "Leonid", "Alina"]
    
    override func loadView() {
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        friendsTableView.delegate = self
        friendsTableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return friends_list.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let cell = UITableViewCell()
       cell.textLabel?.text = friends_list[indexPath.row]
       return cell
   }

    @IBAction func AddFriend(_ sender: Any) {
        if (friend_login.text != nil && !friend_login.text!.isEmpty) {
            User.main_user?.AddFriend(friend_login: friend_login.text!)
            friend_login.text = ""
        }
    }
    
}

