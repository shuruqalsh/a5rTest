// هنا موجود كل شي يخص تحليل لغة الجسد وكتابة المنطق لدوال




import UIKit
import AVFoundation
import Vision
import CoreGraphics

class PresentationAnalyzerViewModel: NSObject, ObservableObject {
    // الليبلز لكل وضعيه
    @Published var positionText: String = ""
    @Published var feedbackText: String = ""
    @Published var handMovementText: String = ""  // لعرض النص المتعلق بحركة اليد
    @Published var videoURL: URL? // ✅ التأكد من أن المتغير موجود

    private var outputURL: URL?
    private var videoOutput: AVCaptureMovieFileOutput?
      private var captureSession: AVCaptureSession?
      private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
      
      override init() {
          super.init()
          setupVision()
      }
    
    // 🆕 المتغيرات الخاصة بوضعية الرقبة دالة (البدايه)
    private var isHandOnNeck: Bool = false
    private var stableFrameCount: Int = 0
    private let requiredStableFrames: Int = 30
    var neckTouchCount: Int = 0// عدد المرات الي الشخص مسك فيها رقبته
    
    // 🆕 المتغيرات الخاصة بتتبع الحركة النسبية
    private var wristPositions: [CGPoint] = []
    private var neckPositions: [CGPoint] = []
    private var relativeMovements: [CGFloat] = []
    // 🆕 المتغيرات الخاصة بوضعية الرقبة دالة (النهايه)
    
    // 🆕 المتغيرات الخاصة بوضعية الرأس  (البدايه)
    private var stableHeadFrameCount: Int = 0
    private var requiredStableHeadFrames: Int = 30 // عدد الإطارات المطلوبة للثبات
    private var isHeadStable: Bool = true
    @Published var headMovementCount: Int = 0 // 🆕 عداد خاص بحركة الرأس
    // 🆕 المتغيرات الخاصة بوضعية الرأس  (النهايه)
    
    
    
    // 🆕 المتغيرات الخاصة بوضعية عدم استخدام لغة الجسد  (البدايه)
    
    // متغيرات جديدة لمراقبة حركة المعصم
    private var lastWristMovement: TimeInterval = 0  // الزمن الذي تم فيه آخر حركة
    private let handRestThreshold: TimeInterval = 5.0 // الحد الأدنى من الوقت (بالثواني) الذي يعتبر فيه المعصم ثابتًا
    private var handIsNotUsed: Bool = false // حالة الاستخدام
    
    // 🆕 المتغيرات الخاصة بوضعية عدم استخدام لغة الجسد  (النهايه)
    
    
    
    
    // 🆕 المتغيرات الخاصة بوضعية   (البدايه)Arms Crossed

    private var isArmsCrossed: Bool = false

    

    // 🆕 النهايه)Arms Crossed

    private var previousLeftWristVelocity: CGFloat = 0
    private var previousRightWristVelocity: CGFloat = 0
    private var lastMovementTimestamp: TimeInterval = 0
    private let movementThreshold: CGFloat = 0.03  // الحد الأدنى للتغير الذي يتم اعتباره حركة
    private let velocityThreshold: CGFloat = 0.02  // حد السرعة لاكتشاف حركة بطيئة
    private var isBodyLanguageUsed = false // لتخزين حالة استخدام لغة الجسد
    
    
    private var stableMovementFrames: Int = 0 // عدد الإطارات التي استمرت فيها الحركة
    private var stableThreshold: Int = 5 // عدد الإطارات التي يجب أن تكون فيها الحركة ثابتة لتغيير الحالة
    private var previousMovementDelta: CGFloat = 0 // لحفظ التغير السابق في الحركة
    
    
    
    private var previousLeftWrist: CGPoint?
    private var previousRightWrist: CGPoint?
    
    
    private var lastDetectedMovement: CGFloat = 0 // لحفظ آخر حركة كبيرة تم اكتشافها
    
    
    private var stillnessStartTime: Date?
    
    
    private var hipPositions: [CGFloat] = []
    private var hipMovements: [CGFloat] = []
    private var stillFrameCount = 0
    
    
    
