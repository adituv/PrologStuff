%----------------------------------------------------------------%
% Prolog implementation of Haskell's Prelude.                    %
%----------------------------------------------------------------%
:-module(prelude_,[id/2,const/3,compose/4,flip/4,'$'/3,until/4,
		  map/3,append/3,filter/3,head/2,last/2,tail/2,
	          init/2,null/1,null/2,len/2,nth/3,reverse/2,
		  foldl/4,foldl1/3,foldr/4,foldr1/3,and/1,and/2,
		  or/1,or/2,any/2,any/3,all/2,all/3,sum/2,
		  product/2,concat/2,concatMap/3,maximum/2,
		  minimum/2,scanl/4,scanl1/3,scanr/4,scanr1/3,
		  iterate/3,repeat/2,replicate/3,replicate_/3,
		  cycle/2,take/3,drop/3,splitAt/4,takeWhile/3,
		  dropWhile/3,span/4,break/4,elem/2,elem/3,
		  notElem/2,notElem/3,lookup/3,zip/3,zip3/4,
		  zipWith/4,zipWith3/5,unzip/3,unzip3/4]).

id(X,X).
const(X,_,X).
compose(G,F,X,Y) :-
	$(F,[X],Tmp),
	$(G,[Tmp],Y).

flip(F,X,Y,Z) :- $(F,[Y,X],Z).

% Originally low-precedence to manipulate operand binding.  Now
% more useful as a general shorthand for call a function
'$'(F,List,R) :-
	append([F|List],[R],X),
	Funct =.. X,
	call(Funct).

until(P,_,X,X) :-
	$(P,[],X),!.
until(P,F,X,Z) :-
	$(F,[X],T),
	until(P,F,T,Z).

% asTypeOf doesn't really work as far as I know.  Omitting it
% Not bothering with error either, or undefined
% And I don't understand $!...

% Mapping the empty list is an id op.
map(_,[],[]) :- !.
map(F,[X|Xs],[Y|Ys]) :-
	$(F,[X],Y),
	map(F,Xs,Ys).

append([],A,A).
append([H|T],A,[H|R]) :- append(T,A,R).

filter(_,[],[]) :- !.
filter(P,[X|Xs],[X|Ys]) :-
	$(P,[],X),!,
	filter(P,Xs,Ys).
filter(P,[_|Xs],Ys) :- filter(P,Xs,Ys).

% Kinda pointless, but here for completion
head([H|_], H).

last([X],X) :- !.
last([_|T],X) :- last(T,X).

% Again kinda redundant
tail([_|T],T).

init([X,_],[X]) :- !.
init([H|T],[H|X]) :- init(T,X).

% Once again, pretty much redundant.
null([]).
null([],true) :- !.
null(_,false).

% Haskell version 'length'.  Here because of name
% conflict with builtin
len([],0).
len([_|T],N) :- len(T,M), N is M+1.

% Haskell version '(!!)'.  Here 'nth' as in ML because
% I want to stay with the usual function syntax
nth([H|_],0,H).
nth([_|T],N,X) :- M is N-1, nth(T,M,X).

% VERY inefficient.  Better way to do this?
reverse([],[]).
reverse([H|T],X) :- reverse(T,Y), append(Y,[H],X).

% foldl?
foldl(F, Start, Xs, Z) :- foldl1(F, [Start|Xs], Z).

foldl1(_,[X],X) :- !.
foldl1(F,[X1,X2|Xs],Z) :-
	$(F,[X1,X2],Y),
	foldl1(F,[Y|Xs],Z).

foldr(_, Start, [], Start) :- !.
foldr(F, Start, [X|Xs], Acc) :-
	foldr(F, Start, Xs, Ac2),
	$(F,[X,Ac2],Acc).

foldr1(F, [X|Xs], Acc) :- foldr(F, X, Xs, Acc).

boolAnd(true,true,true) :- !.
boolAnd(_,_,true).

and(Xs) :- foldl1(boolAnd,Xs,true).
and(Xs,true) :- and(Xs), !.
and(_,false).

boolOr(false,false,false) :- !.
boolOr(_,_,true).

or(Xs) :- foldl1(boolOr,Xs,true).
or(Xs,true) :- or(Xs), !.
or(_,false).

any(P,Xs) :- map(P,Xs,Ys),or(Ys).
any(P,Xs,true) :- any(P,Xs), !.
any(_,_,false).
all(P,Xs) :- map(P,Xs,Ys),and(Ys).
all(P,Xs,true) :- all(P,Xs).
all(_,_,false).

intAdd(X,Y,Z) :- Z is X+Y.

sum(Xs,S) :- foldl1(intAdd,Xs,S).

