//
//  WorkoutBuilderView.swift
//  TrainerMatch
//

import SwiftUI

// MARK: - Exercise Library Item

struct ExerciseLibraryItem: Identifiable {
    let id = UUID()
    let name:        String
    let category:    ExerciseCategory
    let defaultSets: Int
    let defaultReps: String
    let defaultRest: Int
    let tips:        String
    let isTimeBased: Bool

    init(name: String, category: ExerciseCategory, defaultSets: Int,
         defaultReps: String, defaultRest: Int, tips: String = "", isTimeBased: Bool = false) {
        self.name        = name
        self.category    = category
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultRest = defaultRest
        self.tips        = tips
        self.isTimeBased = isTimeBased
    }

    enum ExerciseCategory: String, CaseIterable {
        case chest = "Chest", back = "Back", shoulders = "Shoulders"
        case arms = "Arms", legs = "Legs", core = "Core"
        case cardio = "Cardio", fullBody = "Full Body"

        var icon: String {
            switch self {
            case .chest: return "figure.strengthtraining.traditional"
            case .back: return "figure.row"
            case .shoulders: return "figure.arms.open"
            case .arms: return "dumbbell.fill"
            case .legs: return "figure.run"
            case .core: return "figure.core.training"
            case .cardio: return "heart.fill"
            case .fullBody: return "figure.mixed.cardio"
            }
        }
        var color: Color {
            switch self {
            case .chest: return .red; case .back: return .blue; case .shoulders: return .orange
            case .arms: return .purple; case .legs: return .green; case .core: return .yellow
            case .cardio: return .pink; case .fullBody: return .tmGold
            }
        }
    }
}

// MARK: - Exercise Library Data

