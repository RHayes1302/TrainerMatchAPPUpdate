//
//  MealPlanBuilderView.swift
//  TrainerMatch
//
//  Trainer builds meal plans using a food library with
//  adjustable serving sizes and auto-calculated macros.
//

import SwiftUI

// MARK: - Food Library Item

struct FoodLibraryItem: Identifiable {
    let id = UUID()
    let name:        String
    let category:    FoodCategory
    let servingSize: Double   // grams per 1 serving
    let servingUnit: String   // "oz", "cup", "piece", etc.
    // Macros per 1 serving
    let caloriesPerServing: Int
    let proteinPerServing:  Double
    let carbsPerServing:    Double
    let fatPerServing:      Double
    let mealTypes:   [String] // suggested meal types

    enum FoodCategory: String, CaseIterable {
        case protein    = "Protein"
        case carbs      = "Carbs"
        case vegetables = "Vegetables"
        case fruits     = "Fruits"
        case dairy      = "Dairy"
        case fats       = "Healthy Fats"
        case snacks     = "Snacks"
        case drinks     = "Drinks"

        var icon: String {
            switch self {
            case .protein:    return "flame.fill"
            case .carbs:      return "leaf.fill"
            case .vegetables: return "carrot.fill"
            case .fruits:     return "apple.logo"
            case .dairy:      return "drop.fill"
            case .fats:       return "circle.hexagongrid.fill"
            case .snacks:     return "takeoutbag.and.cup.and.straw.fill"
            case .drinks:     return "cup.and.saucer.fill"
            }
        }

        var color: Color {
            switch self {
            case .protein:    return .red
            case .carbs:      return .orange
            case .vegetables: return .green
            case .fruits:     return .pink
            case .dairy:      return .blue
            case .fats:       return .yellow
            case .snacks:     return .purple
            case .drinks:     return .cyan
            }
        }
    }
}

// MARK: - Food Library Data

