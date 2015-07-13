(* Block[{$Output = {}}, *)
 (*       Quiet[<< KnotTheory`]]; *)

<< "prototype-serialize-homfly.m";

fd = OpenRead["/home/hunchentoot" <> "/lisp-out.txt"];
(* fdout = OpenWrite["~/code/superpolys/lisp-in.txt"]; *)

For[it = Read[fd], it =!= EndOfFile, it = Read[fd],
    WriteString["stdout", ToString[Quiet[SimpleSerialize[Expand[expr]]]] <> "\n"]];

Close[fd];
(* (\* Close[fdout]; *\) *)
