% =====================================================================
% policy.lp -- school (HCMUT) regulations: parameters for
% extended-regulations.lp and the school's constraints, stated with the
% set facts of encoding.lp where possible.
% =====================================================================

% Flat amount fee
#const regular_flat_fee = 13750.
#const discount_3 = 45. % 45 percent
#const discount_2 = 30.
#const discount_1 = 15.


% ------------- Academic year ------------------
#const terms_per_year = 3.
% 2 regular terms (Fall, Spring) and one extra term (Summer)
term_part_type(1, regular).
term_part_type(2, regular).
term_part_type(3, extra).

% 0 = regular terms only, 1 = allow summer/extra terms
#const allow_extra_terms = 1.
:- allow_extra_terms == 0, planned(I), semester_type(I, Type), Type != regular.


% ------------- Semester load -----------------
#const semester_min_load = 12.
#const semester_max_load = 21.
% Extra semester load is unrestricted (999); lower it to cap summers.
% (The cap used is never above the degree total.)
#const extra_max_load = 999.
% 1 = the final semester may be under semester_min_load
#const last_term_underload = 1.
% 0 = no empty regular semester between t+1 and the last planned one
#const allow_regular_gap = 0.

load_cap(regular, semester_max_load).
load_cap(extra, X) :- X = #min{ extra_max_load ; U : map(u, total_degree, U) }.

% minimum load of a planned regular semester
sum(s(I), c, geq, semester_min_load) :- planned(I), semester_type(I, regular),
                                        not underload_ok(I).
underload_ok(I) :- last_term_underload == 1, max_planned(I).

:- allow_regular_gap == 0, semester_type(I, regular), I > t,
   max_planned(M), I < M, not planned(I).


% ------------- Prerequisites / corequisites ----------
% prereq(E,P) (tien quyet): P credited in a semester strictly before E
% coreq(E,P)  (song hanh) : P credited before E or in the same semester
% Facts are in curriculum.lp; checked for planned semesters only.
#defined prereq/2.  #defined coreq/2.
in(P, need_ok_before(I)) :- prereq(E, P), in(X, s(I)), base(X, E), I > t.
in(P, need_ok_upto(I))   :- coreq(E, P),  in(X, s(I)), base(X, E), I > t.

subseteq(need_ok_before(I), ok_before(I)) :- I = t+1..n.
subseteq(need_ok_upto(I),   ok_upto(I))   :- I = t+1..n.


% -------------- Grade scale ------------------
grade(a_plus).
grade_symbol(a_plus, "A+").
grade_passing(a_plus).
grade_earns_credit(a_plus).
grade_points(gpa_4, a_plus, 400).
grade_in_gpa(gpa_4, a_plus).
grade_points(a_plus, 400).
grade_in_gpa(a_plus).
grade_points(gpa_10, a_plus, 975).
grade_in_gpa(gpa_10, a_plus).
grade(a).
grade_symbol(a, "A").
grade_passing(a).
grade_earns_credit(a).
grade_points(gpa_4, a, 400).
grade_in_gpa(gpa_4, a).
grade_points(a, 400).
grade_in_gpa(a).
grade_points(gpa_10, a, 900).
grade_in_gpa(gpa_10, a).
grade(b_plus).
grade_symbol(b_plus, "B+").
grade_passing(b_plus).
grade_earns_credit(b_plus).
grade_points(gpa_4, b_plus, 350).
grade_in_gpa(gpa_4, b_plus).
grade_points(b_plus, 350).
grade_in_gpa(b_plus).
grade_points(gpa_10, b_plus, 825).
grade_in_gpa(gpa_10, b_plus).
grade(b).
grade_symbol(b, "B").
grade_passing(b).
grade_earns_credit(b).
grade_points(gpa_4, b, 300).
grade_in_gpa(gpa_4, b).
grade_points(b, 300).
grade_in_gpa(b).
grade_points(gpa_10, b, 750).
grade_in_gpa(gpa_10, b).
grade(c_plus).
grade_symbol(c_plus, "C+").
grade_passing(c_plus).
grade_earns_credit(c_plus).
grade_points(gpa_4, c_plus, 250).
grade_in_gpa(gpa_4, c_plus).
grade_points(c_plus, 250).
grade_in_gpa(c_plus).
grade_points(gpa_10, c_plus, 675).
grade_in_gpa(gpa_10, c_plus).
grade(c).
grade_symbol(c, "C").
grade_passing(c).
grade_earns_credit(c).
grade_points(gpa_4, c, 200).
grade_in_gpa(gpa_4, c).
grade_points(c, 200).
grade_in_gpa(c).
grade_points(gpa_10, c, 600).
grade_in_gpa(gpa_10, c).
grade(d_plus).
grade_symbol(d_plus, "D+").
grade_passing(d_plus).
grade_earns_credit(d_plus).
grade_points(gpa_4, d_plus, 150).
grade_in_gpa(gpa_4, d_plus).
grade_points(d_plus, 150).
grade_in_gpa(d_plus).
grade_points(gpa_10, d_plus, 525).
grade_in_gpa(gpa_10, d_plus).
grade(d).
grade_symbol(d, "D").
grade_passing(d).
grade_earns_credit(d).
grade_points(gpa_4, d, 100).
grade_in_gpa(gpa_4, d).
grade_points(d, 100).
grade_in_gpa(d).
grade_points(gpa_10, d, 450).
grade_in_gpa(gpa_10, d).
grade(f).
grade_symbol(f, "F").
grade_points(gpa_4, f, 0).
grade_in_gpa(gpa_4, f).
grade_points(f, 0).
grade_in_gpa(f).
grade_points(gpa_10, f, 200).
grade_in_gpa(gpa_10, f).

