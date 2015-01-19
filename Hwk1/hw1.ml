let subset a b = 
	List.for_all (fun i -> List.mem i b) a;; 

let proper_subset a b =
	(subset a b) && not (subset b a);;

let equal_sets a b =
	(subset a b) && (subset b a);;

let rec set_diff a b =
	match a with
	| [] -> []
	| h::t ->
		if List.mem h b		(*If head is in b set*)
		then set_diff t b	(*cut off head and recurse*)
		else h::(set_diff t b);; (*keep head and recurse tail*)





let rec computed_fixed_point eq f x =
	if eq (f x) x
	then x
	else computed_fixed_point eq f (f x);; (*go into loop if not found*)

let take_away_one p =
	p-1;; 

let rec periodic_check f p x =
	if p = 0		(*Base Case*)
	then x
	else f (periodic_check f (take_away_one p) x);;

let rec computed_periodic_point eq f p x =
	if eq (periodic_check f p x) x
	then x 
	else computed_periodic_point eq f p (f x);;






type ('nonterminal, 'terminal) symbol =
	| N of 'nonterminal
	| T of 'terminal;;

let check_predicate_symbol symbol x =
	match x with
	| (pred, goesto) -> if pred = symbol 
						then true
						else false;;

let rec list_of_rh_symbol rhs rules = 
	match rhs with
	| [] -> true
	| h::t -> match h with				
				|N s -> if List.exists (check_predicate_symbol s) rules (*if 1st symbol can change to another symbol*)
						then list_of_rh_symbol t rules (*recurse with the next rh symbol*)
						else false
				|T _ -> list_of_rh_symbol t rules;; (*if terminal move with next rh symbol*)

let rec list_in_order nonblind_rules keeping_rules rules =
	match rules with
	| [] -> keeping_rules
	| h::t -> 	if List.mem h nonblind_rules (*if original rule is in the nonblind_rule*)
				then h::(list_in_order nonblind_rules keeping_rules t) (*"concatenate" the heads to return the list*)
				else list_in_order nonblind_rules keeping_rules t;; (*move on to next rule*)

let rec addTot_list rules tail_list =
	match rules with
	| [] -> tail_list
	| h::t -> match h with
				| (_,rhs) -> 	if list_of_rh_symbol rhs tail_list && not (List.mem h tail_list) 
								then h::(addTot_list t tail_list)
								else addTot_list t tail_list ;;

(*Expr, paired rules*)
(*Rules dont change, dont modify*)
let filter_blind_alleys g =
	match g with
	| (expr,rules) -> expr,list_in_order (computed_fixed_point equal_sets (addTot_list rules) []) [] rules;;

