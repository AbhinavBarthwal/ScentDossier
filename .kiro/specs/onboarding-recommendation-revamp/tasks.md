# Implementation Plan: Onboarding Recommendation Revamp

## Overview

This plan implements the ScentDossier onboarding and recommendation engine revamp across six areas: personality traits surfacing, auto-age calculation, climate inference, removal of "No Preference" options, dual photo upload with analysis, and a weighted multi-factor scoring engine with explanations. Tasks modify existing files (`Models.swift`, `ScoringEngine.swift`, `ProfileView.swift`, `PhotoView.swift`, `CosmicProfileView.swift`, `ResultsView.swift`, `ContentView.swift`) and create new modules (`AgeCalculator.swift`, `ClimateInferenceService.swift`, `PhotoAnalyzer.swift`, `PersonalityTraitsCard.swift`, `RecommendationExplanationGenerator.swift`).

## Tasks

- [x] 1. Update data models and core utilities
  - [x] 1.1 Extend UserProfile and add new data model types in Models.swift
    - Add `photoAnalysis: PhotoAnalysisResult?` property to `UserProfile`
    - Change `budget` default from `"any"` to `""`
    - Change `genderPref` default from `"any"` to `""`
    - Update `isComplete` to require non-empty `budget` and `genderPref`
    - Add `PhotoAnalysisResult` struct with `skinColour`, `attireStyles`, `confidenceLevel`
    - Add `SkinColourClassification` enum (fair, light, medium, olive, tan, dark, deep)
    - Add `ConfidenceLevel` enum (low, moderate, high)
    - Add `ClimateClassification` enum (hot, cold, temperate, humid, dry)
    - Add `FactorWeights` struct with default values (personality: 0.35, climate: 0.25, workStyle: 0.20, age: 0.20) and `effective(...)` redistribution method
    - Add `FamilyScore` struct with `familyId`, `rawScore`, `normalizedScore`, `dimensionContributions`
    - Add `DimensionContributions` struct (personality, climate, workStyle, age, photo)
    - Add `RecommendationExplanation` struct with `text: String`
    - _Requirements: 4.4, 4.5, 5.2, 5.3, 5.4, 7.1, 9.1_

  - [x] 1.2 Create AgeCalculator.swift utility
    - Create `enum AgeCalculator` with `static func age(from birthDate: Date) -> Int`
    - Use `Calendar.current.dateComponents([.year], from:to:)` to compute floored completed years
    - _Requirements: 2.1_

  - [ ]* 1.3 Write property test for AgeCalculator
    - **Property 3: Age calculation correctness**
    - Generate random past birth dates and reference dates; verify result equals Calendar dateComponents year difference
    - **Validates: Requirements 2.1**

  - [ ]* 1.4 Write property test for FactorWeights.effective() redistribution
    - **Property 7: Factor weights always sum to 1.0 with redistribution**
    - For any subset of present dimensions (at least 1), verify effective weights sum to 1.0 (±0.0001)
    - **Validates: Requirements 7.1, 7.4**

- [x] 2. Implement ClimateInferenceService
  - [x] 2.1 Create ClimateInferenceService.swift
    - Define `ClimateInferenceServiceProtocol` with `func inferClimate(from location: String) async throws -> ClimateClassification`
    - Implement `ClimateInferenceService` with a static dictionary mapping city/country keywords to climate classifications
    - Include at least 50 common city/country mappings (e.g., "mumbai" → .hot, "london" → .temperate, "dubai" → .hot)
    - Implement input validation: reject strings < 2 or > 100 characters
    - Implement case-insensitive, partial-match lookup (substring matching)
    - Add 5-second timeout handling
    - _Requirements: 3.1, 3.5_

  - [ ]* 2.2 Write property test for ClimateInferenceService
    - **Property 4: Climate inference returns valid classification**
    - For any known mapping entry (2–100 chars), verify exactly one ClimateClassification is returned
    - **Validates: Requirements 3.1**

- [x] 3. Implement PhotoAnalyzer
  - [x] 3.1 Create PhotoAnalyzer.swift
    - Define `PhotoAnalyzerProtocol` with `analyzeFacePhoto(_:)` and `analyzeFullBodyPhoto(_:)` async methods
    - Implement `PhotoAnalyzer` struct conforming to protocol
    - `analyzeFacePhoto` returns `SkinColourClassification` based on image analysis (can use Vision framework or placeholder ML logic)
    - `analyzeFullBodyPhoto` returns tuple of `(attireStyles: [String], confidence: ConfidenceLevel)` — 1–3 attire labels + confidence level
    - Validate file format (JPEG/PNG) and size (≤ 10MB) before processing
    - Handle errors with descriptive failure reasons
    - 15-second maximum processing time per photo
    - _Requirements: 5.2, 5.3, 5.4, 5.5, 5.6, 5.8_

