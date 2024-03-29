import Foundation
import UIKit
import CoreLocation
import CryptoKit

extension String {
    func base64Encoded() -> String {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString();
        }
        return ""
    }
    func base64Decoded() -> String {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) {
            return String(data: data, encoding: .utf8) ?? ""
        }
        return ""
    }
}


enum Server : String {
    case prot = "http"
    case host = "207.154.204.60"
    case handler_register = "/register"
    case handler_login = "/login"
    case handler_make_friend = "/add_friend"
    case handler_make_route = "/add_route"
    case handler_map = "/map"
    case handler_get_friends = "/friends"
    case port = "8080"
}

extension CLLocationCoordinate2D : Codable {
    enum CodingKeys: String, CodingKey {
        case latitude = "x"
        case longitude = "y"
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
    }
}

func Decode(str: String) -> String {
    return str.base64Decoded()
}

func Encode(str: String) -> String {
    return str.base64Encoded()
}
 
struct RouteData : Codable {
    let start: CLLocationCoordinate2D
    let finish: CLLocationCoordinate2D
    let owner: String
    let date_start: String
    let time_start: String
    var members: [String]
    var maybe_members: [String]
    
    enum CodingKeys: String, CodingKey {
        case start = "start"
        case finish = "finish"
        case owner = "owner"
        case date_start = "date_start"
        case time_start = "time_start"
        case members = "approved"
        case maybe_members = "wait_approve"
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(start, forKey: .start)
        try container.encode(finish, forKey: .finish)
        
        let base_owner: String = owner.base64Encoded()
        try container.encode(base_owner, forKey: .owner)
        
        let base_date_start: String = date_start.base64Encoded()
        try container.encode(base_date_start, forKey: .date_start)
        
        let base_time_start: String = time_start.base64Encoded()
        try container.encode(base_time_start, forKey: .time_start)
        
        let base_members: [String] = members.map(Encode)
        try container.encode(base_members, forKey: .members)
        
        let base_maybe_members: [String] = maybe_members.map(Encode)
        try container.encode(base_maybe_members, forKey: .maybe_members)
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        start = try container.decode(CLLocationCoordinate2D.self, forKey: .start)
        finish = try container.decode(CLLocationCoordinate2D.self, forKey: .finish)
        owner = try container.decode(String.self, forKey: .owner).base64Decoded()
        date_start = try container.decode(String.self, forKey: .date_start).base64Decoded()
        time_start = try container.decode(String.self, forKey: .time_start).base64Decoded()
        do {
            let base_members = try container.decode([String].self, forKey: .members)
            members = base_members.map(Decode)
        } catch {
            members = []
        }
        do {
            let base_maybe_members = try container.decode([String].self, forKey: .maybe_members)
            maybe_members = base_maybe_members.map(Decode)
        } catch {
            maybe_members = []
        }
    }
    init(start: CLLocationCoordinate2D, finish: CLLocationCoordinate2D, owner: String, date: Date) {
        self.start = start
        self.finish = finish
        self.owner = owner
        
        let date_formatter = DateFormatter()
        date_formatter.dateFormat = "yyyy-MM-dd"
        self.date_start = date_formatter.string(from: date)
        let time_formatter = DateFormatter()
        time_formatter.dateFormat = "HH:mm"
        self.time_start = time_formatter.string(from: date)
        members = []
        maybe_members = []
    }
}

struct NetworkRoute : Codable {
    var route: RouteData
    enum CodingKeys: String, CodingKey {
        case route = "route"
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(route, forKey: .route)
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        route = try container.decode(RouteData.self, forKey: .route)
    }
    init(start: CLLocationCoordinate2D, finish: CLLocationCoordinate2D, owner: String, date: Date) {
        route = RouteData(start: start, finish: finish, owner: owner, date: date)
    }
}

