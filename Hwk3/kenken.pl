%Transposing Matrix FOR Col Rows
transposem([], []).
transposem([F|Fs], Ts) :-
transposem(F, [F|Fs], Ts).

transposem([], _, []).
transposem([_|Rs], Ms, [Ts|Tss]) :-
lists_firsts_rests(Ms, Ts, Ms1),
transposem(Rs, Ms1, Tss).

lists_firsts_rests([], [], []).
lists_firsts_rests([[F|Os]|Rest], [F|Fs], [Os|Oss]) :-
lists_firsts_rests(Rest, Fs, Oss).



kenken(N, C, T):-
length(C, X),
X > 0,
length(T, N),
distinct(N, T),
transposem(T, Transd),
distinct(N, Transd),
newkenken(N,C,T),
statistics.

kenken(N, [], T):-
length(T, N),
distinct_labeling(N, T),
transposem(T, Transd),
distinct_labeling(N, Transd),
statistics.

plain_kenken(N, C, T):-
length(C,X),
X > 0,
length(T, N),
plain_distinct(N, T),
transposem(T,LTrans1),
plain_newkenken(N,C,T),
diff(T),
diff(LTrans1),
statistics.

plain_kenken(N, [], T):-
length(T, N),
plain_distinct_labeling(N, T),
transposem(T, Transd),
plain_distinct_labeling(N, Transd),
statistics.

diff([]).
diff([H|Tail]):-
different(H),
diff(Tail).

different([]).
different([H|Tail]):-
\+(member(H,Tail)),
different(Tail).



distinct_labeling(_, []).
distinct_labeling(N, [H|Tail]):-
length(H, N),
fd_domain(H,1,N),
fd_all_different(H),
fd_labeling(H),
distinct_labeling(N, Tail).

plain_distinct_labeling(_, []).
plain_distinct_labeling(N, [H|Tail]):-
length(H, N),
check_range(H,N),
different(H),
plain_distinct_labeling(N, Tail).

check_range([],_).
check_range([A|B],N):-
range(A,1,N),
check_range(B,N).

range(Low, Low, _).
range(Out,Low,High) :- NewLow is Low+1, NewLow =< High,range(Out, NewLow, High).



distinct(_, []).
distinct(N, [H|Tail]):-
length(H, N),
fd_all_different(H),
distinct(N, Tail).

plain_distinct(_, []).
plain_distinct(N, [H|Tail]):-
length(H, N),
plain_distinct(N, Tail).



newkenken(_,[],_).
newkenken(N,[X|Y],T):-
test(X,T,N),
newkenken(N,Y,T).

plain_newkenken(_,[],_).
plain_newkenken(N,[X|Y],T):-
test(X,T,N),
plain_newkenken(N,Y,T).



test(+(A,B),T,N):-
add(A,B,0,T,N).
test(*(A,B),T,N):-
mul(A,B,1,T,N).
test(/(A,B,C),T,N):- 
div(A,B,C,T,N).
test(-(A,B,C),T,N):- 
sub(A,B,C,T,N).



plain_sub(A,B,C,T,N):-
B= BR-BC,
C=CR-CC,
plain_element(T,BR,BC,S1,N),
plain_element(T,CR,CC,S2,N),
plainSub(S1,S2,A).

sub(A,B,C,T,N):-
B= BR-BC,
C=CR-CC,
element(T,BR,BC,S1,N),
element(T,CR,CC,S2,N),
check_sub(S1,S2,A).



add(V,[],E,_,_):- V #= E.
add(V,[A|B],E,T,N):-
A = AR-AC,
element(T,AR,AC,S1,N),
S2 #= E + S1,
add(V,B,S2,T,N).

plain_add(V,[],E,_,_):- =(V, E).
plain_add(V,[A|B],E,T,N):-
A = AR-AC,
plain_element(T,AR,AC,S1,N),
S2 is E + S1,
plain_add(V,B,S2,T,N).



mul(V,[],E,_,_):- V #= E.
mul(V,[A|B],E,T,N):-
A=AR-AC,
element(T,AR, AC,S1,N),
S2 #= E * S1,
mul(V,B,S2,T,N).

plain_mul(V,[],E,_,_):- =(V, E).
plain_mul(V,[A|B],E,T,N):-
A=AR-AC,
plain_element(T,AR, AC,S1,N),
S2 is E * S1,
plain_mul(V,B,S2,T,N).



div(A,B,C,T,N):-
B=BR-BC,
C=CR-CC,
element(T,BR,BC,S1,N),
element(T,CR,CC,S2,N),
check_div(S1,S2,A).

plain_div(A,B,C,T,N):-
B=BR-BC,
C=CR-CC,
plain_element(T,BR,BC,S1,N),
plain_element(T,CR,CC,S2,N),
plainDivEqual(S1,S2,A).



element(T, R, C, Value,N):-
nth(R,T,V),
nth(C,V,Value),
fd_domain(Value,1,N),
fd_labeling(Value).

plain_element(T, R, C, Value,N):-
nth(R,T,V),
nth(C,V,Value),
range(Value,1,N).



check_sub(S1,S2,Result):-
Result #=S1-S2.
check_sub(S1,S2,Result):-
Result #=S2-S1.

plainSub(S1,S2,Result):-
E is S1-S2,
=(Result,E).
plainSub(S1,S2,Result):-
E is S2-S1,
=(Result,E).



check_div(S1,S2,Result):-
S2*Result #=S1.
check_div(S1,S2,Result):-
S1*Result #=S2.

plainDivEqual(S1,S2,Result):-
E is S2*Result,
=(E,S1).
plainDivEqual(S1,S2,Result):-
E is S1*Result,
=(E,S2).



kenken_testcase(
  6,
  [
   +(11, [1-1, 2-1]),
   /(2, 1-2, 1-3),
   *(20, [1-4, 2-4]),
   *(6, [1-5, 1-6, 2-6, 3-6]),
   -(3, 2-2, 2-3),
   /(3, 2-5, 3-5),
   *(240, [3-1, 3-2, 4-1, 4-2]),
   *(6, [3-3, 3-4]),
   *(6, [4-3, 5-3]),
   +(7, [4-4, 5-4, 5-5]),
   *(30, [4-5, 4-6]),
   *(6, [5-1, 5-2]),
   +(9, [5-6, 6-6]),
   +(8, [6-1, 6-2, 6-3]),
   /(2, 6-4, 6-5)
  ]
).
