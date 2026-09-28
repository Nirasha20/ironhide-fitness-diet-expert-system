% ============================================================
%  IronHide Expert System — Knowledge Base (28 Rules)
%  Domain : Fitness & Diet Recommendation
%
%  Rules Source:
%    R1  – R5  : WHO BMI Classification
%                https://www.who.int/news-room/fact-sheets/detail/obesity-and-overweight
%    R6  – R7  : WHO Physical Activity Guidelines for Children (5-17)
%                WHO Guidelines on Physical Activity & Sedentary Behaviour, 2020, pp. 18-19
%    R8  – R9  : WHO Guidelines for Adults 18-64
%                WHO Guidelines on Physical Activity & Sedentary Behaviour, 2020, pp. 26-27
%    R10 – R11 : WHO Guidelines for Older Adults 65+
%                WHO Guidelines on Physical Activity & Sedentary Behaviour, 2020, pp. 34-35
%    R12 – R13 : Balance & Muscle Strengthening for 65+
%                WHO Guidelines on Physical Activity & Sedentary Behaviour, 2020, p. 35
%    R14 – R16 : Hypertension & Physical Activity
%                American Heart Association Guidelines (heart.org/en/healthy-living)
%    R17 – R20 : Diabetes & Physical Activity
%                American Diabetes Association Standards of Medical Care, 2023
%    R21 – R28 : Dietary Rules for Adults
%                Dietary Guidelines for Sri Lankans, 2nd Ed., Nutrition Society of Sri Lanka
%                (www.slns.lk/dietary-guidelines)
% ============================================================

:- module(ironhide_rules, [
    classify_bmi/0,
    classify_age_group/0,
    derive_conditions/0,
    get_recommendations/2
]).

:- use_module(ironhide_facts).

% ─────────────────────────────────────────────────────────
%  FORWARD CHAINING — Derive intermediate facts from inputs
% ─────────────────────────────────────────────────────────

%% classify_bmi/0
%  Computes BMI = weight(kg) / (height_m)^2, asserts bmi_category
classify_bmi :-
    retractall(user_bmi(_)),
    retractall(bmi_category(_)),
    user_weight(W),
    user_height(H),
    H > 0,
    Hm is H / 100.0,
    BMI is W / (Hm * Hm),
    BMIRound is round(BMI * 10) / 10,
    assertz(user_bmi(BMIRound)),
    apply_bmi_rule(BMIRound).

apply_bmi_rule(BMI) :-
    % R1: BMI < 17.0 → moderate and severe thinness
    BMI < 17.0,
    assertz(bmi_category(moderate_thinness)), !.
apply_bmi_rule(BMI) :-
    % R2: BMI < 18.5 → underweight
    BMI < 18.5,
    assertz(bmi_category(underweight)), !.
apply_bmi_rule(BMI) :-
    % R3: BMI 18.5–24.9 → normal weight
    BMI >= 18.5, BMI =< 24.9,
    assertz(bmi_category(normal)), !.
apply_bmi_rule(BMI) :-
    % R4: BMI 25.0–29.9 → overweight
    BMI >= 25.0, BMI < 30.0,
    assertz(bmi_category(overweight)), !.
apply_bmi_rule(BMI) :-
    % R5: BMI >= 30.0 → obese
    BMI >= 30.0,
    assertz(bmi_category(obese)), !.

%% classify_age_group/0
%  Derives age group from user_age/1
classify_age_group :-
    retractall(age_group(_)),
    user_age(Age),
    apply_age_rule(Age).

apply_age_rule(Age) :-
    Age >= 5, Age =< 17,
    assertz(age_group(child)), !.
apply_age_rule(Age) :-
    Age >= 18, Age =< 64,
    assertz(age_group(adult)), !.
apply_age_rule(Age) :-
    Age >= 65,
    assertz(age_group(older_adult)), !.
apply_age_rule(_) :-
    assertz(age_group(unknown)).

%% derive_conditions/0
%  Copies user_condition facts to has_condition facts
derive_conditions :-
    retractall(has_condition(_)),
    forall(
        user_condition(C),
        (C \= none -> assertz(has_condition(C)) ; true)
    ).

% ─────────────────────────────────────────────────────────
%  BACKWARD CHAINING — Query recommendations
%  Each rule produces: rec(RuleID, Category, Recommendation, Explanation)
% ─────────────────────────────────────────────────────────

get_recommendations(Recs, Explanations) :-
    findall(
        rec(RID, Cat, Rec),
        applicable_rule(RID, Cat, Rec),
        Recs
    ),
    findall(
        expl(RID, Expl),
        rule_explanation(RID, Expl),
        Explanations
    ).

% ────────────── PHYSICAL ACTIVITY RULES ──────────────