struct NetworkRoutes : Codable {
    var routes: [RouteData]
    enum CodingKeys: String, CodingKey {
        case routes = "routes"
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(routes, forKey: .routes)
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        routes = try container.decode([RouteData].self, forKey: .routes)
    }
    init() {
        routes = []
    }
}

struct Friends : Codable {
    var friends: [String]
    enum CodingKeys: String, CodingKey {
        case friends = "friends"
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(friends, forKey: .friends)
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        friends = try container.decode([String].self, forKey: .friends)
        friends = friends.map(Decode)
    }
    init() {
        friends = []
    }
}

class User {
    static var main_user: User?
    var routes_controller_: RoutesController
    var avatar: UIImage
    struct PersonData : Codable {
        var login: String
        var password: String
        enum CodingKeys: String, CodingKey {
            case login = "login"
            case password = "password"
        }
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            let base_login: String = login.base64Encoded()
            try container.encode(base_login, forKey: .login)
            
            let base_password: String = password.base64Encoded()
            try container.encode(base_password, forKey: .password)
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            login = try container.decode(String.self, forKey: .login).base64Decoded()
            password = try container.decode(String.self, forKey: .password).base64Decoded()
        }
        init(login:String, password:String) {
            let password_hash = SHA256.hash(data: Data(password.utf8))
            self.login = login
            self.password = password_hash.map { String(format: "%02hhx", $0) }.joined()
        }
    }
    
    struct Token : Codable {
        var token: String
        enum CodingKeys: String, CodingKey {
            case token = "token"
        }
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            let base_token: String = token.base64Encoded()
            try container.encode(base_token, forKey: .token)
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            token = try container.decode(String.self, forKey: .token).base64Decoded()
        }
        init(token: String) {
            self.token = token
        }
    }
    func MakeUrl(path: String) -> URL {
        var component = URLComponents()
        component.scheme = Server.prot.rawValue
        component.host = Server.host.rawValue
        component.path = path
        component.port = Int(Server.port.rawValue)
        return component.url!
    }
    var data: PersonData
    var token: Token?
    init(login: String, password: String) {
        data = PersonData(login:login, password: password)
        token = nil
        routes_controller_ = RoutesController()
        avatar = User.CreateDefaultAvatar(name: data.login)
    }
    func LoginFromCache() -> Void {
        guard let cur_login: String = GetLogin() else { return }
        guard let cur_password: String = GetPassword() else { return }
        guard let cur_token: String = GetToken() else { return }
        
        data.login = cur_login
        data.password = cur_password
        token = Token(token: cur_token)
    }
    func SetTokenFromCache() -> Void {
        guard let cur_token: String = GetToken() else { return }
        token = Token(token: cur_token)
    }
    
}

