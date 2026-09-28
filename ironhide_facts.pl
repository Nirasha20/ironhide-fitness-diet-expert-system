% ============================================================
%  IronHide Expert System — Dynamic Facts
%  Source: WHO Physical Activity Guidelines 2020 &
%          Dietary Reference Table (user-uploaded)
% ============================================================

:- module(ironhide_facts, []).

% Dynamic declarations — asserted at runtime per user session
:- dynamic user_age/1.          % user_age(Years)
:- dynamic user_weight/1.       % user_weight(Kg)
:- dynamic user_height/1.       % user_height(Cm)
:- dynamic user_bmi/1.          % user_bmi(Value)  — derived
:- dynamic user_gender/1.       % user_gender(male|female)
:- dynamic user_condition/1.    % user_condition(hypertension|diabetes|type2_diabetes|none)
:- dynamic user_goal/1.         % user_goal(lose_weight|gain_weight|maintain|improve_health)

% Derived intermediate facts
:- dynamic bmi_category/1.      % bmi_category(moderate_thinness|underweight|normal|overweight|obese)
:- dynamic age_group/1.         % age_group(child|adult|older_adult)
:- dynamic has_condition/1.     % has_condition(hypertension|diabetes|type2_diabetes)
:- dynamic wants_additional_health_benefits/0.
