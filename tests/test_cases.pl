% ============================================================
%  IronHide Expert System — Test Suite
%  Run with: swipl tests/test_cases.pl
%
%  Covers:
%    - BMI classification (R1-R5) via forward chaining
%    - Age group derivation
%    - Condition derivation
%    - Backward chaining rule triggering
%    - Correctness of recommendations per scenario
% ============================================================

% Load the knowledge base (no initialization — safe for testing)
:- consult('../ironhide_kb').

:- initialization(run_test_suite, main).


:- dynamic test_passed_count/1.
:- dynamic test_failed_count/1.
:- dynamic test_result/3.   % test_result(TestCase, Status, Details)

test_passed_count(0).
test_failed_count(0).

% ─── Test Assertion Helper ────────────────────────────────────

assert_test(Name, Goal) :-
    ( call(Goal) ->
        retract(test_passed_count(N)),
        N1 is N + 1,
        assertz(test_passed_count(N1)),
        ansi_format([fg(green)], '    [PASS] ~w~n', [Name])
    ;
        retract(test_failed_count(N)),
        N1 is N + 1,
        assertz(test_failed_count(N1)),
        ansi_format([fg(red)], '    [FAIL] ~w~n', [Name])
    ).

% ─── Session Setup/Teardown ───────────────────────────────────

setup_user(Age, Weight, Height, Conditions, WantsExtra) :-
    clear_session,
    assertz(user_age(Age)),
    assertz(user_weight(Weight)),
    assertz(user_height(Height)),
    forall(member(C, Conditions), assertz(user_condition(C))),
    ( WantsExtra -> assertz(wants_additional_health_benefits) ; true ).

run_all :-
    classify_bmi,
    classify_age_group,
    derive_conditions.

% ─── Entry Point ─────────────────────────────────────────────

:- initialization(run_test_suite, main).

run_test_suite :-
    ansi_format([bold, fg(cyan)],
        '~n================================================================~n', []),
    ansi_format([bold, fg(cyan)],
        '   IronHide Expert System — Test Suite~n', []),
    ansi_format([bold, fg(cyan)],
        '================================================================~n~n', []),

    tc1_adult_normal,
    tc2_child_healthy,
    tc3_older_adult_overweight,
    tc4_adult_obese_hypertension,
    tc5_adult_overweight_diabetes,
    tc6_older_adult_diabetes,
    tc7_adult_underweight_type2,

    print_summary.

% ─────────────────────────────────────────────────────────────
%  TC1: Normal adult, no conditions
%  Input : Age=30, Weight=70kg, Height=175cm
%  BMI   : 70 / (1.75^2) = 22.9 → NORMAL
%  Rules : R8, R21–R28 expected
% ─────────────────────────────────────────────────────────────
tc1_adult_normal :-
    ansi_format([bold, fg(white)],
        '~nTC1: Adult 30yr | 70kg | 175cm | No Conditions~n', []),
    format('     Expected: BMI ~22.9 (Normal), Adult, R8 R21-R28 triggered~n~n'),
    setup_user(30, 70, 175, [], false),
    run_all,

    assert_test('TC1-1: BMI computed ~22.9',
        (user_bmi(B), B > 22.0, B < 24.0)),
    assert_test('TC1-2: BMI category = normal',
        bmi_category(normal)),
    assert_test('TC1-3: Age group = adult',
        age_group(adult)),
    assert_test('TC1-4: R8 triggered',
        recommendation('R8', physical_activity, _)),
    assert_test('TC1-5: R21 (diet) triggered',
        recommendation('R21', diet, _)),
    assert_test('TC1-6: R22 (diet) triggered',
        recommendation('R22', diet, _)),
    assert_test('TC1-7: R26 (water) triggered',
        recommendation('R26', diet, _)),
    assert_test('TC1-8: R28 (sleep) triggered',
        recommendation('R28', lifestyle, _)),
    assert_test('TC1-9: R6 NOT triggered (not a child)',
        \+ recommendation('R6', _, _)),
    assert_test('TC1-10: R12 NOT triggered (not older adult)',
        \+ recommendation('R12', _, _)),
    assert_test('TC1-11: No hypertension rules',
        \+ recommendation('R14', _, _)).

% ─────────────────────────────────────────────────────────────
%  TC2: Child, healthy weight
%  Input : Age=12, Weight=40kg, Height=150cm
%  BMI   : 40 / (1.50^2) = 17.8 → UNDERWEIGHT
%  Rules : R6, R7 expected; adult/older rules NOT
% ─────────────────────────────────────────────────────────────
tc2_child_healthy :-
    ansi_format([bold, fg(white)],
        '~nTC2: Child 12yr | 40kg | 150cm | No Conditions~n', []),
    format('     Expected: BMI ~17.8 (Underweight), Child, R6 R7 triggered~n~n'),
    setup_user(12, 40, 150, [], false),
    run_all,

    assert_test('TC2-1: BMI computed ~17.8',
        (user_bmi(B), B > 17.5, B < 18.0)),
    assert_test('TC2-2: BMI category = underweight',
        bmi_category(underweight)),
    assert_test('TC2-3: Age group = child',
        age_group(child)),
    assert_test('TC2-4: R6 triggered (60 min/day)',
        recommendation('R6', physical_activity, _)),
    assert_test('TC2-5: R7 triggered (muscle/bone)',
        recommendation('R7', physical_activity, _)),
    assert_test('TC2-6: R8 NOT triggered (not adult)',
        \+ recommendation('R8', _, _)),
    assert_test('TC2-7: R10 NOT triggered (not older adult)',
        \+ recommendation('R10', _, _)),
    assert_test('TC2-8: Diet rules NOT triggered for child',
        \+ recommendation('R21', _, _)).

