# Requirements Document

## Introduction

This document specifies the requirements for revamping the ScentDossier onboarding flow and recommendation engine. The revamp enhances the Cosmic Profile step to surface personality traits prominently, streamlines the Profile step by auto-calculating age and auto-inferring climate, upgrades the Photo step to accept two photos with richer analysis (skin colour, attire style, confidence level), and enriches the recommendation engine to display secondary scent families with weighted multi-factor explanations.

## Glossary

- **Onboarding_Flow**: The multi-step wizard (Cosmic Profile → Profile → Personality → Photo → Results) that collects user data and generates fragrance recommendations
- **Cosmic_Profile_Step**: The first onboarding step where the user enters their name and date of birth for numerology and zodiac computation
- **Profile_Step**: The second onboarding step where the user provides lifestyle, location, skin, styling, work, season, occasion, budget, and fragrance lean preferences
- **Photo_Step**: The onboarding step where the user provides photos for visual analysis
- **Scoring_Engine**: The module (`ScoringEngine`) that computes scent family scores from profile data, personality traits, and cosmic profile
- **Numerology_Module**: The existing Chaldean numerology system (`ChaldeanNumerology`) that computes Life Path and Expression numbers from name and birth date
- **Climate_Inference_Service**: A mapping or service that derives climate classification (hot, cold, temperate, humid, dry) from a city/country location string
- **Photo_Analyzer**: The component that processes uploaded photos to extract skin colour, attire style, and confidence level
- **Personality_Traits_Card**: A UI element that prominently displays the numerology-derived personality trait descriptions (Life Path trait + Expression trait)
- **Primary_Family**: The highest-scoring olfactory family in the recommendation results
- **Secondary_Family**: The second-highest-scoring olfactory family in the recommendation results
- **Recommendation_Explanation**: A textual rationale explaining why specific factor combinations (personality traits, age, work style, climate) led to a particular recommendation
- **Factor_Weights**: The relative importance assigned to each scoring dimension (personality traits, age, work style, climate) used by the Scoring_Engine

## Requirements

### Requirement 1: Surface Personality Traits in Cosmic Profile Step

**User Story:** As a user, I want to see my numerology-derived personality traits prominently displayed after entering my name and DOB, so that I understand how my cosmic profile influences my scent recommendations.

#### Acceptance Criteria

1. WHEN the user has entered at least 1 letter character in the name field (up to 50 characters accepted) and has selected a birth date in the Cosmic_Profile_Step, THE Personality_Traits_Card SHALL display the Life Path personality trait and the Expression personality trait as primary outputs of the step
2. THE Personality_Traits_Card SHALL show each trait with its numerology number (1–9, 11, or 22), a descriptive trait phrase, and the linked scent family name, and SHALL indicate master number status for numbers 11 and 22
3. WHEN the user changes their name or birth date, THE Personality_Traits_Card SHALL update within 300ms to reflect the recalculated traits
4. IF the name field is empty (regardless of whether it was changed or cleared) or the birth date is not set, THEN THE Personality_Traits_Card SHALL be hidden until both fields contain valid input again

### Requirement 2: Auto-Calculate Age from DOB

**User Story:** As a user, I want my age to be automatically calculated from the date of birth I entered in Step 1, so that I do not have to enter it again manually.

#### Acceptance Criteria

1. WHEN the user has entered a birth date in the Cosmic_Profile_Step, THE Profile_Step SHALL always display the user age as a whole number of completed years (floored) computed from the difference between the device's current date and the birth date
2. THE Profile_Step SHALL display the calculated age as a read-only label in place of a manual age input field; the calculated age SHALL always be visible when a birth date is set
3. THE Profile_Step SHALL NOT display a manual age input field
4. WHEN the birth date is not set, THE Profile_Step SHALL display a message indicating that the user must complete the Cosmic_Profile_Step first, and SHALL disable navigation to the next step until an age value is available

### Requirement 3: Auto-Infer Climate from Location

**User Story:** As a user, I want the climate to be automatically determined from the city/country I type, so that I do not have to manually select a climate category.

#### Acceptance Criteria

