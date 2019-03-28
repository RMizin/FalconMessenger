import UIKit

let dhRingStorkeAnimationKey = "IDLoading.stroke"
let dhRingRotationAnimationKey = "IDLoading.rotation"
let dhCompletionAnimationDuration: TimeInterval = 0.3
let dhHidesWhenCompletedDelay: TimeInterval = 0.5

public typealias Block = () -> Void


public class CircleProgress: UIView, CAAnimationDelegate {
  public enum ProgressStatus: Int {
    case Unknown, Loading, Progress, Completion
  }
  
  @IBInspectable public var lineWidth: CGFloat = 2.0 {
    didSet {
      progressLayer.lineWidth = lineWidth
      shapeLayer.lineWidth = lineWidth
      
      setProgressLayerPath()
    }
  }
  
  @IBInspectable public var strokeColor: UIColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0) {
    didSet{
      progressLayer.strokeColor = strokeColor.cgColor
      shapeLayer.strokeColor = strokeColor.cgColor
      progressLabel.textColor = strokeColor
    }
  }
  
  @IBInspectable public var fontSize: Float = 25 {
    didSet{
      progressLabel.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
    }
  }
  
  public var hidesWhenCompleted: Bool = false
  public var hideAfterTime: TimeInterval = dhHidesWhenCompletedDelay
  public private(set) var status: ProgressStatus = .Unknown
  
  private var _progress: Double = 0.0
  public var progress: Double {
    get {
      setNeedsDisplay()
      return _progress
    }
    set(newProgress) {
      //Avoid calling excessively
      if (newProgress - _progress >= 0.001 || newProgress >= 100.0) {
        _progress = min(max(0, newProgress), 1)
        progressLayer.strokeEnd = CGFloat(_progress)
        
        if status == .Loading {
          progressLayer.removeAllAnimations()
        } else if(status == .Completion) {
          shapeLayer.strokeStart = 0
          shapeLayer.strokeEnd = 0
          shapeLayer.removeAllAnimations()
        }
        
        status = .Progress
        
       // progressLabel.isHidden = false
        let progressInt: Int = Int(_progress * 100)
        progressLabel.text = "\(progressInt)"
         setNeedsDisplay()
      }
    }
  }
  
  private let progressLayer: CAShapeLayer! = CAShapeLayer()
  private let shapeLayer: CAShapeLayer! = CAShapeLayer()
  private let progressLabel: UILabel! = UILabel()
  
  private var completionBlock: Block?
  public override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }
  
  deinit{
    NotificationCenter.default.removeObserver(self)
  }
  
  override public func layoutSubviews() {
    super.layoutSubviews()
    
    let width = self.bounds.width
    let height = self.bounds.height
    let square = min(width, height)
    
    let bounds = CGRect(origin: CGPoint(x:0, y:0), size: CGSize(width:square, height:square))
    
    progressLayer.frame = CGRect(origin:CGPoint(x:0, y:0), size:CGSize(width:width, height:height))
    setProgressLayerPath()
    
    shapeLayer.bounds = bounds
    shapeLayer.position = CGPoint(x:self.bounds.midX, y:self.bounds.midY)
    
    let labelSquare = sqrt(2) / 2.0 * square
    progressLabel.bounds = CGRect(origin:CGPoint(x:0, y:0), size:CGSize(width:labelSquare, height:labelSquare))
    progressLabel.center = CGPoint(x:self.bounds.midX, y:self.bounds.midY)
  }
  
  public func startLoading() {
    if status == .Loading {
      return
    }
    
    status = .Loading
    
    //progressLabel.isHidden = true
    progressLabel.text = "0"
    _progress = 0
    
    shapeLayer.strokeStart = 0
    shapeLayer.strokeEnd = 0
    shapeLayer.removeAllAnimations()
    
    //self.isHidden = false
    progressLayer.strokeEnd = 0.0
    progressLayer.removeAllAnimations()
    
    let animation = CABasicAnimation(keyPath: "transform.rotation")
    animation.duration = 4.0
    animation.fromValue = 0.0
    animation.toValue = 2 * Double.pi
    animation.repeatCount = Float.infinity
    progressLayer.add(animation, forKey: dhRingRotationAnimationKey)
    
    let totalDuration = 1.0
    let firstDuration = 2.0 * totalDuration / 3.0
    let secondDuration = totalDuration / 3.0
    
    let headAnimation = CABasicAnimation(keyPath: "strokeStart")
    headAnimation.duration = firstDuration
    headAnimation.fromValue = 0.0
    headAnimation.toValue = 0.25
    
    let tailAnimation = CABasicAnimation(keyPath: "strokeEnd")
    tailAnimation.duration = firstDuration
    tailAnimation.fromValue = 0.0
    tailAnimation.toValue = 1.0
    
    let endHeadAnimation = CABasicAnimation(keyPath: "strokeStart")
    endHeadAnimation.beginTime = firstDuration
    endHeadAnimation.duration = secondDuration
    endHeadAnimation.fromValue = 0.25
    endHeadAnimation.toValue = 1.0
    
    let endTailAnimation = CABasicAnimation(keyPath: "strokeEnd")
    endTailAnimation.beginTime = firstDuration
    endTailAnimation.duration = secondDuration
    endTailAnimation.fromValue = 1.0
    endTailAnimation.toValue = 1.0
    
    let animations = CAAnimationGroup()
    animations.duration = firstDuration + secondDuration
    animations.repeatCount = Float.infinity
    animations.animations = [headAnimation, tailAnimation, endHeadAnimation, endTailAnimation]
    progressLayer.add(animations, forKey: dhRingRotationAnimationKey)
  }
  
  public func completeLoading(success: Bool, completion: Block? = nil) {
    if status == .Completion {
      return
    }
    
    completionBlock = completion
    
   // progressLabel.isHidden = true
    progressLayer.strokeEnd = 1.0
    progressLayer.removeAllAnimations()
    
    if success {
      setStrokeSuccessShapePath()
      self.strokeColor = UIColor.green
    } else {
      setStrokeFailureShapePath()
      self.strokeColor = UIColor.red
    }
    
    var strokeStart :CGFloat = 0.25
    var strokeEnd :CGFloat = 0.8
    var phase1Duration = 0.7 * dhCompletionAnimationDuration
    var phase2Duration = 0.3 * dhCompletionAnimationDuration
    var phase3Duration = 0.0
    
    if !success {
      let square = min(self.bounds.width, self.bounds.height)
      let point = errorJoinPoint()
      let increase = 1.0/3 * square - point.x
      let sum = 2.0/3 * square
      strokeStart = increase / (sum + increase)
      strokeEnd = (increase + sum/2) / (sum + increase)
      
      phase1Duration = 0.5 * dhCompletionAnimationDuration
      phase2Duration = 0.2 * dhCompletionAnimationDuration
      phase3Duration = 0.3 * dhCompletionAnimationDuration
    }
    
    shapeLayer.strokeEnd = 1.0
    shapeLayer.strokeStart = strokeStart
		let timeFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
    
    let headStartAnimation = CABasicAnimation(keyPath: "strokeStart")
    headStartAnimation.fromValue = 0.0
    headStartAnimation.toValue = 0.0
    headStartAnimation.duration = phase1Duration
    headStartAnimation.timingFunction = timeFunction
    
    let headEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
    headEndAnimation.fromValue = 0.0
    headEndAnimation.toValue = strokeEnd
    headEndAnimation.duration = phase1Duration
    headEndAnimation.timingFunction = timeFunction
    
    let tailStartAnimation = CABasicAnimation(keyPath: "strokeStart")
    tailStartAnimation.fromValue = 0.0
    tailStartAnimation.toValue = strokeStart
    tailStartAnimation.beginTime = phase1Duration
    tailStartAnimation.duration = phase2Duration
    tailStartAnimation.timingFunction = timeFunction
    
    let tailEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
    tailEndAnimation.fromValue = strokeEnd
    tailEndAnimation.toValue = success ? 1.0 : strokeEnd
    tailEndAnimation.beginTime = phase1Duration
    tailEndAnimation.duration = phase2Duration
    tailEndAnimation.timingFunction = timeFunction
    
    let extraAnimation = CABasicAnimation(keyPath: "strokeEnd")
    extraAnimation.fromValue = strokeEnd
    extraAnimation.toValue = 1.0
    extraAnimation.beginTime = phase1Duration + phase2Duration
    extraAnimation.duration = phase3Duration
    extraAnimation.timingFunction = timeFunction
    
    let groupAnimation = CAAnimationGroup()
    groupAnimation.animations = [headEndAnimation, headStartAnimation, tailStartAnimation, tailEndAnimation]
    if !success {
      groupAnimation.animations?.append(extraAnimation)
    }
    groupAnimation.duration = phase1Duration + phase2Duration + phase3Duration
    groupAnimation.delegate = self
    shapeLayer.add(groupAnimation, forKey: nil)
  }
  
  public func animationDidStop(_: CAAnimation, finished flag: Bool) {
    if hidesWhenCompleted {
      Timer.scheduledTimer(timeInterval: dhHidesWhenCompletedDelay, target: self, selector: #selector(hiddenLoadingView), userInfo: nil, repeats: false)
    } else {
      status = .Completion
      if completionBlock != nil {
        completionBlock!()
      }
    }
  }
  
  //MARK: - Private
  private func initialize() {
    //progressLabel
    progressLabel.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
    progressLabel.textColor = strokeColor
    progressLabel.textAlignment = .center
    progressLabel.adjustsFontSizeToFitWidth = true
   // progressLabel.isHidden = true
    self.addSubview(progressLabel)
    
    //progressLayer
    progressLayer.strokeColor = strokeColor.cgColor
    progressLayer.fillColor = nil
    progressLayer.lineWidth = lineWidth
    self.layer.addSublayer(progressLayer)
    
    //shapeLayer
    shapeLayer.strokeColor = UIColor.gray.cgColor//strokeColor.cgColor
    shapeLayer.fillColor = nil
    shapeLayer.lineWidth = lineWidth
		shapeLayer.lineCap = CAShapeLayerLineCap.round
		shapeLayer.lineJoin = CAShapeLayerLineJoin.round
    shapeLayer.strokeStart = 0.0
    shapeLayer.strokeEnd = 0.0
    self.layer.addSublayer(shapeLayer)
    
		NotificationCenter.default.addObserver(self, selector:#selector(resetAnimations), name: UIApplication.didBecomeActiveNotification, object: nil)
  }
  
  private func setProgressLayerPath() {
    let center = CGPoint(x:self.bounds.midX, y:self.bounds.midY)
    let radius = (min(self.bounds.width, self.bounds.height) - progressLayer.lineWidth) / 2
    let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: CGFloat(0.0), endAngle: CGFloat(2 * Double.pi), clockwise: true)
    progressLayer.path = path.cgPath
    progressLayer.strokeStart = 0.0
    progressLayer.strokeEnd = 0.0
  }
  
  private func setStrokeSuccessShapePath() {
    let width = self.bounds.width
    let height = self.bounds.height
    let square = min(width, height)
    let b = square/2
    let oneTenth = square/10
    let xOffset = oneTenth
    let yOffset = 1.5 * oneTenth
    let ySpace = 3.2 * oneTenth
    let point = correctJoinPoint()
    
    
    let path = CGMutablePath()
    path.move(to: CGPoint(x:point.x, y:point.y))
    path.addLine(to: CGPoint(x:point.x, y:point.y))
    path.addLine(to: CGPoint(x: b - xOffset, y: b + yOffset))
    path.addLine(to: CGPoint(x: 2 * b - xOffset + yOffset - ySpace, y:ySpace ))
    
    shapeLayer.path = path
    shapeLayer.cornerRadius = square/2
    shapeLayer.masksToBounds = true
    shapeLayer.strokeStart = 0.0
    shapeLayer.strokeEnd = 0.0
  }
  
  private func setStrokeFailureShapePath() {
    let width = self.bounds.width
    let height = self.bounds.height
    let square = min(width, height)
    let b = square/2
    let space = square/3
    let point = errorJoinPoint()
    
    
    let path = CGMutablePath()
    path.move(to: CGPoint(x:point.x, y:point.y))
    path.addLine(to: CGPoint(x:2 * b - space, y: 2 * b - space))
    path.move(to: CGPoint(x:2 * b - space, y: space))
    path.addLine(to: CGPoint(x:space, y:2 * b - space))
    
    shapeLayer.path = path
    shapeLayer.cornerRadius = square/2
    shapeLayer.masksToBounds = true
    shapeLayer.strokeStart = 0
    shapeLayer.strokeEnd = 0.0
  }
  
  private func correctJoinPoint() -> CGPoint {
    let r = min(self.bounds.width, self.bounds.height)/2
    let m = r/2
    let k = lineWidth/2
    
    let a: CGFloat = 2.0
    let b = -4 * r + 2 * m
    let c = (r - m) * (r - m) + 2 * r * k - k * k
    let x = (-b - sqrt(b * b - 4 * a * c))/(2 * a)
    let y = x + m
    
    return CGPoint(x:x, y:y)
  }
  
  private func errorJoinPoint() -> CGPoint {
    let r = min(self.bounds.width, self.bounds.height)/2
    let k = lineWidth/2
    
    let a: CGFloat = 2.0
    let b = -4 * r
    let c = r * r + 2 * r * k - k * k
    let x = (-b - sqrt(b * b - 4 * a * c))/(2 * a)
    
    return CGPoint(x:x, y:x)
  }
  
  @objc private func resetAnimations() {
    if status == .Loading {
      status = .Unknown
      progressLayer.removeAnimation(forKey: dhRingRotationAnimationKey)
      progressLayer.removeAnimation(forKey: dhRingStorkeAnimationKey)
      startLoading()
    }
  }
  
  @objc private func hiddenLoadingView() {
    status = .Completion
   // self.isHidden = true
    
    if completionBlock != nil {
      completionBlock!()
    }
  }
}