intProd(X,Y,Z) :- Z is X*Y.

product(Xs,S) :- foldl1(intProd,Xs,S).

concat(Xss,Xs) :- foldl1(append,Xss,Xs).

concatMap(F,Xss,Xs) :-
	map(F,Xss,Yss),
	concat(Yss,Xs).

max(X,Y,X) :- X > Y, !.
max(X,Y,Y) :- Y >= X. % Not necessary for valid arguments, but
                      % prevents incomparables being accepted
min(X,Y,X) :- X < Y, !.
min(X,Y,Y) :- X >= Y.

maximum(Xs,X) :- foldl1(max,Xs,X).
minimum(Xs,X) :- foldl1(min,Xs,X).

scanl(F, S, Xs, Acc) :- scanl1(F,[S|Xs],Acc).

scanl1(_,[X],[X]) :- !.
scanl1(F,[X1,X2|Xs],[X1|Z]) :-
	$(F,[X1,X2],Y),
	scanl1(F,[Y|Xs],Z).

scanr(_,S,[],[S]) :- !.
scanr(F,S,[X|Xs],[Y,Z|Zs]) :-
	scanr(F,S,Xs,[Z|Zs]),
	$(F,[X,Z],Y).

scanr1(F,[X|Xs],Zs) :- scanr(F,X,Xs,Zs).

% Backtracking iterate function F over starting value X
iterate(_,X,X).
iterate(F,X,Z) :-
	iterate(F,X,Y),
	$(F,[Y],Z).

% Requires occurs check to be off.  Creates an infinite list
% of all X's.
repeat(X,Y) :- Y = [X|Y].

% Easy way with occurs check off.  Take the first N elements
% of the infinite list of all X's.
replicate_(N,X,Y) :- Z = [X|Z], take(N,Z,Y).

% Harder, standard recursive way.
replicate(0,_,[]) :- !.
replicate(N,X,[X|Y]) :- M is N-1, replicate(M,X,Y).

% Create a list that is a repetition of all elements in the list
% infinitely
cycle(Xs,Ys) :- append(Xs,P,Ys), P = Ys.

take(0,_,[]).
take(N,[H|T],[H|X]) :- M is N-1, take(M,T,X).

drop(0,X,X).
drop(N,[_|T],X) :- M is N-1, drop(M,T,X).

splitAt(0,X,[],X) :- !.
splitAt(N,_,_,_) :- N < 0, !, fail.
splitAt(N,[X|Xs],[X|Ls],Rs) :- M is N-1, splitAt(M,Xs,Ls,Rs).

takeWhile(P,Xs,Ys) :- span(P,Xs,Ys,_).
dropWhile(P,Xs,Ys) :- span(P,Xs,_,Ys).

span(_,[],[],[]) :- !.
span(P,[X|Xs],[],[X|Xs]) :-
	not($(P,[],X)), !.
span(P,[X|Xs],[X|Ys],Zs) :-
	$(P,[],X),
	span(P,Xs,Ys,Zs).

break(_,[],[],[]) :- !.
break(P,[X|Xs],[],[X|Xs]) :-
	$(P,[],X),!.
break(P,[X|Xs],[X|Ys],Zs) :-
	not($(P,[],X)),
	break(P,Xs,Ys,Zs).

elem(X,Xs) :- member(X,Xs).
elem(X,Xs,true) :- member(X,Xs), !.
elem(_,_,false).

notElem(X,Xs) :- \+member(X,Xs).
notElem(X,Xs,false) :- member(X,Xs), !.
notElem(_,_,true).

lookup(X,Xs,V) :- member((X,V),Xs).

zip([X|Xs],[Y|Ys],[(X,Y)|Zs]) :- zip(Xs,Ys,Zs).
zip(_,_,[]).

zip3([A|As],[B|Bs],[C|Cs],[(A,B,C)|Ds]) :- zip3(As,Bs,Cs,Ds).
zip3(_,_,_,[]).

zipWith(F,[X|Xs],[Y|Ys],[Z|Zs]) :-
	$(F,[X,Y],Z),
	zipWith(F,Xs,Ys,Zs).
zipWith(_,_,_,[]).

zipWith3(F,[A|As],[B|Bs],[C|Cs],[D|Ds]) :-
	$(F,[A,B,C],D),
	zipWith3(F,As,Bs,Cs,Ds).

unzip([],[],[]).
unzip([(X,Y)|Zs],[X|Xs],[Y|Ys]) :- unzip(Zs,Xs,Ys).

unzip3([],[],[],[]).
unzip3([(A,B,C)|Ds],[A|As],[B|Bs],[C|Cs]) :- unzip3(Ds,As,Bs,Cs).
