% ---------- planning horizon -------------------------------------------
#const t = 1.     % completed semesters (history)
#const n = 12.    % last semester the plan may use (4 years x 3 terms)
enroll_part(1).   % semester 1 was a Fall term (1 = Fall, 2 = Spring, 3 = Summer)

% ---------- semester 1 (completed) -----------------------------------
taken((la1003; pe1003; co1023; ph1003; mt1003; co1005), 1).
% A retake in the history is written as an attempt term, e.g.
% taken(retake(mt1003, 1), 4).

% ---------- grade (map attempt to grade) --------------
% No grade = result pending (assumed passed), e.g.
% map(grade, mt1003, f).
% map(grade, retake(mt1003, 1), b_plus).

% ---------- voluntary retake (e.g. to raise the GPA) -----------------
% request(mt1003).

% ---------- major wish (optional; otherwise the solver picks one) ----
% desired_major(ai).

% ---------- offer/closed course --------------------
closed(mt1007, 2).

% ---------- Budget -----------------------------
budget(112000000).