% ─────────────────────────────────────────────────────────────
%  TC3: Older adult, overweight
%  Input : Age=68, Weight=85kg, Height=165cm
%  BMI   : 85 / (1.65^2) = 31.2 → OBESE
%  Rules : R10–R13, R21–R28 expected
% ─────────────────────────────────────────────────────────────
tc3_older_adult_overweight :-
    ansi_format([bold, fg(white)],
        '~nTC3: Older Adult 68yr | 85kg | 165cm | No Conditions~n', []),
    format('     Expected: BMI ~31.2 (Obese), Older Adult, R10-R13 R21-R28~n~n'),
    setup_user(68, 85, 165, [], false),
    run_all,

    assert_test('TC3-1: BMI computed ~31.2',
        (user_bmi(B), B > 31.0, B < 31.5)),
    assert_test('TC3-2: BMI category = obese',
        bmi_category(obese)),
    assert_test('TC3-3: Age group = older_adult',
        age_group(older_adult)),
    assert_test('TC3-4: R10 triggered',
        recommendation('R10', physical_activity, _)),
    assert_test('TC3-5: R11 triggered (can increase)',
        recommendation('R11', physical_activity, _)),
    assert_test('TC3-6: R12 triggered (balance)',
        recommendation('R12', physical_activity, _)),
    assert_test('TC3-7: R13 triggered (muscle strength)',
        recommendation('R13', physical_activity, _)),
    assert_test('TC3-8: R21 (diet) triggered',
        recommendation('R21', diet, _)),
    assert_test('TC3-9: R8 NOT triggered (not 18-64)',
        \+ recommendation('R8', _, _)).

% ─────────────────────────────────────────────────────────────
%  TC4: Adult, obese, hypertension
%  Input : Age=45, Weight=90kg, Height=170cm
%  BMI   : 90 / (1.70^2) = 31.1 → OBESE
%  Rules : R8, R14, R15, R16, R21–R28
% ─────────────────────────────────────────────────────────────
tc4_adult_obese_hypertension :-
    ansi_format([bold, fg(white)],
        '~nTC4: Adult 45yr | 90kg | 170cm | Hypertension~n', []),
    format('     Expected: BMI ~31.1 (Obese), Adult, R8 R14 R15 R16 triggered~n~n'),
    setup_user(45, 90, 170, [hypertension], false),
    run_all,

    assert_test('TC4-1: BMI computed ~31.1',
        (user_bmi(B), B > 31.0, B < 31.3)),
    assert_test('TC4-2: BMI category = obese',
        bmi_category(obese)),
    assert_test('TC4-3: has_condition(hypertension)',
        has_condition(hypertension)),
    assert_test('TC4-4: R8 triggered (adult activity)',
        recommendation('R8', physical_activity, _)),
    assert_test('TC4-5: R14 triggered (hypertension aerobic)',
        recommendation('R14', physical_activity, _)),
    assert_test('TC4-6: R15 triggered (aerobic+resistance)',
        recommendation('R15', physical_activity, _)),
    assert_test('TC4-7: R16 triggered (warm-up/cool-down)',
        recommendation('R16', physical_activity, _)),
    assert_test('TC4-8: R17 NOT triggered (no diabetes)',
        \+ recommendation('R17', _, _)),
    assert_test('TC4-9: R20 NOT triggered (no type2)',
        \+ recommendation('R20', _, _)).

% ─────────────────────────────────────────────────────────────
%  TC5: Adult, overweight, diabetes
%  Input : Age=50, Weight=80kg, Height=165cm
%  BMI   : 80 / (1.65^2) = 29.4 → OVERWEIGHT
%  Rules : R8, R17, R18; R19 NOT (not older adult)
% ─────────────────────────────────────────────────────────────
tc5_adult_overweight_diabetes :-
    ansi_format([bold, fg(white)],
        '~nTC5: Adult 50yr | 80kg | 165cm | Diabetes~n', []),
    format('     Expected: BMI ~29.4 (Overweight), R8 R17 R18 triggered, R19 NOT~n~n'),
    setup_user(50, 80, 165, [diabetes], false),
    run_all,

    assert_test('TC5-1: BMI computed ~29.4',
        (user_bmi(B), B > 29.0, B < 30.0)),
    assert_test('TC5-2: BMI category = overweight',
        bmi_category(overweight)),
    assert_test('TC5-3: has_condition(diabetes)',
        has_condition(diabetes)),
    assert_test('TC5-4: R8 triggered',
        recommendation('R8', physical_activity, _)),
    assert_test('TC5-5: R17 triggered (150 min spread)',
        recommendation('R17', physical_activity, _)),
    assert_test('TC5-6: R18 triggered (resistance 2-3x)',
        recommendation('R18', physical_activity, _)),
    assert_test('TC5-7: R19 NOT triggered (not older adult)',
        \+ recommendation('R19', _, _)),
    assert_test('TC5-8: R14 NOT triggered (no hypertension)',
        \+ recommendation('R14', _, _)).

