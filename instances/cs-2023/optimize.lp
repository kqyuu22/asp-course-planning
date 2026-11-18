% =====================================================================
% optimize.lp -- lexicographic objectives.
% opt(Objective, Priority): higher priority is optimized first.
% Comment out an opt/2 fact to switch that objective off, or change the
% number to reorder.  Objectives without an opt/2 fact cost nothing.
% =====================================================================
opt(terms,       5).   % graduate as early as possible
opt(cost,        4).   % cheapest plan
opt(extra_terms, 3).   % use as few summer terms as possible
opt(retake_asap, 2).   % do mandatory retakes early
% opt(preference,  1). % take prefer(E) electives, avoid avoid(E)
% opt(balance,     1). % even out regular loads (|credits - target|)

#const target_load = 18.
#defined prefer/1.  #defined avoid/1.

% Lowest number of semesters (shortest time): index of the last semester
#minimize{ M@P : max_planned(M), opt(terms, P) }.

% Cheapest plan (paid(I,A) is constant and therefore left out)
#minimize{ S@P,I,R : fee_u(I, R, S), opt(cost, P) }.   % in money_unit

% Fewest extra (summer) terms used
#minimize{ 1@P,I : planned(I), semester_type(I, extra), opt(extra_terms, P) }.

% Mandatory retakes as early as possible
#minimize{ I@P,E : must(E), in(retake(E, _), s(I)), opt(retake_asap, P) }.

% Student preferences: prefer(E). / avoid(E).  (facts in input.lp)
#minimize{ 1@P,E : prefer(E), not in(E, ok), opt(preference, P) ;
           1@P,E : avoid(E), in(E, s(I)), I > t, opt(preference, P) }.

% Balanced load: distance of each regular planned semester from target_load
#minimize{ |C - target_load|@P,I : planned(I), semester_type(I, regular),
                                   semester_credits(I, C), opt(balance, P) }.
