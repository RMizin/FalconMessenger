import UIKit


public struct Announcement {

  public var title: String
  public var subtitle: String?
  public var image: UIImage?
  public var duration: TimeInterval
  public var backgroundColor: UIColor
  public var dragIndicatordColor: UIColor
  public var textColor: UIColor
  public var action: (() -> Void)?

  public init(title: String, subtitle: String? = nil, image: UIImage? = nil, duration: TimeInterval = 2,
              backgroundColor: UIColor,
              textColor: UIColor,
              dragIndicatordColor: UIColor, action: (() -> Void)? = nil) {
    
    self.title = title
    self.subtitle = subtitle
    self.image = image
    self.duration = duration
    self.backgroundColor = backgroundColor
    self.dragIndicatordColor = dragIndicatordColor
    self.textColor = textColor
    self.action = action
  }
}

public struct FontList {
  
  public struct Announcement {
    public static var title = UIFont.boldSystemFont(ofSize: 15)
    public static var subtitle = UIFont.systemFont(ofSize: 13)
  }
}
