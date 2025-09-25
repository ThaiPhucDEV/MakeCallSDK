//
//  CallViewController.swift
//  MakeCallSDKFramework
//
//  Created by PHUC on 19/9/25.
//

import UIKit
import AVFoundation

// MARK: - Call View Controller Delegate
public protocol CallViewControllerDelegate: AnyObject {
    func didTapHangup()
    func didTapSpeaker()
    func didTapMicrophone()
    func didTapKeypad()
}

// MARK: - Call View Controller
public class CallViewController: UIViewController {
    
    // MARK: - Properties
    public weak var delegate: CallViewControllerDelegate?
    
    // UI Elements
    private let backgroundGradientLayer = CAGradientLayer()
    private let avatarImageView = UIImageView()
    private let callerNameLabel = UILabel()
    private let statusLabel = UILabel()
    private let callTimeLabel = UILabel()
    
    // Control buttons container
    private let controlsStackView = UIStackView()
    private let speakerButton = UIButton(type: .system)
    private let microphoneButton = UIButton(type: .system)
    private let keypadButton = UIButton(type: .system)
    
    // End call button
    private let endCallButton = UIButton(type: .system)
    
    // State
    private var currentCallState: CallState = .calling
    private var callTimer: Timer?
    private var callStartTime: Date?
    private var callDuration: TimeInterval = 0
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupEventObserver()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ensureAudioSessionActive()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            removeEventObserver()
            stopCallTimer()
        }
    }
    
