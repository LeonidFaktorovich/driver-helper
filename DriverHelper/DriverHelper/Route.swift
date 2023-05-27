import UIKit
import Foundation

class MemberTableViewCell: UITableViewCell {
    
    let login = UILabel()
    let approve = UIButton(type: .system)
    let dismiss = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Конфигурация UI-элементов внутри ячейки
        let cellWidth = UIScreen.main.bounds.width / 2 // Половина ширины экрана
        let cellHeight: CGFloat = 15
        
        login.frame = CGRect(x: 0, y: 0, width: cellWidth / 3, height: cellHeight)
        approve.frame = CGRect(x: cellWidth / 3, y: 0, width: cellWidth / 3 , height: cellHeight)
        dismiss.frame = CGRect(x: 2 * cellWidth / 3, y: 0, width: cellWidth / 3, height: cellHeight)
        
        login.textAlignment = .center
        login.backgroundColor = .clear
        
        approve.setTitle("Approve", for: .normal)
        dismiss.setTitle("Dismiss", for: .normal)
        
        approve.titleLabel?.font = UIFont.systemFont(ofSize: 8, weight: .bold)
        dismiss.titleLabel?.font = UIFont.systemFont(ofSize: 8, weight: .bold)
        
        approve.setTitleColor(.white, for: .normal)
        dismiss.setTitleColor(.white, for: .normal)
        
        approve.backgroundColor = .systemBlue
        dismiss.backgroundColor = .systemBlue
        
        approve.layer.cornerRadius = cellHeight / 2
        dismiss.layer.cornerRadius = cellHeight / 2
        
        contentView.addSubview(login)
        contentView.addSubview(approve)
        contentView.addSubview(dismiss)
    }
    
    func SetLogin(member_login: String) {
        login.text = member_login
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class RouteView : UIView {
    var owner  = UILabel()
    var start = UILabel()
    var finish = UILabel()
    var date = UILabel()
    var members = UITableView()
    var maybe_members = UITableView()
    
    private func setupView() {
        owner.text = "owner"
        start.text = "start"
        finish.text = "finish"
        date.text = "date"
        addSubview(owner)
        addSubview(start)
        addSubview(finish)
        addSubview(date)
        addSubview(members)
        addSubview(maybe_members)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        
        members.backgroundColor = .clear
        members.backgroundView = nil
        members.separatorStyle = .none
        maybe_members.backgroundColor = .clear
        maybe_members.backgroundView = nil
        maybe_members.separatorStyle = .none
        
        let halfWidth = frame.width / 2
        let label_height: CGFloat = 20
        members.frame = CGRect(x: halfWidth, y: 0, width: halfWidth, height: 100)
        maybe_members.frame = CGRect(x: halfWidth, y: 50, width: halfWidth, height: 100)
        owner.frame = CGRect(x: 0, y: 0, width: halfWidth, height: label_height)
        start.frame = CGRect(x: 0, y: label_height, width: halfWidth, height: label_height)
        finish.frame = CGRect(x: 0, y: 2 * label_height, width: halfWidth, height: label_height)
        date.frame = CGRect(x: 0, y: 3 * label_height, width: halfWidth, height: label_height)
    }
}

class RouteViewController : UITableViewController {
    weak var route_view_: RouteView?
    var cur_route_: Route?
    
    func SetRouteView(route_view: RouteView) {
        route_view_ = route_view
        route_view_?.members.dataSource = self
        route_view_?.maybe_members.dataSource = self
        route_view_?.members.delegate = self
        route_view_?.maybe_members.delegate = self
        
        route_view_?.members.register(MemberTableViewCell.self, forCellReuseIdentifier: "Member")
        route_view_?.maybe_members.register(MemberTableViewCell.self, forCellReuseIdentifier: "MaybeMember")
    }
    
    var count: Int = 0;
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cellIdentifier = ""
        if tableView == route_view_?.members {
            cellIdentifier = "Member"
        } else if tableView == route_view_?.maybe_members {
            cellIdentifier = "MaybeMember"
        }
        let cell = MemberTableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        cell.backgroundColor = .clear
        cell.login.text = "hello"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! MemberTableViewCell
        
        if cell.approve.isTouchInside {
            // Действия для первой кнопки
        } else if cell.dismiss.isTouchInside {
            // Действия для второй кнопки
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 20 // Высота ячейки
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 2
    }
    

}