% R6: Age 5–17 → 60 min/day moderate-to-vigorous activity
applicable_rule('R6', physical_activity,
    '60 min/day of moderate-to-vigorous intensity physical activity') :-
    age_group(child).

% R7: Age 5–17 → Muscle and bone strengthening 3× per week
applicable_rule('R7', physical_activity,
    'Include muscle- and bone-strengthening activities at least 3 times per week') :-
    age_group(child).

% R8: Age 18–64 → ≥150 min moderate-intensity or 75 min vigorous per week
applicable_rule('R8', physical_activity,
    'Do at least 150 min moderate-intensity, or at least 75 min vigorous-intensity, or equivalent combination per week') :-
    age_group(adult).

% R9: Age 18–64 + wants additional health benefits → 300 min/week
applicable_rule('R9', physical_activity,
    'Increase moderate-intensity activity to 300 min per week (or equivalent) for additional health benefits') :-
    age_group(adult),
    wants_additional_health_benefits.

% R10: Age 65+ → ≥150 min moderate-intensity or 75 min vigorous per week
applicable_rule('R10', physical_activity,
    'Do at least 150 min moderate-intensity, or at least 75 min vigorous-intensity, or equivalent combination per week') :-
    age_group(older_adult).

% R11: Age 65+ → Can increase to 300 min/week for additional benefit
applicable_rule('R11', physical_activity,
    'Increase moderate-intensity activity to 300 min per week (or equivalent) for additional health benefits') :-
    age_group(older_adult).

% R12: Age 65+ → Balance activities to prevent falls, 3+ days/week
applicable_rule('R12', physical_activity,
    'Do activity that enhances balance and prevents falls, 3 or more days per week') :-
    age_group(older_adult).

% R13: Age 65+ → Muscle-strengthening 2+ days/week
applicable_rule('R13', physical_activity,
    'Do muscle-strengthening involving major muscle groups on 2 or more days per week') :-
    age_group(older_adult).

% R14: Hypertension → 150 min/week moderate-intensity aerobic
applicable_rule('R14', physical_activity,
    'Aim for at least 150 min/week of moderate-intensity aerobic activity') :-
    has_condition(hypertension).

% R15: Hypertension → Combination aerobic + resistance training
applicable_rule('R15', physical_activity,
    'Use a combination of aerobic exercise and/or resistance training') :-
    has_condition(hypertension).

% R16: Hypertension → Warm-up and cool-down
applicable_rule('R16', physical_activity,
    'Warm up for several minutes before exercise and cool down afterwards') :-
    has_condition(hypertension).

% R17: Diabetes → 150 min/week moderate-to-vigorous, spread over 3 days, no 2 consecutive days without activity
applicable_rule('R17', physical_activity,
    'Do at least 150 min/week of moderate-to-vigorous activity, spread over at least 3 days, with no more than 2 consecutive days without activity') :-
    has_condition(diabetes).

% R18: Diabetes → Resistance exercise 2–3 sessions/week on non-consecutive days
applicable_rule('R18', physical_activity,
    'Do resistance exercise 2 to 3 sessions/week on non-consecutive days') :-
    has_condition(diabetes).

% R19: Diabetes + older adult → Flexibility and balance training 2–3×/week
applicable_rule('R19', physical_activity,
    'Add flexibility and balance training 2 to 3 times per week') :-
    has_condition(diabetes),
    age_group(older_adult).

% R20: Type 2 diabetes → Break up long sitting with 15 min walk after meals
applicable_rule('R20', physical_activity,
    'Break up long sitting with a 15 min walk after meals, or 3 min of light walking or body-weight exercise every 30 min') :-
    has_condition(type2_diabetes).

% ────────────── DIETARY RULES ──────────────

% R21: Any adult → Choose whole grains, parboiled or less polished rice
applicable_rule('R21', diet,
    'Choose whole grains, including parboiled or less polished rice, over refined grains') :-
    age_group(adult).
applicable_rule('R21', diet,
    'Choose whole grains, including parboiled or less polished rice, over refined grains') :-
    age_group(older_adult).

% R22: Any adult → Eat 2 vegetables (one leafy) and 2 fruits daily
applicable_rule('R22', diet,
    'Eat at least two vegetables (one green leafy) and two fruits daily') :-
    age_group(adult).
applicable_rule('R22', diet,
    'Eat at least two vegetables (one green leafy) and two fruits daily') :-
    age_group(older_adult).

% R23: Any adult → Eat fish, egg, or lean meat with pulses in every meal
applicable_rule('R23', diet,
    'Eat fish, egg, or lean meat with pulses in every meal') :-
    age_group(adult).
applicable_rule('R23', diet,
    'Eat fish, egg, or lean meat with pulses in every meal') :-
    age_group(older_adult).