struct FoodLibrary {
    static let all: [FoodLibraryItem] = [
        // PROTEIN
        FoodLibraryItem(name: "Chicken Breast",        category: .protein,    servingSize: 113, servingUnit: "4 oz",   caloriesPerServing: 187, proteinPerServing: 35,  carbsPerServing: 0,   fatPerServing: 4,   mealTypes: ["Lunch","Dinner","Post-Workout"]),
        FoodLibraryItem(name: "Ground Turkey (93%)",   category: .protein,    servingSize: 113, servingUnit: "4 oz",   caloriesPerServing: 170, proteinPerServing: 23,  carbsPerServing: 0,   fatPerServing: 8,   mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Salmon Fillet",         category: .protein,    servingSize: 113, servingUnit: "4 oz",   caloriesPerServing: 207, proteinPerServing: 29,  carbsPerServing: 0,   fatPerServing: 10,  mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Tilapia",               category: .protein,    servingSize: 113, servingUnit: "4 oz",   caloriesPerServing: 145, proteinPerServing: 30,  carbsPerServing: 0,   fatPerServing: 3,   mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Tuna (canned, water)",  category: .protein,    servingSize: 85,  servingUnit: "3 oz",   caloriesPerServing: 100, proteinPerServing: 22,  carbsPerServing: 0,   fatPerServing: 1,   mealTypes: ["Lunch","Snack"]),
        FoodLibraryItem(name: "Shrimp",                category: .protein,    servingSize: 113, servingUnit: "4 oz",   caloriesPerServing: 112, proteinPerServing: 24,  carbsPerServing: 0,   fatPerServing: 1,   mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Lean Beef (93%)",       category: .protein,    servingSize: 113, servingUnit: "4 oz",   caloriesPerServing: 215, proteinPerServing: 26,  carbsPerServing: 0,   fatPerServing: 12,  mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Egg Whites",            category: .protein,    servingSize: 120, servingUnit: "4 whites", caloriesPerServing: 68, proteinPerServing: 14, carbsPerServing: 1,   fatPerServing: 0,   mealTypes: ["Breakfast","Post-Workout"]),
        FoodLibraryItem(name: "Whole Eggs",            category: .protein,    servingSize: 100, servingUnit: "2 eggs", caloriesPerServing: 143, proteinPerServing: 13,  carbsPerServing: 1,   fatPerServing: 10,  mealTypes: ["Breakfast"]),
        FoodLibraryItem(name: "Whey Protein Shake",    category: .protein,    servingSize: 30,  servingUnit: "1 scoop",caloriesPerServing: 120, proteinPerServing: 25,  carbsPerServing: 3,   fatPerServing: 2,   mealTypes: ["Post-Workout","Snack"]),
        FoodLibraryItem(name: "Cottage Cheese",        category: .protein,    servingSize: 226, servingUnit: "1 cup",  caloriesPerServing: 206, proteinPerServing: 28,  carbsPerServing: 8,   fatPerServing: 5,   mealTypes: ["Breakfast","Snack"]),
        FoodLibraryItem(name: "Turkey Breast Deli",    category: .protein,    servingSize: 85,  servingUnit: "3 oz",   caloriesPerServing: 90,  proteinPerServing: 18,  carbsPerServing: 2,   fatPerServing: 1,   mealTypes: ["Lunch","Snack"]),
        FoodLibraryItem(name: "Bison (ground)",        category: .protein,    servingSize: 113, servingUnit: "4 oz",   caloriesPerServing: 200, proteinPerServing: 26,  carbsPerServing: 0,   fatPerServing: 10,  mealTypes: ["Dinner"]),
        FoodLibraryItem(name: "Edamame",               category: .protein,    servingSize: 155, servingUnit: "1 cup",  caloriesPerServing: 188, proteinPerServing: 17,  carbsPerServing: 14,  fatPerServing: 8,   mealTypes: ["Snack","Lunch"]),

        // CARBS
        FoodLibraryItem(name: "White Rice (cooked)",   category: .carbs,      servingSize: 186, servingUnit: "1 cup",  caloriesPerServing: 242, proteinPerServing: 4,   carbsPerServing: 53,  fatPerServing: 0,   mealTypes: ["Lunch","Dinner","Post-Workout"]),
        FoodLibraryItem(name: "Brown Rice (cooked)",   category: .carbs,      servingSize: 196, servingUnit: "1 cup",  caloriesPerServing: 216, proteinPerServing: 5,   carbsPerServing: 45,  fatPerServing: 2,   mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Oatmeal (cooked)",      category: .carbs,      servingSize: 234, servingUnit: "1 cup",  caloriesPerServing: 166, proteinPerServing: 6,   carbsPerServing: 32,  fatPerServing: 4,   mealTypes: ["Breakfast","Pre-Workout"]),
        FoodLibraryItem(name: "Sweet Potato",          category: .carbs,      servingSize: 130, servingUnit: "1 medium",caloriesPerServing: 112, proteinPerServing: 2,  carbsPerServing: 26,  fatPerServing: 0,   mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Quinoa (cooked)",       category: .carbs,      servingSize: 185, servingUnit: "1 cup",  caloriesPerServing: 222, proteinPerServing: 8,   carbsPerServing: 39,  fatPerServing: 4,   mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Whole Wheat Bread",     category: .carbs,      servingSize: 56,  servingUnit: "2 slices",caloriesPerServing: 138, proteinPerServing: 6,  carbsPerServing: 24,  fatPerServing: 2,   mealTypes: ["Breakfast","Lunch"]),
        FoodLibraryItem(name: "Pasta (cooked)",        category: .carbs,      servingSize: 140, servingUnit: "1 cup",  caloriesPerServing: 220, proteinPerServing: 8,   carbsPerServing: 43,  fatPerServing: 1,   mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Potatoes (baked)",      category: .carbs,      servingSize: 173, servingUnit: "1 medium",caloriesPerServing: 161, proteinPerServing: 4,  carbsPerServing: 37,  fatPerServing: 0,   mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Rice Cakes",            category: .carbs,      servingSize: 18,  servingUnit: "2 cakes",caloriesPerServing: 70,  proteinPerServing: 1,   carbsPerServing: 15,  fatPerServing: 0,   mealTypes: ["Snack","Pre-Workout"]),
        FoodLibraryItem(name: "Cream of Rice",         category: .carbs,      servingSize: 35,  servingUnit: "1/4 cup dry",caloriesPerServing: 130, proteinPerServing: 3, carbsPerServing: 28, fatPerServing: 0,  mealTypes: ["Breakfast","Post-Workout"]),
        FoodLibraryItem(name: "Ezekiel Bread",         category: .carbs,      servingSize: 68,  servingUnit: "2 slices",caloriesPerServing: 160, proteinPerServing: 8,  carbsPerServing: 30,  fatPerServing: 1,   mealTypes: ["Breakfast","Lunch"]),

        // VEGETABLES
        FoodLibraryItem(name: "Broccoli",              category: .vegetables, servingSize: 91,  servingUnit: "1 cup",  caloriesPerServing: 31,  proteinPerServing: 3,   carbsPerServing: 6,   fatPerServing: 0,   mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Spinach",               category: .vegetables, servingSize: 30,  servingUnit: "1 cup",  caloriesPerServing: 7,   proteinPerServing: 1,   carbsPerServing: 1,   fatPerServing: 0,   mealTypes: ["Breakfast","Lunch","Dinner"]),
        FoodLibraryItem(name: "Asparagus",             category: .vegetables, servingSize: 134, servingUnit: "1 cup",  caloriesPerServing: 27,  proteinPerServing: 3,   carbsPerServing: 5,   fatPerServing: 0,   mealTypes: ["Dinner"]),
        FoodLibraryItem(name: "Green Beans",           category: .vegetables, servingSize: 100, servingUnit: "1 cup",  caloriesPerServing: 31,  proteinPerServing: 2,   carbsPerServing: 7,   fatPerServing: 0,   mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Zucchini",              category: .vegetables, servingSize: 124, servingUnit: "1 cup",  caloriesPerServing: 21,  proteinPerServing: 2,   carbsPerServing: 4,   fatPerServing: 0,   mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Bell Peppers",          category: .vegetables, servingSize: 92,  servingUnit: "1 cup",  caloriesPerServing: 31,  proteinPerServing: 1,   carbsPerServing: 6,   fatPerServing: 0,   mealTypes: ["Lunch","Dinner","Snack"]),
        FoodLibraryItem(name: "Cucumber",              category: .vegetables, servingSize: 119, servingUnit: "1 cup",  caloriesPerServing: 16,  proteinPerServing: 1,   carbsPerServing: 4,   fatPerServing: 0,   mealTypes: ["Snack","Lunch"]),
        FoodLibraryItem(name: "Mixed Greens Salad",    category: .vegetables, servingSize: 85,  servingUnit: "2 cups", caloriesPerServing: 20,  proteinPerServing: 2,   carbsPerServing: 3,   fatPerServing: 0,   mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Cauliflower",           category: .vegetables, servingSize: 107, servingUnit: "1 cup",  caloriesPerServing: 27,  proteinPerServing: 2,   carbsPerServing: 5,   fatPerServing: 0,   mealTypes: ["Lunch","Dinner"]),

        // FRUITS
        FoodLibraryItem(name: "Banana",                category: .fruits,     servingSize: 118, servingUnit: "1 medium",caloriesPerServing: 105, proteinPerServing: 1,  carbsPerServing: 27,  fatPerServing: 0,   mealTypes: ["Breakfast","Pre-Workout","Snack"]),
        FoodLibraryItem(name: "Blueberries",           category: .fruits,     servingSize: 148, servingUnit: "1 cup",  caloriesPerServing: 84,  proteinPerServing: 1,   carbsPerServing: 21,  fatPerServing: 0,   mealTypes: ["Breakfast","Snack"]),
        FoodLibraryItem(name: "Strawberries",          category: .fruits,     servingSize: 152, servingUnit: "1 cup",  caloriesPerServing: 49,  proteinPerServing: 1,   carbsPerServing: 12,  fatPerServing: 0,   mealTypes: ["Breakfast","Snack"]),
        FoodLibraryItem(name: "Apple",                 category: .fruits,     servingSize: 182, servingUnit: "1 medium",caloriesPerServing: 95,  proteinPerServing: 0,  carbsPerServing: 25,  fatPerServing: 0,   mealTypes: ["Snack"]),
        FoodLibraryItem(name: "Mango",                 category: .fruits,     servingSize: 165, servingUnit: "1 cup",  caloriesPerServing: 99,  proteinPerServing: 1,   carbsPerServing: 25,  fatPerServing: 1,   mealTypes: ["Breakfast","Snack"]),
        FoodLibraryItem(name: "Mixed Berries",         category: .fruits,     servingSize: 140, servingUnit: "1 cup",  caloriesPerServing: 70,  proteinPerServing: 1,   carbsPerServing: 17,  fatPerServing: 0,   mealTypes: ["Breakfast","Snack"]),

        // DAIRY
        FoodLibraryItem(name: "Greek Yogurt (0%)",     category: .dairy,      servingSize: 200, servingUnit: "3/4 cup",caloriesPerServing: 100, proteinPerServing: 17,  carbsPerServing: 6,   fatPerServing: 0,   mealTypes: ["Breakfast","Snack"]),
        FoodLibraryItem(name: "Milk (2%)",             category: .dairy,      servingSize: 244, servingUnit: "1 cup",  caloriesPerServing: 122, proteinPerServing: 8,   carbsPerServing: 12,  fatPerServing: 5,   mealTypes: ["Breakfast","Snack"]),
        FoodLibraryItem(name: "Almond Milk (unsw.)",   category: .dairy,      servingSize: 244, servingUnit: "1 cup",  caloriesPerServing: 30,  proteinPerServing: 1,   carbsPerServing: 1,   fatPerServing: 3,   mealTypes: ["Breakfast"]),
        FoodLibraryItem(name: "Low-Fat Cheese",        category: .dairy,      servingSize: 28,  servingUnit: "1 oz",   caloriesPerServing: 49,  proteinPerServing: 7,   carbsPerServing: 1,   fatPerServing: 2,   mealTypes: ["Breakfast","Lunch","Snack"]),

        // HEALTHY FATS
        FoodLibraryItem(name: "Avocado",               category: .fats,       servingSize: 100, servingUnit: "1/2 avocado",caloriesPerServing: 160, proteinPerServing: 2, carbsPerServing: 9, fatPerServing: 15, mealTypes: ["Breakfast","Lunch"]),
        FoodLibraryItem(name: "Almonds",               category: .fats,       servingSize: 28,  servingUnit: "1 oz (23)",caloriesPerServing: 164, proteinPerServing: 6,  carbsPerServing: 6,   fatPerServing: 14,  mealTypes: ["Snack"]),
        FoodLibraryItem(name: "Peanut Butter",         category: .fats,       servingSize: 32,  servingUnit: "2 tbsp",  caloriesPerServing: 191, proteinPerServing: 7,  carbsPerServing: 7,   fatPerServing: 16,  mealTypes: ["Breakfast","Snack"]),
        FoodLibraryItem(name: "Olive Oil",             category: .fats,       servingSize: 14,  servingUnit: "1 tbsp",  caloriesPerServing: 119, proteinPerServing: 0,  carbsPerServing: 0,   fatPerServing: 14,  mealTypes: ["Lunch","Dinner"]),
        FoodLibraryItem(name: "Walnuts",               category: .fats,       servingSize: 28,  servingUnit: "1 oz (14 halves)",caloriesPerServing: 185, proteinPerServing: 4, carbsPerServing: 4, fatPerServing: 18, mealTypes: ["Snack"]),
        FoodLibraryItem(name: "Chia Seeds",            category: .fats,       servingSize: 28,  servingUnit: "2 tbsp",  caloriesPerServing: 138, proteinPerServing: 5,  carbsPerServing: 12,  fatPerServing: 9,   mealTypes: ["Breakfast"]),
        FoodLibraryItem(name: "Flaxseed",              category: .fats,       servingSize: 14,  servingUnit: "1 tbsp",  caloriesPerServing: 55,  proteinPerServing: 2,  carbsPerServing: 3,   fatPerServing: 4,   mealTypes: ["Breakfast"]),

        // SNACKS
        FoodLibraryItem(name: "Protein Bar",           category: .snacks,     servingSize: 60,  servingUnit: "1 bar",   caloriesPerServing: 200, proteinPerServing: 20, carbsPerServing: 22,  fatPerServing: 6,   mealTypes: ["Snack","Pre-Workout"]),
        FoodLibraryItem(name: "Beef Jerky",            category: .snacks,     servingSize: 28,  servingUnit: "1 oz",    caloriesPerServing: 82,  proteinPerServing: 11, carbsPerServing: 4,   fatPerServing: 2,   mealTypes: ["Snack"]),
        FoodLibraryItem(name: "Hummus",                category: .snacks,     servingSize: 60,  servingUnit: "1/4 cup", caloriesPerServing: 109, proteinPerServing: 5,  carbsPerServing: 12,  fatPerServing: 5,   mealTypes: ["Snack","Lunch"]),
        FoodLibraryItem(name: "Protein Pudding",       category: .snacks,     servingSize: 150, servingUnit: "1 cup",   caloriesPerServing: 130, proteinPerServing: 15, carbsPerServing: 10,  fatPerServing: 3,   mealTypes: ["Snack"]),

        // DRINKS
        FoodLibraryItem(name: "Protein Shake (mixed)", category: .drinks,     servingSize: 350, servingUnit: "12 oz",   caloriesPerServing: 150, proteinPerServing: 25, carbsPerServing: 8,   fatPerServing: 3,   mealTypes: ["Post-Workout","Snack"]),
        FoodLibraryItem(name: "Green Smoothie",        category: .drinks,     servingSize: 350, servingUnit: "12 oz",   caloriesPerServing: 180, proteinPerServing: 5,  carbsPerServing: 35,  fatPerServing: 3,   mealTypes: ["Breakfast"]),
        FoodLibraryItem(name: "Orange Juice",          category: .drinks,     servingSize: 240, servingUnit: "8 oz",    caloriesPerServing: 112, proteinPerServing: 2,  carbsPerServing: 26,  fatPerServing: 0,   mealTypes: ["Breakfast"]),
        FoodLibraryItem(name: "Chocolate Milk",        category: .drinks,     servingSize: 240, servingUnit: "8 oz",    caloriesPerServing: 158, proteinPerServing: 8,  carbsPerServing: 26,  fatPerServing: 3,   mealTypes: ["Post-Workout"]),
    ]

    static func search(_ query: String) -> [FoodLibraryItem] {
        guard !query.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    static func byCategory(_ category: FoodLibraryItem.FoodCategory) -> [FoodLibraryItem] {
        all.filter { $0.category == category }
    }

    static func forMealType(_ mealType: String) -> [FoodLibraryItem] {
        all.filter { $0.mealTypes.contains(mealType) }
    }
}

// MARK: - Selected Food (with adjustable servings)

struct SelectedFood: Identifiable {
    let id = UUID()
    let food:     FoodLibraryItem
    var servings: Double  // multiplier (1.0 = 1 serving, 2.0 = 2 servings, 0.5 = half)

    var calories: Int    { Int(Double(food.caloriesPerServing) * servings) }
    var protein:  Double { food.proteinPerServing  * servings }
    var carbs:    Double { food.carbsPerServing     * servings }
    var fat:      Double { food.fatPerServing       * servings }
    var servingLabel: String {
        if servings == floor(servings) {
            return "\(Int(servings))x \(food.servingUnit)"
        } else {
            return String(format: "%.1fx \(food.servingUnit)", servings)
        }
    }
}

// MARK: - Meal Plan Builder View

struct MealPlanBuilderView: View {
    let trainerId: String
    let clientId:  String
    let clientName: String
    @Environment(\.dismiss) var dismiss

    @State private var title         = ""
    @State private var description   = ""
    @State private var dailyCalories = 2000
    @State private var proteinTarget = 150.0
    @State private var carbsTarget   = 200.0
    @State private var fatTarget     = 65.0
    @State private var meals: [BuiltMeal] = []
    @State private var isSaving      = false
    @State private var showingAddMeal = false

    var totalCalories: Int   { meals.reduce(0) { $0 + $1.totalCalories } }
    var totalProtein:  Double { meals.reduce(0) { $0 + $1.totalProtein } }
    var totalCarbs:    Double { meals.reduce(0) { $0 + $1.totalCarbs } }
    var totalFat:      Double { meals.reduce(0) { $0 + $1.totalFat } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    formBlock("PLAN TITLE") {
                        TextField("e.g. Lean Bulk Phase 1", text: $title)
                            .foregroundColor(.white).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.tmGold.opacity(0.3), lineWidth: 1))
                    }

                    // Daily Targets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DAILY TARGETS").font(.system(size: 10, weight: .bold))
                            .tracking(1.2).foregroundColor(.tmGold)

                        // Auto-calculated from meals vs manual targets
                        if !meals.isEmpty {
                            HStack(spacing: 0) {
                                macroActualCell(totalCalories, Int(dailyCalories), "Calories", .tmGold)
                                macroActualCell(Int(totalProtein), Int(proteinTarget), "Protein", .red)
                                macroActualCell(Int(totalCarbs),   Int(carbsTarget),   "Carbs",   .blue)
                                macroActualCell(Int(totalFat),     Int(fatTarget),     "Fat",     .yellow)
                            }
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
                        }

                        macroStepper("Daily Calorie Goal",  value: $dailyCalories, step: 50,  color: .tmGold)
                        HStack(spacing: 10) {
                            macroDoubleStepper("Protein (g)", value: $proteinTarget, step: 5, color: .red)
                            macroDoubleStepper("Carbs (g)",   value: $carbsTarget,   step: 5, color: .blue)
                            macroDoubleStepper("Fat (g)",     value: $fatTarget,     step: 5, color: .yellow)
                        }
                    }

                    // Meals
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("MEALS").font(.system(size: 10, weight: .bold))
                                    .tracking(1.2).foregroundColor(.tmGold)
                                if !meals.isEmpty {
                                    Text("\(meals.count) meals • \(totalCalories) cal")
                                        .font(.caption2).foregroundColor(.white.opacity(0.4))
                                }
                            }
                            Spacer()
                            Button(action: { showingAddMeal = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill").font(.caption)
                                    Text("Add Meal").font(.caption).fontWeight(.semibold)
                                }
                                .foregroundColor(.black).padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Capsule().fill(Color.tmGold))
                            }
                        }

