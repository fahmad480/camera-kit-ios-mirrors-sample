//  Copyright Snap Inc. All rights reserved.
//  CameraKitSandbox

import Photos
import UIKit

/// Base preview view controller that describes properties and views of all preview controllers
public class PreviewViewController: UIViewController {

    /// Callback when user presses close button and dismisses preview view controller
    public var onDismiss: (() -> Void)?

    // MARK: View Properties

    fileprivate let closeButton: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = PreviewElements.closeButton.id
        button.setImage(
            UIImage(named: "ck_close_x", in: BundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    fileprivate let uploadButton: UIButton = {
        let button = UIButton()
        button.setTitle("Upload", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    fileprivate let cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.backgroundColor = .systemGray
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    fileprivate let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.isHidden = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    fileprivate let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.7
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    fileprivate let qrCodeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    fileprivate let qrCodeCloseButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    fileprivate lazy var uploadButtonStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [uploadButton, cancelButton])
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 16.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: Setup

    override public func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        view.backgroundColor = .black
        setupCloseButton()
        setupUploadButtons()
        setupLoadingIndicator()
        setupOverlayView()
        setupQRCodeView()
    }

    // MARK: Overridable Actions

    func uploadPreview() {
        fatalError("upload preview action has to be implemented by subclass")
    }

    func showLoading() {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        uploadButtonStackView.isHidden = true
        overlayView.isHidden = true
    }

    func hideLoading() {
        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()
        uploadButtonStackView.isHidden = false
        overlayView.isHidden = true
    }
}

// MARK: Close Button

extension PreviewViewController {
    fileprivate func setupCloseButton() {
        closeButton.addTarget(self, action: #selector(self.closeButtonPressed(_:)), for: .touchUpInside)
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32.0),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16.0),
        ])
    }

    @objc private func closeButtonPressed(_ sender: UIButton) {
        onDismiss?()
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Upload Buttons

extension PreviewViewController {
    fileprivate func setupUploadButtons() {
        uploadButton.addTarget(self, action: #selector(uploadButtonPressed(_:)), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed(_:)), for: .touchUpInside)
        view.addSubview(uploadButtonStackView)
        NSLayoutConstraint.activate([
            uploadButtonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            uploadButtonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32.0),
            uploadButtonStackView.widthAnchor.constraint(equalToConstant: 256),
            uploadButtonStackView.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc private func uploadButtonPressed(_ sender: UIButton) {
        uploadPreview()
    }

    @objc private func cancelButtonPressed(_ sender: UIButton) {
        onDismiss?()
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Loading Indicator

extension PreviewViewController {
    fileprivate func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

// MARK: Overlay View

extension PreviewViewController {
    fileprivate func setupOverlayView() {
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: QR Code View

extension PreviewViewController {
    fileprivate func setupQRCodeView() {
        view.addSubview(qrCodeImageView)
        view.addSubview(qrCodeCloseButton)
        
        NSLayoutConstraint.activate([
            qrCodeImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrCodeImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            qrCodeImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            qrCodeImageView.heightAnchor.constraint(equalTo: qrCodeImageView.widthAnchor),
            
            qrCodeCloseButton.topAnchor.constraint(equalTo: qrCodeImageView.bottomAnchor, constant: 16),
            qrCodeCloseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrCodeCloseButton.widthAnchor.constraint(equalToConstant: 44),
            qrCodeCloseButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        qrCodeCloseButton.addTarget(self, action: #selector(qrCodeCloseButtonPressed(_:)), for: .touchUpInside)
    }
    
    @objc private func qrCodeCloseButtonPressed(_ sender: UIButton) {
        qrCodeImageView.isHidden = true
        qrCodeCloseButton.isHidden = true
        overlayView.isHidden = true
        uploadButtonStackView.isHidden = false
    }
    
    func showQRCode(_ qrCodeImage: UIImage) {
        qrCodeImageView.image = qrCodeImage
        qrCodeImageView.isHidden = false
        qrCodeCloseButton.isHidden = false
        overlayView.isHidden = false
        uploadButtonStackView.isHidden = true
    }
}