% R24: Any adult → Limit salty foods and adding salt
applicable_rule('R24', diet,
    'Limit salty foods and adding salt to food') :-
    age_group(adult).
applicable_rule('R24', diet,
    'Limit salty foods and adding salt to food') :-
    age_group(older_adult).

% R25: Any adult → Limit sugary drinks, biscuits, cakes, sweets
applicable_rule('R25', diet,
    'Limit sugary drinks, biscuits, cakes, sweets, and sweeteners') :-
    age_group(adult).
applicable_rule('R25', diet,
    'Limit sugary drinks, biscuits, cakes, sweets, and sweeteners') :-
    age_group(older_adult).

% R26: Any adult → Drink 8–10 glasses (1.5–2.0 L) of water daily
applicable_rule('R26', diet,
    'Drink 8 to 10 glasses (1.5 to 2.0 L) of water through the day') :-
    age_group(adult).
applicable_rule('R26', diet,
    'Drink 8 to 10 glasses (1.5 to 2.0 L) of water through the day') :-
    age_group(older_adult).

% R27: Any adult → 150–300 min/week moderate physical activity
applicable_rule('R27', physical_activity,
    'Do 150 to 300 min/week of moderate physical activity') :-
    age_group(adult).
applicable_rule('R27', physical_activity,
    'Do 150 to 300 min/week of moderate physical activity') :-
    age_group(older_adult).

% R28: Any adult → Sleep 7–8 hours per night
applicable_rule('R28', lifestyle,
    'Sleep 7 to 8 hours continuously each day') :-
    age_group(adult).
applicable_rule('R28', lifestyle,
    'Sleep 7 to 8 hours continuously each day') :-
    age_group(older_adult).

% ─────────────────────────────────────────────────────────
%  Rule Explanations (for reasoning trace / explanation facility)
% ─────────────────────────────────────────────────────────

rule_explanation('R6',  'WHO: Children aged 5-17 need 60 min/day of moderate-vigorous activity for healthy development.').
rule_explanation('R7',  'WHO: Muscle and bone-strengthening activities are critical during growth years to build skeletal density.').
rule_explanation('R8',  'WHO: Adults 18-64 need 150 min moderate or 75 min vigorous activity per week to reduce chronic disease risk.').
rule_explanation('R9',  'WHO: Increasing to 300 min/week provides additional cardiovascular and metabolic health benefits.').
rule_explanation('R10', 'WHO: Older adults (65+) follow the same base activity guidelines as younger adults.').
rule_explanation('R11', 'WHO: Older adults can gain extra health benefits from increasing weekly activity to 300 min.').
rule_explanation('R12', 'WHO: Balance training in older adults significantly reduces fall risk and injury.').
rule_explanation('R13', 'WHO: Muscle-strengthening counteracts age-related muscle loss (sarcopenia).').
rule_explanation('R14', 'AHA: Moderate aerobic activity lowers blood pressure by improving vascular flexibility.').
rule_explanation('R15', 'AHA: Combining aerobic and resistance training provides complementary blood pressure management.').
rule_explanation('R16', 'AHA: Warm-up/cool-down prevents hypertensive spikes during sudden exercise transitions.').
rule_explanation('R17', 'ADA: Spreading activity over 3+ days prevents consecutive inactivity which impairs insulin sensitivity.').
rule_explanation('R18', 'ADA: Resistance training 2-3×/week improves glucose uptake and insulin sensitivity in muscles.').
rule_explanation('R19', 'ADA: Older adults with diabetes benefit from balance training to offset increased fall risk from neuropathy.').
rule_explanation('R20', 'ADA: Post-meal walking reduces glucose spikes in type 2 diabetes by utilizing glucose for muscle activity.').
rule_explanation('R21', 'SLNS: Whole grains and parboiled rice have lower glycaemic index, aiding weight and blood sugar management.').
rule_explanation('R22', 'SLNS: Two vegetables and two fruits daily provide essential micronutrients, fibre, and antioxidants.').
rule_explanation('R23', 'SLNS: Protein from fish/egg/lean meat with pulses ensures complete amino acid profiles.').
rule_explanation('R24', 'SLNS: Excess salt (sodium) raises blood pressure; recommended intake is <5g NaCl/day.').
rule_explanation('R25', 'SLNS: Sugary foods cause blood glucose spikes, weight gain, and dental problems.').
rule_explanation('R26', 'SLNS: Adequate hydration maintains metabolism, kidney function, and physical performance.').
rule_explanation('R27', 'SLNS: Regular moderate physical activity reduces obesity, cardiovascular disease, and diabetes risk.').
rule_explanation('R28', 'SLNS: 7-8 hours of sleep regulates hunger hormones (ghrelin/leptin) and supports muscle recovery.').
