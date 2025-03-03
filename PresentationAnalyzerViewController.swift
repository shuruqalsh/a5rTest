import UIKit
import AVFoundation
import Vision

class PresentationAnalyzerViewController: UIViewController {
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private let feedbackLabel = PaddingLabel()
    private let startButton = UIButton()
    
    // Vision request for face analysis
    private var faceAnalysisRequest: VNDetectFaceLandmarksRequest?
    private var poseRequest: VNDetectHumanBodyPoseRequest?
    
    // Add these properties at the top of the class
    private var lastWarningTime: Date?
    private let warningCooldown: TimeInterval = 3.0 // Show warning every 3 seconds
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
        setupVision()
    }
    
    private func setupUI() {
        // Setup preview view
        let previewView = UIView()
        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)
        
        // Setup feedback label
        feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
        feedbackLabel.textAlignment = .left
        feedbackLabel.numberOfLines = 0
        feedbackLabel.backgroundColor = .black.withAlphaComponent(0.8)
        feedbackLabel.layer.cornerRadius = 10
        feedbackLabel.clipsToBounds = true
        feedbackLabel.textColor = .white
        feedbackLabel.font = .systemFont(ofSize: 16)
        feedbackLabel.padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        view.addSubview(feedbackLabel)
        
        // Setup start button
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.setTitle("Start Analysis", for: .normal)
        startButton.backgroundColor = .systemBlue
        startButton.layer.cornerRadius = 10
        startButton.addTarget(self, action: #selector(startAnalysis), for: .touchUpInside)
        view.addSubview(startButton)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            feedbackLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            feedbackLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            feedbackLabel.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -20),
            
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Failed to access front camera")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            captureSession.addOutput(videoOutput)
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            if let previewLayer = videoPreviewLayer {
                previewLayer.frame = view.layer.bounds
                view.layer.insertSublayer(previewLayer, at: 0)
            }
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    private func setupVision() {
        // Setup face detection request
        faceAnalysisRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            if let error = error {
                print("Face detection error: \(error.localizedDescription)")
                return
            }
            self?.handleFaceDetectionResults(request)
        }
        
        // Setup body pose detection request
        poseRequest = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            if let error = error {
                print("Pose detection error: \(error.localizedDescription)")
                return
            }
            self?.handlePoseResults(request)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = view.layer.bounds
    }
    
    @objc private func startAnalysis() {
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.stopRunning()
            }
            startButton.setTitle("Start Analysis", for: .normal)
            startButton.backgroundColor = .systemBlue
        } else {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
            startButton.setTitle("Stop Analysis", for: .normal)
            startButton.backgroundColor = .systemRed
        }
    }
    
    private func handleFaceDetectionResults(_ request: VNRequest) {
        guard let observations = request.results as? [VNFaceObservation] else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let face = observations.first {
                var feedback = ""
                
                // Analyze eye movement
                if let landmarks = face.landmarks {
                    if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
                        feedback += "Eye contact: Good\n"
                    }
                }
                
                // Analyze head pose
                let pitch = face.pitch?.doubleValue ?? 0
                let yaw = face.yaw?.doubleValue ?? 0
                
                // Check for raised arms / hands behind head
                if abs(pitch) < 0.1 && abs(yaw) < 0.1 {
                    // If head is straight but we can't see much of the shoulders
                    // it might indicate raised arms
                    feedback += "⚠️ Warning: Avoid putting hands behind your head - " +
                              "it can appear casual or defensive. Keep your arms relaxed " +
                              "at your sides or use natural gestures.\n"
                }
                
                if abs(pitch) > 0.5 || abs(yaw) > 0.5 {
                    feedback += "Head position: Try to keep your head more stable\n"
                } else {
                    feedback += "Head position: Good\n"
                }
                
                // Style the feedback label
                let attributedString = NSMutableAttributedString()
                
                // Split feedback into lines
                let lines = feedback.components(separatedBy: "\n")
                for (index, line) in lines.enumerated() {
                    if line.isEmpty { continue }
                    
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 16, weight: line.contains("Warning") ? .bold : .regular),
                        .foregroundColor: line.contains("Warning") ? UIColor.red : UIColor.white
                    ]
                    
                    let attributedLine = NSAttributedString(string: line + "\n", attributes: attributes)
                    attributedString.append(attributedLine)
                }
                
                self.feedbackLabel.attributedText = attributedString
            }
        }
    }
    
    private func handlePoseResults(_ request: VNRequest) {
        guard let observations = request.results as? [VNHumanBodyPoseObservation] else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let pose = observations.first {
                // Check for hands behind head pose
                if let rightWrist = try? pose.recognizedPoint(.rightWrist),
                   let leftWrist = try? pose.recognizedPoint(.leftWrist),
                   let nose = try? pose.recognizedPoint(.nose) {
                    
                    // If wrists are above nose level and towards the back of the head
                    if rightWrist.y > nose.y && leftWrist.y > nose.y {
                        let warning = "⚠️ Warning: Avoid putting hands behind your head - " +
                                    "it can appear casual or defensive. Keep your arms relaxed " +
                                    "at your sides or use natural gestures.\n"
                        updateFeedbackLabel(warning)
                    }
                }
            }
        }
    }
    
    private func updateFeedbackLabel(_ newFeedback: String) {
        // Style the feedback label
        let attributedString = NSMutableAttributedString()
        
        // Split feedback into lines
        let lines = newFeedback.components(separatedBy: "\n")
        for line in lines {
            if line.isEmpty { continue }
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: line.contains("Warning") ? .bold : .regular),
                .foregroundColor: line.contains("Warning") ? UIColor.red : UIColor.white
            ]
            
            let attributedLine = NSAttributedString(string: line + "\n", attributes: attributes)
            attributedString.append(attributedLine)
        }
        
        feedbackLabel.attributedText = attributedString
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension PresentationAnalyzerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            // Perform both face and pose detection
            try imageRequestHandler.perform([faceAnalysisRequest, poseRequest].compactMap { $0 })
        } catch {
            print("Failed to perform Vision request: \(error.localizedDescription)")
        }
    }
} 