                        if meals.isEmpty {
                            Button(action: { showingAddMeal = true }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 32)).foregroundColor(.tmGold.opacity(0.4))
                                    Text("Tap to build your meal plan")
                                        .font(.subheadline).foregroundColor(.white.opacity(0.35))
                                    Text("50+ foods with adjustable serving sizes")
                                        .font(.caption).foregroundColor(.white.opacity(0.25))
                                }
                                .frame(maxWidth: .infinity).padding(24)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.03))
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.tmGold.opacity(0.15),
                                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))))
                            }
                            .buttonStyle(.plain)
                        } else {
                            ForEach(Array(meals.enumerated()), id: \.element.id) { i, meal in
                                BuiltMealCard(meal: meal,
                                    onDelete: { meals.removeAll { $0.id == meal.id } },
                                    onEdit: { updated in
                                        if let idx = meals.firstIndex(where: { $0.id == meal.id }) {
                                            meals[idx] = updated
                                        }
                                    }
                                )
                            }
                        }
                    }

                    // Assign Button
                    Button(action: savePlan) {
                        HStack(spacing: 8) {
                            if isSaving { ProgressView().tint(.black) } else {
                                Image(systemName: "paperplane.fill")
                                Text("ASSIGN TO \(clientName.uppercased())")
                                    .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                            }
                        }
                        .foregroundColor(canSave ? .black : .white.opacity(0.4))
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 27)
                            .fill(canSave ? Color.tmGold : Color.white.opacity(0.08))
                            .shadow(color: canSave ? Color.tmGold.opacity(0.4) : .clear, radius: 10, y: 4))
                    }
                    .disabled(!canSave || isSaving)
                }
                .padding(20)
            }
        }
        .navigationTitle("Create Meal Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .sheet(isPresented: $showingAddMeal) {
            MealBuilderSheet { newMeal in
                meals.append(newMeal)
            }
        }
    }

    private var canSave: Bool { !title.isEmpty && !meals.isEmpty }

    private func macroActualCell(_ actual: Int, _ target: Int, _ label: String, _ color: Color) -> some View {
        let pct = target > 0 ? min(Double(actual) / Double(target), 1.0) : 0
        let over = actual > target
        return VStack(spacing: 4) {
            Text("\(actual)").font(.system(size: 14, weight: .black))
                .foregroundColor(over ? .orange : color)
            Text("/ \(target)").font(.system(size: 9)).foregroundColor(.white.opacity(0.3))
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 2).fill(over ? Color.orange : color)
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 3)
        }
        .frame(maxWidth: .infinity).padding(.horizontal, 4)
    }

    private func savePlan() {
        guard canSave,
              let tUUID = UUID(uuidString: trainerId),
              let cUUID = UUID(uuidString: clientId) else { return }
        isSaving = true

        let mealItems = meals.map { builtMeal -> MealItem in
            MealItem(
                id: UUID(),
                mealType: builtMeal.mealType,
                name: builtMeal.name,
                calories: builtMeal.totalCalories,
                protein: builtMeal.totalProtein,
                carbs: builtMeal.totalCarbs,
                fat: builtMeal.totalFat,
                notes: builtMeal.foods.map { "\($0.servingLabel) \($0.food.name)" }.joined(separator: ", ")
            )
        }

        let plan = MealPlanRow(
            id: UUID(), trainerId: tUUID, clientId: cUUID,
            title: title, description: description,
            meals: mealItems, dailyCalories: dailyCalories,
            proteinG: proteinTarget, carbsG: carbsTarget, fatG: fatTarget,
            weekStart: Date(), isActive: true, createdAt: Date()
        )

        Task {
            do {
                try await SBMealPlanStore.shared.create(plan)
                await MainActor.run { isSaving = false; dismiss() }
            } catch {
                print("❌ Meal plan save error: \(error)")
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

    private func macroStepper(_ label: String, value: Binding<Int>, step: Int, color: Color) -> some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.6))
            Spacer()
            Button(action: { if value.wrappedValue > step { value.wrappedValue -= step } }) {
                Image(systemName: "minus.circle.fill").foregroundColor(color).font(.title3)
            }
            Text("\(value.wrappedValue)").font(.system(size: 18, weight: .black))
                .foregroundColor(color).frame(minWidth: 55)
            Button(action: { value.wrappedValue += step }) {
                Image(systemName: "plus.circle.fill").foregroundColor(color).font(.title3)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
    }

    private func macroDoubleStepper(_ label: String, value: Binding<Double>, step: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(color)
            HStack(spacing: 4) {
                Button(action: { if value.wrappedValue > step { value.wrappedValue -= step } }) {
                    Image(systemName: "minus.circle.fill").foregroundColor(color).font(.caption)
                }
                Text("\(Int(value.wrappedValue))").font(.system(size: 15, weight: .black))
                    .foregroundColor(.white).frame(minWidth: 30)
                Button(action: { value.wrappedValue += step }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(color).font(.caption)
                }
            }
        }
        .frame(maxWidth: .infinity).padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
    }
}

