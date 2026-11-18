% =====================================================================
% school-independent extension of encoding.lp
%
% It only MODELS: terms, offering, grades and attempts, retakes, credit
% (the credited sets ok, ok(I), ok_before(I), ok_upto(I)), GPA,
% semester credits and a generic tuition engine.  It imposes no school
% rule.  School constraints: policy.lp.  Programme constraints:
% curriculum.lp.  Student: input.lp.
%
% Parameters it reads (declared by policy.lp):
%   terms_per_year, term_part_type(P,Type), retake_mode(M), max_attempts,
%   load_cap(Type,Cap), grade/grade_* facts, scale/3, default_scale/1,
%   fee rules (in(R,fee), map(fee_*,R,V)), money_unit
% =====================================================================

% optional relations (may have no facts)
#defined offer/2.  #defined closed/2.  #defined request/1.  #defined paid/2.
#defined budget/1.  #defined fee_one_rule_per_semester/0.  #defined min_gpa/2.
#defined offered_slot/2.
#defined equal/2.         % encoding.lp primitive, may be unused


% ----------- Semesters -------------------
% Student semester I (1st, 2nd, ... of their studies) -> calendar part P
% of the academic year.  enroll_part(Q): part of semester 1 (input.lp).
part(I, P) :- I = 1..n, enroll_part(Q), P = ((I + Q - 2) \ terms_per_year) + 1.
semester_type(I, Type) :- part(I, P), term_part_type(P, Type).


% ----------- Offering frequency ---------------------
% offered_slot(E,P): the course runs in term part P of every academic year.
% A course with no declaration at all is always offered.
offered(E, I) :- offered_slot(E, P), part(I, P), I = 1..n.

declared(E) :- offered_slot(E, _).   % system declared
declared(E) :- offer(E, _).          % student declared

offered(E, I) :- in(E, m), not declared(E), I = 1..n.   % default

% noff(I) = attempts whose module is not available in semester I;
% s(I) /\ noff(I) = {}
in(X, noff(I)) :- base(X, E), I = t+1..n, not avail(E, I).
empty(int(noff(I), s(I))) :- I = t+1..n.


% -------------- Attempt status: passed / failed / unknown -----------
status(X, passed)  :- hist(X, _), map(grade, X, G), grade(G), grade_passing(G).
status(X, failed)  :- hist(X, _), map(grade, X, G), grade(G), not grade_passing(G).
status(X, unknown) :- hist(X, _), not map(grade, X, _).     % pending result

% catch typos / undeclared grade constants
:- taken(X, _), map(grade, X, G), not grade(G).

% an attempt that yields credit (a pending result is assumed passed)
credit_ok(X) :- status(X, passed), map(grade, X, G), grade_earns_credit(G).
credit_ok(X) :- status(X, unknown).


% -------------- Attempts ------------------------------
% A module is attempted at most once as itself: s(I) and s(J) are
% disjoint.  A further attempt is the separate term retake(E,K).
empty(int(s(I), s(J))) :- I = 1..n, J = I+1..n.

% every module is an attempt of itself
base(E, E) :- in(E, m).

% attempt_count(E,N): recorded attempts;  last_attempt(E,X): latest one
attempt_count(E, N) :- hist(_, E), N = #count{ X : hist(X, E) }.
last_no(E, K)       :- hist(_, E), K = #max{ K2 : hist(X, E), attempt_no(X, K2) }.
last_attempt(E, X)  :- hist(X, E), attempt_no(X, K), last_no(E, K).
next_retake(E, K+1) :- last_no(E, K).

% Deciding attempt final_attempt(E,X), by retake_mode/1:
%   latest  : the latest attempt counts, even if it is worse
%   highest : the best graded attempt counts (ties -> latest of them)
% A pending latest attempt is always the deciding one.
final_attempt(E, X) :- last_attempt(E, X), status(X, unknown).
final_attempt(E, X) :- retake_mode(latest), last_attempt(E, X), not status(X, unknown).

graded_pts(E, X, P) :- hist(X, E), map(grade, X, G), default_scale(S), grade_points(S, G, P).
best_pts(E, P)      :- graded_pts(E, _, _), P = #max{ P2 : graded_pts(E, _, P2) }.
best_no(E, K)       :- best_pts(E, P), K = #max{ K2 : graded_pts(E, Y, P), attempt_no(Y, K2) }.
final_attempt(E, X) :- retake_mode(highest), last_attempt(E, L), not status(L, unknown),
                       best_no(E, K), attempt_no(X, K), hist(X, E).

:- hist(_, E), not final_attempt(E, _).     % exactly one retake_mode must be set
:- retake_mode(M1), retake_mode(M2), M1 != M2.

earned(E)        :- final_attempt(E, X), status(X, passed), credit_ok(X).
failed_course(E) :- final_attempt(E, X), status(X, failed).


% -------------- Retakes ------------------------------
% Candidates: failed modules, or an explicit request(E) on a module
% already attempted (e.g. to improve the GPA), within max_attempts.
retake_option(E, N) :- failed_course(E), next_retake(E, N),
                       attempt_count(E, A), A < max_attempts.
retake_option(E, N) :- request(E), hist(_, E), next_retake(E, N),
                       attempt_count(E, A), A < max_attempts.

{ in(retake(E, N), s(I)) } :- retake_option(E, N), I = t+1..n.

% a retake is an attempt of its base module and carries its credits
base(retake(E, N), E)   :- retake_option(E, N).
map(c, retake(E, N), C) :- retake_option(E, N), map(c, E, C).

% must(E): the retake has to be planned.  Which modules must be retaken
% is school policy (policy.lp); a student request always counts.
must(E) :- request(E), hist(_, E).
:- must(E), retake_option(E, N), not in(retake(E, N), s).
retake_blocked(E) :- must(E), not retake_option(E, _).   % attempts exhausted
:- retake_blocked(E).


