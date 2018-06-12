import UIKit

class CustomizedView: UIView {
    var cornerRadius: CGFloat = 0.0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    var borderWidth: CGFloat = 0.0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    var borderColor: UIColor = UIColor.clear {
        didSet {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    func removeGestureRecgonizers() {
        guard let _gestureReognizers = gestureRecognizers else { return }
        for gestureRecognizer in _gestureReognizers {
            removeGestureRecognizer(gestureRecognizer)
        }
    }
}