    private var faceAnalysisRequest: VNDetectFaceLandmarksRequest?
    private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    private let sequenceRequestHandler = VNSequenceRequestHandler()
 
    
    func setupCamera(in view: UIView) {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("❌ Failed to access front camera")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            let videoOutput = AVCaptureMovieFileOutput() // 🎥 إضافة الـ Movie Output للتسجيل
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                self.videoOutput = videoOutput
            }
            
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            }
            
            view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            
            let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            
            DispatchQueue.main.async {
                videoPreviewLayer.frame = view.bounds
                view.layer.addSublayer(videoPreviewLayer)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
            
        } catch {
            print("❌ Error setting up camera: \(error.localizedDescription)")
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
    
    private func analyzeBodyPose(_ pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([bodyPoseRequest])
            guard let observation = bodyPoseRequest.results?.first else { return }
            
            // 🔥 تعريف جميع الـ Landmarks الخاصة بالجسم
            let points = try observation.recognizedPoints(.all)
            
            // ✅ استدعاء دوال التحليل المختلفة وتمرير جميع النقاط
            analyzeNeckPosition(points)
            analyzeHandMovement(points)
            // ✅ تحليل الأذرع المتقاطعة باستخدام الهندسة فقط
            _ = areArmsCrossedUsingGeometry(points)
            
            
            
        } catch {
            print("Error analyzing body pose: \(error.localizedDescription)")
        }
    }
    
    
    private func handleFaceDetectionResults(_ request: VNRequest) {
        guard let observations = request.results as? [VNFaceObservation] else { return }
        
        DispatchQueue.main.async { [weak self] in
            if let face = observations.first {
                let pitch = face.pitch?.doubleValue ?? 0
                let yaw = face.yaw?.doubleValue ?? 0
                
                // ✅ التحقق من مدى ثبات الرأس (تجاهل الحركات الصغيرة)
                if abs(pitch) > 0.5 || abs(yaw) > 0.5 {
                    self?.stableHeadFrameCount += 1
                    print("🕒 إطارات حركة الرأس: \(self?.stableHeadFrameCount ?? 0)/\(self?.requiredStableHeadFrames ?? 0)")
                    
                    if self?.stableHeadFrameCount ?? 0 >= self?.requiredStableHeadFrames ?? 0 {
                        if self?.isHeadStable ?? true {
                            self?.isHeadStable = false
                            self?.headMovementCount += 1 // 🆕 زيادة العداد عند اكتشاف حركة الرأس الزائدة
                            self?.feedbackText = "حركة الرأس: حاول تثبيت رأسك أكثر (\(self?.headMovementCount ?? 0) مرات)"
                            print("🚨 الرأس يتحرك كثيرًا! عدد المرات: \(self?.headMovementCount ?? 0)")
                        }
                    }
                } else {
                    self?.resetHeadStabilityState()
                }
            }
        }
    }
    
    private func resetHeadStabilityState() {
        stableHeadFrameCount = 0
        isHeadStable = true
        feedbackText = "حركة الرأس: جيدة"
    }
    
    
    
    
    func analyzeNeckPosition(_ points: [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint]) {
        guard let rightWrist = points[.rightWrist],
              let leftWrist = points[.leftWrist],
              let neck = points[.neck],
              let rightElbow = points[.rightElbow],
              let leftElbow = points[.leftElbow] else {
            resetNeckPositionState()
            return
        }
        
        // 📏 حساب المسافات وزاوية الانحناء لكل من اليد اليمنى واليسرى
        let rightDistanceToNeck = hypot(rightWrist.location.x - neck.location.x, rightWrist.location.y - neck.location.y)
        let rightElbowBend = abs(rightElbow.location.y - rightWrist.location.y)
        
        let leftDistanceToNeck = hypot(leftWrist.location.x - neck.location.x, leftWrist.location.y - neck.location.y)
        let leftElbowBend = abs(leftElbow.location.y - leftWrist.location.y)
        
        // ✅ التحقق من كلتا اليدين بنفس الشروط
        let isRightHandOnNeck = rightDistanceToNeck < 0.1 && rightElbowBend > 0.1
        let isLeftHandOnNeck = leftDistanceToNeck < 0.1 && leftElbowBend > 0.1
        
        // ✅ التحقق من الثبات لعدد كافي من الإطارات
        if (isRightHandOnNeck || isLeftHandOnNeck) {
            stableFrameCount += 1
            print("🕒 إطارات الثبات: \(stableFrameCount)/\(requiredStableFrames)")
            
            if stableFrameCount >= requiredStableFrames && !isHandOnNeck {
                neckTouchCount += 1
                isHandOnNeck = true
                
                // 🆕 تحديد اليد المستخدمة ووضع النص المناسب
                let handUsed = isRightHandOnNeck ? "اليمنى" : "اليسرى"
                
                DispatchQueue.main.async {
                    self.positionText = "🛑 اليد \(handUsed) على الرقبة (\(self.neckTouchCount) مرات)"
                    self.feedbackText = "تم اكتشاف وضع اليد \(handUsed) على الرقبة"
                }
                print("🛑 اليد \(handUsed) على الرقبة - عدد المرات: \(neckTouchCount)")
            }
        } else {
            resetNeckPositionState()
        }
    }
    
    private func resetNeckPositionState() {
        stableFrameCount = 0
        isHandOnNeck = false
        DispatchQueue.main.async {
            self.positionText = ""
            self.feedbackText = ""
        }
    }
    
    
    
    
    
    private func analyzeHandMovement(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        guard let leftWrist = points[.leftWrist], let rightWrist = points[.rightWrist] else { return }
        
        let currentTime = Date().timeIntervalSince1970
        let leftWristMovement = distanceBetweenPoints(previousLeftWrist ?? leftWrist.location, leftWrist.location)
        let rightWristMovement = distanceBetweenPoints(previousRightWrist ?? rightWrist.location, rightWrist.location)
        
        // قياس إذا كانت الحركة صغيرة جدًا (أي المعصم ثابت):
        if leftWristMovement < 0.02 && rightWristMovement < 0.02 {
            if currentTime - lastWristMovement > handRestThreshold {
                // إذا كانت اليد ثابتة لفترة طويلة
                if !handIsNotUsed {
                    handIsNotUsed = true
                    DispatchQueue.main.async {
                        self.handMovementText = "اليد غير مستخدمة. حاول تحريك يدك!"
                        self.feedbackText = "اليد ثابتة لفترة طويلة."
                    }
                    print("🚨 اليد لم تتحرك لفترة طويلة!")
                }
            }
        } else {
            lastWristMovement = currentTime
            handIsNotUsed = false
            DispatchQueue.main.async {
                self.handMovementText = ""
            }
        }
        
        // تحديث المواضع السابقة للمعصمين
        previousLeftWrist = leftWrist.location
        previousRightWrist = rightWrist.location
    }
    
    
    func areArmsCrossedUsingGeometry(_ points: [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint]) -> Bool {
        
        // التحقق من وجود النقاط الأساسية: المرفقين والأكتاف
        guard let leftElbow = points[.leftElbow],
              let rightElbow = points[.rightElbow],
              let leftShoulder = points[.leftShoulder],
              let rightShoulder = points[.rightShoulder] else {
            print("النقاط الأساسية مفقودة لتحليل الأذرع المتقاطعة")
            self.positionText = "النقاط الأساسية مفقودة لتحليل الأذرع المتقاطعة"
            return false
        }
        
        // تقدير مواقع المعصمين باستخدام الاستيفاء الهندسي
        let estimatedLeftWrist = estimateWristPosition(elbow: leftElbow.location, shoulder: leftShoulder.location)
        let estimatedRightWrist = estimateWristPosition(elbow: rightElbow.location, shoulder: rightShoulder.location)
        
        // التحقق من وجود تقاطع على شكل حرف X
        let isCrossed = estimatedLeftWrist.x > rightElbow.location.x &&
                        estimatedRightWrist.x < leftElbow.location.x
        
        if isCrossed {
            self.positionText = "الأيدي مكتّفة (Crossed Arms) ✅"
        } else {
        }
        
        print(positionText)
        return isCrossed
    }


    // دالة تقدير موقع المعصم باستخدام الاستيفاء الهندسي
    func estimateWristPosition(elbow: CGPoint, shoulder: CGPoint) -> CGPoint {
        let dx = elbow.x - shoulder.x
        let dy = elbow.y - shoulder.y
        return CGPoint(x: elbow.x + dx, y: elbow.y + dy)
    }

    // ⭐️ دالة لحساب المسافة بين نقطتين باستخدام قانون المسافة الإقليدية
    private func distanceBetweenPoints(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        return hypot(point1.x - point2.x, point1.y - point2.y)
    }



    private func calculateAngleBetweenPoints(shoulder: CGPoint, elbow: CGPoint, wrist: CGPoint) -> CGFloat {
        // حساب المتجهات بين النقاط
        let vector1 = CGVector(dx: elbow.x - shoulder.x, dy: elbow.y - shoulder.y)
        let vector2 = CGVector(dx: wrist.x - elbow.x, dy: wrist.y - elbow.y)
        
        // حساب الجداء النقطي بين المتجهات
        let dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy
        let magnitude1 = sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy)
        let magnitude2 = sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy)
        
        // حساب الزاوية بين المتجهات
        let angle = acos(dotProduct / (magnitude1 * magnitude2)) * 180 / .pi
        
        return angle.isNaN ? 0 : angle
    }

    func stopCamera() { // ⭐️ دالة لإيقاف الكاميرا عند عدم الحاجة إليها
        captureSession?.stopRunning()
        captureSession = nil
    }

    
    private func updatePositionLabel(_ position: String) {
        DispatchQueue.main.async { [weak self] in
            self?.positionText = position
        }
    }

    

    
    func startRecording() {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let outputURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        
        self.videoURL = outputURL
        
        if let videoOutput = videoOutput, !videoOutput.isRecording {
            videoOutput.startRecording(to: outputURL, recordingDelegate: self)
            print("🎥 بدء التسجيل إلى \(outputURL)")
        }
    }

    func stopRecording() {
        guard let videoOutput = videoOutput else {
            print("❌ خطأ: `videoOutput` غير مهيأ!")
            return
        }
        videoOutput.stopRecording()

        }
    }



extension PresentationAnalyzerViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            videoURL = outputFileURL
        } else {
            print("Error recording movie: \(error!.localizedDescription)")
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
