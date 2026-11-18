% ---------------- output ----------------
#show.
#show plan(I, X)            : in(X, s(I)), I > t.
#show major(M)              : in(M, major_sel).
#show qualified/1.
#show credits(I, C)         : semester_credits(I, C), planned(I).
#show term(I, Ty)           : semester_type(I, Ty), planned(I).
#show fee(I, S)             : fee(I, _, S), planned(I).
#show last_semester(M)      : max_planned(M).
#show must/1.
#show gpa/2.
#show gpa_below_min/3.
#show earned_credits/1.
#show unknown_course/1.
