brew install gnu-prolog --use-gcc
gplc to compile

3x3 T
[
	[1,2,3],
	[1,2,4],
	[1,2,5]
]

Transposing Matrix
transposem(_,_)
transposem(_,_,_)
lists_firsts_rests(_,_,_)

length
Built in function for finding length of list
Make sure length is > 0


Running this query shows that it ran in about 3ms while the plain kenken version was slower.
kenken(
  4,
  [
   +(6, [1-1, 1-2, 2-1]),
   *(96, [1-3, 1-4, 2-2, 2-3, 2-4]),
   -(1, 3-1, 3-2),
   -(1, 4-1, 4-2),
   +(8, [3-3, 4-3, 4-4]),
   *(2, [3-4])
  ],
  T
), write(T), nl, fail. 