1. WHEN the user has stopped typing in the location field of the Profile_Step for at least 1 second and the entered text is between 2 and 100 characters, THE Climate_Inference_Service SHALL derive the climate classification (hot, cold, temperate, humid, or dry) from the entered location
2. THE Profile_Step SHALL NOT display a manual climate picker when a climate value has been successfully inferred
3. WHILE the Climate_Inference_Service is processing the location input, THE Profile_Step SHALL display a loading indicator below the location field in place of the climate value
4. WHEN the Climate_Inference_Service returns a climate classification, THE Profile_Step SHALL display the inferred climate value as a non-editable label below the location field showing the classification name (hot, cold, temperate, humid, or dry)
5. IF the Climate_Inference_Service returns no result or an error after a maximum wait time of 5 seconds, THEN THE Profile_Step SHALL display a manual climate picker with the available options (hot, cold, temperate, humid, dry) and retain any text already entered in the location field
6. IF the user modifies the location field text (whether or not a climate was previously inferred), THEN THE Climate_Inference_Service SHALL attempt to derive the climate classification using the updated location text following the same 1-second debounce

### Requirement 4: Remove "No Preference" Option from Budget and Fragrance Lean

**User Story:** As a user completing my profile, I want to be guided toward a specific budget range and fragrance lean, so that recommendations are more targeted.

#### Acceptance Criteria

1. THE Profile_Step SHALL NOT include a "No preference" or "any" option in the Budget picker, presenting only the four budget tiers: Everyday, Mid-range, Premium, and Luxury/Niche
2. THE Profile_Step SHALL NOT include a "No preference" or "any" option in the Fragrance Lean picker, presenting only the three options: Feminine-leaning, Masculine-leaning, and Unisex only
3. THE Profile_Step SHALL display no pre-selected value for Budget and Fragrance Lean, requiring the user to make an explicit selection before the Continue button becomes enabled
4. THE Scoring_Engine SHALL require a specific budget tier (1, 2, 3, or 4) for catalog filtering
5. THE Scoring_Engine SHALL require a specific fragrance lean value (feminine, masculine, or unisex) for catalog filtering
6. IF the Scoring_Engine receives an invalid or missing budget or fragrance lean value, THEN THE Scoring_Engine SHALL reject the request and require the client to provide valid data before producing recommendations

### Requirement 5: Dual Photo Upload with Enhanced Analysis

**User Story:** As a user, I want to upload both a face photo and a full-body photo, so that the app can analyze my skin colour, attire style, and confidence level for better recommendations.

#### Acceptance Criteria

1. THE Photo_Step SHALL present two distinct photo upload slots: one labeled "Face Photo" and one labeled "Full-Body Photo", each independently selectable by the user
2. WHEN the user uploads a face photo, THE Photo_Analyzer SHALL extract a skin colour classification from the face image, returning exactly one value from a predefined set of categories (e.g., fair, light, medium, olive, tan, dark, deep)
3. WHEN the user uploads a full-body photo, THE Photo_Analyzer SHALL extract between 1 and 3 attire and clothing style cues from the full-body image, each expressed as a short descriptive label
4. WHEN the user uploads a full-body photo, THE Photo_Analyzer SHALL estimate a confidence level based on posture and expression visible in the image, expressed as one of three discrete levels: low, moderate, or high
5. WHEN photo analysis processing completes for either upload, THE Photo_Step SHALL display the analysis results (skin colour, attire style cues, confidence level) to the user within 15 seconds of upload submission
6. IF the Photo_Analyzer fails to process an uploaded photo, THEN THE Photo_Step SHALL display an error message indicating the failure reason and allow the user to retry the upload or skip that photo
7. IF the user uploads only one of the two photos or no photos at all, THEN THE Photo_Step SHALL allow the user to proceed, using partial analysis results from any uploaded photo or no photo data respectively
8. THE Photo_Step SHALL accept image files in JPEG or PNG format with a maximum file size of 10 MB per photo

### Requirement 6: Display Secondary Scent Family in Results

**User Story:** As a user viewing my results, I want to see both my primary and secondary scent families, so that I understand the full breadth of my scent profile.

#### Acceptance Criteria

1. THE ResultsView SHALL display exactly two families in the olfactory signature section: the Primary_Family (highest-scoring family) and the Secondary_Family (second-highest-scoring family), using a deterministic tiebreaker rule (alphabetical by family ID) when multiple families share the same second-highest score
2. THE ResultsView SHALL visually distinguish the Primary_Family from the Secondary_Family by rendering the Primary_Family with a larger colour swatch and font size, and by positioning it to the left of the Secondary_Family
3. THE ResultsView SHALL show the colour swatch, family label, and description for both the Primary_Family and Secondary_Family