% --------------- Credited modules ----------------------------------
% history: the deciding attempt, if it yields credit
in(E, ok(I)) :- final_attempt(E, X), taken(X, I), credit_ok(X).
% plan: a planned attempt is assumed passed
in(E, ok(I)) :- in(X, s(I)), base(X, E), I > t.

in(E, ok)           :- in(E, ok(I)).
in(E, ok_before(J)) :- in(E, ok(I)), I <  J, J = 1..n.   % credited before J
in(E, ok_upto(J))   :- in(E, ok(I)), I <= J, J = 1..n.   % credited by J


% ------------- Cumulative GPA (history only) -----------------
% GPA is scaled by 100 and rounded: gpa(gpa_4, 325) = 3.25
gpa_sel(E, X)        :- final_attempt(E, X), map(grade, X, _).
gpa_attempt(E, X, S) :- gpa_sel(E, X), map(grade, X, G), grade_in_gpa(S, G).

gpa_denominator(S, D) :- scale(S, _, _),
    D = #sum{ C, E : gpa_attempt(E, _, S), map(c, E, C) }.
gpa_numerator(S, N) :- scale(S, _, _),
    N = #sum{ C*P, E : gpa_attempt(E, X, S), map(grade, X, G),
                       grade_points(S, G, P), map(c, E, C) }.
gpa_d(S, D) :- gpa_denominator(S, D), D > 0.
gpa(S, G)   :- gpa_d(S, D), gpa_numerator(S, N), G = (2*N + D) / (2*D).
gpa(G) :- default_scale(S), gpa(S, G).

% report only: future grades are unknown
gpa_below_min(S, G, Min) :- gpa(S, G), min_gpa(S, Min), G < Min.
earned_credits(C) :- C = #sum{ Cr, E : earned(E), map(c, E, Cr) }.


% ------------- Planned semesters, semester credits -------------
planned(I)       :- in(_, s(I)), I > t.
later_planned(I) :- planned(I), planned(J), J > I.
max_planned(I)   :- planned(I), not later_planned(I).

% load_cap(Type, Cap): the most credits a semester of that type can hold.
% It is a hard bound, and it limits the counters below.
term_cap(I, Cap) :- semester_type(I, Ty), load_cap(Ty, Cap), I = t+1..n.
sum(s(I), c, bw, (0, Cap)) :- term_cap(I, Cap).

% Credit total of each future semester as bounded counters load_ge(I,K)
% ("at least K credits").  A C = #sum{...} assignment would be grounded
% once per reachable sum (hundreds of values, each with fee atoms, which
% also overflows clasp's 32-bit weights).
load_ge(I, K) :- term_cap(I, Cap), K = 1..Cap,
                 K #sum{ Cr, X : in(X, s(I)), map(c, X, Cr) }.
semester_credits(I, 0) :- term_cap(I, _), not load_ge(I, 1).
semester_credits(I, K) :- load_ge(I, K), not load_ge(I, K+1).


% ------------------------- Tuition engine -------------------------
% fee rule R: lower/upper credit bound, flat amount, rate, credit offset
fee_min_credit(R, 0) :- in(R, fee), not map(fee_min_credit, R, _).
fee_flat(R, 0)       :- in(R, fee), not map(fee_flat, R, _).
fee_rate(R, 0)       :- in(R, fee), not map(fee_rate, R, _).
fee_credits(R, 0)    :- in(R, fee), not map(fee_credits, R, _).

fee_min_credit(R, L) :- in(R, fee), map(fee_min_credit, R, L).
fee_flat(R, V)       :- in(R, fee), map(fee_flat, R, V).
fee_rate(R, V)       :- in(R, fee), map(fee_rate, R, V).
fee_credits(R, V)    :- in(R, fee), map(fee_credits, R, V).

fee_min_credit_ok(R, I) :- in(R, fee), I = t+1..n, semester_credits(I, C),
                           fee_min_credit(R, L), C >= L.
is_in_range(R, I) :- fee_min_credit_ok(R, I), semester_credits(I, C),
                     map(fee_max_credit, R, H), C <= H.
is_in_range(R, I) :- fee_min_credit_ok(R, I), not map(fee_max_credit, R, _).

applies(R, I) :- is_in_range(R, I), not map(fee_type, R, _).       % untyped
applies(R, I) :- is_in_range(R, I), map(fee_type, R, Ty), semester_type(I, Ty).

% fee = flat + rate * max(0, credits - offset); 0 credits costs nothing
charged(R, I, C-D) :- applies(R, I), semester_credits(I, C), C > 0, fee_credits(R, D), C > D.
charged(R, I, 0)   :- applies(R, I), semester_credits(I, C), C > 0, fee_credits(R, D), C <= D.
fee(I, R, S) :- charged(R, I, X), fee_flat(R, A), fee_rate(R, P), S = A + P*X.
fee(I, R, 0) :- applies(R, I), semester_credits(I, 0).

% the flag fee_one_rule_per_semester: exactly one rule per planned semester
:- fee_one_rule_per_semester, planned(I), #count{ R : applies(R, I) } != 1.

% Money in the solver is counted in units of money_unit: clasp adds up
% the weights of every *possible* fee atom, which overflows 32 bits in
% plain currency.  Fee amounts should be multiples of money_unit.
fee_u(I, R, S/money_unit) :- fee(I, R, S).

% budget/1 (input.lp), with recorded payments paid(I, Amount).
% (A constraint rather than fee_total(T) = #sum, which would be grounded
%  for every reachable sum.)
:- budget(B), #sum{ S,I,R : fee_u(I, R, S) ; A/money_unit,I : paid(I, A) } > B/money_unit.