// MARK: - Built Meal Model

struct BuiltMeal: Identifiable {
    let id = UUID()
    var mealType: String
    var name:     String
    var foods:    [SelectedFood]

    var totalCalories: Int    { foods.reduce(0) { $0 + $1.calories } }
    var totalProtein:  Double { foods.reduce(0) { $0 + $1.protein } }
    var totalCarbs:    Double { foods.reduce(0) { $0 + $1.carbs } }
    var totalFat:      Double { foods.reduce(0) { $0 + $1.fat } }
}

// MARK: - Built Meal Card

struct BuiltMealCard: View {
    let meal:     BuiltMeal
    let onDelete: () -> Void
    let onEdit:   (BuiltMeal) -> Void
    @State private var showingEdit = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(meal.mealType).font(.system(size: 10, weight: .bold))
                        .foregroundColor(.tmGold)
                    Text(meal.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button(action: { showingEdit = true }) {
                        Image(systemName: "pencil").font(.caption).foregroundColor(.tmGold)
                            .padding(6)
                    }
                    Button(action: onDelete) {
                        Image(systemName: "trash").font(.caption).foregroundColor(.red.opacity(0.7))
                            .padding(6)
                    }
                }
            }

            // Macro bar
            HStack(spacing: 0) {
                mealMacro("\(meal.totalCalories)", "cal", .tmGold)
                mealMacro(String(format: "%.0fg", meal.totalProtein), "protein", .red)
                mealMacro(String(format: "%.0fg", meal.totalCarbs),   "carbs",   .blue)
                mealMacro(String(format: "%.0fg", meal.totalFat),     "fat",     .yellow)
            }
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))

            // Food list
            VStack(alignment: .leading, spacing: 4) {
                ForEach(meal.foods) { sf in
                    HStack(spacing: 6) {
                        Circle().fill(sf.food.category.color).frame(width: 6, height: 6)
                        Text(sf.food.name).font(.caption).foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text(sf.servingLabel).font(.caption2).foregroundColor(.white.opacity(0.4))
                        Text("• \(sf.calories) cal").font(.caption2).foregroundColor(.white.opacity(0.4))
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .sheet(isPresented: $showingEdit) {
            MealBuilderSheet(existingMeal: meal) { updated in onEdit(updated) }
        }
    }

    private func mealMacro(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 13, weight: .black)).foregroundColor(color)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.35))
        }.frame(maxWidth: .infinity)
    }
}

