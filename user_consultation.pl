% Expert System Shell based on Luger

solve(Goal,CF) :-
    print_instructions,
    retractall(known(_,_)),
    solve(Goal,CF,[],20).

print_instructions :-
    nl, write('You will be asked a series of queries.'), nl,
    write('Your response must be either:'),
    nl, write('a. A number between -100 and 100 representing'), nl,
    write(' your confidence in the truth of the query'), nl,
    write('b. why'),
    nl, write('c. how(X), where X is a goal'),nl.

% solve(+,?,+,+)
solve(Goal,CF,_,Threshold) :-
    known(Goal,CF),!,
    above_threshold(CF,Threshold).

solve(\+ Goal,CF,Rules,Threshold) :- !,
    invert_threshold(Threshold,New_threshold),
    solve(Goal,CF_goal,Rules,New_threshold),
    negate_cf(CF_goal,CF).

solve((Goal1,Goal2),CF,Rules,Threshold) :- !,
    solve(Goal1,CF1,Rules,Threshold),
    above_threshold(CF1,Threshold),
    solve(Goal2,CF2,Rules,Threshold),
    above_threshold(CF2,Threshold),
    and_cf(CF1,CF2,CF).

solve(Goal,CF,Rules,Threshold) :-
    rule((Goal:-(Premise)),CF_rule),
    solve(Premise,CF_premise,[rule((Goal:-Premise),CF_rule)|Rules],Threshold),
    rule_cf(CF_rule,CF_premise,CF),
    above_threshold(CF,Threshold).

solve(Goal,CF,_,Threshold) :-
    rule(Goal,CF),
    above_threshold(CF,Threshold).

solve(Goal,CF,Rules,Threshold) :-
    askable(Goal),
    askuser(Goal,CF,Rules),!,
    assert(known(Goal,CF)),
    above_threshold(CF,Threshold).

above_threshold(CF,T) :- T>=0, CF>=T.
above_threshold(CF,T) :- T<0, CF=<T.

invert_threshold(Threshold,New_threshold) :-
    New_threshold is -1 * Threshold.

negate_cf(CF,Negated_CF) :-
    Negated_CF is -1 * CF.

and_cf(A,B,A) :- A =< B.
and_cf(A,B,B) :- B < A.

rule_cf(CF_rule,CF_premise,CF) :-
    CF is (CF_rule * CF_premise / 100).

askuser(Goal,CF,Rules) :-
    nl,write('Query : '),
    write(Goal), write(' ? '),
    read(Ans),
    respond(Ans,Goal,CF,Rules).

% respond(+, +, ?, +) ------------

respond(CF,_,CF,_) :-
    number(CF), CF=<100, CF>= -100. % no response issued because user enters a valid CF

respond(why,Goal,CF,[Rule|Rules]) :-
    nl, write_rule(Rule),
    askuser(Goal,CF,Rules).

respond(why,Goal,CF,[]) :-
    nl, write('Back to top of rule stack.'), nl, askuser(Goal,CF,[]).

respond(how(X),Goal,CF,Rules) :-
    build_proof(X,CF_X,Proof), !,
    nl, write('The goal '), write(X),
    write(' was concluded with certainty '), write(CF_X), write('.'), nl, nl, write('The proof of this is:'), nl,
    write_proof(Proof,0), nl,
    askuser(Goal,CF,Rules).

respond(how(X),Goal,CF,Rules) :-
    write('The truth of '), write(X), nl,
    write('is not yet known.'), nl,
    askuser(Goal,CF,Rules).

respond(_,Goal,CF,Rules):-
    write_rule('Unrecognized response.'), nl,
    askuser(Goal,CF,Rules).

% ------------

% build_proof(+,?,?) ------------

build_proof(Goal,CF,(Goal,CF:-given)) :-
    known(Goal,CF), !.
build_proof(\+ Goal, CF, \+ Proof) :- !,
    build_proof(Goal,CF_goal,Proof), negate_cf(CF_goal,CF).

