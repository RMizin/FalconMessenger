import UIKit

class InAppNotificationBanner: CustomizedView {
  
    private let contentView: CustomizedView = {
        let view = CustomizedView()
        view.clipsToBounds = true
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.cornerRadius = 20
        return view
    }()
    
    private let pictureImageView: CustomizedImageView = {
        let view = CustomizedImageView()
        view.clipsToBounds = true
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
				view.contentMode = UIView.ContentMode.scaleAspectFill
        view.cornerRadius = 20
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.clipsToBounds = true
        label.backgroundColor = .clear
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 17)
        return label
    }()
    
    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.clipsToBounds = true
        label.backgroundColor = .clear
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    private let indicatorView: CustomizedView = {
        let view = CustomizedView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.clipsToBounds = true
        view.cornerRadius = 3
        return view
    }()
    
    override init(frame: CGRect) {
      super.init(frame: frame)
      setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      setupViews()
    }
  
    private func setupViews() {
      addSubview(contentView)
      let contentViewConstraints: [NSLayoutConstraint] = [
        NSLayoutConstraint(item: contentView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 10),
        NSLayoutConstraint(item: contentView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -10),
        contentView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
        contentView.widthAnchor.constraint(lessThanOrEqualToConstant: 500),
        contentView.heightAnchor.constraint(equalToConstant: 96),
        contentView.topAnchor.constraint(equalTo: topAnchor, constant: 5)
      ]
      contentViewConstraints[0].priority = UILayoutPriority.defaultHigh
      contentViewConstraints[1].priority = UILayoutPriority.defaultHigh
      NSLayoutConstraint.activate(contentViewConstraints)
      
      contentView.addSubview(pictureImageView)
      contentView.addSubview(titleLabel)
      contentView.addSubview(detailsLabel)
      contentView.addSubview(indicatorView)
      
      NSLayoutConstraint.activate([
        pictureImageView.widthAnchor.constraint(equalToConstant: 40),
        pictureImageView.heightAnchor.constraint(equalToConstant: 40),
        pictureImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25),
        pictureImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
        titleLabel.leadingAnchor.constraint(equalTo: pictureImageView.trailingAnchor, constant: 10),
        titleLabel.heightAnchor.constraint(equalToConstant: 25),
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
        titleLabel.topAnchor.constraint(equalTo: pictureImageView.topAnchor),
        detailsLabel.leadingAnchor.constraint(equalTo: pictureImageView.trailingAnchor, constant: 10),
        detailsLabel.heightAnchor.constraint(equalToConstant: 20),
        detailsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
        detailsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
        indicatorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        indicatorView.widthAnchor.constraint(equalToConstant: 50),
        indicatorView.heightAnchor.constraint(equalToConstant: 6),
        indicatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
    }
  
    var notification: InAppNotification?
    
    func updateUI() {
        self.titleLabel.text = notification?.title
        self.detailsLabel.text = notification?.subtitle
        
        if let url = notification?.resource as? URL, let data = notification?.data, let placeholder = UIImage(data: data) {
          pictureImageView.sd_setImage(with: url, placeholderImage: placeholder, options: [.continueInBackground, .scaleDownLargeImages], completed: nil)
        } else if let image = notification?.resource as? UIImage {
          self.pictureImageView.image = image
        } else if let data = notification?.resource as? Data, let image = UIImage(data: data) {
          self.pictureImageView.image = image
        } else {
          self.pictureImageView.image = UIImage(named: "NotificationPlaceholder")
        }
    }
    
    static let height: CGFloat = 106
    static let top: CGFloat = 5
}
