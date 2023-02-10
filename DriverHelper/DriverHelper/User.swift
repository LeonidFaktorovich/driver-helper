import Foundation

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
    case host = "xxx" // change for release
    case handler_register = "/registration"
    case handler_login = "/login"
    case handler_make_friend = "/make_friend"
    case handler_update_points = "/map"
    case port = "5000"
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
    var data: PersonData
    var token: Token?
    init(login: String, password: String) {
        data = PersonData(login:login, password: password)
        token = nil
    }
    
}

extension User {
    func Registration() -> Void {
        var cur_url: URL {
            var component = URLComponents()
            component.scheme = Server.prot.rawValue
            component.host = Server.host.rawValue
            component.path = Server.handler_register.rawValue
            component.port = Int(Server.port.rawValue)
            return component.url!
        }
        
        var request = URLRequest(url: cur_url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["Content-Type" : "application/json"]
        
        let jsonEncoder = JSONEncoder()
        let httpBody = try! jsonEncoder.encode(data)
        request.httpBody = httpBody
        let session = URLSession.shared
        
        // for async use DispatchQueue.main.async {}
        let task = session.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if (httpResponse.statusCode != 200) {
                    print("error")
                }
            }
            guard let token_data = data else { return }
            self.token = try! JSONDecoder().decode(Token.self, from: token_data)
            UserSave(user: main_user!)
            
        }
        task.resume()
    }
    func Login() -> Void {
        var cur_url: URL {
            var component = URLComponents()
            component.scheme = Server.prot.rawValue
            component.host = Server.host.rawValue
            component.path = Server.handler_login.rawValue
            component.port = Int(Server.port.rawValue)
            return component.url!
        }
        var request = URLRequest(url: cur_url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Content-Type" : "application/json"]
        let jsonEncoder = JSONEncoder()
        let httpBody = try! jsonEncoder.encode(data)
        request.httpBody = httpBody
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let token_data = data else { return }
                self.token = try! JSONDecoder().decode(Token.self, from: token_data)
            }
        }
        task.resume()
    }
}

var main_user: User?


