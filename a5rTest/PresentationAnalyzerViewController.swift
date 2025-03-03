import UIKit
import AVFoundation
import Vision

class PresentationAnalyzerViewController: UIViewController {
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private let feedbackLabel = PaddingLabel()
    private let startButton = UIButton()
    
    // Vision requests for face and body analysis
    private var faceAnalysisRequest: VNDetectFaceLandmarksRequest?
    private var poseRequest: VNDetectHumanBodyPoseRequest?
    
    private let sequenceRequestHandler = VNSequenceRequestHandler()

    // Vision request for person segmentation
    private var personSegmentationRequest: VNGeneratePersonSegmentationRequest?
    
    // Add these properties at the top of the class
    private var lastHandOnNeckTime: Date?
    private let handOnNeckCooldown: TimeInterval = 2.0 // time required for hand to be on neck (2 seconds)
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
        
        // Setup person segmentation request
        personSegmentationRequest = VNGeneratePersonSegmentationRequest { [weak self] request, error in
            if let error = error {
                print("Person segmentation error: \(error.localizedDescription)")
                return
            }
            self?.handlePersonSegmentationResults(request)
        }
        personSegmentationRequest?.qualityLevel = .balanced
        personSegmentationRequest?.outputPixelFormat = kCVPixelFormatType_OneComponent8
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
                
                if abs(pitch) > 0.5 || abs(yaw) > 0.5 {
                    feedback += "Head position: Try to keep your head more stable\n"
                } else {
                    feedback += "Head position: Good\n"
                }
                
                updateFeedbackLabel(feedback)
            }
        }
    }
    
    private func handlePoseResults(_ request: VNRequest) {
        guard let observations = request.results as? [VNHumanBodyPoseObservation] else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let pose = observations.first {
                // الحصول على نقاط المعالم المطلوبة
                if let rightWrist = try? pose.recognizedPoint(.rightWrist),
                   let leftWrist = try? pose.recognizedPoint(.leftWrist),
                   let rightElbow = try? pose.recognizedPoint(.rightElbow),
                   let leftElbow = try? pose.recognizedPoint(.leftElbow),
                   let rightShoulder = try? pose.recognizedPoint(.rightShoulder),
                   let leftShoulder = try? pose.recognizedPoint(.leftShoulder),
                   let nose = try? pose.recognizedPoint(.nose) {
                    
                    // حساب الزوايا بين الكتف والكوع والمعصم
                    let rightElbowAngle = self.calculateAngle(from: rightShoulder.location, to: rightElbow.location, to: rightWrist.location)
                    let leftElbowAngle = self.calculateAngle(from: leftShoulder.location, to: leftElbow.location, to: leftWrist.location)
                    
                    // التحقق إذا كانت الزاوية أقل من ٥ درجات
                    if rightElbowAngle < 5 || leftElbowAngle < 5 {
                        self.updateFeedbackLabel("Warning: The arm position is incorrect! Please adjust the angle.")
                    } else {
                        self.updateFeedbackLabel("Arm position: Correct")
                    }
                    
                    // تحقق من اليد على الرقبة (إذا كان المعصم قريبًا من الرقبة)
                    if rightWrist.confidence > 0.5 && leftWrist.confidence > 0.5 {
                        let rightWristToNeckDistance = self.calculateDistance(from: rightWrist.location, to: nose.location)
                        let leftWristToNeckDistance = self.calculateDistance(from: leftWrist.location, to: nose.location)
                        
                        // تحديد المسافة بين اليد والرقبة
                        let rightWristToNeckRatio = rightWristToNeckDistance / self.calculateDistance(from: rightShoulder.location, to: nose.location)
                        let leftWristToNeckRatio = leftWristToNeckDistance / self.calculateDistance(from: leftShoulder.location, to: nose.location)
                        
                        // زيادة المسافة إلى 40 بكسل بدلاً من 30
                        let distanceThreshold: CGFloat = 30 // المسافة الجديدة
                        
                        // التأكد من أن كلا الشرطين صحيحين قبل تنفيذ التحذير
                        if (rightWristToNeckRatio < 0.5 || leftWristToNeckRatio < 0.5) {
                            if let lastTime = self.lastHandOnNeckTime {
                                if Date().timeIntervalSince(lastTime) > self.handOnNeckCooldown {
                                    self.updateFeedbackLabel("Warning: Hand on neck detected! Avoid this posture.")
                                    self.lastHandOnNeckTime = Date()
                                }
                            } else {
                                self.lastHandOnNeckTime = Date()
                            }
                        } else {
                            self.lastHandOnNeckTime = nil
                        }
                    }
                }
            }
        }
    }

    private func handlePersonSegmentationResults(_ request: VNRequest) {
        guard let observations = request.results as? [VNPixelBufferObservation], let observation = observations.first else { return }
        
        let maskPixelBuffer = observation.pixelBuffer
        let ciImage = CIImage(cvPixelBuffer: maskPixelBuffer)
        
        // Process the mask (e.g., apply it to the video frame)
    }

    // Function to calculate the angle between three points
    private func calculateAngle(from p1: CGPoint, to p2: CGPoint, to p3: CGPoint) -> Double {
        let vector1 = CGPoint(x: p1.x - p2.x, y: p1.y - p2.y)
        let vector2 = CGPoint(x: p3.x - p2.x, y: p3.y - p2.y)
        
        let dotProduct = vector1.x * vector2.x + vector1.y * vector2.y
        let magnitude1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
        let magnitude2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y)
        
        let cosineTheta = dotProduct / (magnitude1 * magnitude2)
        
        // Calculate the angle in degrees
        let angle = acos(cosineTheta) * (180.0 / .pi)
        return angle
    }
    
    private func calculateDistance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
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
        
        do {
            // استخدام VNSequenceRequestHandler بدلاً من VNImageRequestHandler
            try sequenceRequestHandler.perform([faceAnalysisRequest, poseRequest, personSegmentationRequest].compactMap { $0 }, on: pixelBuffer, orientation: .up)
        } catch {
            print("Failed to perform Vision request: \(error.localizedDescription)")
        }
    }

}
