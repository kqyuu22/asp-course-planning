% =====================================================================
% translate.lp -- student history (input.lp) into sets and attempts
% =====================================================================
% taken(X, I)       attempt X in completed semester I (I <= t)
%                   X = E               first attempt of module E
%                   X = retake(E, K)    K-th retake of E (K = 1, 2, ...)
% map(grade, X, G)  grade G of attempt X (no grade = result pending)
% ---------------------------------------------------------------------
:- taken(_, I), I > t.
in(X, s(I)) :- taken(X, I).

% attempt X belongs to base module E
hist(E, E)            :- taken(E, _), in(E, m).
hist(retake(E, K), E) :- taken(retake(E, K), _), in(E, m).
base(X, E)            :- hist(X, E).

% attempt number: first attempt = 0, retake(E,K) = K
attempt_no(E, 0)            :- hist(E, E).
attempt_no(retake(E, K), K) :- hist(retake(E, K), E).

% sanity checks on the history
:- hist(retake(E, _), E), not hist(E, E).          % retake without a first attempt
:- hist(retake(E, K), E), K < 1.
:- taken(retake(E, K), I), taken(E, J), I <= J.      % retake must come later
unknown_course(X) :- taken(X, _), not hist(X, _).    % not in the curriculum (reported)

% ---------------------------------------------------------------------
% Offering: student-declared offer(E,I) and closures closed(E,I)
% ---------------------------------------------------------------------
offered(E, I) :- offer(E, I).
avail(E, I)   :- offered(E, I), not closed(E, I).
