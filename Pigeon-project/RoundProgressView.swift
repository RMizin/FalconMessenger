import UIKit


public class RoundProgressView: UIView {
    
     var percent:Double = 0.000001  {
        didSet {
           setNeedsDisplay()
        }
    }
    private var startAngle = CGFloat(-90 * Double.pi / 180)
    private var endAngle = CGFloat(270 * Double.pi / 180)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

  required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
    }

  var progressColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
  var progressBackgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
  
  override public func draw(_ rect: CGRect) {
        // General Declarations
        guard let context = UIGraphicsGetCurrentContext() else {
            print("Error getting context")
            return
        }
  
        // Background Drawing
        let backgroundPath = UIBezierPath(ovalIn: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height))
        backgroundColor?.setFill()
        backgroundPath.fill()
        
        // Background Inner Shadow
        context.saveGState();
        UIRectClip(backgroundPath.bounds);
        context.setShadow(offset: CGSize.zero, blur: 0, color: nil);
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        context.setBlendMode(CGBlendMode.sourceOut)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        backgroundPath.fill()
        context.endTransparencyLayer()
        context.endTransparencyLayer()
        context.restoreGState()
        
        // ProgressBackground Drawing
        let kMFPadding = CGFloat(15)
        
        let progressBackgroundPath = UIBezierPath(ovalIn: CGRect(x: rect.minX + kMFPadding/2, y: rect.minY + kMFPadding/2, width: rect.size.width - kMFPadding, height: rect.size.height - kMFPadding))
        progressBackgroundColor.setStroke()
        progressBackgroundPath.lineWidth = 5
        progressBackgroundPath.stroke()
        
        // Progress Drawing
        let progressRect = CGRect(x: rect.minX + kMFPadding/2, y: rect.minY + kMFPadding/2, width: rect.size.width - kMFPadding, height: rect.size.height - kMFPadding)
        let progressPath = UIBezierPath()
        progressPath.addArc(withCenter: CGPoint(x: progressRect.midX, y: progressRect.midY), radius: progressRect.width / 2, startAngle: startAngle, endAngle: (endAngle - startAngle) * (CGFloat(percent) / 100) + startAngle, clockwise: true)
        progressColor.setStroke()
        progressPath.lineWidth = 4
        progressPath.lineCapStyle = CGLineCap.round
        progressPath.stroke()
    }
}