struct ExerciseLibrary {
    static let all: [ExerciseLibraryItem] = [
        // CHEST
        ExerciseLibraryItem(name: "Barbell Bench Press",     category: .chest,     defaultSets: 4, defaultReps: "8-10",     defaultRest: 90,  tips: "Keep shoulder blades retracted, feet flat on floor."),
        ExerciseLibraryItem(name: "Dumbbell Bench Press",    category: .chest,     defaultSets: 3, defaultReps: "10-12",    defaultRest: 75,  tips: "Full range of motion, controlled descent."),
        ExerciseLibraryItem(name: "Incline Bench Press",     category: .chest,     defaultSets: 3, defaultReps: "8-10",     defaultRest: 90,  tips: "Set bench 30-45 degrees for upper chest focus."),
        ExerciseLibraryItem(name: "Cable Fly",               category: .chest,     defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Squeeze chest at peak contraction."),
        ExerciseLibraryItem(name: "Push-Up",                 category: .chest,     defaultSets: 3, defaultReps: "15-20",    defaultRest: 60,  tips: "Keep core tight, full range of motion."),
        ExerciseLibraryItem(name: "Dumbbell Fly",            category: .chest,     defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Slight bend in elbows throughout movement."),
        ExerciseLibraryItem(name: "Chest Dip",               category: .chest,     defaultSets: 3, defaultReps: "10-12",    defaultRest: 75,  tips: "Lean forward slightly to target chest."),
        ExerciseLibraryItem(name: "Decline Bench Press",     category: .chest,     defaultSets: 3, defaultReps: "8-10",     defaultRest: 90,  tips: "Targets lower chest — keep feet secured."),
        ExerciseLibraryItem(name: "Pec Deck",                category: .chest,     defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Squeeze at the midpoint for max contraction."),
        // BACK
        ExerciseLibraryItem(name: "Deadlift",                category: .back,      defaultSets: 4, defaultReps: "5-6",      defaultRest: 120, tips: "Neutral spine, drive through heels, chest up."),
        ExerciseLibraryItem(name: "Pull-Up",                 category: .back,      defaultSets: 4, defaultReps: "6-10",     defaultRest: 90,  tips: "Full hang at bottom, chin over bar at top."),
        ExerciseLibraryItem(name: "Barbell Row",             category: .back,      defaultSets: 4, defaultReps: "8-10",     defaultRest: 90,  tips: "Hinge at hips, pull to lower chest."),
        ExerciseLibraryItem(name: "Lat Pulldown",            category: .back,      defaultSets: 3, defaultReps: "10-12",    defaultRest: 75,  tips: "Pull bar to upper chest, lean slightly back."),
        ExerciseLibraryItem(name: "Seated Cable Row",        category: .back,      defaultSets: 3, defaultReps: "10-12",    defaultRest: 75,  tips: "Keep chest up, squeeze shoulder blades together."),
        ExerciseLibraryItem(name: "Single Arm Dumbbell Row", category: .back,      defaultSets: 3, defaultReps: "10-12",    defaultRest: 60,  tips: "Brace on bench, row elbow to hip."),
        ExerciseLibraryItem(name: "Face Pull",               category: .back,      defaultSets: 3, defaultReps: "15-20",    defaultRest: 60,  tips: "Pull to face level, external rotate at end."),
        ExerciseLibraryItem(name: "Hyperextension",          category: .back,      defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Keep movement controlled, don't hyperextend."),
        ExerciseLibraryItem(name: "Meadows Row",             category: .back,      defaultSets: 3, defaultReps: "10-12",    defaultRest: 60,  tips: "Perpendicular to barbell, drive elbow high."),
        ExerciseLibraryItem(name: "Cable Pullover",          category: .back,      defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Straight arms, focus on lat stretch and squeeze."),
        ExerciseLibraryItem(name: "Chest Supported Row",     category: .back,      defaultSets: 3, defaultReps: "10-12",    defaultRest: 60,  tips: "Chest on pad eliminates lower back stress."),
        ExerciseLibraryItem(name: "TRX Row",                 category: .back,      defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Body angle determines difficulty — lean back more to increase."),
        // SHOULDERS
        ExerciseLibraryItem(name: "Overhead Press",          category: .shoulders, defaultSets: 4, defaultReps: "8-10",     defaultRest: 90,  tips: "Bar path straight up, lock out at top."),
        ExerciseLibraryItem(name: "Dumbbell Shoulder Press", category: .shoulders, defaultSets: 3, defaultReps: "10-12",    defaultRest: 75,  tips: "Don't flare elbows excessively forward."),
        ExerciseLibraryItem(name: "Lateral Raise",           category: .shoulders, defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Lead with elbows, slight forward lean, control the drop."),
        ExerciseLibraryItem(name: "Front Raise",             category: .shoulders, defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Control the descent, avoid using momentum."),
        ExerciseLibraryItem(name: "Arnold Press",            category: .shoulders, defaultSets: 3, defaultReps: "10-12",    defaultRest: 75,  tips: "Rotate palms outward as you press up."),
        ExerciseLibraryItem(name: "Rear Delt Fly",           category: .shoulders, defaultSets: 3, defaultReps: "15-20",    defaultRest: 60,  tips: "Slight bend in elbows, squeeze rear delts at top."),
        ExerciseLibraryItem(name: "Upright Row",             category: .shoulders, defaultSets: 3, defaultReps: "10-12",    defaultRest: 60,  tips: "Elbows lead upward, pull to chin level."),
        ExerciseLibraryItem(name: "Cable Lateral Raise",     category: .shoulders, defaultSets: 3, defaultReps: "15-20",    defaultRest: 45,  tips: "Single arm, cable provides constant tension throughout."),
        ExerciseLibraryItem(name: "Plate Front Raise",       category: .shoulders, defaultSets: 3, defaultReps: "12-15",    defaultRest: 45,  tips: "Hold plate at 10 and 2, control the descent."),
        ExerciseLibraryItem(name: "Bent Over Rear Delt Row", category: .shoulders, defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Hinge forward, pull elbows wide and high."),
        ExerciseLibraryItem(name: "Landmine Press",          category: .shoulders, defaultSets: 3, defaultReps: "10-12",    defaultRest: 60,  tips: "Press at angle — great for shoulder health and stability."),
        // ARMS
        ExerciseLibraryItem(name: "Barbell Curl",            category: .arms,      defaultSets: 3, defaultReps: "10-12",    defaultRest: 60,  tips: "Keep elbows pinned at sides, full range of motion."),
        ExerciseLibraryItem(name: "Dumbbell Curl",           category: .arms,      defaultSets: 3, defaultReps: "10-12",    defaultRest: 60,  tips: "Supinate wrist at top for peak bicep contraction."),
        ExerciseLibraryItem(name: "Hammer Curl",             category: .arms,      defaultSets: 3, defaultReps: "10-12",    defaultRest: 60,  tips: "Neutral grip targets brachialis and forearm thickness."),
        ExerciseLibraryItem(name: "Tricep Pushdown",         category: .arms,      defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Keep elbows at sides, fully extend and squeeze."),
        ExerciseLibraryItem(name: "Skull Crusher",           category: .arms,      defaultSets: 3, defaultReps: "10-12",    defaultRest: 75,  tips: "Lower bar to forehead, keep elbows pointed up."),
        ExerciseLibraryItem(name: "Overhead Tricep Extension", category: .arms,    defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Keep upper arms stationary, full stretch at bottom."),
        ExerciseLibraryItem(name: "Concentration Curl",      category: .arms,      defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Elbow on inner thigh, full range of motion."),
        ExerciseLibraryItem(name: "Cable Curl",              category: .arms,      defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Keep elbows fixed, cable provides constant tension."),
        ExerciseLibraryItem(name: "Reverse Curl",            category: .arms,      defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Overhand grip targets brachialis and forearms."),
        ExerciseLibraryItem(name: "Wrist Curl",              category: .arms,      defaultSets: 3, defaultReps: "15-20",    defaultRest: 45,  tips: "Forearm on bench, isolate wrist movement only."),
        ExerciseLibraryItem(name: "Diamond Push-Up",         category: .arms,      defaultSets: 3, defaultReps: "10-15",    defaultRest: 60,  tips: "Hands close in diamond shape, keep elbows tucked."),
        ExerciseLibraryItem(name: "Rope Pushdown",           category: .arms,      defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Spread rope at bottom for full tricep extension."),
        ExerciseLibraryItem(name: "Tricep Dip",              category: .arms,      defaultSets: 3, defaultReps: "10-15",    defaultRest: 60,  tips: "Keep elbows close to body, upright torso."),
        // LEGS
        ExerciseLibraryItem(name: "Barbell Squat",           category: .legs,      defaultSets: 4, defaultReps: "6-8",      defaultRest: 120, tips: "Break parallel depth, knees track over toes."),
        ExerciseLibraryItem(name: "Romanian Deadlift",       category: .legs,      defaultSets: 3, defaultReps: "10-12",    defaultRest: 90,  tips: "Hinge at hips, feel the hamstring stretch, flat back."),
        ExerciseLibraryItem(name: "Leg Press",               category: .legs,      defaultSets: 4, defaultReps: "10-12",    defaultRest: 90,  tips: "Don't lock knees at top, full range of motion."),
        ExerciseLibraryItem(name: "Walking Lunge",           category: .legs,      defaultSets: 3, defaultReps: "12 each",  defaultRest: 75,  tips: "Step forward, knee should not pass toes."),
        ExerciseLibraryItem(name: "Leg Curl",                category: .legs,      defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Full contraction, controlled descent on the way down."),
        ExerciseLibraryItem(name: "Leg Extension",           category: .legs,      defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Full extension, squeeze quad at top."),
        ExerciseLibraryItem(name: "Calf Raise",              category: .legs,      defaultSets: 4, defaultReps: "15-20",    defaultRest: 45,  tips: "Full stretch at bottom, pause and hold at top."),
        ExerciseLibraryItem(name: "Hip Thrust",              category: .legs,      defaultSets: 4, defaultReps: "12-15",    defaultRest: 75,  tips: "Drive hips up explosively, squeeze glutes at top."),
        ExerciseLibraryItem(name: "Bulgarian Split Squat",   category: .legs,      defaultSets: 3, defaultReps: "10 each",  defaultRest: 75,  tips: "Rear foot elevated, front foot forward enough."),
        ExerciseLibraryItem(name: "Goblet Squat",            category: .legs,      defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Hold dumbbell at chest, squat deep, elbows inside knees."),
        ExerciseLibraryItem(name: "Sumo Squat",              category: .legs,      defaultSets: 3, defaultReps: "12-15",    defaultRest: 60,  tips: "Wide stance, toes out, drive knees out on the way up."),
        ExerciseLibraryItem(name: "Step Up",                 category: .legs,      defaultSets: 3, defaultReps: "12 each",  defaultRest: 60,  tips: "Drive through heel of elevated foot, fully extend at top."),
        ExerciseLibraryItem(name: "Wall Sit",                category: .legs,      defaultSets: 3, defaultReps: "45 sec",   defaultRest: 45,  tips: "Thighs parallel to floor, back flat against wall."),
        ExerciseLibraryItem(name: "Glute Bridge",            category: .legs,      defaultSets: 3, defaultReps: "15-20",    defaultRest: 45,  tips: "Drive hips up, squeeze glutes hard at top."),
        ExerciseLibraryItem(name: "Donkey Kick",             category: .legs,      defaultSets: 3, defaultReps: "15 each",  defaultRest: 45,  tips: "Keep core tight, extend leg fully behind you."),
        ExerciseLibraryItem(name: "Lateral Band Walk",       category: .legs,      defaultSets: 3, defaultReps: "20 each",  defaultRest: 45,  tips: "Keep tension on band throughout, don't let knees cave."),
        ExerciseLibraryItem(name: "Box Step Down",           category: .legs,      defaultSets: 3, defaultReps: "10 each",  defaultRest: 60,  tips: "Slow eccentric descent, control every inch."),
        // CORE
        ExerciseLibraryItem(name: "Plank",                   category: .core,      defaultSets: 3, defaultReps: "45 sec",   defaultRest: 45,  tips: "Neutral spine, brace core, don't let hips sag."),
        ExerciseLibraryItem(name: "Crunch",                  category: .core,      defaultSets: 3, defaultReps: "20-25",    defaultRest: 45,  tips: "Lift shoulders off floor, don't pull on neck."),
        ExerciseLibraryItem(name: "Bicycle Crunch",          category: .core,      defaultSets: 3, defaultReps: "20 each",  defaultRest: 45,  tips: "Controlled rotation, don't rush the movement."),
        ExerciseLibraryItem(name: "Russian Twist",           category: .core,      defaultSets: 3, defaultReps: "20 each",  defaultRest: 45,  tips: "Lean back slightly, rotate from core not arms."),
        ExerciseLibraryItem(name: "Leg Raise",               category: .core,      defaultSets: 3, defaultReps: "15-20",    defaultRest: 45,  tips: "Lower back pressed to floor throughout."),
        ExerciseLibraryItem(name: "Cable Crunch",            category: .core,      defaultSets: 3, defaultReps: "15-20",    defaultRest: 45,  tips: "Crunch with abs, not just pulling with arms."),
        ExerciseLibraryItem(name: "Ab Wheel Rollout",        category: .core,      defaultSets: 3, defaultReps: "10-12",    defaultRest: 60,  tips: "Keep core braced, don't let hips drop."),
        ExerciseLibraryItem(name: "Side Plank",              category: .core,      defaultSets: 3, defaultReps: "30 sec each", defaultRest: 45, tips: "Hips up, body in straight line from head to feet."),
        ExerciseLibraryItem(name: "Dead Bug",                category: .core,      defaultSets: 3, defaultReps: "10 each",  defaultRest: 45,  tips: "Lower back pressed to floor, move opposite arm and leg."),
        ExerciseLibraryItem(name: "Pallof Press",            category: .core,      defaultSets: 3, defaultReps: "12 each",  defaultRest: 45,  tips: "Anti-rotation exercise — resist the urge to twist."),
        ExerciseLibraryItem(name: "Dragon Flag",             category: .core,      defaultSets: 3, defaultReps: "5-8",      defaultRest: 60,  tips: "Advanced move — keep body completely rigid."),
        ExerciseLibraryItem(name: "Hollow Body Hold",        category: .core,      defaultSets: 3, defaultReps: "30 sec",   defaultRest: 45,  tips: "Lower back pressed down, arms and legs extended low."),
        ExerciseLibraryItem(name: "Cable Woodchop",          category: .core,      defaultSets: 3, defaultReps: "12 each",  defaultRest: 45,  tips: "Rotate from the core, keep arms relatively straight."),
        // CARDIO
        ExerciseLibraryItem(name: "Treadmill Run",           category: .cardio,    defaultSets: 1, defaultReps: "20 min",   defaultRest: 0,   tips: "Maintain conversational pace, land midfoot.", isTimeBased: true),
        ExerciseLibraryItem(name: "Stair Master",            category: .cardio,    defaultSets: 1, defaultReps: "20 min",   defaultRest: 0,   tips: "Maintain upright posture, don't lean on rails.", isTimeBased: true),
        ExerciseLibraryItem(name: "Incline Treadmill Walk",  category: .cardio,    defaultSets: 1, defaultReps: "30 min",   defaultRest: 0,   tips: "Set incline 8-15%, moderate pace — excellent low impact cardio.", isTimeBased: true),
        ExerciseLibraryItem(name: "Elliptical",              category: .cardio,    defaultSets: 1, defaultReps: "20 min",   defaultRest: 0,   tips: "Low impact — keep resistance high enough to challenge yourself.", isTimeBased: true),
        ExerciseLibraryItem(name: "Stair Climb",             category: .cardio,    defaultSets: 1, defaultReps: "20 min",   defaultRest: 0,   tips: "Use actual stairs or stair climber machine.", isTimeBased: true),
        ExerciseLibraryItem(name: "Stationary Bike",         category: .cardio,    defaultSets: 1, defaultReps: "20 min",   defaultRest: 0,   tips: "Maintain steady cadence, vary resistance.", isTimeBased: true),
        ExerciseLibraryItem(name: "Rowing Machine",          category: .cardio,    defaultSets: 1, defaultReps: "15 min",   defaultRest: 0,   tips: "Drive with legs first, then pull arms — 60% legs 40% arms.", isTimeBased: true),
        ExerciseLibraryItem(name: "Cycling (Outdoor)",       category: .cardio,    defaultSets: 1, defaultReps: "30 min",   defaultRest: 0,   tips: "Maintain consistent cadence, vary terrain for challenge.", isTimeBased: true),
        ExerciseLibraryItem(name: "Recumbent Bike",          category: .cardio,    defaultSets: 1, defaultReps: "20 min",   defaultRest: 0,   tips: "Great for lower back support — ideal for beginners and seniors.", isTimeBased: true),
        ExerciseLibraryItem(name: "Swimming Laps",           category: .cardio,    defaultSets: 1, defaultReps: "20 min",   defaultRest: 0,   tips: "Excellent full body low impact cardio — focus on breathing rhythm.", isTimeBased: true),
        ExerciseLibraryItem(name: "Water Aerobics",          category: .cardio,    defaultSets: 1, defaultReps: "30 min",   defaultRest: 0,   tips: "Great for joints — maintain intensity throughout the session.", isTimeBased: true),
        ExerciseLibraryItem(name: "Pool Walking",            category: .cardio,    defaultSets: 1, defaultReps: "20 min",   defaultRest: 0,   tips: "Walk in chest-deep water for resistance — low impact.", isTimeBased: true),
        ExerciseLibraryItem(name: "Aqua Jogging",            category: .cardio,    defaultSets: 1, defaultReps: "20 min",   defaultRest: 0,   tips: "Use flotation belt, simulate running motion in deep water.", isTimeBased: true),
        ExerciseLibraryItem(name: "Nordic Walking",          category: .cardio,    defaultSets: 1, defaultReps: "30 min",   defaultRest: 0,   tips: "Use poles for full body engagement — 90% of muscles activated.", isTimeBased: true),
        ExerciseLibraryItem(name: "Tai Chi",                 category: .cardio,    defaultSets: 1, defaultReps: "20 min",   defaultRest: 0,   tips: "Focus on breathing and slow controlled movement — great for balance.", isTimeBased: true),
        ExerciseLibraryItem(name: "Yoga Flow",               category: .cardio,    defaultSets: 1, defaultReps: "30 min",   defaultRest: 0,   tips: "Maintain flow between poses, synchronize with breath.", isTimeBased: true),
        ExerciseLibraryItem(name: "Dance Cardio",            category: .cardio,    defaultSets: 1, defaultReps: "30 min",   defaultRest: 0,   tips: "Keep moving, have fun — intensity determines calorie burn.", isTimeBased: true),
        ExerciseLibraryItem(name: "Kickboxing",              category: .cardio,    defaultSets: 1, defaultReps: "30 min",   defaultRest: 0,   tips: "Full extension on strikes, keep guard up between combos.", isTimeBased: true),
        ExerciseLibraryItem(name: "Jump Rope",               category: .cardio,    defaultSets: 5, defaultReps: "2 min",    defaultRest: 60,  tips: "Land softly on balls of feet, keep jumps small.", isTimeBased: true),
        ExerciseLibraryItem(name: "HIIT Sprint Intervals",   category: .cardio,    defaultSets: 8, defaultReps: "30 sec",   defaultRest: 30,  tips: "Max effort on sprints, full recovery between sets.", isTimeBased: true),
        ExerciseLibraryItem(name: "Battle Ropes",            category: .cardio,    defaultSets: 5, defaultReps: "30 sec",   defaultRest: 30,  tips: "Full arm movement from shoulders, engage core.", isTimeBased: true),
        ExerciseLibraryItem(name: "Versa Climber",           category: .cardio,    defaultSets: 1, defaultReps: "15 min",   defaultRest: 0,   tips: "Simultaneous arm and leg drive — elite full body cardio.", isTimeBased: true),
        ExerciseLibraryItem(name: "Burpee",                  category: .cardio,    defaultSets: 4, defaultReps: "10-15",    defaultRest: 60,  tips: "Explosive jump at top, controlled descent."),
        ExerciseLibraryItem(name: "Mountain Climber",        category: .cardio,    defaultSets: 3, defaultReps: "30 sec",   defaultRest: 45,  tips: "Hips level, drive knees to chest rapidly.", isTimeBased: true),
        ExerciseLibraryItem(name: "Box Jump",                category: .cardio,    defaultSets: 4, defaultReps: "8-10",     defaultRest: 60,  tips: "Land softly with bent knees, step down don't jump down."),
        // FULL BODY
        ExerciseLibraryItem(name: "Kettlebell Swing",        category: .fullBody,  defaultSets: 4, defaultReps: "15-20",    defaultRest: 60,  tips: "Hip hinge not a squat — power comes from glutes."),
        ExerciseLibraryItem(name: "Thruster",                category: .fullBody,  defaultSets: 4, defaultReps: "10-12",    defaultRest: 75,  tips: "Squat to press in one fluid explosive motion."),
        ExerciseLibraryItem(name: "Clean and Press",         category: .fullBody,  defaultSets: 4, defaultReps: "5-6",      defaultRest: 120, tips: "Explosive pull from floor, catch at shoulders, press overhead."),
        ExerciseLibraryItem(name: "Turkish Get-Up",          category: .fullBody,  defaultSets: 3, defaultReps: "5 each",   defaultRest: 90,  tips: "Slow and controlled — keep weight locked out overhead."),
        ExerciseLibraryItem(name: "Farmer's Carry",          category: .fullBody,  defaultSets: 4, defaultReps: "40 yards", defaultRest: 60,  tips: "Keep chest up, shoulders back, walk with purpose."),
        ExerciseLibraryItem(name: "Sled Push",               category: .fullBody,  defaultSets: 4, defaultReps: "20 yards", defaultRest: 90,  tips: "Drive through legs, lean into sled at 45 degrees."),
        ExerciseLibraryItem(name: "Man Maker",               category: .fullBody,  defaultSets: 3, defaultReps: "8-10",     defaultRest: 90,  tips: "Push-up, row each arm, squat, then press — one fluid movement."),
        ExerciseLibraryItem(name: "Bear Crawl",              category: .fullBody,  defaultSets: 3, defaultReps: "20 yards", defaultRest: 60,  tips: "Keep hips low, move opposite hand and foot together."),
    ]
    
        static func byCategory(_ cat: ExerciseLibraryItem.ExerciseCategory) -> [ExerciseLibraryItem] { all.filter { $0.category == cat } }
    static func search(_ q: String) -> [ExerciseLibraryItem] { q.isEmpty ? all : all.filter { $0.name.localizedCaseInsensitiveContains(q) } }
}

// MARK: - Weekly Day Model

struct WorkoutDay: Identifiable {
    let id = UUID()
    var dayNumber:   Int
    var isRestDay:   Bool = false
    var muscleGroup: String = ""
    var title:       String = ""
    var difficulty:  String = "intermediate"
    var estimatedMins: Int = 45
    var exercises:   [ExerciseItem] = []

    var displayTitle: String {
        if isRestDay { return "Rest Day" }
        if !title.isEmpty { return title }
        if !muscleGroup.isEmpty { return muscleGroup }
        return "Day \(dayNumber)"
    }
}

// MARK: - Workout Builder View

struct WorkoutBuilderView: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = SBWorkoutStore.shared

    @State private var days: [WorkoutDay] = [WorkoutDay(dayNumber: 1)]
    @State private var selectedDayIndex = 0
    @State private var showingLibrary   = false
    @State private var isSaving         = false
    @State private var editingExercise: ExerciseItem? = nil

    let muscleGroups = ["Chest", "Back", "Shoulders", "Arms", "Legs", "Glutes", "Core", "Push", "Pull", "Upper Body", "Lower Body", "Full Body", "Cardio"]
    let difficulties = ["beginner", "intermediate", "advanced"]

    var currentDay: WorkoutDay { days[selectedDayIndex] }
    var canSave: Bool { days.contains { !$0.isRestDay && !$0.exercises.isEmpty } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Day tabs
                dayTabBar

                ScrollView {
                    VStack(spacing: 20) {
                        if currentDay.isRestDay {
                            restDayCard
                        } else {
                            activeDay
                        }
                    }
                    .padding(20)
                }

                // Save button
                VStack(spacing: 0) {
                    Divider().background(Color.white.opacity(0.08))
                    Button(action: {
                        guard canSave else { return }
                        TrainerLocalCache.shared.saveWorkoutProgramAsTemplate(
                            trainerId: trainerId,
                            title: days.first(where: { !$0.isRestDay })?.muscleGroup ?? "\(days.count)-Day Program",
                            days: days.map { day in
                                WorkoutRow(id: UUID(),
                                    trainerId: UUID(uuidString: trainerId) ?? UUID(),
                                    clientId: UUID(uuidString: clientId) ?? UUID(),
                                    title: day.isRestDay ? "Rest Day" : (day.muscleGroup.isEmpty ? "Day \(day.dayNumber)" : day.muscleGroup),
                                    description: "",
                                    exercises: day.exercises,
                                    difficulty: day.difficulty,
                                    estimatedMins: day.isRestDay ? 0 : day.estimatedMins,
                                    status: "assigned",
                                    muscleGroup: day.isRestDay ? nil : (day.muscleGroup.isEmpty ? nil : day.muscleGroup),
                                    dayNumber: day.dayNumber,
                                    isRestDay: day.isRestDay,
                                    assignedDate: Date(),
                                    dueDate: Date().addingTimeInterval(7 * 86400),
                                    completedAt: nil, createdAt: Date())
                            }
                        )
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save as Template").font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.tmGold).frame(maxWidth: .infinity).frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 22).stroke(Color.tmGold, lineWidth: 1))
                    }
                    .disabled(!canSave)

                    Button(action: saveProgram) {
                        HStack(spacing: 8) {
                            if isSaving { ProgressView().tint(.black) } else {
                                Image(systemName: "paperplane.fill")
                                Text("ASSIGN \(days.count)-DAY PROGRAM TO \(clientName.uppercased())")
                                    .font(.system(size: 13, weight: .heavy)).tracking(0.3)
                            }
                        }
                        .foregroundColor(canSave ? .black : .white.opacity(0.4))
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(canSave ? Color.tmGold : Color.white.opacity(0.08))
                    }
                    .disabled(!canSave || isSaving)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                }
            }
        }
        .navigationTitle("Build Weekly Program").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.tmGold) }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: addDay) {
                    HStack(spacing: 4) { Image(systemName: "plus"); Text("Add Day") }
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(.tmGold)
                }
            }
        }
        .sheet(isPresented: $showingLibrary) {
            ExerciseLibraryView { exercise in
                let item = ExerciseItem(id: UUID(), name: exercise.name,
            sets: exercise.isTimeBased ? 1 : exercise.defaultSets,
            reps: exercise.defaultReps, weight: "",
            notes: exercise.tips,
            restSeconds: exercise.isTimeBased ? 0 : exercise.defaultRest)
                days[selectedDayIndex].exercises.append(item)
                if days[selectedDayIndex].muscleGroup.isEmpty {
                    days[selectedDayIndex].muscleGroup = exercise.category.rawValue
                }
            }
        }
        .sheet(item: $editingExercise) { ex in
            ExerciseEditSheet(exercise: ex) { updated in
                if let i = days[selectedDayIndex].exercises.firstIndex(where: { $0.id == updated.id }) {
                    days[selectedDayIndex].exercises[i] = updated
                }
            }
        }
    }

    // MARK: - Day Tab Bar

    private var dayTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(days.indices, id: \.self) { i in
                    Button(action: { selectedDayIndex = i }) {
                        VStack(spacing: 4) {
                            Text("Day \(days[i].dayNumber)")
                                .font(.system(size: 11, weight: .bold))
                            if days[i].isRestDay {
                                Image(systemName: "moon.zzz.fill").font(.system(size: 10)).foregroundColor(.blue.opacity(0.8))
                            } else if !days[i].muscleGroup.isEmpty {
                                Text(days[i].muscleGroup).font(.system(size: 9)).lineLimit(1)
                            } else if !days[i].exercises.isEmpty {
                                Text("\(days[i].exercises.count) ex").font(.system(size: 9))
                            } else {
                                Text("Empty").font(.system(size: 9)).opacity(0.5)
                            }
                        }
                        .foregroundColor(selectedDayIndex == i ? .tmGold : .white.opacity(0.4))
                        .frame(width: 72).padding(.vertical, 10)
                        .background(selectedDayIndex == i ? Color.tmGold.opacity(0.08) : Color.clear)
                        .overlay(alignment: .bottom) {
                            if selectedDayIndex == i { Rectangle().fill(Color.tmGold).frame(height: 2) }
                        }
                    }
                }
            }
        }
        .background(Color.white.opacity(0.04))
    }

    // MARK: - Rest Day Card

    private var restDayCard: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "moon.zzz.fill").font(.system(size: 48)).foregroundColor(.blue.opacity(0.6))
                Text("Rest Day").font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text("Recovery is part of the program. No exercises scheduled for Day \(currentDay.dayNumber).")
                    .font(.subheadline).foregroundColor(.white.opacity(0.5)).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding(40)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.2), lineWidth: 1)))

            Button(action: {
                days[selectedDayIndex].isRestDay = false
                days[selectedDayIndex].title = ""
            }) {
                HStack(spacing: 6) { Image(systemName: "dumbbell.fill"); Text("Convert to Workout Day") }
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.tmGold)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(RoundedRectangle(cornerRadius: 22).stroke(Color.tmGold, lineWidth: 1))
            }

            if days.count > 1 {
                Button(action: removeDay) {
                    Text("Remove Day \(currentDay.dayNumber)")
                        .font(.system(size: 13)).foregroundColor(.red.opacity(0.7))
                }
            }
        }
    }