// MARK: - Meal Builder Sheet

struct MealBuilderSheet: View {
    let existingMeal: BuiltMeal?
    let onSave: (BuiltMeal) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var mealType:     String
    @State private var mealName:     String
    @State private var selectedFoods: [SelectedFood]
    @State private var showingLibrary = false

    let mealTypes = ["Breakfast","Lunch","Dinner","Snack","Pre-Workout","Post-Workout"]

    init(existingMeal: BuiltMeal? = nil, onSave: @escaping (BuiltMeal) -> Void) {
        self.existingMeal = existingMeal
        self.onSave = onSave
        _mealType      = State(initialValue: existingMeal?.mealType ?? "Breakfast")
        _mealName      = State(initialValue: existingMeal?.name ?? "")
        _selectedFoods = State(initialValue: existingMeal?.foods ?? [])
    }

    var totalCals:    Int    { selectedFoods.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { selectedFoods.reduce(0) { $0 + $1.protein } }
    var totalCarbs:   Double { selectedFoods.reduce(0) { $0 + $1.carbs } }
    var totalFat:     Double { selectedFoods.reduce(0) { $0 + $1.fat } }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        // Meal type picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MEAL TYPE").font(.system(size: 10, weight: .bold))
                                .tracking(1.2).foregroundColor(.tmGold)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(mealTypes, id: \.self) { type in
                                        Button(action: {
                                            mealType = type
                                            if mealName.isEmpty { mealName = type }
                                        }) {
                                            Text(type).font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(mealType == type ? .black : .white.opacity(0.6))
                                                .padding(.horizontal, 14).padding(.vertical, 8)
                                                .background(Capsule().fill(mealType == type
                                                    ? Color.tmGold : Color.white.opacity(0.08)))
                                        }.buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Meal name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MEAL NAME").font(.system(size: 10, weight: .bold))
                                .tracking(1.2).foregroundColor(.tmGold)
                            TextField("e.g. Post-Workout Shake", text: $mealName)
                                .foregroundColor(.white).padding(12)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }

                        // Macro summary
                        if !selectedFoods.isEmpty {
                            HStack(spacing: 0) {
                                summaryMacro("\(totalCals)", "cal", .tmGold)
                                summaryMacro(String(format: "%.0fg", totalProtein), "protein", .red)
                                summaryMacro(String(format: "%.0fg", totalCarbs),   "carbs",   .blue)
                                summaryMacro(String(format: "%.0fg", totalFat),     "fat",     .yellow)
                            }
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.tmGold.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.tmGold.opacity(0.2), lineWidth: 1))
                        }

                        // Foods added
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("FOODS").font(.system(size: 10, weight: .bold))
                                    .tracking(1.2).foregroundColor(.tmGold)
                                Spacer()
                                Button(action: { showingLibrary = true }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "plus.circle.fill").font(.caption)
                                        Text("Browse Foods").font(.caption).fontWeight(.semibold)
                                    }
                                    .foregroundColor(.black).padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(Capsule().fill(Color.tmGold))
                                }
                            }

                            if selectedFoods.isEmpty {
                                Button(action: { showingLibrary = true }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "fork.knife").foregroundColor(.tmGold.opacity(0.5))
                                        Text("Browse 50+ foods with adjustable servings")
                                            .font(.caption).foregroundColor(.white.opacity(0.35))
                                    }
                                    .frame(maxWidth: .infinity).padding(14)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03))
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.tmGold.opacity(0.15),
                                                    style: StrokeStyle(lineWidth: 1, dash: [5, 4]))))
                                }
                                .buttonStyle(.plain)
                            } else {
                                ForEach(Array(selectedFoods.enumerated()), id: \.element.id) { i, sf in
                                    SelectedFoodRow(
                                        selectedFood: sf,
                                        onServingsChanged: { newServings in
                                            selectedFoods[i].servings = newServings
                                        },
                                        onRemove: { selectedFoods.remove(at: i) }
                                    )
                                }
                            }
                        }

                        // Save button
                        Button(action: save) {
                            Text(existingMeal != nil ? "UPDATE MEAL" : "ADD TO PLAN")
                                .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                                .foregroundColor(canSave ? .black : .white.opacity(0.4))
                                .frame(maxWidth: .infinity).frame(height: 52)
                                .background(RoundedRectangle(cornerRadius: 26)
                                    .fill(canSave ? Color.tmGold : Color.white.opacity(0.08)))
                        }
                        .disabled(!canSave)
                    }
                    .padding(16)
                }
            }
            .navigationTitle(existingMeal != nil ? "Edit Meal" : "Build Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
                }
            }
            .sheet(isPresented: $showingLibrary) {
                FoodLibraryBrowser(mealTypeFilter: mealType) { food in
                    if let existing = selectedFoods.firstIndex(where: { $0.food.id == food.id }) {
                        selectedFoods[existing].servings += 1
                    } else {
                        selectedFoods.append(SelectedFood(food: food, servings: 1.0))
                    }
                }
            }
        }
    }

    private var canSave: Bool { !mealName.isEmpty && !selectedFoods.isEmpty }

    private func save() {
        let meal = BuiltMeal(mealType: mealType, name: mealName, foods: selectedFoods)
        onSave(meal)
        dismiss()
    }

    private func summaryMacro(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 15, weight: .black)).foregroundColor(color)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
        }.frame(maxWidth: .infinity)
    }
}

