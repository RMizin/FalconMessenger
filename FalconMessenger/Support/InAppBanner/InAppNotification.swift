import UIKit

public struct InAppNotification {
    public let resource: Any?
    public let title: String
    public let subtitle: String
    public let data: Data?
    
    public init(resource: Any?, title: String, subtitle: String, data: Data? ) {
        self.resource = resource
        self.title = title
        self.subtitle = subtitle
        self.data = data
    }
}
