// هنا موجود كل شي يخص تحليل لغة الجسد وكتابة المنطق لدوال




import UIKit
import AVFoundation
import Vision
import CoreGraphics

class PresentationAnalyzerViewModel: NSObject, ObservableObject {
    @Published var positionText: String = ""
    @Published var feedbackText: String = ""
    @Published var cameraError: String = ""
    
    private var leftHipPositions: [CGFloat] = []
    private var rightHipPositions: [CGFloat] = []
    private var leftKneePositions: [CGFloat] = []
    private var rightKneePositions: [CGFloat] = []
    private var kneeDistances: [CGFloat] = []

    
    private var previousLeftWristVelocity: CGFloat = 0
    private var previousRightWristVelocity: CGFloat = 0
    private var lastMovementTimestamp: TimeInterval = 0
    private let movementThreshold: CGFloat = 0.03  // الحد الأدنى للتغير الذي يتم اعتباره حركة
    private let velocityThreshold: CGFloat = 0.02  // حد السرعة لاكتشاف حركة بطيئة
    private var isBodyLanguageUsed = false // لتخزين حالة استخدام لغة الجسد

    
    private var stableMovementFrames: Int = 0 // عدد الإطارات التي استمرت فيها الحركة
    private var stableThreshold: Int = 5 // عدد الإطارات التي يجب أن تكون فيها الحركة ثابتة لتغيير الحالة
    private var previousMovementDelta: CGFloat = 0 // لحفظ التغير السابق في الحركة

    
    private var wristPositions: [CGPoint] = []

    private var previousLeftWrist: CGPoint?
    private var previousRightWrist: CGPoint?