- [x] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Build the weighted scoring engine
  - [x] 5.1 Implement weightedScoreFamilies in ScoringEngine.swift
    - Add `static func weightedScoreFamilies(profile:traits:cosmicProfile:photoAnalysis:weights:) -> [String: Double]`
    - Implement personality scoring dimension (boldness, experimental, extroversion, warmth → family scores)
    - Implement climate scoring dimension (hot/cold/temperate/humid/dry → family boosts)
    - Implement work style scoring dimension (corporate/creative/outdoor/remote → family boosts)
    - Implement age bracket scoring: 18–29 boost citrus/aquatic/fruity, 30–45 boost floral/fougere/woody, 46+ boost oriental/leather/gourmand (1–3 points per family)
    - Multiply each dimension's raw score by its effective weight, sum to produce final score per family
    - Normalize final scores to 0–100 scale (highest = 100, others proportional)
    - Handle missing dimensions via `FactorWeights.effective(...)` redistribution
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

  - [x] 5.2 Integrate photo analysis into scoring
    - Apply skin colour scoring: up to 3 points per scent family based on `SkinColourClassification`
    - Use photo-derived attire style in place of manual styling preference when available
    - Apply confidence level as additive modifier to boldness axis, capped at [0.0, 1.0]
    - Fall back to manual profile data for missing photo classifications
    - No penalty when photo data is absent
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

  - [x] 5.3 Add input validation to scoring engine
    - Reject scoring request if budget is not in {"1", "2", "3", "4"}
    - Reject scoring request if genderPref is not in {"feminine", "masculine", "unisex"}
    - Update `matchCatalog` to enforce strict budget/genderPref filtering (remove "any" fallback)
    - _Requirements: 4.4, 4.5, 4.6_

  - [x] 5.4 Implement deterministic top-2 family selection with tiebreaker
    - Update `topFamilies` to return exactly 2 families (primary + secondary)
    - When ties exist for second place, select alphabetically first family ID
    - _Requirements: 6.1_

  - [ ]* 5.5 Write property test for scoring engine validation
    - **Property 5: Scoring engine rejects invalid budget or fragrance lean**
    - For invalid budget/genderPref values, verify engine rejects and produces no recommendations
    - **Validates: Requirements 4.4, 4.5, 4.6**

  - [ ]* 5.6 Write property test for top-2 family selection
    - **Property 6: Top-2 family selection with deterministic tiebreaker**
    - For any non-empty scores dict with ≥ 2 families, verify primary = highest, secondary = second-highest with alphabetical tiebreaker
    - **Validates: Requirements 6.1**

  - [ ]* 5.7 Write property test for age bracket scoring
    - **Property 8: Age bracket scoring correctness**
    - For any age 18–100, verify exactly one bracket's families boosted 1–3 points, others get 0
    - **Validates: Requirements 7.2**

  - [ ]* 5.8 Write property test for weighted scoring formula
    - **Property 9: Weighted scoring formula correctness**
    - For random raw dimension scores and valid weights summing to 1.0, verify final = sum(raw × weight)
    - **Validates: Requirements 7.3**

  - [ ]* 5.9 Write property test for score normalization
    - **Property 10: Score normalization to 0–100**
    - For any scores dict with ≥ 1 positive value, verify max = 100 and proportional relationships preserved
    - **Validates: Requirements 7.5**

  - [ ]* 5.10 Write property tests for photo scoring integration
    - **Property 14: Skin colour scoring capped at 3 points**
    - **Property 15: Photo attire replaces manual styling**
    - **Property 16: Confidence level modifies boldness within bounds**
    - **Property 17: Graceful degradation with missing or partial photo data**
    - **Validates: Requirements 9.1, 9.2, 9.3, 9.4, 9.5, 9.6**

- [x] 6. Implement RecommendationExplanationGenerator
  - [x] 6.1 Create RecommendationExplanationGenerator.swift
    - Implement `static func generate(for:scores:allFragrances:) -> RecommendationExplanation`
    - Select top-2 contributing dimensions for the fragrance's family from `DimensionContributions`
    - Generate 1–3 sentence explanation in plain language referencing those dimensions
    - No numeric score values or technical terminology (no "weight", "factor", "dimension score")
    - Fall back to generic explanation when < 2 dimensions have non-zero contribution
    - Ensure uniqueness: incorporate fragrance-specific attributes (name, house, notes) to differentiate text
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

  - [ ]* 6.2 Write property tests for RecommendationExplanationGenerator
    - **Property 11: Explanation references top-2 contributing dimensions**
    - **Property 12: Explanation format constraints**
    - **Property 13: Explanation uniqueness across fragrance set**
    - **Validates: Requirements 8.2, 8.3, 8.5**

