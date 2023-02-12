import Foundation
import UIKit
import CoreLocation

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
    case port = "5000"
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

struct MapPoint : Codable {
    let x: Double
    let y: Double
    
    enum CodingKeys: String, CodingKey {
        case x = "x"
        case y = "y"
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
    }
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

struct NetworkRoute : Codable {
    let start: CLLocationCoordinate2D
    let finish: CLLocationCoordinate2D
    let owner: String
    let date_start: String
    let time_start: String
    
    enum CodingKeys: String, CodingKey {
        case start = "start"
        case finish = "finish"
        case owner = "owner"
        case date_start = "date_start"
        case time_start = "time_start"
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
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        start = try container.decode(CLLocationCoordinate2D.self, forKey: .start)
        finish = try container.decode(CLLocationCoordinate2D.self, forKey: .finish)
        owner = try container.decode(String.self, forKey: .owner).base64Decoded()
        date_start = try container.decode(String.self, forKey: .date_start).base64Decoded()
        time_start = try container.decode(String.self, forKey: .time_start).base64Decoded()
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
    }
}

class User {
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
            self.login = login
            self.password = password
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
        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                guard let token_data = data else { return }
                print(httpResponse.statusCode)
                if httpResponse.statusCode == 200 {
                    self.token = try! JSONDecoder().decode(Token.self, from: token_data)
                    UserSave(user: main_user!)
                } else if httpResponse.statusCode == 409 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                    let dictionary = json as! [String: Any]
                    error_msg = dictionary["detail"] as? String
                } else {
                    error_msg = "Uknown error"
                }
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
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
        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                guard let token_data = data else { return }
                if httpResponse.statusCode == 200 {
                    self.token = try! JSONDecoder().decode(Token.self, from: token_data)
                    UserSave(user: main_user!)
                } else if httpResponse.statusCode == 404 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                    let dictionary = json as! [String: Any]
                    error_msg = dictionary["detail"] as? String
                } else {
                    error_msg = "Uknown error"
                }
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
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
        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 {
                    error_msg = "User with " + friend_login + " not found."
                } else {
                    error_msg = "Uknown error"
                }
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return error_msg
    }
    func GetMap() -> [NetworkRoute] {
        let cur_url = MakeUrl(path: Server.handler_map.rawValue)
        var request = URLRequest(url: cur_url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Content-Type" : "application/json", "token" : token!.token.base64Encoded()]
        let session = URLSession.shared
        var routes: [NetworkRoute] = []
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: request) { data, response, error in
            routes = try! JSONDecoder().decode([NetworkRoute].self, from: data!);
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
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

var main_user: User?


