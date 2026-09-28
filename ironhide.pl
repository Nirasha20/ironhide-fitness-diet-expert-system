% ============================================================
%  IronHide Expert System — Main Entry Point
%  Provides HTTP REST API + serves static web UI
%
%  To run:  swipl ironhide.pl
%           Then open http://localhost:8080 in your browser
% ============================================================

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_cors)).
:- use_module(library(json)).
:- use_module(library(lists)).

:- use_module(ironhide_facts).
:- use_module(ironhide_rules).

% ─── HTTP Route Dispatch ──────────────────────────────────
:- http_handler(root(.),          http_redirect(moved, root(index)),  []).
:- http_handler(root(index),      serve_index,    []).
:- http_handler(root('web/'),     serve_web_files, [prefix]).
:- http_handler(root(analyze),    handle_analyze, [method(post)]).
:- http_handler(root(rules),      handle_rules,   [method(get)]).

% Serve static web files
serve_web_files(Request) :-
    http_reply_from_files('web/', [], Request).

% Serve index.html
serve_index(_Request) :-
    http_reply_file('web/index.html', [], _Request).

% ─── Start Server ────────────────────────────────────────
:- initialization(main, main).

main :-
    set_cors_enabled,
    Port = 8080,
    format("~n============================================~n"),
    format(" IronHide Expert System~n"),
    format(" Starting HTTP server on port ~w~n", [Port]),
    format(" Open: http://localhost:~w~n", [Port]),
    format("============================================~n~n"),
    http_server(http_dispatch, [port(Port)]).

set_cors_enabled :-
    set_setting(http:cors, [*]).

% ─── Handle Analysis Request ─────────────────────────────
handle_analyze(Request) :-
    http_read_json_dict(Request, Data, []),
    
    % Extract user inputs
    Age     = Data.age,
    Weight  = Data.weight,
    Height  = Data.height,
    Goal    = Data.goal,
    Conditions = Data.conditions,
    WantsExtra = Data.wants_extra_benefits,
    
    % Clear previous session facts
    retractall(user_age(_)),
    retractall(user_weight(_)),
    retractall(user_height(_)),
    retractall(user_goal(_)),
    retractall(user_condition(_)),
    retractall(wants_additional_health_benefits),
    
    % Assert new facts
    assertz(user_age(Age)),
    assertz(user_weight(Weight)),
    assertz(user_height(Height)),
    assertz(user_goal(Goal)),
    
    % Assert conditions
    assert_conditions(Conditions),
    
    % Assert extra benefits flag
    (WantsExtra = true -> assertz(wants_additional_health_benefits) ; true),
    
    % Run forward chaining inference
    classify_bmi,
    classify_age_group,
    derive_conditions,
    
    % Run backward chaining to collect recommendations
    get_recommendations(Recs, Expls),
    
    % Collect derived facts for display
    user_bmi(BMI),
    bmi_category(BMICat),
    age_group(AgeGrp),
    
    % Build response JSON
    recs_to_json(Recs, Expls, RecJSON),
    
    bmi_category_label(BMICat, BMILabel),
    age_group_label(AgeGrp, AgeLabel),
    
    Response = _{
        bmi: BMI,
        bmi_category: BMILabel,
        age_group: AgeLabel,
        recommendations: RecJSON,
        reasoning_chain: [
            "Step 1: Computed BMI from weight and height",
            "Step 2: Classified BMI category using WHO thresholds (R1-R5)",
            "Step 3: Determined age group from user age (R6-R13)",
            "Step 4: Registered health conditions (hypertension/diabetes)",
            "Step 5: Applied backward chaining — queried applicable rules",
            "Step 6: Generated recommendations with explanations"
        ]
    },
    reply_json_dict(Response).

handle_analyze(_Request) :-
    reply_json_dict(_{error: "Invalid input data"}, [status(400)]).

% ─── Handle Rules List Request ───────────────────────────
handle_rules(_Request) :-
    findall(
        _{id: RID, category: Cat, rule: Rec, explanation: Expl},
        (   clause(applicable_rule(RID, Cat0, Rec), _),
            \+ clause(applicable_rule(RID, Cat0, Rec), true),  % has body
            atom_string(Cat0, Cat),
            (clause(rule_explanation(RID, Expl), true) -> true ; Expl = "")
        ),
        Rules
    ),
    findall(
        _{id: RID, category: Cat, rule: Rec, explanation: Expl},
        (   member(RID, ['R1','R2','R3','R4','R5']),
            rule_info(RID, Cat, Rec, Expl)
        ),
        BMIRules
    ),
    append(BMIRules, Rules, AllRules),
    reply_json_dict(_{rules: AllRules, total: 28}).

rule_info('R1', "bmi", "BMI < 17.0 → Moderate and severe thinness",
    "WHO: BMI below 17 indicates significant nutritional deficiency requiring medical attention.").
rule_info('R2', "bmi", "BMI < 18.5 → Underweight",
    "WHO: BMI below 18.5 indicates underweight status; increased caloric intake recommended.").
rule_info('R3', "bmi", "BMI 18.5–24.9 → Normal weight",
    "WHO: Healthy weight range; maintain through balanced diet and regular activity.").
rule_info('R4', "bmi", "BMI 25.0–29.9 → Overweight",
    "WHO: BMI above 25 increases risk of cardiovascular disease and diabetes.").
rule_info('R5', "bmi", "BMI ≥ 30.0 → Obese",
    "WHO: Obesity significantly increases chronic disease risk; weight management is critical.").

% ─── Helper Predicates ───────────────────────────────────

assert_conditions([]) :- !.
assert_conditions([H|T]) :-
    (H = "hypertension"   -> assertz(user_condition(hypertension))   ; true),
    (H = "diabetes"       -> assertz(user_condition(diabetes))       ; true),
    (H = "type2_diabetes" -> assertz(user_condition(type2_diabetes)) ; true),
    assert_conditions(T).

recs_to_json(Recs, Expls, JSON) :-
    findall(
        _{rule_id: RID, category: CatStr, recommendation: Rec, explanation: Expl},
        (   member(rec(RID, Cat, Rec), Recs),
            atom_string(Cat, CatStr),
            (   member(expl(RID, Expl), Expls)
            ->  true
            ;   Expl = "See WHO/SLNS guidelines."
            )
        ),
        JSON
    ).

bmi_category_label(moderate_thinness, "Moderate & Severe Thinness (BMI < 17.0)").
bmi_category_label(underweight,       "Underweight (BMI < 18.5)").
bmi_category_label(normal,            "Normal Weight (BMI 18.5–24.9)").
bmi_category_label(overweight,        "Overweight (BMI 25.0–29.9)").
bmi_category_label(obese,             "Obese (BMI ≥ 30.0)").

age_group_label(child,       "Child (5–17 years)").
age_group_label(adult,       "Adult (18–64 years)").
age_group_label(older_adult, "Older Adult (65+ years)").
age_group_label(unknown,     "Unknown Age Group").