    // MARK: - Active Day

    private var activeDay: some View {
        VStack(spacing: 20) {
            // Day header controls
            HStack(spacing: 12) {
                // Rest day toggle
                Button(action: { days[selectedDayIndex].isRestDay = true; days[selectedDayIndex].exercises = [] }) {
                    HStack(spacing: 6) { Image(systemName: "moon.zzz.fill").font(.caption); Text("Set Rest Day").font(.caption).fontWeight(.semibold) }
                        .foregroundColor(.blue.opacity(0.8)).padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Capsule().fill(Color.blue.opacity(0.1)).overlay(Capsule().stroke(Color.blue.opacity(0.3), lineWidth: 1)))
                }
                Spacer()
                if days.count > 1 {
                    Button(action: removeDay) {
                        Image(systemName: "trash").font(.caption).foregroundColor(.red.opacity(0.6))
                            .padding(8).background(Circle().fill(Color.red.opacity(0.08)))
                    }
                }
            }

            // Muscle group
            formBlock("MUSCLE GROUP / FOCUS") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(muscleGroups, id: \.self) { g in
                            Button(action: { days[selectedDayIndex].muscleGroup = days[selectedDayIndex].muscleGroup == g ? "" : g }) {
                                Text(g).font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(currentDay.muscleGroup == g ? .black : .white.opacity(0.6))
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Capsule().fill(currentDay.muscleGroup == g ? Color.tmGold : Color.white.opacity(0.08)))
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }

            // Difficulty + Duration
            HStack(spacing: 12) {
                formBlock("DIFFICULTY") {
                    Menu {
                        ForEach(difficulties, id: \.self) { d in Button(d.capitalized) { days[selectedDayIndex].difficulty = d } }
                    } label: {
                        HStack {
                            Circle().fill(difficultyColor).frame(width: 8, height: 8)
                            Text(currentDay.difficulty.capitalized).foregroundColor(.white); Spacer()
                            Image(systemName: "chevron.down").font(.caption).foregroundColor(.gray)
                        }.padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    }
                }
                formBlock("EST. MINS") {
                    HStack {
                        Button(action: { if days[selectedDayIndex].estimatedMins > 5 { days[selectedDayIndex].estimatedMins -= 5 } }) {
                            Image(systemName: "minus.circle.fill").foregroundColor(.tmGold).font(.title3)
                        }
                        Text("\(currentDay.estimatedMins)").font(.system(size: 18, weight: .bold)).foregroundColor(.white).frame(minWidth: 36)
                        Button(action: { days[selectedDayIndex].estimatedMins += 5 }) {
                            Image(systemName: "plus.circle.fill").foregroundColor(.tmGold).font(.title3)
                        }
                    }.padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                }
            }

            // Exercises
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("EXERCISES").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                        if !currentDay.exercises.isEmpty {
                            Text("\(currentDay.exercises.count) exercises • \(currentDay.exercises.reduce(0) { $0 + $1.sets }) sets")
                                .font(.caption2).foregroundColor(.white.opacity(0.4))
                        }
                    }
                    Spacer()
                    Button(action: { showingLibrary = true }) {
                        HStack(spacing: 6) { Image(systemName: "plus.circle.fill").font(.caption); Text("Add").font(.caption).fontWeight(.semibold) }
                            .foregroundColor(.black).padding(.horizontal, 12).padding(.vertical, 6).background(Capsule().fill(Color.tmGold))
                    }
                }

                if currentDay.exercises.isEmpty {
                    Button(action: { showingLibrary = true }) {
                        VStack(spacing: 10) {
                            Image(systemName: "dumbbell.fill").font(.system(size: 28)).foregroundColor(.tmGold.opacity(0.4))
                            Text("Tap to add exercises").font(.subheadline).foregroundColor(.white.opacity(0.35))
                        }
                        .frame(maxWidth: .infinity).padding(24)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.03))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tmGold.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))))
                    }.buttonStyle(.plain)
                } else {
                    // Exercise cards stacked like food items
                    VStack(spacing: 0) {
                        ForEach(Array(currentDay.exercises.enumerated()), id: \.element.id) { i, ex in
                            ExerciseCard(exercise: ex, index: i + 1,
                                onEdit: { editingExercise = ex },
                                onDelete: { days[selectedDayIndex].exercises.removeAll { $0.id == ex.id } },
                                onMoveUp:   { if i > 0 { days[selectedDayIndex].exercises.swapAt(i, i-1) } },
                                onMoveDown: { if i < currentDay.exercises.count-1 { days[selectedDayIndex].exercises.swapAt(i, i+1) } }
                            )
                            if i < currentDay.exercises.count - 1 {
                                Divider().background(Color.white.opacity(0.06)).padding(.leading, 52)
                            }
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    // MARK: - Helpers

    private var difficultyColor: Color {
        switch currentDay.difficulty {
        case "beginner": return .green; case "advanced": return .red; default: return .tmGold
        }
    }

    private func addDay() {
        let newNum = (days.map { $0.dayNumber }.max() ?? 0) + 1
        days.append(WorkoutDay(dayNumber: newNum))
        selectedDayIndex = days.count - 1
    }

    private func removeDay() {
        guard days.count > 1 else { return }
        days.remove(at: selectedDayIndex)
        // Renumber
        for i in days.indices { days[i].dayNumber = i + 1 }
        selectedDayIndex = max(0, selectedDayIndex - 1)
    }

    private func saveProgram() {
        guard canSave,
              let tUUID = UUID(uuidString: trainerId),
              let cUUID = UUID(uuidString: clientId) else { return }
        isSaving = true

        Task {
            do {
                let rows = days.map { day in
                    WorkoutRow(
                        id: UUID(), trainerId: tUUID, clientId: cUUID,
                        title: day.isRestDay ? "Rest Day" : (day.title.isEmpty ? (day.muscleGroup.isEmpty ? "Day \(day.dayNumber)" : day.muscleGroup) : day.title),
                        description: "",
                        exercises: day.isRestDay ? [] : day.exercises,
                        difficulty: day.difficulty,
                        estimatedMins: day.isRestDay ? 0 : day.estimatedMins,
                        status: "assigned",
                        muscleGroup: day.isRestDay ? nil : (day.muscleGroup.isEmpty ? nil : day.muscleGroup),
                        dayNumber: day.dayNumber,
                        isRestDay: day.isRestDay,
                        assignedDate: Date(),
                        dueDate: Date().addingTimeInterval(7 * 86400),
                        completedAt: nil, createdAt: Date()
                    )
                }
                try await SBWorkoutStore.shared.replaceProgram(rows)
                await MainActor.run { isSaving = false; dismiss() }
            } catch {
                print("❌ Program save error: \(error)")
                await MainActor.run { isSaving = false }
            }
        }
    }

    private func formBlock<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
            content()
        }
    }
}