### Requirement 7: Weighted Multi-Factor Recommendation Engine

**User Story:** As a user, I want the recommendation engine to weight personality traits, age, work style, and climate conditions when scoring fragrances, so that my recommendations reflect all relevant lifestyle dimensions.

#### Acceptance Criteria

1. THE Scoring_Engine SHALL assign Factor_Weights to the following dimensions with default values that sum to 1.0: personality traits (0.35), climate (0.25), work style (0.20), and age (0.20), where each weight is a value between 0.0 and 1.0 inclusive
2. THE Scoring_Engine SHALL apply age-based scoring using three brackets: ages 18–29 boost citrus, aquatic, and fruity families; ages 30–45 boost floral, fougere, and woody families; ages 46 and above boost oriental, leather, and gourmand families, with each boost adding a score increment between 1 and 3 points per matching family
3. THE Scoring_Engine SHALL combine personality trait scores, age-based scores, work style scores, and climate scores by multiplying each dimension's raw score contribution by its assigned Factor_Weight, then summing the weighted contributions to produce a final score for each scent family
4. IF any dimension value is missing or empty for a user profile (whether age, climate, work style, or personality traits), THEN THE Scoring_Engine SHALL redistribute that dimension's weight equally among the remaining dimensions that have valid values
5. WHEN the final weighted scores are computed for all scent families, THE Scoring_Engine SHALL normalize the results to a 0–100 scale where the highest-scoring family receives 100 and all others are scaled proportionally

### Requirement 8: Recommendation Explanation

**User Story:** As a user, I want an explanation of why certain factor combinations led to my specific recommendations, so that I can trust and understand the engine output.

#### Acceptance Criteria

1. THE ResultsView SHALL display a Recommendation_Explanation for each recommended fragrance
2. THE Recommendation_Explanation SHALL reference only dimensions with meaningful non-zero contributions, selecting the two dimensions with the highest individual score contribution for that fragrance's scent family; IF fewer than two dimensions have non-zero contribution, THEN THE Recommendation_Explanation SHALL fall back to a generic explanation referencing the fragrance's scent family and overall profile compatibility
3. THE Recommendation_Explanation SHALL describe the relationship between the contributing factors and the recommended scent family in plain language consisting of 1 to 3 sentences and containing no internal score values or technical terminology
4. WHEN the user expands a fragrance card, THE Recommendation_Explanation SHALL be visible within the expanded detail section without requiring additional scrolling within that section
5. THE Recommendation_Explanation SHALL be unique per fragrance card, such that no two fragrance cards within the same results set display identical explanation text, including when generic explanations are used (each generic explanation SHALL reference the specific fragrance's family and characteristics)

### Requirement 9: Integrate Photo Analysis into Scoring

**User Story:** As a user who uploaded photos, I want my skin colour, attire style, and confidence level to influence my fragrance recommendations, so that visual cues improve match accuracy.

#### Acceptance Criteria

1. WHEN photo analysis results are available and a skin colour classification is returned, THE Scoring_Engine SHALL apply the skin colour as a scoring factor for scent family selection with a maximum weight no greater than that of the climate factor (3 points per scent family)
2. WHEN photo analysis results are available and an attire style classification is returned, THE Scoring_Engine SHALL use the attire style as the styling scoring factor in place of the manually-selected aesthetic preference, applying the same weight values used for the manual styling factor
3. IF both photo-derived attire style and a manually-selected aesthetic preference are available, THEN THE Scoring_Engine SHALL use the photo-derived attire style and disregard the manual aesthetic preference for scoring purposes
4. WHEN photo analysis results are available and a confidence level is returned, THE Scoring_Engine SHALL apply the confidence level as an additive modifier to the boldness personality trait axis, capped so that the final boldness value remains within the 0.0 to 1.0 range
5. IF photo analysis results are not available or the photo analysis fails entirely, THEN THE Scoring_Engine SHALL exclude all photo data and use only the manually-entered profile data and personality quiz results, applying no score reduction or penalty for missing photo data
6. IF photo analysis returns a partial result where any one or more classifications are missing (skin colour, attire style, or confidence level), THEN THE Scoring_Engine SHALL incorporate whichever classifications are available and fall back to manual profile data for the missing classifications