extension User {
    func Register() -> String? {
        let cur_url = MakeUrl(path: Server.handler_register.rawValue)
        
        var request = URLRequest(url: cur_url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["Content-Type" : "application/json"]
        
        let jsonEncoder = JSONEncoder()
        let httpBody = try! jsonEncoder.encode(data)
        request.httpBody = httpBody
        let session = URLSession.shared
        
        // for async use DispatchQueue.main.async {}
        var error_msg: String?
        let group = DispatchGroup()
        group.enter()
        let task = session.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                guard let token_data = data else { return }
                if httpResponse.statusCode == 200 {
                    self.token = try! JSONDecoder().decode(Token.self, from: token_data)
                    UserSave(user: self)
                } else if httpResponse.statusCode == 409 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                    let dictionary = json as! [String: Any]
                    error_msg = dictionary["detail"] as? String
                } else {
                    error_msg = "Uknown error"
                }
            }
            group.leave()
        }
        task.resume()
        group.wait()
        return error_msg
        
    }
    func Login() -> String? {
        let cur_url = MakeUrl(path: Server.handler_login.rawValue)
        var request = URLRequest(url: cur_url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["Content-Type" : "application/json"]
        let jsonEncoder = JSONEncoder()
        let httpBody = try! jsonEncoder.encode(data)
        request.httpBody = httpBody
        let session = URLSession.shared

        var error_msg: String?
        let group = DispatchGroup()
        group.enter()
        let task = session.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                guard let token_data = data else { return }
                if httpResponse.statusCode == 200 {
                    self.token = try! JSONDecoder().decode(Token.self, from: token_data)
                    UserSave(user: User.main_user!)
                } else if httpResponse.statusCode == 404 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                    let dictionary = json as! [String: Any]
                    error_msg = dictionary["detail"] as? String
                    error_msg = error_msg?.base64Decoded()
                } else {
                    error_msg = "Uknown error"
                }
            }
            group.leave()
        }
        task.resume()
        group.wait()
        return error_msg
    }
    func AddFriend(friend_login: String) -> String? {
        let cur_url = MakeUrl(path: Server.handler_make_friend.rawValue)
        var request = URLRequest(url: cur_url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["Content-Type" : "application/json", "token" : token!.token.base64Encoded()]
        let dict = ["friend_login" : friend_login.base64Encoded()]
        let httpBody = try! JSONSerialization.data(withJSONObject: dict)
        request.httpBody = httpBody
        let session = URLSession.shared
        
        var error_msg: String?
        let group = DispatchGroup()
        group.enter()
        let task = session.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 {
                    error_msg = "User with " + friend_login + " not found."
                } else {
                    error_msg = "Uknown error"
                }
            }
            group.leave()
        }
        task.resume()
        group.wait()
        return error_msg
    }
    func GetFriends() -> Friends {
        let cur_url = MakeUrl(path: Server.handler_get_friends.rawValue)
        var request = URLRequest(url: cur_url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Content-Type" : "application/json", "token" : token!.token.base64Encoded()]
        let session = URLSession.shared
        var friends: Friends = Friends()
        let group = DispatchGroup()
        group.enter()
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data else {
                group.leave()
                return
            }
            if data.isEmpty {
                group.leave()
                return
            }
            friends = try! JSONDecoder().decode(Friends.self, from: data);
            group.leave()
        }
        task.resume()
        group.wait()
        // friends.friends = friends.friends.map(Decode)
        return friends
    }
    func GetMap() -> NetworkRoutes {
        let cur_url = MakeUrl(path: Server.handler_map.rawValue)
        var request = URLRequest(url: cur_url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Content-Type" : "application/json", "token" : token!.token.base64Encoded()]
        let session = URLSession.shared
        var routes = NetworkRoutes()
        
        let group = DispatchGroup()
        group.enter()
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data else {
                group.leave()
                return
            }
            if data.isEmpty {
                group.leave()
                return
            }
            routes = try! JSONDecoder().decode(NetworkRoutes.self, from: data);
            group.leave()
        }
        task.resume()
        group.wait()
        return routes
    }
    func AddRoute(route: NetworkRoute) -> Void {
        let cur_url = MakeUrl(path: Server.handler_make_route.rawValue)
        var request = URLRequest(url: cur_url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["Content-Type" : "application/json", "token" : token!.token.base64Encoded()]
        let httpBody = try! JSONEncoder().encode(route)
        request.httpBody = httpBody
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
        }
        task.resume()
    }
 }

extension User {
    private static func CreateDefaultAvatar(name: String) -> UIImage {
        let size = CGSize(width: 140, height: 140) // размеры картинки
        let backgroundColor = ColorFromName(name: name) // цвет фона
        let textColor = UIColor.white // цвет текста

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!

        // заполняем фон
        backgroundColor.setFill()
        context.fill(CGRect(origin: CGPoint.zero, size: size))

        // рисуем текст
        let text = String(name[name.startIndex]) as NSString
        let font = UIFont.systemFont(ofSize: 72)
        let attributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: textColor]
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2, width: textSize.width, height: textSize.height)
        text.draw(in: textRect, withAttributes: attributes)

        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