build_proof((Goal1,Goal2),CF,(Proof1,Proof2)) :-
    build_proof(Goal1,CF1,Proof1),
    build_proof(Goal2,CF2,Proof2), and_cf(CF1,CF2,CF).

build_proof(Goal,CF,(Goal,CF:-Proof)) :-
    rule((Goal:-Premise),CF_rule),
    build_proof(Premise,CF_premise,Proof),
    rule_cf(CF_rule,CF_premise,CF).

build_proof(Goal,CF,(Goal,CF:-fact)) :- rule(Goal,CF).

% ------------

write_rule(rule((Goal:-(Premise)),CF)) :-
    write('I am trying to prove the following rule:'), nl, write(Goal),
    write(':-'), nl,
    write_premise(Premise),
    write('CF = '), write(CF), nl.

write_rule(rule(Goal,CF)) :-
    write('I am trying to prove the following goal:'), nl, write(Goal),
    write('CF = '), write(CF), nl.

write_premise((Premise1,Premise2)) :- !,
    write_premise(Premise1), write_premise(Premise2).

write_premise(\+ Premise) :- !,
    write(' '), write(not), write(' '), write(Premise), nl. write_premise(Premise) :- !,
    write(' '), write(Premise), nl.

% write_proof(+,+)
write_proof((Goal,CF:-given),Level) :-
    indent(Level), write(Goal), write(' CF='), write(CF), write(' was given by the user'), nl, !.

write_proof((Goal,CF:-fact),Level) :-
    indent(Level), write(Goal), write(' CF='), write(CF), write(' was a fact in the KB'), nl, !.

write_proof((Goal,CF:-Proof),Level) :-
    indent(Level), write(Goal), write(' CF='), write(CF), write(':-'), nl, New_level is Level + 1,
    write_proof(Proof,New_level), !.

write_proof(\+ Proof,Level) :-
    indent(Level), write((not)), nl,
    New_level is Level + 1,
    write_proof(Proof,New_level), !.

write_proof((Proof1,Proof2),Level) :-
    write_proof(Proof1,Level), write_proof(Proof2,Level), !.

% ruleset ------------
indent(0).
indent(X):-
    write(''), X_new is X - 1, indent(X_new). 
    
rule((recommend(Advice):- 
    (sport(X), recommend(X, Advice))), 100).

% rules for sport ------------
rule((sport(sprinting) :- 
    (age_between_13_17, physique(runner), capability(speed), health_condition(healthy))),100).

rule((sport(middletolong_distance) :- 
    (age_between_13_17, physique(runner), capability(endurance), health_condition(healthy))), 100).

rule((sport(throwing) :- 
    (age_between_13_17, physique(thrower), capability(strong_arms), health_condition(healthy))), 100).

rule((sport(jumping) :- 
    (age_between_13_17, physique(jumper), capability(jump_high), health_condition(healthy))), 100).
% ------------

% rules for a persons health condition ------------
rule((health_condition(healthy) :- 
    (xray, ecg, cvc, \+ covid, \+ mumps, \+ chicken_pox)), 100).
% ------------

% rules for physiques
rule((physique(runner) :- 
    (characteristic(slender), characteristic(tall))), 100).

rule((physique(jumper) :- 
    (characteristic(long_legs), characteristic(tall),  characteristic(slender))), 100).

rule((physique(thrower) :-  
    (characteristic(tall), characteristic(muscular), characteristic(thick))), 100).
% ------------

% rules for capability ------------
rule((capability(endurance):- 
    (\+gender(female), gender(male), can_run_800m_in_120s_to_155s)), 100).

rule((capability(endurance):- 
    (\+gender(male),gender(female), can_run_800m_in_145s_to_210s)), 100).

rule((capability(speed) :-  
    (\+gender(female),gender(male), can_run_30m_within_6s)), 100).

rule((capability(speed) :-  
    (\+gender(male),gender(female), can_run_30m_within_7s)), 100).

rule((capability(strong_arms) :- 
    (\+gender(female),gender(male), can_throw_700g_to_1500g)), 100).

rule((capability(strong_arms) :- 
    (\+gender(male),gender(female), can_throw_500g_to_1000g)), 100).