// MARK: - Selected Food Row (with serving adjuster)

struct SelectedFoodRow: View {
    let selectedFood:       SelectedFood
    let onServingsChanged:  (Double) -> Void
    let onRemove:           () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Category color dot
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedFood.food.category.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: selectedFood.food.category.icon)
                    .font(.system(size: 14))
                    .foregroundColor(selectedFood.food.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(selectedFood.food.name)
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                Text("\(selectedFood.calories) cal • P:\(String(format: "%.0f", selectedFood.protein))g C:\(String(format: "%.0f", selectedFood.carbs))g F:\(String(format: "%.0f", selectedFood.fat))g")
                    .font(.caption2).foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            // Serving adjuster
            HStack(spacing: 6) {
                Button(action: {
                    let newVal = max(0.5, selectedFood.servings - 0.5)
                    onServingsChanged(newVal)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20)).foregroundColor(.tmGold.opacity(0.8))
                }

                VStack(spacing: 1) {
                    Text(selectedFood.servings == floor(selectedFood.servings)
                         ? "\(Int(selectedFood.servings))x"
                         : String(format: "%.1fx", selectedFood.servings))
                        .font(.system(size: 13, weight: .black)).foregroundColor(.white)
                    Text(selectedFood.food.servingUnit)
                        .font(.system(size: 8)).foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }
                .frame(minWidth: 44)

                Button(action: { onServingsChanged(selectedFood.servings + 0.5) }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20)).foregroundColor(.tmGold.opacity(0.8))
                }

                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18)).foregroundColor(.red.opacity(0.6))
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 1))
    }
}

