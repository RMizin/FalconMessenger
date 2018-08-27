import Foundation

class Utils {
    static let shared = Utils()
    private init() {}
    
    var bundle: Bundle { return Bundle(for: type(of: self)) }
}
