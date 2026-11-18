% ==========================================
% Transcript / user input
% ==========================================

% Past attempts: grade(C, G), 0..4 scale. G >= 2 is a pass.
grade(mt1003, 1).      % failed compulsory -> required retake
grade(im1013, 1).      % failed elective
grade(co1007, 4).      % passed -> credits count, cannot be retaken
grade(la1007, 4).      % passed -> credits count, cannot be retaken

% Explicit request to retake a failed elective (electives are optional
% otherwise; failed compulsory courses are always retaken).
retake_requested(im1013).
