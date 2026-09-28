% ============================================================
%  IronHide Expert System — CLI Runner
%  Loads knowledge base + provides interactive terminal UI
%
%  HOW TO RUN:
%    swipl ironhide_standalone.pl
%  or use:
%    run_cli.bat   (Windows)
% ============================================================

:- use_module(library(ansi_term)).
:- consult(ironhide_kb).       % Load knowledge base (no auto-start)

:- initialization(main, main). % Entry point when run with swipl

main :-
    print_banner,
    run_session.

% ─── Banner ──────────────────────────────────────────────────

print_banner :-
    nl,
    ansi_format([bold, fg(cyan)],
        '================================================================~n', []),
    ansi_format([bold, fg(cyan)],
        '   IronHide Expert System  -  Fitness & Diet Recommendation~n', []),
    ansi_format([bold, fg(cyan)],
        '   Version 1.0  |  28 Rules  |  SWI-Prolog~n', []),
    ansi_format([bold, fg(cyan)],
        '================================================================~n~n', []).

% ─── Main Session Loop ────────────────────────────────────────

run_session :-
    collect_user_data,
    ansi_format([bold, fg(yellow)], '~n--- Running Inference Engine ---~n', []),
    run_inference,
    display_results,
    nl,
    ansi_format([fg(yellow)], 'Run another query? (yes/no): ', []),
    read_line_to_string(user_input, Ans),
    str_lower(Ans, AnsLower),
    ( AnsLower = "yes" ->
        ( clear_session, run_session )
    ;
        ansi_format([bold, fg(green)],
            '~nThank you for using IronHide. Stay fit!~n~n', [])
    ).

% ─── String Helper ───────────────────────────────────────────

str_lower(S, L) :-
    string_codes(S, Codes),
    maplist(lower_code, Codes, LCodes),
    string_codes(L, LCodes).

lower_code(C, L) :-
    ( C >= 0'A, C =< 0'Z -> L is C + 32 ; L = C ).

% ─── Data Collection ─────────────────────────────────────────

collect_user_data :-
    ansi_format([bold], '~n--- User Profile Input ---~n~n', []),

    prompt_number('  Enter your age (years)   : ', Age),
    assertz(user_age(Age)),

    prompt_number('  Enter your weight (kg)   : ', Weight),
    assertz(user_weight(Weight)),

    prompt_number('  Enter your height (cm)   : ', Height),
    assertz(user_height(Height)),

    nl,
    format('  Goals:~n'),
    format('    lose_weight | gain_weight | maintain | improve_health~n'),
    ansi_format([fg(yellow)], '  Your goal (type exactly) : ', []),
    read_line_to_atom(user_input, Goal),
    assertz(user_goal(Goal)),

    nl,
    format('  Health conditions (comma-separated, or press Enter for none):~n'),
    format('    Options: hypertension, diabetes, type2_diabetes~n'),
    ansi_format([fg(yellow)], '  Your conditions          : ', []),
    read_line_to_string(user_input, CondStr),
    parse_conditions(CondStr),

    nl,
    ansi_format([fg(yellow)], '  Want additional health benefits? (yes/no): ', []),
    read_line_to_string(user_input, Extra),
    str_lower(Extra, ExtraL),
    ( ExtraL = "yes" -> assertz(wants_additional_health_benefits) ; true ),
    nl.

prompt_number(Prompt, N) :-
    ansi_format([fg(yellow)], Prompt, []),
    read_line_to_string(user_input, Str),
    ( number_string(N, Str) ->
        true
    ;
        format('  [!] Please enter a valid number.~n'),
        prompt_number(Prompt, N)
    ).

parse_conditions(Str) :-
    split_string(Str, ",", " ", Parts),
    forall(member(P, Parts), (
        atom_string(A, P),
        ( member(A, [hypertension, diabetes, type2_diabetes]) ->
            assertz(user_condition(A))
        ; true )
    )).

% ─── Results Display ─────────────────────────────────────────

display_results :-
    user_bmi(BMI),
    bmi_category(BMICat),
    age_group(AgeGrp),
    user_goal(Goal),

    nl,
    ansi_format([bold, fg(green)],
        '================================================================~n', []),
    ansi_format([bold, fg(green)],
        '                    IronHide Recommendations~n', []),
    ansi_format([bold, fg(green)],
        '================================================================~n', []),
    format('  BMI Value    : ~1f~n',  [BMI]),
    bmi_label(BMICat, BLabel),
    format('  BMI Category : ~w~n',  [BLabel]),
    format('  Age Group    : ~w~n',  [AgeGrp]),
    format('  Your Goal    : ~w~n',  [Goal]),
    nl,

    get_recommendations(Recs),

    % ── Physical Activity ──
    include(is_physical, Recs, PhysRecs),
    ( PhysRecs \= [] ->
        ( ansi_format([bold, fg(magenta)],
            '  [PHYSICAL ACTIVITY]~n', []),
          forall(member(rec(RID, _, Text, Expl), PhysRecs), (
              format('~n    Rule ~w:~n', [RID]),
              format('      ~w~n', [Text]),
              ansi_format([fg(cyan)], '      WHY: ~w~n', [Expl])
          )),
          nl
        )
    ; true ),

    % ── Diet ──
    include(is_diet, Recs, DietRecs),
    ( DietRecs \= [] ->
        ( ansi_format([bold, fg(yellow)],
            '  [DIETARY RECOMMENDATIONS]~n', []),
          forall(member(rec(RID, _, Text, Expl), DietRecs), (
              format('~n    Rule ~w:~n', [RID]),
              format('      ~w~n', [Text]),
              ansi_format([fg(cyan)], '      WHY: ~w~n', [Expl])
          )),
          nl
        )
    ; true ),

    % ── Lifestyle ──
    include(is_lifestyle, Recs, LifeRecs),
    ( LifeRecs \= [] ->
        ( ansi_format([bold, fg(blue)],
            '  [LIFESTYLE RECOMMENDATIONS]~n', []),
          forall(member(rec(RID, _, Text, Expl), LifeRecs), (
              format('~n    Rule ~w:~n', [RID]),
              format('      ~w~n', [Text]),
              ansi_format([fg(cyan)], '      WHY: ~w~n', [Expl])
          )),
          nl
        )
    ; true ),

    ansi_format([bold, fg(green)],
        '================================================================~n~n', []).

% ─── BMI Category Labels ─────────────────────────────────────

bmi_label(moderate_thinness, 'Moderate & Severe Thinness (BMI < 17.0)').
bmi_label(underweight,       'Underweight (BMI 17.0-18.4)').
bmi_label(normal,            'Normal Weight (BMI 18.5-24.9)').
bmi_label(overweight,        'Overweight (BMI 25.0-29.9)').
bmi_label(obese,             'Obese (BMI >= 30.0)').
bmi_label(unknown,           'Unknown').
