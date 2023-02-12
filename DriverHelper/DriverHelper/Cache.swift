import Foundation


struct UserData {
    let login : String
    let password : String
    let token : String
}

enum DataKeys : String {
    case login = "login"
    case password = "password"
    case token = "token"
}



func UserSave(user: User) -> Void {
    let defaults = UserDefaults.standard
    defaults.set(user.data.login, forKey: DataKeys.login.rawValue)
    defaults.set(user.data.password, forKey: DataKeys.password.rawValue)
    defaults.set(user.token!.token, forKey: DataKeys.token.rawValue)
}

func GetToken() -> String? {
    let defaults = UserDefaults.standard
    return defaults.string(forKey: DataKeys.token.rawValue)
}

func GetLogin() -> String? {
    let defaults = UserDefaults.standard
    return defaults.string(forKey: DataKeys.login.rawValue)
}

func GetPassword() -> String? {
    let defaults = UserDefaults.standard
    return defaults.string(forKey: DataKeys.password.rawValue)
}

func UserExit() -> Void {
    let defaults = UserDefaults.standard
    
    defaults.removeObject(forKey: DataKeys.login.rawValue)
    defaults.removeObject(forKey: DataKeys.password.rawValue)
    defaults.removeObject(forKey: DataKeys.token.rawValue)
}
