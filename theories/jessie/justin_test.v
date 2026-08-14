(** Justin parser tests, mirroring upstream test-justin.js from the Jessie
    project:
      https://github.com/endojs/Jessie/blob/main/packages/parse/test/test-justin.js *)

From Coq Require Import List String ZArith Ascii.
From Coq Require Import Lists.List.
From jessie Require Import jessica_ast jesc_parser jesc_lexer jesc_parse.
Import MenhirLibParser.Inter.
Import ListNotations.
Open Scope char_scope.
Open Scope string_scope.

Module JustinTests.
  Import JessicaAst.

  (* [parse_justin_str] comes from [jesc_parse].

  Wrap [s] in double quotes, as a JS string literal. *)
  Definition dquote (s : string) : string :=
    String """"%char (s ++ String """"%char EmptyString).

  (* Justin expression tests (mirroring test-justin.js) *)

  Example test_justin_number :
    parse_justin_str "1" = Some (JDataNum 1).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_negative_number :
    parse_justin_str "-7" = Some (JDataNum (-7)).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_string_single_quotes :
    parse_justin_str "'x'" = Some (JDataString "x").
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_string_double_quotes :
    parse_justin_str (dquote "x") = Some (JDataString "x").
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_array :
    parse_justin_str "[1, 2]" = Some (JArray [JDataNum 1; JDataNum 2]).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_array_trailing_comma :
    parse_justin_str "[1, 2,]" = Some (JArray [JDataNum 1; JDataNum 2]).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_array_empty :
    parse_justin_str "[]" = Some (JArray []).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_record :
    parse_justin_str "{ a: 1 }" = Some (JRecord [JProp "a" (JDataNum 1)]).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_record_trailing_comma :
    parse_justin_str "{ a: 1, }" = Some (JRecord [JProp "a" (JDataNum 1)]).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_record_empty :
    parse_justin_str "{}" = Some (JRecord []).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_get :
    parse_justin_str "x.y" = Some (JGet (JUse "x") "y").
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_call :
    parse_justin_str "f(1, 2)" = Some (JCall (JUse "f") [JDataNum 1; JDataNum 2]).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_call_no_args :
    parse_justin_str "f()" = Some (JCall (JUse "f") []).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_get_call :
    parse_justin_str "x.f(1)" = Some (JCall (JGet (JUse "x") "f") [JDataNum 1]).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_less :
    parse_justin_str "0 < c.incr()" =
      Some (JGreater (JCall (JGet (JUse "c") "incr") []) (JDataNum 0)).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_not :
    parse_justin_str "!x" = Some (JPreOp "!" (JUse "x")).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_assign :
    parse_justin_str "x = 1" = Some (JAssign (JUse "x") (JDataNum 1)).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_assign_op :
    parse_justin_str "x += 1" = Some (JAssignOp "+=" (JUse "x") (JDataNum 1)).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_arrow :
    parse_justin_str "x => 1" = Some (JArrow [JDef "x"] (JBodyExpr (JDataNum 1))).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_arrow_params :
    parse_justin_str "(a, b) => a" =
      Some (JArrow [JDef "a"; JDef "b"] (JBodyExpr (JUse "a"))).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_arrow_empty :
    parse_justin_str "() => 1" = Some (JArrow [] (JBodyExpr (JDataNum 1))).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_comment :
    parse_justin_str "1 // trailing comment" = Some (JDataNum 1).
  Proof. vm_compute. reflexivity. Qed.

  (* Cover-grammar tests: a single ( [expr list] ) shape is shared by
     parenthesized expressions, call arguments, and arrow-parameter lists,
     then re-interpreted (Supplemental Syntax).  The "must cover" validation
     in jesc_parse.v rejects the invalid readings. *)

  Example test_justin_paren_singleton :
    parse_justin_str "(a)" = Some (JUse "a").
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_paren_nested :
    parse_justin_str "((a))" = Some (JUse "a").
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_arrow_single_paren_param :
    parse_justin_str "(a) => a" =
      Some (JArrow [JDef "a"] (JBodyExpr (JUse "a"))).
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_arrow_match_array :
    parse_justin_str "([a, b]) => a" =
      Some (JArrow [JMatchArray [JDef "a"; JDef "b"]] (JBodyExpr (JUse "a"))).
  Proof. vm_compute. reflexivity. Qed.

  (* Negative cover-grammar tests: the permissive cover is rejected by the
     "must cover" early-error check. *)

  Example test_justin_rejects_paren_sequence :
    parse_justin_str "(a, b)" = None.
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_rejects_empty_paren :
    parse_justin_str "()" = None.
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_rejects_arrow_non_pattern_param :
    parse_justin_str "(1) => 1" = None.
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_rejects_arrow_sequence_param :
    parse_justin_str "(a, 1) => a" = None.
  Proof. vm_compute. reflexivity. Qed.

  Example test_justin_rejects_arrow_nested_non_pattern :
    parse_justin_str "([1]) => 1" = None.
  Proof. vm_compute. reflexivity. Qed.

  (* Negative tests *)

  Example test_justin_rejects_two_numbers :
    parse_justin_str "1 2" = None.
  Proof. vm_compute. reflexivity. Qed.
End JustinTests.
