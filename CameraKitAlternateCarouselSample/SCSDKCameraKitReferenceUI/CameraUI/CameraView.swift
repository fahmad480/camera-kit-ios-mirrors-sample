//  Copyright Snap Inc. All rights reserved.
//  CameraKit

import AVFoundation
import AVKit
import SCSDKCameraKit
import UIKit

/// A UILabel subclass that adds padding around the text
public class PaddedLabel: UILabel {
    public var padding = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    
    override public func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }
    
    override public var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + padding.left + padding.right,
                      height: size.height + padding.top + padding.bottom)
    }
}

/// This is the default view that backs the CameraViewController.
open class CameraView: UIView {
    private enum Constants {
        static let cameraFlip = "ck_camera_flip"
        static let lensExplore = "ck_lens_explore"
    }

    /// default camerakit view to draw outputted textures
    public let previewView: PreviewView = {
        let view = PreviewView()
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// Resolution label to display camera resolution
    public let resolutionLabel: PaddedLabel = {
        let label = PaddedLabel()
        label.textColor = .white
        label.backgroundColor = UIColor(white: 0, alpha: 0.5)
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Resolution: --"
        label.isHidden = false
        return label
    }()

    /// button to flip camera input position in full frame
    public lazy var fullFrameFlipCameraButton: UIButton = {
        let button = UIButton(type: .custom)
        button.accessibilityIdentifier = CameraElements.flipCameraButton.id
        button.accessibilityValue = CameraElements.CameraFlip.front
        button.accessibilityLabel = NSLocalizedString("Camera Flip Button", comment: "")
        button.setImage(
            UIImage(named: Constants.cameraFlip, in: BundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    /// button to flip camera input position in small frame
    public lazy var smallFrameFlipCameraButton: UIButton = {
        let button = UIButton(type: .custom)
        button.accessibilityIdentifier = CameraElements.flipCameraButton.id
        button.accessibilityValue = CameraElements.CameraFlip.front
        button.accessibilityLabel = NSLocalizedString("Camera Flip Button", comment: "")
        button.setImage(
            UIImage(named: Constants.cameraFlip, in: BundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true

        return button
    }()

    /// Debug button for frame orientation
    public let frameOrientationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Frame: Portrait", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// Debug button for video orientation
    public let videoOrientationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Video: Portrait", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// Debug button for mirror control
    public let mirrorButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Mirror: On", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// Debug button for camera position
    public let positionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Position: Front", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// current lens information bar plus clear current lens button
    public let clearLensView: ClearLensView = {
        let view = ClearLensView()
        view.backgroundColor = UIColor(hex: 0x16191C, alpha: 0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true

        return view
    }()

    public let hintLabel: UILabel = {
        let label = UILabel()
        label.alpha = 0.0
        label.font = .boldSystemFont(ofSize: 20.0)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    /// camera button to capture/record
    public let cameraButton: CameraButton = {
        let view = CameraButton()
        view.accessibilityIdentifier = CameraElements.cameraButton.id
        view.isAccessibilityElement = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// lens button to open lens picker
    public let lensPickerButton: UIButton = {
        let button = UIButton(type: .custom)
        button.accessibilityIdentifier = CameraElements.lensPickerButton.id
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(
            UIImage(named: Constants.lensExplore, in: BundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        return button
    }()

    public let snapWatermark: SnapWatermarkView = {
        let view = SnapWatermarkView()
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    public let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        if #available(iOS 13, *) {
            view.style = .large
            view.color = .white
        } else {
            view.style = .whiteLarge
        }

        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("Unimplemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
    }

}

// MARK: General View Setup

extension CameraView {

    private func setup() {
        setupPreview()
        setupHintLabel()
        setupCameraRing()
        setupLensPickerButton()
        setupFlipButtons()
        setupCameraBar()
        setupWatermark()
        setupActivityIndicator()
        setupDebugButtons()
        setupResolutionLabel()
    }

    private func setupPreview() {
        addSubview(previewView)
        NSLayoutConstraint.activate([
            previewView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewView.topAnchor.constraint(equalTo: topAnchor),
            previewView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupDebugButtons() {
        addSubview(frameOrientationButton)
        addSubview(videoOrientationButton)
        addSubview(mirrorButton)
        addSubview(positionButton)

        NSLayoutConstraint.activate([
            // Frame orientation button
            frameOrientationButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            frameOrientationButton.bottomAnchor.constraint(equalTo: cameraButton.topAnchor, constant: -16),
            frameOrientationButton.widthAnchor.constraint(equalToConstant: 120),
            frameOrientationButton.heightAnchor.constraint(equalToConstant: 44),

            // Video orientation button
            videoOrientationButton.leadingAnchor.constraint(equalTo: frameOrientationButton.trailingAnchor, constant: 8),
            videoOrientationButton.bottomAnchor.constraint(equalTo: cameraButton.topAnchor, constant: -16),
            videoOrientationButton.widthAnchor.constraint(equalToConstant: 120),
            videoOrientationButton.heightAnchor.constraint(equalToConstant: 44),

            // Mirror button
            mirrorButton.leadingAnchor.constraint(equalTo: videoOrientationButton.trailingAnchor, constant: 8),
            mirrorButton.bottomAnchor.constraint(equalTo: cameraButton.topAnchor, constant: -16),
            mirrorButton.widthAnchor.constraint(equalToConstant: 80),
            mirrorButton.heightAnchor.constraint(equalToConstant: 44),

            // Position button
            positionButton.leadingAnchor.constraint(equalTo: mirrorButton.trailingAnchor, constant: 8),
            positionButton.bottomAnchor.constraint(equalTo: cameraButton.topAnchor, constant: -16),
            positionButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            positionButton.widthAnchor.constraint(equalToConstant: 100),
            positionButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

}

// MARK: Camera Bottom Bar

extension CameraView {

    private func setupCameraBar() {
        addSubview(clearLensView)
        NSLayoutConstraint.activate([
            clearLensView.centerXAnchor.constraint(equalTo: centerXAnchor),
            clearLensView.bottomAnchor.constraint(equalTo: cameraButton.topAnchor, constant: -24),
            clearLensView.heightAnchor.constraint(equalToConstant: 40.0),
            clearLensView.widthAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.width - 40*2),
        ])
    }

}

// MARK: Camera Ring

extension CameraView {

    private func setupCameraRing() {
        addSubview(cameraButton)
        NSLayoutConstraint.activate([
            cameraButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -68.0),
            cameraButton.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }

    private func setupLensPickerButton() {
        addSubview(lensPickerButton)
        NSLayoutConstraint.activate([
            lensPickerButton.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            lensPickerButton.trailingAnchor.constraint(equalTo: cameraButton.leadingAnchor, constant: -24)
        ])
    }

    private func setupFlipButtons() {
        addSubview(fullFrameFlipCameraButton)
        NSLayoutConstraint.activate([
            fullFrameFlipCameraButton.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            fullFrameFlipCameraButton.leadingAnchor.constraint(equalTo: cameraButton.trailingAnchor, constant: 24)
        ])

        addSubview(smallFrameFlipCameraButton)
        NSLayoutConstraint.activate([
            smallFrameFlipCameraButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            smallFrameFlipCameraButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])
    }

    func updateFlipButton(isInFullScreen: Bool) {
        fullFrameFlipCameraButton.isHidden = !isInFullScreen
        smallFrameFlipCameraButton.isHidden = isInFullScreen
    }

}

// MARK: Watermark

extension CameraView {

    private func setupWatermark() {
        addSubview(snapWatermark)
        NSLayoutConstraint.activate([
            snapWatermark.topAnchor.constraint(equalTo: topAnchor, constant: 73),
            snapWatermark.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
}

// MARK: Hint

extension CameraView {

    private func setupHintLabel() {
        addSubview(hintLabel)
        NSLayoutConstraint.activate([
            hintLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            hintLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

}

// MARK: Activity Indicator

extension CameraView {

    public func setupActivityIndicator() {
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

}

// MARK: Resolution Label

extension CameraView {
    
    private func setupResolutionLabel() {
        addSubview(resolutionLabel)
        NSLayoutConstraint.activate([
            resolutionLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            resolutionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            resolutionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
        ])
    }
    
    public func updateResolutionLabel(with size: CGSize) {
        let width = Int(size.width)
        let height = Int(size.height)
        
        // Ensure UI updates happen on main thread
        DispatchQueue.main.async { [weak self] in
            self?.resolutionLabel.text = "\(width)×\(height)"
        }
    }
    
}

// MARK: Tap to Focus

extension CameraView {

    public func drawTapAnimationView(at point: CGPoint) {
        let view = TapAnimationView(center: point)
        addSubview(view)

        view.show()
    }

}