rule((capability(jump_high) :- 
    (\+gender(female),gender(male), can_jump_high)), 100).

rule((capability(jump_high) :- 
    (\+gender(male),gender(female), can_jump_high)), 100).
% ------------

% rules for characteristics ------------
rule((characteristic(tall) :- 
    (height_above_170)), 100). 

rule((characteristic(long_legs) :-  
    (longlegs)), 100).

rule((characteristic(slender) :-  
    (\+bmi_between_21_24, bmi_between_18_21)), 100).

rule((characteristic(thick) :- 
    (\+bmi_between_18_21, bmi_between_21_24)), 100).

rule((characteristic(muscular) :-
    (is_muscular)), 100).
% ------------

% rules for recommend ------------
rule(recommend(sprinting, 'Recommended for sprinting events'),100).
rule(recommend(middletolong_distance, 'Recommended for middle to long distance running events'),100).
rule(recommend(throwing, 'Recommended for throwing events'),100).
rule(recommend(jumping, 'Recommended for jumping events'),100).
% ------------

% askables
askable(gender(_)).
askable(height_above_170).
askable(bmi_between_18_21).
askable(bmi_between_21_24).
askable(longlegs).
askable(is_muscular).
askable(can_run_800m_in_120s_to_155s).
askable(can_run_800m_in_145s_to_210s).
askable(can_run_30m_within_6s).
askable(can_run_30m_within_7s).
askable(can_throw_500g_to_1000g).
askable(can_throw_700g_to_1500g).
askable(can_jump_high).
askable(age_between_13_17).
askable(xray).
askable(ecg).
askable(cvc).
askable(mumps).
askable(chicken_pox).
askable(covid).

% INSTRUCTIONS -----

% instructions detailing how the user is to answer the 'characteristics'
% section
characteristics_instructions :-
   write("Answer the following questions to your best ability. Please answer with an float."),
   nl,
   write("If you are unsure of your answer, please provide an estimate."),
   nl.

% instructions detailing how the user is to answer the 'capabilities' section
capabilities_and_characteristic_instructions :-
    write("Answer the following questions to your best ability. Please answer with a number between -100 and 100 representing how confident you are in these skills."),
    nl.

% instructions detailing how the user is to answer the 'health' section
health_instructions :-
    write("Answer the following questions to your best ability. Please answer with either -100 or 100. -100 being false, 100 being true."),
    nl.

% -----

% PROMPTING -----
characteristics_prompt(Characteristic, Characteristic_Prompt) :-
    write(Characteristic_Prompt),
    write(": "),
    read(Characteristic_Level),
    assert(characteristic(Characteristic, Characteristic_Level)).

capabilities_prompt(Capability, Capability_Prompt) :-
    write(Capability_Prompt),
    write(": "),
    read(Capability_Level),
    assert(capability(Capability, Capability_Level)).

health_prompt(Health_Indicator, Health_Prompt) :-
    write(Health_Prompt),
    write(": "),
    read(Health_Indicator_Level),
    assert(health(Health_Indicator, Health_Indicator_Level)).


% -----


% look to reformat this to adhere to backward chaining
% menu :- 
%    clear,
%   characteristics_instructions,
%   characteristics_prompt(height, 'What is your height (in centimeters)')
%   characteristics_prompt(bmi, 'What is your BMI?')
%   characteristics_prompt(leg_length, 'What is your leg length (in centimeters)?')
%   characteristics_prompt(lift_weight, 'What weight can you consistently lift (in kg)?')
%
%   capabilities_instructions,
%   capabilities_prompt(run_distance, 'At what time (in seconds) can you complete an 800m run?')
%   capabilities_speed(run_time, 'At what time (in seconds) can you complete an 30m dash?')
%   capabilities_speed(throw_distance, 'What weight (in grams) can you throw?')
%   capabilities_prompt(jump_height, 'How high can you jump (in meters)?')
%
%   health_instructions,
%   health_prompt(asthma, 'Do you have any record of having asthma?')
%
%   save.
%