// MARK: - Food Library Browser

struct FoodLibraryBrowser: View {
    let mealTypeFilter: String
    let onAdd: (FoodLibraryItem) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var searchText = ""
    @State private var selectedCategory: FoodLibraryItem.FoodCategory? = nil
    @State private var showSuggested = true
    @State private var addedIds: Set<UUID> = []
    @State private var showingCustomEntry = false

    private var filtered: [FoodLibraryItem] {
        var list: [FoodLibraryItem]
        if showSuggested && searchText.isEmpty && selectedCategory == nil {
            list = FoodLibrary.forMealType(mealTypeFilter)
        } else if let cat = selectedCategory {
            list = FoodLibrary.byCategory(cat)
        } else {
            list = FoodLibrary.all
        }
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {

                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.4))
                        TextField("Search foods...", text: $searchText)
                            .foregroundColor(.white)
                            .onChange(of: searchText) { _, _ in showSuggested = searchText.isEmpty }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Suggested chip
                            Button(action: { selectedCategory = nil; showSuggested = true }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "star.fill").font(.system(size: 11))
                                    Text("Suggested")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(showSuggested && selectedCategory == nil ? .black : .white.opacity(0.6))
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(Capsule().fill(showSuggested && selectedCategory == nil
                                    ? Color.tmGold : Color.white.opacity(0.08)))
                            }.buttonStyle(.plain)

                            // All chip
                            Button(action: { selectedCategory = nil; showSuggested = false }) {
                                Text("All").font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(!showSuggested && selectedCategory == nil ? .black : .white.opacity(0.6))
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(Capsule().fill(!showSuggested && selectedCategory == nil
                                        ? Color.tmGold : Color.white.opacity(0.08)))
                            }.buttonStyle(.plain)

                            ForEach(FoodLibraryItem.FoodCategory.allCases, id: \.self) { cat in
                                Button(action: { selectedCategory = cat; showSuggested = false }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: cat.icon).font(.system(size: 11))
                                        Text(cat.rawValue).font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(selectedCategory == cat ? .black : .white.opacity(0.6))
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(Capsule().fill(selectedCategory == cat
                                        ? cat.color : Color.white.opacity(0.08)))
                                }.buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 8)

                    if showSuggested && selectedCategory == nil && searchText.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill").font(.caption2).foregroundColor(.tmGold)
                            Text("Suggested for \(mealTypeFilter)")
                                .font(.caption).foregroundColor(.tmGold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16).padding(.bottom, 4)
                    }

                    Divider().background(Color.white.opacity(0.08))

                    if filtered.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "fork.knife").font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.2)).padding(.top, 60)
                            Text("No foods found").font(.headline).foregroundColor(.white.opacity(0.4))
                            Text("Add it manually below")
                                .font(.subheadline).foregroundColor(.white.opacity(0.3))
                            Button(action: { showingCustomEntry = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Custom Food")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 24).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 20).fill(Color.tmGold))
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filtered) { food in
                                FoodLibraryRow(food: food, isAdded: addedIds.contains(food.id)) {
                                    onAdd(food)
                                    addedIds.insert(food.id)
                                }
                                .listRowBackground(Color.white.opacity(0.03))
                                .listRowSeparatorTint(Color.white.opacity(0.06))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Food Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingCustomEntry = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                            Text("Custom")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.tmGold)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.tmGold)
                }
            }
            .sheet(isPresented: $showingCustomEntry) {
                CustomFoodEntrySheet { food in
                    onAdd(food)
                    addedIds.insert(food.id)
                    showingCustomEntry = false
                }
            }
        }
    }
}