% ------------ Numeric grade scale
% ----- 4-scale
scale(gpa_4, 0, 400).
scale_precision(gpa_4, 2).
% ----- 10-scale
scale(gpa_10, 0, 1000).
scale_precision(gpa_10, 2).

% Set default scale
default_scale(gpa_10).

% -------------- Retake ------------------------
% A failed compulsory module must be retaken
must(E) :- failed_course(E), in(E, comp).
% Retake mode: highest grade / latest attempt  (exactly one)
retake_mode(highest).
% retake_mode(latest).
% Maximum number of attempts per module (first attempt included)
#const max_attempts = 3.

% --------------- Graduation requirements ----------------------

graduation_requirement(min_total_credits, 128).
graduation_requirement(min_cumulative_gpa, 250).
% Unify the credit bound of total degree from graduation requirement
map(l, total_degree, X) :- graduation_requirement(min_total_credits, X).
map(u, total_degree, X) :- graduation_requirement(min_total_credits, X).
min_gpa(gpa_4, X) :- graduation_requirement(min_cumulative_gpa, X).

% credits of the whole degree:  L <= sum_{E in ok} c(E) <= U
sum(int(ok, m), c, bw, (L, U)) :- map(l, total_degree, L), map(u, total_degree, U).

% redundant (implied by the line above) but helps the solver: the future
% semesters supply at least the credits that the degree still needs
:- map(l, total_degree, L),
   #sum{ K,I : semester_credits(I, K), I > t ; Cr,E : in(E, ok(I)), I <= t, map(c, E, Cr) } < L.


% ---------------- External requirements ------------------------


% ---------------- Tuition fee ----------------------------------
% ----------- Two fee types: regular-semester fees and extra-semester fees.
in((regular_fee_high; regular_fee_mid;
    regular_fee_low_1; regular_fee_low_2; regular_fee_low_3), regular_fee).
in(extra_semester_fee, extra_fee).

% All fee rules are still in the `fee` domain.
in(R, fee) :- in(R, regular_fee).
in(R, fee) :- in(R, extra_fee).

% Map each fee rule to the semester type it may be charged in.
% Values `regular` / `extra` match semester_type/2.
map(fee_type, R, regular) :- in(R, regular_fee).
map(fee_type, R, extra)   :- in(R, extra_fee).

fee_one_rule_per_semester.

% money is counted in units of 100 VND inside the solver
#const money_unit = 100.



% semester credits in [0,6]
map(fee_min_credit, regular_fee_low_3, 0).
map(fee_max_credit, regular_fee_low_3, 6).
map(fee_flat, regular_fee_low_3, 8662500).


% semester credits in [7,9]
map(fee_min_credit, regular_fee_low_2, 7).
map(fee_max_credit, regular_fee_low_2, 9).
map(fee_flat, regular_fee_low_2, 11025000).

% semester credits in [10,12]
map(fee_min_credit, regular_fee_low_1, 10).
map(fee_max_credit, regular_fee_low_1, 12).
map(fee_flat, regular_fee_low_1, 13387500).

% semester credit in [13, 18]
map(fee_min_credit, regular_fee_mid, 13).
map(fee_max_credit, regular_fee_mid, 18).
map(fee_flat, regular_fee_mid, 15750000).

% semester credit in [19, inf]
map(fee_min_credit, regular_fee_high, 19).
map(fee_max_credit, regular_fee_high, 999).
map(fee_flat, regular_fee_high, 15750000).
map(fee_credits, regular_fee_high, 18). % Credit offset is 18
map(fee_rate, regular_fee_high, 940000).

% extra semester fee
map(fee_min_credit, extra_semester_fee, 0).
map(fee_max_credit, extra_semester_fee, 999).
map(fee_rate, extra_semester_fee, 1690000).

% ------------------------------------------------------------------
% Milestone thresholds (credits accumulated before the course)
% ------------------------------------------------------------------
% CO3335: 65% of 128 -> 84
milestone(co3335, 84).
% CO4029: 70% of 128 -> 90
milestone(co4029, 90).
% CO4337: 85% of 128 -> 109
milestone(co4337, 109).