    private var lastDetectedMovement: CGFloat = 0 // لحفظ آخر حركة كبيرة تم اكتشافها

    
    private var stillnessStartTime: Date?

    
    private var hipPositions: [CGFloat] = []
    private var hipMovements: [CGFloat] = []
    private var stillFrameCount = 0

    
    private var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            if let layer = videoPreviewLayer {
                layer.videoGravity = .resizeAspectFill
            }
        }
    }
    private var neckPositions: [CGPoint] = []
    private var relativeMovements: [CGFloat] = []
    
    private var faceAnalysisRequest: VNDetectFaceLandmarksRequest?
    private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    private let sequenceRequestHandler = VNSequenceRequestHandler()
    
    override init() {
        super.init()
        setupVision()
    }
    
    func setupCamera(in view: UIView) {
        // Ensure we're on the main thread
        DispatchQueue.main.async {
            self.setupCameraInternal(in: view)
        }
    }

    private func setupCameraInternal(in view: UIView) {
        // Stop existing session if any
        captureSession?.stopRunning()
        
        // Create new session
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // Set quality level
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }
        
        // Setup camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            self.cameraError = "No front camera available"
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                self.cameraError = "Could not add camera input"
                return
            }
            
            // Setup video output
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            } else {
                self.cameraError = "Could not add video output"
                return
            }
            
            // Commit configuration
            session.commitConfiguration()
            
            // Setup preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            
            // Remove existing preview layer if any
            view.layer.sublayers?.forEach { layer in
                if layer is AVCaptureVideoPreviewLayer {
                    layer.removeFromSuperlayer()
                }
            }
            
            // Add new preview layer
            view.layer.insertSublayer(previewLayer, at: 0)
            self.videoPreviewLayer = previewLayer
            self.captureSession = session
            
            // Start running
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
            
        } catch {
            self.cameraError = "Camera setup error: \(error.localizedDescription)"
            print("Camera setup error: \(error)")
        }
    }

    
    
    private func setupVision() {
        faceAnalysisRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            if let error = error {
                print("Face detection error: \(error.localizedDescription)")
                return
            }
            self?.handleFaceDetectionResults(request)
        }
    }
    
    private func handleFaceDetectionResults(_ request: VNRequest) {
        guard let observations = request.results as? [VNFaceObservation] else { return }
        
        DispatchQueue.main.async { [weak self] in
            if let face = observations.first {
                let pitch = face.pitch?.doubleValue ?? 0
                let yaw = face.yaw?.doubleValue ?? 0
                
                if abs(pitch) > 0.5 || abs(yaw) > 0.5 {
                    self?.feedbackText = "حركة الرأس: حاول تثبيت رأسك أكثر"
                } else {
                    self?.feedbackText = "حركة الرأس: جيدة"
                }
            }
        }
    }
    
    private func analyzeBodyPose(_ pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([bodyPoseRequest])
            guard let observation = bodyPoseRequest.results?.first else { return }
            
            let points = try observation.recognizedPoints(.all)
            if let wrist = points[.rightWrist],
               let neck = points[.neck],
               let elbow = points[.rightElbow] {
                
                
                // ✅ استدعاء دالة تحليل حركة رقم 3
                detectBodyLanguageUsage(points)
                
                let distanceToNeck = hypot(wrist.location.x - neck.location.x, wrist.location.y - neck.location.y)
                let elbowBend = abs(elbow.location.y - wrist.location.y)
                
                if distanceToNeck < 0.1 && elbowBend > 0.1 {
                    trackWristAndNeckPosition(wrist.location, neck.location) // ✅ تمرير كلًا من اليد والرقبة
                } else {
                    
                    wristPositions.removeAll() // ⭐️ إعادة ضبط المصفوفة عند الوضع الطبيعي
                }
            }
        } catch {
            print("Error analyzing body pose: \(error.localizedDescription)")
        }
    }

    private func trackWristAndNeckPosition(_ wrist: CGPoint, _ neck: CGPoint) {
        wristPositions.append(wrist)
        neckPositions.append(neck)
        
        if wristPositions.count > 45 {
            wristPositions.removeFirst()
        }
        if neckPositions.count > 45 {
            neckPositions.removeFirst()
        }
        
        // ⭐️ حساب المسافة النسبية بين اليد والرقبة عبر كل الإطارات المخزنة
        let relativeDistances = zip(wristPositions, neckPositions).map { distanceBetweenPoints($0, $1) }
        
        // ⭐️ حساب التغيير اللحظي في المسافة النسبية
        let currentRelativeMovement = abs(relativeDistances.last ?? 0.0 - (relativeDistances.dropLast().last ?? 0.0))
        
        // ⭐️ إضافة الحركة النسبية إلى المصفوفة
        relativeMovements.append(currentRelativeMovement)
        if relativeMovements.count > 15 { // حفظ آخر 15 حركة نسبية فقط
            relativeMovements.removeFirst()
        }
        
        // ⭐️ حساب متوسط الحركة النسبية الأخيرة
        let averageRelativeMovement = relativeMovements.reduce(0.0, +) / CGFloat(relativeMovements.count)
        
        print("📊 الحركة اللحظية النسبية: \(currentRelativeMovement), متوسط الحركة النسبية: \(averageRelativeMovement)")

        // ⭐️ منطق تحديد الحالة بناءً على الاستقرار بمرور الوقت
        if averageRelativeMovement < 0.02 { // 🔥 العتبة المخفضة للاستقرار
            print("🛑 اليد ثابتة على الرقبة أثناء الحركة")
            updatePositionLabel("🛑 اليد ثابتة على الرقبة")
        } else {
            updatePositionLabel("🛑 اليد ثابتة على الرقبة")
        }
    }
    

    private func detectBodyLanguageUsage(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        let stableThreshold = 40 // عدد الإطارات اللازمة للاستقرار
        
        guard let leftWrist = points[.leftWrist],
              let rightWrist = points[.rightWrist] else {
            print("❌ المعصمان غير موجودين")
            return
        }

        // حساب التغير بين المعصمين في الإطار الحالي والإطار السابق
        let leftWristDelta = distanceBetweenPoints(leftWrist.location, previousLeftWrist ?? leftWrist.location)
        let rightWristDelta = distanceBetweenPoints(rightWrist.location, previousRightWrist ?? rightWrist.location)

        // حساب التغير الإجمالي في الحركات
        let totalMovementDelta = leftWristDelta + rightWristDelta
        
        // حساب السرعة عبر التغيرات الزمنية
        let currentTime = Date().timeIntervalSince1970
        let deltaTime = currentTime - lastMovementTimestamp
        let leftWristVelocity = leftWristDelta / CGFloat(deltaTime)
        let rightWristVelocity = rightWristDelta / CGFloat(deltaTime)
        
        // تحقق من إذا كانت الحركة بطيئة
        let isMovingSlowly = leftWristVelocity < velocityThreshold && rightWristVelocity < velocityThreshold
        
        // إذا كان التغير في الحركة أكبر من العتبة و لم تكن الحركة بطيئة
        let isUsingBodyLanguage = totalMovementDelta > movementThreshold && !isMovingSlowly

        if isUsingBodyLanguage {
            if !isBodyLanguageUsed {
                updatePositionLabel("👐 الشخص يستخدم لغة الجسد")
                isBodyLanguageUsed = true
                stableMovementFrames = 0 // إعادة تعيين الإطارات إذا بدأت الحركة
            }
        } else {
            stableMovementFrames += 1
            if stableMovementFrames >= stableThreshold {
                if isBodyLanguageUsed {
                    updatePositionLabel("✋ الشخص لا يستخدم لغة الجسد")
                    isBodyLanguageUsed = false
                }
            }
        }
        
        // تحديث الإحداثيات والسرعة السابقة للإطار التالي
        previousLeftWrist = leftWrist.location
        previousRightWrist = rightWrist.location
        lastMovementTimestamp = currentTime
    }

    // ⭐️ دالة لحساب المسافة بين نقطتين باستخدام قانون المسافة الإقليدية
    private func distanceBetweenPoints(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        return hypot(point1.x - point2.x, point1.y - point2.y)
    }



   

    
    private func updatePositionLabel(_ position: String) {
        DispatchQueue.main.async { [weak self] in
            self?.positionText = position
        }
    }

    
      
}

extension PresentationAnalyzerViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        do {
            try sequenceRequestHandler.perform([faceAnalysisRequest].compactMap { $0 }, on: pixelBuffer, orientation: .up)
            analyzeBodyPose(pixelBuffer)
        } catch {
            print("Failed to perform Vision request: \(error.localizedDescription)")
        }
    }
}
