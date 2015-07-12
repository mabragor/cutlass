
Block[{$Output = {}},
      Quiet[<< KnotTheory`]];


StringRiffle[lst_List, x_] :=
    (StringJoin @@ Riffle[lst, x]);
TrySelectNonZero[rule1_ ,rule2_] :=
    If[rule1[[1,1]] =!= 0,
       rule1,
       Rule[-rule2[[1]], rule2[[2]]]];
SimpleSerializedHOMFLY[knot_] :=
    Module[{homfly = Expand[HOMFLYPT[knot][a,z] /. {z -> q - 1/q}]},
	   SimpleSerialize[homfly]];
SimpleSerialize[x_Plus] :=
    StringRiffle[Sort[Map[SimpleSerialize, List @@ x]], ";"];
SimpleSerialize[x_Integer] :=
    StringJoin["0,0,", ToString[x]];
SimpleSerialize[x_Times] :=
    ActualSimpleSerialize[x];
SimpleSerialize[x_Power] :=
    ActualSimpleSerialize[x];

ActualSimpleSerialize[x_] :=
    Module[{rules1 = CoefficientRules[x, {a}],
	    rules2 = CoefficientRules[x, {1/a}]},
	   If[Or[Not[1 === Length[rules1]],
		 Not[1 === Length[rules2]]],
	      Message[ss::timesNonMonomial,
		      "Something went wrong: times pattern is not a monomial. Forgot Expand[]?"],
	      Module[{arule = TrySelectNonZero[rules1[[1]], rules2[[1]]]},
		     Module[{rules3 = CoefficientRules[arule[[2]], {q}],
			     rules4 = CoefficientRules[arule[[2]], {1/q}]},
			    Module[{qrule = TrySelectNonZero[rules3[[1]], rules4[[1]]]},
				   StringRiffle[{ToString[arule[[1,1]]],
						 ToString[qrule[[1,1]]],
						 ToString[qrule[[2]]]},
						","]]]]]];

