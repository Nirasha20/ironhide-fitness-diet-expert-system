% ============================================================
%  IronHide Expert System — CLI Interface (No HTTP needed)
%  Usage: swipl ironhide_cli.pl
%  Useful for quick testing without a browser
% ============================================================

:- use_module(ironhide_facts).
:- use_module(ironhide_rules).

:- initialization(main, main).

main :-
    ansi_format([bold, fg(cyan)],
        "~n╔═══════════════════════════════════════════╗~n", []),
    ansi_format([bold, fg(cyan)],
        "║   IronHide Expert System  (CLI Mode)     ║~n", []),
    ansi_format([bold, fg(cyan)],
        "║   Fitness & Diet Recommendation           ║~n", []),
    ansi_format([bold, fg(cyan)],
        "╚═══════════════════════════════════════════╝~n~n", []),
    run_session.

run_session :-
    collect_user_data,
    run_inference,
    display_results,
    nl,
    ansi_format([fg(yellow)], "Run another query? (yes/no): ", []),
    read_line_to_string(user_input, Ans),
    (string_lower(Ans, "yes") ->
        (retract_all_user_facts, run_session)
    ;
        ansi_format([bold, fg(green)], "~nGoodbye! Stay fit with IronHide.~n~n", [])
    ).

% ─── Collect User Data ────────────────────────────────────

collect_user_data :-
    ansi_format([bold], "Please enter your details:~n~n", []),
    
    % Age
    prompt_number("Enter your age (years): ", Age),
    assertz(user_age(Age)),
    
    % Weight
    prompt_number("Enter your weight (kg): ", Weight),
    assertz(user_weight(Weight)),
    
    % Height
    prompt_number("Enter your height (cm): ", Height),
    assertz(user_height(Height)),
    
    % Goal
    nl,
    format("Goals:~n  1. lose_weight~n  2. gain_weight~n  3. maintain~n  4. improve_health~n"),
    ansi_format([fg(yellow)], "Enter your goal: ", []),
    read_line_to_atom(user_input, Goal),
    assertz(user_goal(Goal)),
    
    % Conditions
    nl,
    format("Health conditions (enter comma-separated, or 'none'):~n"),
    format("  Options: hypertension, diabetes, type2_diabetes~n"),
    ansi_format([fg(yellow)], "Your conditions: ", []),
    read_line_to_string(user_input, CondStr),
    parse_conditions(CondStr),
    
    % Additional benefits
    nl,
    ansi_format([fg(yellow)], "Do you want additional health benefits? (yes/no): ", []),
    read_line_to_string(user_input, Extra),
    (string_lower(Extra, "yes") -> assertz(wants_additional_health_benefits) ; true),
    nl.

prompt_number(Prompt, N) :-
    ansi_format([fg(yellow)], Prompt, []),
    read_line_to_string(user_input, Str),
    number_string(N, Str).

parse_conditions(Str) :-
    (Str = "none" -> true ;
        split_string(Str, ",", " ", Parts),
        forall(member(P, Parts), (
            string_to_atom(P, A),
            (member(A, [hypertension, diabetes, type2_diabetes]) ->
                assertz(user_condition(A)) ; true)
        ))
    ).

% ─── Run Inference ───────────────────────────────────────

run_inference :-
    ansi_format([bold, fg(cyan)], "~n[Inference Engine Running...]~n", []),
    
    % Forward Chaining
    format("  → Forward Chain: Computing BMI...~n"),
    classify_bmi,
    user_bmi(BMI),
    bmi_category(BMICat),
    format("  → Forward Chain: BMI = ~1f, Category = ~w~n", [BMI, BMICat]),
    
    format("  → Forward Chain: Classifying age group...~n"),
    classify_age_group,
    age_group(AgeGrp),
    format("  → Forward Chain: Age Group = ~w~n", [AgeGrp]),
    
    format("  → Forward Chain: Deriving conditions...~n"),
    derive_conditions,
    format("  → Backward Chain: Querying applicable rules...~n"),
    nl.

% ─── Display Results ─────────────────────────────────────

display_results :-
    user_bmi(BMI),
    bmi_category(BMICat),
    age_group(AgeGrp),
    
    ansi_format([bold, fg(green)],
        "╔══════════════════════════════════════════════════╗~n", []),
    ansi_format([bold, fg(green)],
        "║             IronHide Recommendations             ║~n", []),
    ansi_format([bold, fg(green)],
        "╚══════════════════════════════════════════════════╝~n", []),
    
    format("  BMI          : ~1f (~w)~n", [BMI, BMICat]),
    format("  Age Group    : ~w~n", [AgeGrp]),
    nl,
    
    get_recommendations(Recs, Expls),
    
    % Physical Activity Section
    ansi_format([bold, fg(magenta)], "  ◆ PHYSICAL ACTIVITY RECOMMENDATIONS~n", []),
    forall(
        member(rec(RID, physical_activity, Rec), Recs),
        (   format("    [~w] ~w~n", [RID, Rec]),
            (member(expl(RID, E), Expls) -> format("         ↳ ~w~n", [E]) ; true)
        )
    ),
    nl,
    
    % Diet Section
    ansi_format([bold, fg(yellow)], "  ◆ DIETARY RECOMMENDATIONS~n", []),
    forall(
        member(rec(RID, diet, Rec), Recs),
        (   format("    [~w] ~w~n", [RID, Rec]),
            (member(expl(RID, E), Expls) -> format("         ↳ ~w~n", [E]) ; true)
        )
    ),
    nl,
    
    % Lifestyle Section
    ansi_format([bold, fg(blue)], "  ◆ LIFESTYLE RECOMMENDATIONS~n", []),
    forall(
        member(rec(RID, lifestyle, Rec), Recs),
        (   format("    [~w] ~w~n", [RID, Rec]),
            (member(expl(RID, E), Expls) -> format("         ↳ ~w~n", [E]) ; true)
        )
    ),
    nl.

% ─── Reset Facts Between Sessions ────────────────────────

retract_all_user_facts :-
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
