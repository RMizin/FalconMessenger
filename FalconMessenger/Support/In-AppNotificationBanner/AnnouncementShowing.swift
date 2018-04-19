import UIKit

public func show(shout announcement: Announcement, to: UIViewController, completion: (() -> Void)? = nil) {
  shoutView.craft(announcement, to: to, completion: completion)
}
