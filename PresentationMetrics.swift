import Foundation

struct PresentationMetrics {
    var eyeContactScore: Double = 0.0
    var headStabilityScore: Double = 0.0
    var speakingPaceScore: Double = 0.0
    
    mutating func updateEyeContact(_ score: Double) {
        eyeContactScore = (eyeContactScore + score) / 2
    }
    
    mutating func updateHeadStability(_ score: Double) {
        headStabilityScore = (headStabilityScore + score) / 2
    }
    
    mutating func updateSpeakingPace(_ score: Double) {
        speakingPaceScore = (speakingPaceScore + score) / 2
    }
    
    var overallScore: Double {
        return (eyeContactScore + headStabilityScore + speakingPaceScore) / 3
    }
} 