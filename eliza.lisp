(defun variable-p (x) "Is x a variable (a symbol beginning with '?')?" (and (symbolp x) (equal (char (symbol-name x) 0) #\?))) (defconstant fail nil "Indicates pat-match failure") (defconstant no-bindings '((t . t)) "Indicates pat-match success, with no variables") (defun get-binding (var bindings) "Find a (variable . value) pair in a binding list" (assoc var bindings)) (defun binding-val (binding) "Get the value part of a single binding" (cdr binding)) (defun lookup (var bindings) "Get the value part (for var) from a binding list" (binding-val (get-binding var bindings))) (defun extend-bindings (var val bindings) "Add a (var. value) pair to a binding list" (cons (cons var val) ;; Once we add a "real" binding, ;; we can get rid of the dummy no-bindings (if (eq bindings no-bindings) nil bindings))) (defun match-variable (var input bindings) "Does VAR match input? Uses (or updates) and returns bindings" (let ((binding (get-binding var bindings))) (cond ((not binding) (extend-bindings var input bindings)) ((equal input (binding-val binding)) bindings) (t fail)))) (defun starts-with (list x) "Is this a list whose first element is x?" (and (consp list) (eql (car list) x))) (defun segment-pattern-p (pattern) "Is this a segment matching pattern: ((?* var) . pat)" (and (consp pattern) (starts-with (car pattern) '?*))) (defun segment-match (pattern input bindings &optional (start 0)) "Match the segment pattern ((?* var) . pat) against input" (let ((var (cadr (car pattern))) (pat (cdr pattern))) (if (null pat) (match-variable var input bindings) ;; We assume that pat starts with a constant ;; In other words, a pattern can't have 2 consecutive vars (let ((pos (position (car pat) input :start start :test #'equal))) (if (null pos) fail (let ((b2 (pat-match pat (subseq input pos) (match-variable var (subseq input 0 pos) bindings)))) ;; If this match failed, try another longer one		(if (eq b2 fail) (segment-match pattern input bindings (+ pos 1)) b2))))))) (defun pat-match (pattern input &optional (bindings no-bindings)) "Match pattern against input in the context of the bindings" (cond ((eq bindings fail) fail) ((variable-p pattern) (match-variable pattern input bindings)) ((eql pattern input) bindings) ((segment-pattern-p pattern) (segment-match pattern input bindings)) ((and (consp pattern) (consp input)) (pat-match (cdr pattern) (cdr input) (pat-match (car pattern) (car input) bindings))) ((not (pat-match pattern input)) (princ `(Tell me more about ,input))) (t fail))) ;;now that we have a pattern matcher, let's create some rules (defun rule-pattern (rule) (car rule)) (defun rule-responses (rule) (cdr rule)) (defparameter *eliza-rules* '((((?* ?x) hello (?* ?y)) (How do you do. Please state your problem.) (How are you. Please tell me about your problem.)) (((?* ?x) hi (?* ?y)) (How do you do. Please state your problem.) (How are you. Please tell me about your problem.)) (((?* ?x) I want (?* ?y)) (What would it mean if you got ?y) (How can you get it) (Why do you want ?y) (Suppose you got ?y soon)) (((?* ?x) if (?* ?y)) (Do you really think its likely that ?y) (Do you wish that ?y) (What do you think about ?y) (Really-- if ?y)) (((?* ?x) no (?* ?y)) (Why not?) (You are being a bit negative) (Are you saying "NO" just to be negative?)) (((?* ?x) I was (?* ?y)) (Were you really?) (Perhaps I already knew you were ?y) (Why do you tell me you were ?y now?)) (((?* ?x) I feel (?* ?y)) (Do you often feel ?y ?)) (((?* ?x) I felt (?* ?y)) (What other feelings do you have ?) (Why did you feel so ?)))) (defun switch-viewpoint (words) "Change I to you and vice versa, and so on." (sublis '((I . you) (you . I) (me . you) (am . are)) words)) (defun mklist (x) "Return x if it is a list, otherwise (x)" (if (listp x) x (list x))) (defun mappend (fn lst) "Apply fn to each element of list and append the results" (apply #'append (mapcar fn lst))) (defun flatten (lst) "Append together elements (or lists) in the list." (mappend #'mklist lst)) (defun random-elt (choices) "Choose an element from a list at random" (elt choices (random (length choices)))) (defun punctuation-p (char) (find char ".,;:'!?#-()\\\"")) (defun read-line-no-punct () "Read an input line. Ignore punctuation" (read-from-string (concatenate 'string "(" (substitute-if #\space #'punctuation-p (read-line)) ")"))) (defun use-eliza-rules (input) "Find some rule with which to transform the input." (some #'(lambda (rule) (let ((result (pat-match (rule-pattern rule) input))) (if (not (eq result fail)) (sublis (switch-viewpoint result) (random-elt (rule-responses rule)))))) *eliza-rules*)) (defun print-with-spaces (lst) (format t "~{~a ~}" lst)) (defun eliza () "Respond to user input using pattern matching rules" (loop (print 'eliza>) (let* ((input (read-line-no-punct)) (response (flatten (use-eliza-rules input)))) (print-with-spaces response)))) 