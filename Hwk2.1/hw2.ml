type ('nonterminal, 'terminal) symbol =
	| N of 'nonterminal
	| T of 'terminal;;

(*Sentence, [
				(Sentence, [N Quiet]
				(Sentence, [N Grunt]
				(Sentence, [N Shout]
			]*)

(*Sentence, function 
			| Sentence -> 	[
							[N Quiet]
							[N Grunt] 	
							[N Shout]
							]*)

(*return a function that returns a list of what the symbol goes to*)
let rec new_grammar rules nonterminal = 
	match rules with
	| [] -> []
	| (symbol, rules)::t -> if rules = nonterminal (*if not terminal*)
							then rules::(new_grammar t nonterminal) (*then add it to the list*)  
							else new_grammar t nonterminal;; (*else dont add to list and recurse*)

let convert_grammar gram1 =
	match gram1 with
	| (symbol, rules) -> (symbol, (new_grammar rules));;





let rec follow_the_rhs rhs =
	if rhs = []
	then acceptor derivation frag
	else 


(* Return a matcher for gram *)
let parse_prefix gram =