// MARK: - Exercise Card (list style like food items)

struct ExerciseCard: View {
    let exercise:   ExerciseItem
    let index:      Int
    let onEdit:     () -> Void
    let onDelete:   () -> Void
    let onMoveUp:   () -> Void
    let onMoveDown: () -> Void
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } }) {
                HStack(spacing: 14) {
                    // Number
                    Text("\(index)").font(.system(size: 12, weight: .black)).foregroundColor(.black)
                        .frame(width: 28, height: 28).background(Circle().fill(Color.tmGold))

                    // Name + sets/reps or duration
                    VStack(alignment: .leading, spacing: 3) {
                        Text(exercise.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                        if exercise.reps.contains("min") || exercise.reps.contains("sec") {
                            Text("⏱ \(exercise.reps)")
                                .font(.caption).foregroundColor(.blue.opacity(0.8))
                        } else {
                            Text("\(exercise.sets) sets · \(exercise.reps) reps")
                                .font(.caption).foregroundColor(.white.opacity(0.45))
                        }
                    }

                    Spacer()

                    // Weight if set
                    if !exercise.weight.isEmpty {
                        Text(exercise.weight).font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                    }

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Expanded detail
            if expanded {
                VStack(alignment: .leading, spacing: 10) {
                    // Rest time + tips
                    if exercise.restSeconds > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "timer").font(.caption2).foregroundColor(.tmGold)
                            Text("\(exercise.restSeconds)s rest between sets").font(.caption).foregroundColor(.white.opacity(0.6))
                        }
                    }
                    if !exercise.notes.isEmpty {
                        Text(exercise.notes).font(.caption).foregroundColor(.white.opacity(0.5)).fixedSize(horizontal: false, vertical: true)
                    }
                    // Action buttons
                    HStack(spacing: 8) {
                        Button(action: onMoveUp)   { Image(systemName: "arrow.up").font(.caption).foregroundColor(.white.opacity(0.5)).padding(8).background(Circle().fill(Color.white.opacity(0.06))) }
                        Button(action: onMoveDown) { Image(systemName: "arrow.down").font(.caption).foregroundColor(.white.opacity(0.5)).padding(8).background(Circle().fill(Color.white.opacity(0.06))) }
                        Button(action: onEdit)     { HStack(spacing: 4) { Image(systemName: "pencil").font(.caption); Text("Edit").font(.caption) }.foregroundColor(.tmGold).padding(.horizontal, 12).padding(.vertical, 6).background(Capsule().fill(Color.tmGold.opacity(0.1))) }
                        Spacer()
                        Button(action: onDelete)   { Image(systemName: "trash").font(.caption).foregroundColor(.red.opacity(0.7)).padding(8).background(Circle().fill(Color.red.opacity(0.08))) }
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Exercise Row Card (kept for trainer workout view)

struct ExerciseRowCard: View {
    let exercise: ExerciseItem; let index: Int
    let onEdit: () -> Void; let onDelete: () -> Void
    let onMoveUp: () -> Void; let onMoveDown: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)").font(.system(size: 12, weight: .black)).foregroundColor(.black).frame(width: 28, height: 28).background(Circle().fill(Color.tmGold))
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                HStack(spacing: 6) { Text("\(exercise.sets) sets"); Text("×"); Text(exercise.reps); if exercise.restSeconds > 0 { Text("· \(exercise.restSeconds)s rest") } }.font(.caption).foregroundColor(.white.opacity(0.45))
                if !exercise.weight.isEmpty { Text("Weight: \(exercise.weight)").font(.caption2).foregroundColor(.tmGold) }
            }
            Spacer()
            HStack(spacing: 4) {
                Button(action: onMoveUp)   { Image(systemName: "chevron.up").font(.caption).foregroundColor(.white.opacity(0.4)).padding(6) }
                Button(action: onMoveDown) { Image(systemName: "chevron.down").font(.caption).foregroundColor(.white.opacity(0.4)).padding(6) }
                Button(action: onEdit)     { Image(systemName: "pencil").font(.caption).foregroundColor(.tmGold).padding(6) }
                Button(action: onDelete)   { Image(systemName: "trash").font(.caption).foregroundColor(.red.opacity(0.7)).padding(6) }
            }
        }
        .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05))).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

