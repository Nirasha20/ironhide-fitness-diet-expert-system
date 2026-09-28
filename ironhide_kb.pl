% ============================================================
%  IronHide Expert System — KNOWLEDGE BASE ONLY
%  (No initialization, safe to load from tests and other files)
%
%  Rules Source:
%    R1 – R5   : WHO BMI Classification
%                https://www.who.int/news-room/fact-sheets/detail/obesity-and-overweight
%    R6 – R7   : WHO Physical Activity Guidelines for Children (5-17)
%                WHO Guidelines on Physical Activity & Sedentary Behaviour, 2020, pp. 18-19
%    R8 – R9   : WHO Guidelines for Adults 18-64
%                WHO Guidelines on Physical Activity & Sedentary Behaviour, 2020, pp. 26-27
%    R10 – R11 : WHO Guidelines for Older Adults 65+
%                WHO Guidelines on Physical Activity & Sedentary Behaviour, 2020, pp. 34-35
%    R12 – R13 : Balance & Muscle Strengthening for Older Adults
%                WHO Guidelines on Physical Activity & Sedentary Behaviour, 2020, p. 35
%    R14 – R16 : Hypertension & Physical Activity
%                American Heart Association (https://www.heart.org/en/healthy-living/fitness)
%    R17 – R20 : Diabetes & Physical Activity
%                American Diabetes Association Standards of Medical Care, 2023
%                https://doi.org/10.2337/dc23-S005
%    R21 – R28 : Dietary Rules for Adults
%                Dietary Guidelines for Sri Lankans, 2nd Ed.
%                Nutrition Society of Sri Lanka (www.slns.lk)
% ============================================================

% ─────────────────────────────────────────────────────────────
%  SECTION 1 : WORKING MEMORY — Dynamic Facts
% ─────────────────────────────────────────────────────────────

:- dynamic user_age/1.
:- dynamic user_weight/1.
:- dynamic user_height/1.
:- dynamic user_bmi/1.
:- dynamic user_goal/1.
:- dynamic user_condition/1.
:- dynamic bmi_category/1.
:- dynamic age_group/1.
:- dynamic has_condition/1.
:- dynamic wants_additional_health_benefits/0.

% ─────────────────────────────────────────────────────────────
%  SECTION 2 : FORWARD CHAINING
% ─────────────────────────────────────────────────────────────

%% classify_bmi/0 — Applies R1-R5 via forward chaining
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

% R1: BMI < 17.0 → Moderate and severe thinness
apply_bmi_rule(BMI) :- BMI < 17.0, !, assertz(bmi_category(moderate_thinness)).
% R2: BMI 17.0–18.4 → Underweight
apply_bmi_rule(BMI) :- BMI < 18.5, !, assertz(bmi_category(underweight)).
% R3: BMI 18.5–24.9 → Normal weight
apply_bmi_rule(BMI) :- BMI =< 24.9, !, assertz(bmi_category(normal)).
% R4: BMI 25.0–29.9 → Overweight
apply_bmi_rule(BMI) :- BMI < 30.0, !, assertz(bmi_category(overweight)).
% R5: BMI >= 30.0 → Obese
apply_bmi_rule(_)   :- assertz(bmi_category(obese)).

%% classify_age_group/0 — Derives age group
classify_age_group :-
    retractall(age_group(_)),
    user_age(Age),
    apply_age_rule(Age).

apply_age_rule(Age) :- Age >= 5,  Age =< 17, !, assertz(age_group(child)).
apply_age_rule(Age) :- Age >= 18, Age =< 64, !, assertz(age_group(adult)).
apply_age_rule(Age) :- Age >= 65,             !, assertz(age_group(older_adult)).
apply_age_rule(_)   :- assertz(age_group(unknown)).

%% derive_conditions/0 — Copies user conditions to working memory
derive_conditions :-
    retractall(has_condition(_)),
    forall(
        user_condition(C),
        ( C \= none -> assertz(has_condition(C)) ; true )
    ).

% ─────────────────────────────────────────────────────────────
%  SECTION 3 : KNOWLEDGE BASE — 28 Rules (Backward Chaining)
%  Format: recommendation(RuleID, Category, RecommendationText)
%  Each rule fires when its body conditions are satisfied.
% ─────────────────────────────────────────────────────────────

% ── R6: Children — 60 min/day activity ────────────────────
% Source: WHO 2020, p.18
recommendation('R6', physical_activity,
    '60 min/day of moderate-to-vigorous intensity physical activity') :-
    age_group(child).

% ── R7: Children — Muscle/bone strengthening ──────────────
% Source: WHO 2020, p.19
recommendation('R7', physical_activity,
    'Include muscle- and bone-strengthening activities at least 3 times per week') :-
    age_group(child).

% ── R8: Adults 18-64 — Base activity ─────────────────────
% Source: WHO 2020, p.26
recommendation('R8', physical_activity,
    'Do at least 150 min moderate-intensity, or 75 min vigorous-intensity, or equivalent combination per week') :-
    age_group(adult).

% ── R9: Adults 18-64 — Extra health benefits ─────────────
% Source: WHO 2020, p.27
recommendation('R9', physical_activity,
    'Increase moderate-intensity activity to 300 min per week for additional health benefits') :-
    age_group(adult),
    wants_additional_health_benefits.

% ── R10: Older Adults 65+ — Base activity ────────────────
% Source: WHO 2020, p.34
recommendation('R10', physical_activity,
    'Do at least 150 min moderate-intensity, or 75 min vigorous-intensity, or equivalent combination per week') :-
    age_group(older_adult).

% ── R11: Older Adults 65+ — Increase to 300 min ──────────
% Source: WHO 2020, p.35
recommendation('R11', physical_activity,
    'Increase moderate-intensity activity to 300 min per week for additional health benefits') :-
    age_group(older_adult).

% ── R12: Older Adults 65+ — Balance training ─────────────
% Source: WHO 2020, p.35
recommendation('R12', physical_activity,
    'Do activity that enhances balance and prevents falls, 3 or more days per week') :-
    age_group(older_adult).

% ── R13: Older Adults 65+ — Muscle strengthening ─────────
% Source: WHO 2020, p.35
recommendation('R13', physical_activity,
    'Do muscle-strengthening involving major muscle groups on 2 or more days per week') :-
    age_group(older_adult).

% ── R14: Hypertension — Aerobic target ───────────────────
% Source: AHA, heart.org/en/healthy-living/fitness
recommendation('R14', physical_activity,
    'Aim for at least 150 min/week of moderate-intensity aerobic activity') :-
    has_condition(hypertension).

% ── R15: Hypertension — Aerobic + Resistance ─────────────
% Source: AHA
recommendation('R15', physical_activity,
    'Use a combination of aerobic exercise and/or resistance training') :-
    has_condition(hypertension).

% ── R16: Hypertension — Warm-up/cool-down ────────────────
% Source: AHA
recommendation('R16', physical_activity,
    'Warm up for several minutes before exercise and cool down afterwards') :-
    has_condition(hypertension).

% ── R17: Diabetes — 150 min spread over 3+ days ──────────
% Source: ADA Standards 2023, doi:10.2337/dc23-S005
recommendation('R17', physical_activity,
    'Do at least 150 min/week moderate-to-vigorous activity, spread over at least 3 days, with no more than 2 consecutive days without activity') :-
    has_condition(diabetes).

% ── R18: Diabetes — Resistance training ──────────────────
% Source: ADA 2023
recommendation('R18', physical_activity,
    'Do resistance exercise 2 to 3 sessions/week on non-consecutive days') :-
    has_condition(diabetes).

% ── R19: Diabetes + Older Adult — Balance training ───────
% Source: ADA 2023 (compound rule: requires BOTH conditions)
recommendation('R19', physical_activity,
    'Add flexibility and balance training 2 to 3 times per week') :-
    has_condition(diabetes),
    age_group(older_adult).

% ── R20: Type 2 Diabetes — Break sitting ─────────────────
% Source: ADA 2023
recommendation('R20', physical_activity,
    'Break up long sitting with a 15 min walk after meals, or 3 min of light walking or body-weight exercise every 30 min') :-
    has_condition(type2_diabetes).

% ── R21: Adults — Choose whole grains ────────────────────
% Source: SLNS Dietary Guidelines for Sri Lankans, 2nd Ed.
recommendation('R21', diet,
    'Choose whole grains, including parboiled or less polished rice, over refined grains') :-
    \+ age_group(child).

% ── R22: Adults — Vegetables and fruits ──────────────────
% Source: SLNS
recommendation('R22', diet,
    'Eat at least two vegetables (one green leafy) and two fruits daily') :-
    \+ age_group(child).

% ── R23: Adults — Protein sources ────────────────────────
% Source: SLNS
recommendation('R23', diet,
    'Eat fish, egg, or lean meat with pulses in every meal') :-
    \+ age_group(child).

% ── R24: Adults — Limit salt ─────────────────────────────
% Source: SLNS
recommendation('R24', diet,
    'Limit salty foods and adding salt to food') :-
    \+ age_group(child).

% ── R25: Adults — Limit sugar ────────────────────────────
% Source: SLNS
recommendation('R25', diet,
    'Limit sugary drinks, biscuits, cakes, sweets, and sweeteners') :-
    \+ age_group(child).

% ── R26: Adults — Water intake ───────────────────────────
% Source: SLNS
recommendation('R26', diet,
    'Drink 8 to 10 glasses (1.5 to 2.0 L) of water through the day') :-
    \+ age_group(child).

% ── R27: Adults — General activity target ────────────────
% Source: SLNS
recommendation('R27', physical_activity,
    'Do 150 to 300 min/week of moderate physical activity') :-
    \+ age_group(child).

% ── R28: Adults — Sleep ──────────────────────────────────
% Source: SLNS
recommendation('R28', lifestyle,
    'Sleep 7 to 8 hours continuously each day') :-
    \+ age_group(child).

% ─────────────────────────────────────────────────────────────
%  SECTION 4 : EXPLANATION BASE
%  explanation(RuleID, SourceAndReason)
% ─────────────────────────────────────────────────────────────

explanation('R6',  'WHO 2020 p.18: Children aged 5-17 need 60 min/day for healthy growth, fitness and mental health.').
explanation('R7',  'WHO 2020 p.19: Bone-strengthening during growth builds skeletal density and reduces fracture risk.').
explanation('R8',  'WHO 2020 p.26: 150 min/week moderate activity significantly reduces CVD and diabetes risk in adults.').
explanation('R9',  'WHO 2020 p.27: 300 min/week provides additional benefits including reduced depression and cancer risk.').
explanation('R10', 'WHO 2020 p.34: Older adults need the same base activity as younger adults for chronic disease prevention.').
explanation('R11', 'WHO 2020 p.35: Higher activity volumes yield greater health benefits in older adults.').
explanation('R12', 'WHO 2020 p.35: Balance training in older adults significantly reduces fall risk and related injuries.').
explanation('R13', 'WHO 2020 p.35: Muscle-strengthening counteracts age-related muscle loss (sarcopenia).').
explanation('R14', 'AHA (heart.org): Aerobic activity lowers blood pressure by improving vascular flexibility.').
explanation('R15', 'AHA: Combining aerobic and resistance training provides complementary BP management.').
explanation('R16', 'AHA: Warm-up/cool-down prevents hypertensive spikes during sudden exercise transitions.').
explanation('R17', 'ADA 2023: Spreading activity prevents consecutive inactivity that impairs insulin sensitivity.').
explanation('R18', 'ADA 2023: Resistance training 2-3x/week improves glucose uptake and insulin sensitivity.').
explanation('R19', 'ADA 2023: Older adults with diabetes benefit from balance training to offset fall risk from neuropathy.').
explanation('R20', 'ADA 2023: Post-meal walking reduces postprandial glucose spikes by using glucose in working muscles.').
explanation('R21', 'SLNS: Whole grains have lower glycaemic index, aiding weight and blood sugar management.').
explanation('R22', 'SLNS: 2 vegetables + 2 fruits daily provide essential micronutrients, fibre, and antioxidants.').
explanation('R23', 'SLNS: Protein from fish/egg/lean meat with pulses ensures complete amino acid profiles.').
explanation('R24', 'SLNS: Excess sodium raises blood pressure; WHO recommends less than 5g NaCl per day.').
explanation('R25', 'SLNS: Sugary foods cause glucose spikes, promote weight gain and increase type 2 diabetes risk.').
explanation('R26', 'SLNS: Adequate hydration maintains metabolism, kidney function, and physical performance.').
explanation('R27', 'SLNS: 150-300 min/week moderate activity reduces obesity, CVD, and diabetes risk.').
explanation('R28', 'SLNS: 7-8 hours sleep regulates hunger hormones (ghrelin/leptin) and supports muscle recovery.').

% ─────────────────────────────────────────────────────────────
%  SECTION 5 : BACKWARD CHAINING — Collect Recommendations
% ─────────────────────────────────────────────────────────────

%% get_recommendations(-Recs)
%  Collects all rec(RID, Cat, Text, Expl) for applicable rules.
get_recommendations(Recs) :-
    findall(
        rec(RID, Cat, Text, Expl),
        (   recommendation(RID, Cat, Text),
            ( explanation(RID, Expl) -> true ; Expl = 'See referenced source.' )
        ),
        Recs
    ).

% ─────────────────────────────────────────────────────────────
%  SECTION 6 : INFERENCE ENGINE ORCHESTRATOR
% ─────────────────────────────────────────────────────────────

run_inference :-
    format('~n  [FC] Step 1: Computing BMI from weight and height (rules R1-R5)~n'),
    classify_bmi,
    user_bmi(BMI),
    bmi_category(Cat),
    format('  [FC] Step 2: BMI = ~1f  =>  Category = ~w~n', [BMI, Cat]),
    format('  [FC] Step 3: Classifying age group from age~n'),
    classify_age_group,
    age_group(AgeGrp),
    format('  [FC] Step 4: Age Group = ~w~n', [AgeGrp]),
    format('  [FC] Step 5: Deriving health conditions into working memory~n'),
    derive_conditions,
    format('  [BC] Step 6: Backward chaining — querying applicable recommendation rules~n'),
    nl.

% ─────────────────────────────────────────────────────────────
%  SECTION 7 : SESSION UTILITIES
% ─────────────────────────────────────────────────────────────

clear_session :-
    retractall(user_age(_)),
    retractall(user_weight(_)),
    retractall(user_height(_)),
    retractall(user_goal(_)),
    retractall(user_condition(_)),
    retractall(wants_additional_health_benefits),
    retractall(user_bmi(_)),
    retractall(bmi_category(_)),
    retractall(age_group(_)),
    retractall(has_condition(_)).

is_physical(rec(_, physical_activity, _, _)).
is_diet(rec(_, diet, _, _)).
is_lifestyle(rec(_, lifestyle, _, _)).
