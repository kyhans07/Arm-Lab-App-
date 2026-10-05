import Foundation
import SwiftData

// MARK: - Enums

enum BodyPart: String, Codable, CaseIterable, Identifiable {
    case feet = "Feet"
    case legs = "Legs"
    case hips = "Hips"
    case core = "Core"
    case shoulders = "Shoulders"
    case forearm = "Forearm"
    case wrist = "Wrist"
    case neck = "Neck"
    
    var id: String { self.rawValue }
}

// MARK: - SwiftData Models

@Model
final class DailyLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var readinessScore: Int
    var mentalFocusScore: Int
    var notes: String
    
    @Relationship(deleteRule: .cascade) var warmUpEntries: [WarmUpEntry]?
    @Relationship(deleteRule: .cascade) var throwingLog: ThrowingLog?
    @Relationship(deleteRule: .cascade) var moundLog: MoundLog?
    @Relationship(deleteRule: .cascade) var exerciseLogs: [ExerciseLog]?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        readinessScore: Int = 7,
        mentalFocusScore: Int = 8,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.readinessScore = readinessScore
        self.mentalFocusScore = mentalFocusScore
        self.notes = notes
    }
}

@Model
final class WarmUpEntry {
    var bodyPartRaw: String
    var isCompleted: Bool
    var mobilityScore: Int

    var bodyPart: BodyPart {
        get { BodyPart(rawValue: bodyPartRaw) ?? .shoulders }
        set { bodyPartRaw = newValue.rawValue }
    }

    init(bodyPart: BodyPart, isCompleted: Bool = false, mobilityScore: Int = 5) {
        self.bodyPartRaw = bodyPart.rawValue
        self.isCompleted = isCompleted
        self.mobilityScore = mobilityScore
    }
}

@Model
final class ThrowingLog {
    var maxDistanceFeet: Double
    var highIntentThrows: Int
    var peakVelocityMph: Double

    init(maxDistanceFeet: Double = 120.0, highIntentThrows: Int = 15, peakVelocityMph: Double = 90.0) {
        self.maxDistanceFeet = maxDistanceFeet
        self.highIntentThrows = highIntentThrows
        self.peakVelocityMph = peakVelocityMph
    }
}

@Model
final class MoundLog {
    var pitchCount: Int
    var strikePercentage: Double
    var pitchQualityScore: Int

    init(pitchCount: Int = 30, strikePercentage: Double = 65.0, pitchQualityScore: Int = 4) {
        self.pitchCount = pitchCount
        self.strikePercentage = strikePercentage
        self.pitchQualityScore = pitchQualityScore
    }
}

@Model
final class ExerciseLog {
    var name: String
    var sets: Int
    var reps: Int
    var weightLbs: Double
    var rpe: Int

    init(name: String, sets: Int, reps: Int, weightLbs: Double, rpe: Int) {
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weightLbs = weightLbs
        self.rpe = rpe
    }
}