// MARK: - Exercise Library Browser

struct ExerciseLibraryView: View {
    let onAdd: (ExerciseLibraryItem) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseLibraryItem.ExerciseCategory? = nil
    @State private var addedIds: Set<UUID> = []

    private var filtered: [ExerciseLibraryItem] {
        var list = selectedCategory != nil ? ExerciseLibrary.byCategory(selectedCategory!) : ExerciseLibrary.all
        if !searchText.isEmpty { list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        return list
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack(spacing: 10) { Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.4)); TextField("Search exercises...", text: $searchText).foregroundColor(.white) }
                        .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06))).padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(label: "All", icon: "square.grid.2x2.fill", color: .tmGold, isSelected: selectedCategory == nil) { selectedCategory = nil }
                            ForEach(ExerciseLibraryItem.ExerciseCategory.allCases, id: \.self) { cat in
                                CategoryChip(label: cat.rawValue, icon: cat.icon, color: cat.color, isSelected: selectedCategory == cat) { selectedCategory = selectedCategory == cat ? nil : cat }
                            }
                        }.padding(.horizontal, 16)
                    }.padding(.bottom, 8)
                    Divider().background(Color.white.opacity(0.08))
                    List {
                        ForEach(filtered) { exercise in
                            ExerciseLibraryRow(exercise: exercise, isAdded: addedIds.contains(exercise.id)) { onAdd(exercise); addedIds.insert(exercise.id) }
                                .listRowBackground(Color.white.opacity(0.03)).listRowSeparatorTint(Color.white.opacity(0.06))
                        }
                    }.listStyle(.plain).scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Exercise Library").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() }.foregroundColor(.tmGold) } }
        }
    }
}