- [x] 7. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Update CosmicProfileView with PersonalityTraitsCard
  - [x] 8.1 Create PersonalityTraitsCard.swift
    - Build SwiftUI view that accepts a `CosmicProfile`
    - Display Life Path number + trait phrase + linked scent family + master number badge
    - Display Expression number + trait phrase + linked scent family + master number badge
    - Match existing design system (DT tokens, fonts, colors)
    - Hide when `cosmicProfile` is nil
    - _Requirements: 1.1, 1.2_

  - [x] 8.2 Integrate PersonalityTraitsCard into CosmicProfileView
    - Add `PersonalityTraitsCard` below the existing cosmic result card
    - Ensure it updates within 300ms when name or DOB changes (inline computation)
    - Hide when name is empty or birth date not set
    - _Requirements: 1.1, 1.3, 1.4_

  - [ ]* 8.3 Write property tests for CosmicProfile computation
    - **Property 1: Cosmic profile computation completeness**
    - **Property 2: Invalid cosmic inputs produce nil profile**
    - For valid name (1–50 chars with ≥ 1 letter) + past DOB, verify both numbers in {1–9, 11, 22}, non-empty descriptions, valid scent families, correct isMaster
    - For invalid inputs (no letters, nil DOB), verify nil profile
    - **Validates: Requirements 1.1, 1.2, 1.4**

- [x] 9. Update ProfileView with auto-age and climate inference
  - [x] 9.1 Refactor ProfileView for auto-calculated age
    - Replace manual age `TextField` with a read-only label showing computed age from `AgeCalculator.age(from:)`
    - Display "Complete Cosmic Profile step first" message if `profile.birthDate` is nil
    - Disable forward navigation when age is unavailable
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [x] 9.2 Integrate ClimateInferenceService into ProfileView
    - Add 1-second debounce on location text field changes
    - Show loading indicator while inference is processing
    - Display inferred climate as non-editable label when successful
    - Show manual climate picker as fallback on error/timeout/no-result
    - Re-trigger inference when location text changes
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [x] 9.3 Remove "No Preference" options from Budget and Fragrance Lean pickers
    - Remove `("any", "No preference")` from Budget picker options
    - Remove `("any", "No preference")` from Fragrance Lean picker options
    - Ensure no pre-selected value (empty string default)
    - Disable Continue button until both are selected
    - _Requirements: 4.1, 4.2, 4.3_

- [x] 10. Update PhotoView for dual photo upload
  - [x] 10.1 Refactor PhotoView with two upload slots
    - Add two independent `PhotosPicker` slots: "Face Photo" and "Full-Body Photo"
    - Validate JPEG/PNG format and ≤ 10MB per photo
    - Display per-photo analysis results after processing
    - Show error messages with failure reason and retry option on failure
    - Allow user to proceed with 0, 1, or 2 photos
    - Integrate `PhotoAnalyzer` to process each photo independently
    - Store results in `profile.photoAnalysis`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8_

- [x] 11. Update ResultsView with secondary family and explanations
  - [x] 11.1 Update ResultsView olfactory signature section
    - Display Primary Family with larger colour swatch and font, positioned left
    - Display Secondary Family with smaller swatch, positioned right
    - Show colour swatch, family label, and description for both
    - Use the new `topFamilies` (2 families) from the weighted scoring engine
    - _Requirements: 6.1, 6.2, 6.3_

  - [x] 11.2 Integrate RecommendationExplanation into fragrance cards
    - Replace the existing hardcoded `whyText` with `RecommendationExplanationGenerator.generate(...)` output
    - Show explanation in expanded card section without additional scrolling
    - Ensure each card has unique explanation text
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 12. Wire everything together in ContentView
  - [x] 12.1 Update ContentView to use new scoring engine and pass photo data
    - Replace `ScoringEngine.scoreFamilies(...)` call with `ScoringEngine.weightedScoreFamilies(...)`
    - Add `@State private var photoAnalysis: PhotoAnalysisResult?`
    - Pass `photoAnalysis` through to scoring and results
    - Update `top3` to use new 2-family selection (rename to `topFamilyPair` or similar)
    - Pass `DimensionContributions` to `ResultsView` for explanation generation
    - Ensure auto-age from `profile.birthDate` is wired into the scoring engine
    - Guard scoring with budget/genderPref validation (don't compute if empty)
    - _Requirements: 2.1, 4.4, 4.5, 7.1, 7.3, 9.1_

- [x] 13. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- The existing `scoreFamilies` method can remain for backward compatibility; the new `weightedScoreFamilies` becomes the primary path
- All new files should be created in `ScentDossier/ScentDossier/` alongside existing source files

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["1.3", "1.4", "2.1", "3.1", "8.1"] },
    { "id": 2, "tasks": ["2.2", "5.1"] },
    { "id": 3, "tasks": ["5.2", "5.3", "5.4"] },
    { "id": 4, "tasks": ["5.5", "5.6", "5.7", "5.8", "5.9", "5.10", "6.1"] },
    { "id": 5, "tasks": ["6.2", "8.2", "8.3", "9.1", "9.2", "9.3"] },
    { "id": 6, "tasks": ["10.1", "11.1", "11.2"] },
    { "id": 7, "tasks": ["12.1"] }
  ]
}
```