% ─────────────────────────────────────────────────────────────
%  TC6: Older adult, diabetes
%  Input : Age=70, Weight=75kg, Height=165cm
%  BMI   : 75 / (1.65^2) = 27.5 → OVERWEIGHT
%  Rules : R10-R13, R17, R18, R19 (R19 needs older+diabetes)
% ─────────────────────────────────────────────────────────────
tc6_older_adult_diabetes :-
    ansi_format([bold, fg(white)],
        '~nTC6: Older Adult 70yr | 75kg | 165cm | Diabetes~n', []),
    format('     Expected: R10-R13 R17 R18 R19 all triggered~n~n'),
    setup_user(70, 75, 165, [diabetes], false),
    run_all,

    assert_test('TC6-1: Age group = older_adult',
        age_group(older_adult)),
    assert_test('TC6-2: has_condition(diabetes)',
        has_condition(diabetes)),
    assert_test('TC6-3: R10 triggered',
        recommendation('R10', physical_activity, _)),
    assert_test('TC6-4: R12 triggered (balance)',
        recommendation('R12', physical_activity, _)),
    assert_test('TC6-5: R13 triggered (muscle strength)',
        recommendation('R13', physical_activity, _)),
    assert_test('TC6-6: R17 triggered',
        recommendation('R17', physical_activity, _)),
    assert_test('TC6-7: R18 triggered',
        recommendation('R18', physical_activity, _)),
    assert_test('TC6-8: R19 triggered (older+diabetes)',
        recommendation('R19', physical_activity, _)),
    assert_test('TC6-9: R8 NOT triggered (not adult 18-64)',
        \+ recommendation('R8', _, _)).

% ─────────────────────────────────────────────────────────────
%  TC7: Adult, underweight, type2 diabetes
%  Input : Age=35, Weight=45kg, Height=170cm
%  BMI   : 45 / (1.70^2) = 15.6 → MODERATE THINNESS
%  Rules : R8, R20, R21-R28
% ─────────────────────────────────────────────────────────────
tc7_adult_underweight_type2 :-
    ansi_format([bold, fg(white)],
        '~nTC7: Adult 35yr | 45kg | 170cm | Type2 Diabetes~n', []),
    format('     Expected: BMI ~15.6 (Moderate Thinness), R8 R20 triggered~n~n'),
    setup_user(35, 45, 170, [type2_diabetes], false),
    run_all,

    assert_test('TC7-1: BMI computed ~15.6',
        (user_bmi(B), B > 15.0, B < 16.0)),
    assert_test('TC7-2: BMI category = moderate_thinness',
        bmi_category(moderate_thinness)),
    assert_test('TC7-3: Age group = adult',
        age_group(adult)),
    assert_test('TC7-4: has_condition(type2_diabetes)',
        has_condition(type2_diabetes)),
    assert_test('TC7-5: R8 triggered (adult activity)',
        recommendation('R8', physical_activity, _)),
    assert_test('TC7-6: R20 triggered (post-meal walking)',
        recommendation('R20', physical_activity, _)),
    assert_test('TC7-7: R21 diet triggered',
        recommendation('R21', diet, _)),
    assert_test('TC7-8: R25 (limit sugar) triggered',
        recommendation('R25', diet, _)),
    assert_test('TC7-9: R17 NOT triggered (no diabetes, only type2)',
        \+ recommendation('R17', _, _)).

% ─────────────────────────────────────────────────────────────
%  Summary
% ─────────────────────────────────────────────────────────────
print_summary :-
    test_passed_count(P),
    test_failed_count(F),
    Total is P + F,
    nl,
    ansi_format([bold, fg(cyan)],
        '================================================================~n', []),
    ansi_format([bold, fg(green)], '  PASSED : ~w / ~w~n', [P, Total]),
    ( F > 0 ->
        ansi_format([bold, fg(red)],   '  FAILED : ~w / ~w~n', [F, Total])
    ;
        ansi_format([bold, fg(green)], '  FAILED : 0 / ~w~n', [Total])
    ),
    ansi_format([bold, fg(cyan)],
        '================================================================~n', []),
    ( F =:= 0 ->
        ansi_format([bold, fg(green)], '~n  All ~w tests PASSED! The system is working correctly.~n~n', [Total])
    ;
        ansi_format([bold, fg(red)],   '~n  ~w test(s) FAILED. Please review the rules.~n~n', [F])
    ).