//    deinit {
//        removeEventObserver()
//        stopCallTimer()
//    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        setupBackground()
        setupAvatarSection()
        setupControlButtons()
        setupEndCallButton()
        setupConstraints()
        setupAccessibility()
    }
    
    private func setupBackground() {
        // Create iOS-like gradient background (light blue to dark blue)
        backgroundGradientLayer.colors = [
            UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0).cgColor,  // Light blue
            UIColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1.0).cgColor   // Dark blue
        ]
        backgroundGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)
    }
    
    private func setupAvatarSection() {
        // Avatar
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 70
        avatarImageView.layer.masksToBounds = true
        avatarImageView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        avatarImageView.layer.borderWidth = 3
        avatarImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Default avatar icon (person silhouette)
        let personIcon = createPersonIcon()
        avatarImageView.image = personIcon
        
        // Caller name
        callerNameLabel.font = UIFont.systemFont(ofSize: 32, weight: .light)
        callerNameLabel.textColor = .white
        callerNameLabel.textAlignment = .center
        callerNameLabel.numberOfLines = 2
        callerNameLabel.text = "Unknown Caller"
        callerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Status label
        statusLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        statusLabel.textAlignment = .center
        statusLabel.text = "Calling…"
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Call time label (hidden initially)
        callTimeLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        callTimeLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        callTimeLabel.textAlignment = .center
        callTimeLabel.isHidden = true
        callTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(avatarImageView)
        view.addSubview(callerNameLabel)
        view.addSubview(statusLabel)
        view.addSubview(callTimeLabel)
    }
    
    private func setupControlButtons() {
        controlsStackView.axis = .horizontal
        controlsStackView.distribution = .equalSpacing
        controlsStackView.alignment = .center
        controlsStackView.spacing = 40
        controlsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Speaker Button
        configureControlButton(speakerButton,
                             iconName: "speaker.wave.2.fill",
                             action: #selector(speakerTapped))
        
        // Microphone Button
        configureControlButton(microphoneButton,
                             iconName: "mic.fill",
                             action: #selector(microphoneTapped))
        
        // Keypad Button
        configureControlButton(keypadButton,
                             iconName: "keyboard.fill",
                             action: #selector(keypadTapped))
        
        controlsStackView.addArrangedSubview(speakerButton)
        controlsStackView.addArrangedSubview(microphoneButton)
        controlsStackView.addArrangedSubview(keypadButton)
        
        view.addSubview(controlsStackView)
    }
    
    private func configureControlButton(_ button: UIButton,
                                           iconName: String,
                                           action: Selector) {
           button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
           button.layer.cornerRadius = 35
           button.layer.masksToBounds = false
           
           button.layer.shadowColor = UIColor.black.cgColor
           button.layer.shadowOffset = CGSize(width: 0, height: 4)
           button.layer.shadowRadius = 8
           button.layer.shadowOpacity = 0.3
           
           // Set tint color for better visibility
           button.tintColor = .white
           
           var icon: UIImage?
           
           // Try to load from system first (iOS 13+)
           if #available(iOS 13.0, *) {
               let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
               icon = UIImage(systemName: iconName, withConfiguration: config)
           }
           
           // Fallback to custom assets from framework bundle
           if icon == nil {
               icon = UIImage.fromFramework(named: iconName)
           }
           
           // Ultimate fallback - create simple icon
           if icon == nil {
               icon = createFallbackIcon(for: iconName)
           }
           
           button.setImage(icon, for: .normal)
           button.translatesAutoresizingMaskIntoConstraints = false
           button.addTarget(self, action: action, for: .touchUpInside)
           
           NSLayoutConstraint.activate([
               button.widthAnchor.constraint(equalToConstant: 70),
               button.heightAnchor.constraint(equalToConstant: 70)
           ])
       }
    
    private func createFallbackIcon(for iconName: String) -> UIImage? {
            let size = CGSize(width: 24, height: 24)
            let renderer = UIGraphicsImageRenderer(size: size)
            
            return renderer.image { context in
                UIColor.white.setFill()
                
                switch iconName {
                case "speaker.wave.2.fill":
                    // Simple speaker icon
                    let rect = CGRect(x: 2, y: 8, width: 8, height: 8)
                    UIBezierPath(rect: rect).fill()
                    
                    let triangle = UIBezierPath()
                    triangle.move(to: CGPoint(x: 10, y: 6))
                    triangle.addLine(to: CGPoint(x: 18, y: 2))
                    triangle.addLine(to: CGPoint(x: 18, y: 22))
                    triangle.addLine(to: CGPoint(x: 10, y: 18))
                    triangle.close()
                    triangle.fill()
                    
                case "mic.fill":
                    // Simple microphone icon
                    let rect = CGRect(x: 10, y: 4, width: 4, height: 12)
                    UIBezierPath(roundedRect: rect, cornerRadius: 2).fill()
                    
                    let stand = CGRect(x: 11, y: 16, width: 2, height: 4)
                    UIBezierPath(rect: stand).fill()
                    
                case "keypad", "grid.circle.fill":
                    // Simple keypad/grid icon
                    for row in 0..<3 {
                        for col in 0..<3 {
                            let x = CGFloat(col * 6 + 3)
                            let y = CGFloat(row * 6 + 3)
                            let dot = CGRect(x: x, y: y, width: 3, height: 3)
                            UIBezierPath(roundedRect: dot, cornerRadius: 1.5).fill()
                        }
                    }
                    
                default:
                    // Default icon - circle
                    let circle = CGRect(x: 8, y: 8, width: 8, height: 8)
                    UIBezierPath(ovalIn: circle).fill()
                }
            }
        }


    
    private func setupEndCallButton() {
         endCallButton.backgroundColor = .systemRed
         endCallButton.layer.cornerRadius = 35
         endCallButton.layer.masksToBounds = false
         
         // Enhanced shadow for prominence
         endCallButton.layer.shadowColor = UIColor.black.cgColor
         endCallButton.layer.shadowOffset = CGSize(width: 0, height: 6)
         endCallButton.layer.shadowRadius = 12
         endCallButton.layer.shadowOpacity = 0.2
         
         endCallButton.tintColor = .white
         
         // End call icon
         if #available(iOS 13.0, *) {
             let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
             let endCallIcon = UIImage(systemName: "phone.down.fill", withConfiguration: config)
             endCallButton.setImage(endCallIcon, for: .normal)
         } else {
             // Fallback for iOS 12 and earlier
             let endCallIcon = UIImage.fromFramework(named: "phone.down.fill") ?? createFallbackIcon(for: "phone.down.fill")
             endCallButton.setImage(endCallIcon, for: .normal)
         }
         
         endCallButton.translatesAutoresizingMaskIntoConstraints = false
         endCallButton.addTarget(self, action: #selector(hangupTapped), for: .touchUpInside)
         
         view.addSubview(endCallButton)
     }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Avatar
            avatarImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            avatarImageView.widthAnchor.constraint(equalToConstant: 140),
            avatarImageView.heightAnchor.constraint(equalToConstant: 140),
            
            // Caller name
            callerNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            callerNameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 24),
            callerNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            callerNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            
            // Status label
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: callerNameLabel.bottomAnchor, constant: 12),
            
            // Call time label
            callTimeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            callTimeLabel.topAnchor.constraint(equalTo: callerNameLabel.bottomAnchor, constant: 12),
            
            // Control buttons
            controlsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controlsStackView.bottomAnchor.constraint(equalTo: endCallButton.topAnchor, constant: -60),
            controlsStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            controlsStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            
            // End call button
            endCallButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            endCallButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            endCallButton.widthAnchor.constraint(equalToConstant: 70),
            endCallButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    private func setupAccessibility() {
        avatarImageView.accessibilityLabel = "Caller Avatar"
        callerNameLabel.accessibilityLabel = "Caller Name"
        statusLabel.accessibilityLabel = "Call Status"
        callTimeLabel.accessibilityLabel = "Call Duration"
        
        speakerButton.accessibilityLabel = "Toggle Speaker"
        microphoneButton.accessibilityLabel = "Toggle Microphone"
        keypadButton.accessibilityLabel = "Show Keypad"
        endCallButton.accessibilityLabel = "End Call"
    }
    
    private func setupEventObserver() {
        MakeCallEventManager.shared.addObserver(self)
    }
    
    private func removeEventObserver() {
        MakeCallEventManager.shared.removeObserver(self)
    }
    
    private func ensureAudioSessionActive() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to activate audio session: \(error)")
        }
    }
    
    private func updateGradientFrame() {
        backgroundGradientLayer.frame = view.bounds
    }
    
    // MARK: - Helper Methods
    
    private func createPersonIcon() -> UIImage? {
        let size = CGSize(width: 80, height: 80)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Set fill color
            UIColor.white.withAlphaComponent(0.6).setFill()
            
            // Draw person silhouette
            let path = UIBezierPath()
            
            // Head (circle)
            let headRect = CGRect(x: 25, y: 10, width: 30, height: 30)
            path.append(UIBezierPath(ovalIn: headRect))
            
            // Body (arc)
            let bodyRect = CGRect(x: 15, y: 35, width: 50, height: 35)
            path.append(UIBezierPath(ovalIn: bodyRect))
            
            path.fill()
        }
    }
    
    // MARK: - Button Actions
    
    @objc private func speakerTapped() {
        animateButtonTap(speakerButton)
        delegate?.didTapSpeaker()
    }
    
    @objc private func microphoneTapped() {
        animateButtonTap(microphoneButton)
        delegate?.didTapMicrophone()
    }
    
    @objc private func keypadTapped() {
        animateButtonTap(keypadButton)
        delegate?.didTapKeypad()
    }
    
    @objc private func hangupTapped() {
        animateButtonTap(endCallButton)
        delegate?.didTapHangup()
    }
    
    // MARK: - UI Updates
    
    public func updateCallerInfo(name: String?, avatar: UIImage?) {
        DispatchQueue.main.async {
            self.callerNameLabel.text = name ?? "Unknown Caller"
            
            if let avatar = avatar {
                self.avatarImageView.image = avatar
            } else {
                self.avatarImageView.image = self.createPersonIcon()
            }
        }
    }
    
    public func updateCallState(_ state: CallState) {
        DispatchQueue.main.async {
            self.currentCallState = state
            
            switch state {
            case .calling:
                self.statusLabel.text = "Calling…"
                self.statusLabel.isHidden = false
                self.callTimeLabel.isHidden = true
                self.stopCallTimer()
                
            case .ringing:
                self.statusLabel.text = "Ringing…"
                self.statusLabel.isHidden = false
                self.callTimeLabel.isHidden = true
                self.pulseAnimation(self.statusLabel)
                self.stopCallTimer()
                
            case .connected:
                self.statusLabel.isHidden = true
                self.callTimeLabel.isHidden = false
                self.stopPulseAnimation(self.statusLabel)
                self.startCallTimer()
                
            case .ended:
                self.statusLabel.text = "Call Ended"
                self.statusLabel.isHidden = false
                self.callTimeLabel.isHidden = true
                self.stopPulseAnimation(self.statusLabel)
                self.stopCallTimer()
                
            case .error:
                self.statusLabel.text = "Call Failed"
                self.statusLabel.isHidden = false
                self.callTimeLabel.isHidden = true
                self.stopPulseAnimation(self.statusLabel)
                self.stopCallTimer()
                
            case .idle:
                self.statusLabel.text = "Ready"
                self.statusLabel.isHidden = false
                self.callTimeLabel.isHidden = true
                self.stopCallTimer()
            case .busy:
                     self.statusLabel.text = "User Busy"
                     self.statusLabel.isHidden = false
                     self.callTimeLabel.isHidden = true
                     self.stopPulseAnimation(self.statusLabel)
                     self.stopCallTimer()
                
            case .noAnswer:
                self.statusLabel.text = "No Answer"
                self.statusLabel.isHidden = false
                self.callTimeLabel.isHidden = true
                self.stopPulseAnimation(self.statusLabel)
                self.stopCallTimer()
                
            case .unowned:
                     self.statusLabel.text = "User Busy"
                     self.statusLabel.isHidden = false
                     self.callTimeLabel.isHidden = true
                     self.stopPulseAnimation(self.statusLabel)
                     self.stopCallTimer()

            }
            
            
            // Update accessibility
            self.statusLabel.accessibilityValue = self.statusLabel.text
        }
    }
    
    public func updateSpeakerButton(enabled: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                self.speakerButton.backgroundColor = enabled ?
                    UIColor.white.withAlphaComponent(0.9) :
                    UIColor.white.withAlphaComponent(0.2)
                
                self.speakerButton.tintColor = enabled ? .systemBlue : .white
            }
            
            self.speakerButton.accessibilityValue = enabled ? "On" : "Off"
        }
    }
    
    public func updateMicButton(enabled: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                self.microphoneButton.backgroundColor = enabled ?
                    UIColor.white.withAlphaComponent(0.2) :
                    UIColor.systemRed.withAlphaComponent(0.8)
                
                if #available(iOS 13.0, *) {
                                let iconName = enabled ? "mic.fill" : "mic.slash.fill"
                                let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
                                let icon = UIImage(systemName: iconName, withConfiguration: config)
                                self.microphoneButton.setImage(icon, for: .normal)
                            } else {
                                let iconName = enabled ? "mic.fill" : "mic.slash.fill"
                                let icon = UIImage(named: iconName) // Use custom image assets
                                self.microphoneButton.setImage(icon, for: .normal)
                            }
                self.microphoneButton.tintColor = .white
            }
            
            self.microphoneButton.accessibilityValue = enabled ? "Unmuted" : "Muted"
        }
    }
    
    // MARK: - Call Timer
    
    private func startCallTimer() {
        callStartTime = Date()
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCallTime()
        }
    }
    
    private func stopCallTimer() {
        callTimer?.invalidate()
        callTimer = nil
        callStartTime = nil
    }
    
    private func updateCallTime() {
        guard let startTime = callStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        DispatchQueue.main.async {
            self.callTimeLabel.text = String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Animations
    
    private func animateButtonTap(_ button: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = CGAffineTransform.identity
            }
        }
    }
    
    private func pulseAnimation(_ view: UIView) {
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.duration = 1.2
        pulseAnimation.fromValue = 0.5
        pulseAnimation.toValue = 1.0
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .greatestFiniteMagnitude
        view.layer.add(pulseAnimation, forKey: "pulse")
    }
    
    private func stopPulseAnimation(_ view: UIView) {
        view.layer.removeAnimation(forKey: "pulse")
        view.alpha = 1.0
    }
}
extension UIImage {
    static func fromFramework(named name: String) -> UIImage? {
        let bundle = Bundle(for: CallViewController.self) // lấy bundle của framework
        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
}

// MARK: - Event Observer Implementation
extension CallViewController: MakeCallEventObserver {
    
    public func handleEvent(_ event: MakeCallEvent) {
        switch event {
        case .callStateChanged(let state):
            updateCallState(state)
            
        case .audioRouteChanged(let isSpeakerEnabled):
            updateSpeakerButton(enabled: isSpeakerEnabled)
            
        case .microphoneStateChanged(let isMuted):
            updateMicButton(enabled: !isMuted)
            
        case .error(let error):
            DispatchQueue.main.async {
                self.showError(error.localizedDescription)
            }
            
        default:
            break
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Call Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.delegate?.didTapHangup()
        })
        present(alert, animated: true)
    }
}