// MARK: - Supporting Views

struct CategoryChip: View {
    let label: String; let icon: String; let color: Color; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) { Image(systemName: icon).font(.system(size: 11)); Text(label).font(.system(size: 12, weight: .semibold)) }
                .foregroundColor(isSelected ? .black : .white.opacity(0.6)).padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(isSelected ? color : Color.white.opacity(0.08)))
        }.buttonStyle(.plain)
    }
}

struct ExerciseLibraryRow: View {
    let exercise: ExerciseLibraryItem; let isAdded: Bool; let onAdd: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            ZStack { RoundedRectangle(cornerRadius: 8).fill(exercise.category.color.opacity(0.15)).frame(width: 40, height: 40); Image(systemName: exercise.category.icon).font(.system(size: 16)).foregroundColor(exercise.category.color) }
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                HStack(spacing: 6) {
                    Text(exercise.category.rawValue).font(.caption).foregroundColor(exercise.category.color)
                    Text("·").foregroundColor(.white.opacity(0.3))
                    if exercise.isTimeBased {
                        Text("⏱ \(exercise.defaultReps)").font(.caption).foregroundColor(.blue.opacity(0.8))
                    } else {
                        Text("\(exercise.defaultSets) sets · \(exercise.defaultReps)").font(.caption).foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            Spacer()
            Button(action: onAdd) { Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill").font(.system(size: 26)).foregroundColor(isAdded ? .green : .tmGold) }.buttonStyle(.plain)
        }.padding(.vertical, 6)
    }
}

// MARK: - Exercise Edit Sheet

struct ExerciseEditSheet: View {
    let exercise: ExerciseItem; let onSave: (ExerciseItem) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name: String; @State private var sets: String; @State private var reps: String
    @State private var weight: String; @State private var rest: String; @State private var notes: String

