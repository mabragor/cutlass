<< "prototype-serialize-homfly.m";

rolfsenTotalNumbers = {0, 0, 1, 1, 2, 3, 7, 21, 49, 165};

fd = OpenWrite["/home/popolit/quicklisp/local-projects/cutlass/rolfsen-homflies.txt"];

(* "rolfsen:" <> ToString[nints] <> "_" <> ToString[i] *)

Module[{j = 1},
       For[nints = 3, nints < 11, nints ++,
	   For[i = 1, i < rolfsenTotalNumbers[[nints]] + 1, i ++,
	       WriteString[fd, ToString[(j ++)]
			   <> "\t" <> ToString[SimpleSerializedHOMFLY[Knot[nints, i]]] <> "\n"]]];

                        
KnotTheory::loading: Loading precomputed data in PD4Knots`.

KnotTheory::credits: The HOMFLYPT program was written by Scott Morrison.


(* Expand[HOMFLYPT[Knot[4,1]][a,q - 1/q]] *)
(* SimpleSerializedHOMFLY[Knot[4,1]] *)