// MARK: - Food Library Row

struct FoodLibraryRow: View {
    let food:    FoodLibraryItem
    let isAdded: Bool
    let onAdd:   () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(food.category.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: food.category.icon)
                    .font(.system(size: 16)).foregroundColor(food.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(food.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                HStack(spacing: 6) {
                    Text(food.servingUnit).font(.caption).foregroundColor(.white.opacity(0.4))
                    Text("•").foregroundColor(.white.opacity(0.2))
                    Text("\(food.caloriesPerServing) cal").font(.caption).foregroundColor(.tmGold)
                    Text("•").foregroundColor(.white.opacity(0.2))
                    Text("P:\(String(format: "%.0f", food.proteinPerServing))g")
                        .font(.caption).foregroundColor(.red.opacity(0.8))
                }
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(isAdded ? .green : .tmGold)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Custom Food Entry Sheet

struct CustomFoodEntrySheet: View {
    let onAdd: (FoodLibraryItem) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name       = ""
    @State private var servingUnit = "1 serving"
    @State private var calories   = ""
    @State private var protein    = ""
    @State private var carbs      = ""
    @State private var fat        = ""
    @State private var category: FoodLibraryItem.FoodCategory = .protein

    private var canAdd: Bool { !name.isEmpty && !calories.isEmpty }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        // Name
                        fieldBlock("FOOD NAME") {
                            TextField("e.g. Homemade Protein Pancakes", text: $name)
                                .foregroundColor(.white).padding(12)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.tmGold.opacity(0.3), lineWidth: 1))
                        }

                        // Serving unit
                        fieldBlock("SERVING SIZE") {
                            TextField("e.g. 1 cup, 4 oz, 1 piece", text: $servingUnit)
                                .foregroundColor(.white).padding(12)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }

                        // Category
                        fieldBlock("CATEGORY") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(FoodLibraryItem.FoodCategory.allCases, id: \.self) { cat in
                                        Button(action: { category = cat }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: cat.icon).font(.system(size: 11))
                                                Text(cat.rawValue).font(.system(size: 11, weight: .semibold))
                                            }
                                            .foregroundColor(category == cat ? .black : .white.opacity(0.6))
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(Capsule().fill(category == cat
                                                ? cat.color : Color.white.opacity(0.08)))
                                        }.buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Macros
                        fieldBlock("CALORIES PER SERVING *") {
                            TextField("e.g. 250", text: $calories)
                                .keyboardType(.numberPad).foregroundColor(.white).padding(12)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.tmGold.opacity(0.3), lineWidth: 1))
                        }

                        HStack(spacing: 12) {
                            fieldBlock("PROTEIN (g)") {
                                TextField("0", text: $protein)
                                    .keyboardType(.decimalPad).foregroundColor(.white).padding(12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.08)))
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.red.opacity(0.2), lineWidth: 1))
                            }
                            fieldBlock("CARBS (g)") {
                                TextField("0", text: $carbs)
                                    .keyboardType(.decimalPad).foregroundColor(.white).padding(12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.08)))
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1))
                            }
                            fieldBlock("FAT (g)") {
                                TextField("0", text: $fat)
                                    .keyboardType(.decimalPad).foregroundColor(.white).padding(12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.yellow.opacity(0.08)))
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.yellow.opacity(0.2), lineWidth: 1))
                            }
                        }

                        // Preview card
                        if canAdd {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PREVIEW").font(.system(size: 10, weight: .bold))
                                    .tracking(1.2).foregroundColor(.tmGold)
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(category.color.opacity(0.15)).frame(width: 40, height: 40)
                                        Image(systemName: category.icon)
                                            .font(.system(size: 16)).foregroundColor(category.color)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                        HStack(spacing: 6) {
                                            Text(servingUnit).font(.caption).foregroundColor(.white.opacity(0.4))
                                            Text("•").foregroundColor(.white.opacity(0.2))
                                            Text("\(calories) cal").font(.caption).foregroundColor(.tmGold)
                                            if !protein.isEmpty {
                                                Text("• P:\(protein)g").font(.caption).foregroundColor(.red.opacity(0.8))
                                            }
                                        }
                                    }
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                            }
                        }

                        Button(action: addCustomFood) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("ADD TO MEAL").font(.system(size: 15, weight: .heavy)).tracking(0.5)
                            }
                            .foregroundColor(canAdd ? .black : .white.opacity(0.4))
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(RoundedRectangle(cornerRadius: 26)
                                .fill(canAdd ? Color.tmGold : Color.white.opacity(0.08)))
                        }
                        .disabled(!canAdd)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Custom Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
                }
            }
        }
    }

    private func addCustomFood() {
        let item = FoodLibraryItem(
            name:                name,
            category:            category,
            servingSize:         100,
            servingUnit:         servingUnit.isEmpty ? "1 serving" : servingUnit,
            caloriesPerServing:  Int(calories) ?? 0,
            proteinPerServing:   Double(protein) ?? 0,
            carbsPerServing:     Double(carbs) ?? 0,
            fatPerServing:       Double(fat) ?? 0,
            mealTypes:           []
        )
        onAdd(item)
        dismiss()
    }

    private func fieldBlock<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
            content()
        }
    }
}
