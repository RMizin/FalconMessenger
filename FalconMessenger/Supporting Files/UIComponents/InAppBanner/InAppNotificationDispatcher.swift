import UIKit

public class InAppNotificationDispatcher {
    public static let shared = InAppNotificationDispatcher()
    
    private var bannerWindow: UIWindow = UIWindow(frame: .zero)
    private let banner: InAppNotificationBanner = {
        let view: InAppNotificationBanner = InAppNotificationBanner(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private let animationDuration: TimeInterval = 0.3
    private let appearDuration: TimeInterval = 2.0
    private var animator: UIViewPropertyAnimator?
    
    // First constraint is always going to be the top constraint
    private var bannerConstraints: [NSLayoutConstraint] = []
    private var timer: Timer?
    private var bannerClickCallback: ((InAppNotification) -> ())?
    
    // MARK: - Init
    private init() {
        setupListeners()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public API methods
    public func show(notification: InAppNotification, clickCallback: @escaping (InAppNotification) -> ()) {
        bannerWindow = UIWindow(frame: .zero)
        banner.removeGestureRecgonizers()
        banner.notification = notification
        banner.updateUI()
        bannerClickCallback = clickCallback
        setupBannerGestureRecognizers(banner: banner)
        
        timer?.invalidate()
        timer = nil
        showBanner {
            self.timer?.invalidate()
            self.timer = self.startTimer(timeInterval: self.appearDuration) {
                self.timer?.invalidate()
                self.timer = nil
                self.hideBanner(animated: true) { }
            }
        }
    }
    
    // MARK: - Show/Hide banner
    private func showBanner(_ completion: @escaping () -> ()) {
        bannerWindow = initializeNewWindow()
        setup(window: bannerWindow, for: UIApplication.shared.statusBarOrientation, in: UIDevice.current.userInterfaceIdiom)
      
        bannerWindow.makeKeyAndVisible()
        
    //    banner.alpha = 0.0
        bannerWindow.addSubview(banner)
        bannerConstraints = setupBannerConstraints(banner: banner, bannerWindow: bannerWindow)
        NSLayoutConstraint.activate(bannerConstraints)
        bannerWindow.layoutIfNeeded()

        bannerConstraints[0].constant = 0
        animator?.stopAnimation(true)
				animator = UIViewPropertyAnimator(duration: animationDuration, curve: UIView.AnimationCurve.easeOut) {
           // self.banner.alpha = 1.0
            self.bannerWindow.layoutIfNeeded()
        }
        animator?.addCompletion { _ in
            self.animator?.stopAnimation(true)
            self.animator = nil
            completion()
        }
        animator?.startAnimation()
    }
    
    private func hideBanner(animated: Bool, _ completion: @escaping () -> ()) {
        bannerConstraints[0].constant = -InAppNotificationBanner.height - 50
        animator?.stopAnimation(true)
        
        if animated {
						animator = UIViewPropertyAnimator(duration: animationDuration, curve: UIView.AnimationCurve.linear) {
              self.bannerWindow.layoutIfNeeded()
            }
            animator?.addCompletion { _ in
              self.bannerWindow = UIWindow(frame: .zero)
              self.animator?.stopAnimation(true)
              self.animator = nil
              self.banner.removeGestureRecgonizers()
              self.bannerClickCallback = nil
              completion()
            }
            animator?.startAnimation()
        } else {
          self.bannerWindow.layoutIfNeeded()
          self.bannerWindow = UIWindow(frame: .zero)
          self.animator?.stopAnimation(true)
          self.animator = nil
          self.banner.removeGestureRecgonizers()
          self.bannerClickCallback = nil
          completion()
        }
    }
    
    // MARK: - Setup
    private func setupListeners() {
			NotificationCenter.default.addObserver(self,
																						 selector: #selector(statusBarDidChangeFrame(_:)),
																						 name: UIApplication.didChangeStatusBarFrameNotification,
																						 object: nil)
    }

    private func startTimer(timeInterval: TimeInterval, callback: @escaping () -> ()) -> Timer {
        return Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { (_) in
            callback()
        }
    }
    
    private func initializeNewWindow() -> UIWindow {
        let window = UIWindow(frame: .zero)
        window.backgroundColor = UIColor.clear
			window.windowLevel = UIWindow.Level.alert
        return window
    }
    
    private func setup(window: UIWindow, for orientation: UIInterfaceOrientation, in userInterfaceIdiom: UIUserInterfaceIdiom) {
        window.transform = windowTransformation(for: orientation, in: userInterfaceIdiom)
        window.frame = windowFrame(for: orientation, in: userInterfaceIdiom)
        window.layoutIfNeeded()
    }
    
    private func setupBannerConstraints(banner: InAppNotificationBanner, bannerWindow: UIWindow) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        if #available(iOS 11.0, *) {
            constraints.append(banner.topAnchor.constraint(equalTo: bannerWindow.safeAreaLayoutGuide.topAnchor, constant: -InAppNotificationBanner.height))
            constraints.append(banner.leadingAnchor.constraint(equalTo: bannerWindow.safeAreaLayoutGuide.leadingAnchor, constant: 0))
            constraints.append(banner.trailingAnchor.constraint(equalTo: bannerWindow.safeAreaLayoutGuide.trailingAnchor, constant: 0))
            constraints.append(banner.heightAnchor.constraint(equalToConstant: InAppNotificationBanner.height))
        } else {
            constraints.append(banner.topAnchor.constraint(equalTo: bannerWindow.topAnchor, constant: -InAppNotificationBanner.height))
            constraints.append(banner.leadingAnchor.constraint(equalTo: bannerWindow.leadingAnchor, constant: 0))
            constraints.append(banner.trailingAnchor.constraint(equalTo: bannerWindow.trailingAnchor, constant: 0))
            constraints.append(banner.heightAnchor.constraint(equalToConstant: InAppNotificationBanner.height))
        }
        return constraints
    }
    
    private func setupBannerGestureRecognizers(banner: InAppNotificationBanner) {
      banner.isUserInteractionEnabled = true
      
      let tapGR = UITapGestureRecognizer(target: self, action: #selector(bannerClicked(_:)))
      tapGR.numberOfTapsRequired = 1
      banner.addGestureRecognizer(tapGR)
      
      let swipeGR = UISwipeGestureRecognizer(target: self, action: #selector(bannerSwipped(_:)))
      swipeGR.direction = .up
      banner.addGestureRecognizer(swipeGR)
      banner.addGestureRecognizer(panGestureRecognizer)
    }
  
    open fileprivate(set) lazy var panGestureRecognizer: UIPanGestureRecognizer = { [unowned self] in
      let gesture = UIPanGestureRecognizer()
      gesture.addTarget(self, action: #selector(handlePanGestureRecognizer(_:)))
      
      return gesture
    }()

    @objc private func handlePanGestureRecognizer(_ sender: UIPanGestureRecognizer) {
      guard let banner = sender.view as? InAppNotificationBanner else { return }
      let translation = panGestureRecognizer.translation(in: banner)
      
      if panGestureRecognizer.state == .began {
        self.timer?.invalidate()
        self.timer = nil
      } else if panGestureRecognizer.state == .changed {
        let maxTranslation: CGFloat = 50
        
        if translation.y < maxTranslation {
          banner.frame.origin.y = translation.y
        } else {
          banner.frame.origin.y = maxTranslation
        }
      } else {
        banner.removeGestureRecgonizers()
        self.hideBanner(animated: true) {}
      }
    }

    private func windowTransformation(for orientation: UIInterfaceOrientation, in userInterfaceIdiom: UIUserInterfaceIdiom) -> CGAffineTransform {
        if userInterfaceIdiom == .pad {
          return CGAffineTransform(rotationAngle: -CGFloat(360).degreesToRadians)
        }

        switch orientation {
        case .landscapeLeft:
            return CGAffineTransform(rotationAngle: -CGFloat(90).degreesToRadians)
        case .landscapeRight:
            return CGAffineTransform(rotationAngle: CGFloat(90).degreesToRadians)
        case .portrait:
            return CGAffineTransform(rotationAngle: -CGFloat(360).degreesToRadians)
        case .portraitUpsideDown:
            return CGAffineTransform.identity
        case .unknown:
            return CGAffineTransform(rotationAngle: CGFloat(0).degreesToRadians)
				@unknown default:
					fatalError()
			}
    }
    
    private func windowFrame(for orientation: UIInterfaceOrientation, in userInterfaceIdiom: UIUserInterfaceIdiom) -> CGRect {
        if userInterfaceIdiom == .pad {
            return CGRect(x: 0, y: InAppNotificationBanner.top, width: UIScreen.main.bounds.size.width, height: InAppNotificationBanner.height)
        }
        
        switch orientation {
        case .landscapeLeft:
          return CGRect(x:InAppNotificationBanner.top, y: 0, width: InAppNotificationBanner.height, height: UIScreen.main.bounds.size.width)
         //   return CGRect(x: InAppNotificationBanner.top, y: 0, width: InAppNotificationBanner.height, height: UIScreen.main.bounds.size.width )
        case .landscapeRight:
            return CGRect(x: UIScreen.main.bounds.size.height - InAppNotificationBanner.height - InAppNotificationBanner.top, y: 0, width: InAppNotificationBanner.height, height: UIScreen.main.bounds.size.width)
        case .portrait:
            return CGRect(x: 0, y: InAppNotificationBanner.top, width: UIScreen.main.bounds.size.width, height: InAppNotificationBanner.height)
        case .portraitUpsideDown:
            return CGRect(x: 0, y: InAppNotificationBanner.top, width: UIScreen.main.bounds.size.width, height: InAppNotificationBanner.height)
        case .unknown:
            return CGRect(x: 0, y: InAppNotificationBanner.top, width: UIScreen.main.bounds.size.width, height: InAppNotificationBanner.height)
				@unknown default:
					fatalError()
			}
    }
    
    // MARK: - UI Interactions
    @objc private func bannerClicked(_ sender: UITapGestureRecognizer) {
        guard let banner = sender.view as? InAppNotificationBanner else { return }
        guard let notification = banner.notification else { return }
        bannerClickCallback?(notification)
       hideBanner(animated: true) {}
//        hideBanner(animated: true) {
//            self.timer?.invalidate()
//            self.timer = nil
//        }
    }
    
    @objc private func bannerSwipped(_ sender: UISwipeGestureRecognizer) {
        guard let banner = sender.view as? InAppNotificationBanner else { return }
        banner.removeGestureRecgonizers()
        hideBanner(animated: true) {}
    }
    
    // MARK: - Listeners
    @objc private func statusBarDidChangeFrame(_ notification: Notification) {
        setup(window: bannerWindow, for: UIApplication.shared.statusBarOrientation, in: UIDevice.current.userInterfaceIdiom)
    }
}

extension CGFloat {
    var degreesToRadians: CGFloat {
        return (self * CGFloat.pi) / 180
    }
}