    init(exercise: ExerciseItem, onSave: @escaping (ExerciseItem) -> Void) {
        self.exercise = exercise; self.onSave = onSave
        _name = State(initialValue: exercise.name); _sets = State(initialValue: "\(exercise.sets)")
        _reps = State(initialValue: exercise.reps); _weight = State(initialValue: exercise.weight)
        _rest = State(initialValue: "\(exercise.restSeconds)"); _notes = State(initialValue: exercise.notes)
    }

    private var isTimeBased: Bool {
        reps.contains("min") || reps.contains("sec") || name.lowercased().contains("cardio") ||
        name.lowercased().contains("treadmill") || name.lowercased().contains("swim") ||
        name.lowercased().contains("bike") || name.lowercased().contains("rowing") ||
        name.lowercased().contains("stair") || name.lowercased().contains("elliptical") ||
        name.lowercased().contains("walk") || name.lowercased().contains("cycling") ||
        name.lowercased().contains("yoga") || name.lowercased().contains("tai chi") ||
        name.lowercased().contains("dance") || name.lowercased().contains("water") ||
        name.lowercased().contains("aqua") || name.lowercased().contains("pool") ||
        name.lowercased().contains("sprint") || name.lowercased().contains("kickbox") ||
        name.lowercased().contains("jump rope") || name.lowercased().contains("battle rope")
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        field("EXERCISE NAME", text: $name)
                        if isTimeBased {
                            // Time-based cardio
                            field("DURATION", text: $reps, placeholder: "e.g. 20 min, 30 sec")
                            HStack(spacing: 8) {
                                ForEach(["5 min","10 min","15 min","20 min","30 min","45 min","60 min"], id: \.self) { t in
                                    Button(action: { reps = t }) {
                                        Text(t).font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(reps == t ? .black : .white.opacity(0.6))
                                            .padding(.horizontal, 8).padding(.vertical, 5)
                                            .background(Capsule().fill(reps == t ? Color.blue : Color.white.opacity(0.08)))
                                    }.buttonStyle(.plain)
                                }
                            }
                        } else {
                            HStack(spacing: 12) { field("SETS", text: $sets, keyboard: .numberPad); field("REPS", text: $reps) }
                            HStack(spacing: 12) { field("WEIGHT", text: $weight, placeholder: "e.g. 135 lbs"); field("REST (sec)", text: $rest, keyboard: .numberPad) }
                        }
                        field("TIPS / NOTES", text: $notes, multiline: true)
                        Button(action: save) {
                            Text("SAVE").font(.system(size: 15, weight: .heavy)).foregroundColor(.black)
                                .frame(maxWidth: .infinity).frame(height: 52).background(RoundedRectangle(cornerRadius: 26).fill(Color.tmGold))
                        }
                    }.padding(20)
                }
            }
            .navigationTitle("Edit Exercise").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.tmGold) } }
        }
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String = "", keyboard: UIKeyboardType = .default, multiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
            if multiline {
                TextField(placeholder.isEmpty ? label.lowercased() : placeholder, text: text, axis: .vertical)
                    .lineLimit(2...4).foregroundColor(.white).padding(12).background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
            } else {
                TextField(placeholder.isEmpty ? label.lowercased() : placeholder, text: text)
                    .keyboardType(keyboard).foregroundColor(.white).padding(12).background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
            }
        }
    }

    private func save() {
        let updated = ExerciseItem(id: exercise.id, name: name, sets: Int(sets) ?? exercise.sets, reps: reps, weight: weight, notes: notes, restSeconds: Int(rest) ?? exercise.restSeconds)
        onSave(updated); dismiss()
    }
}
