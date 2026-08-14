(** Jessie/Justin parser tests, mirroring upstream test-justin.js and
    test-jessie.js from the Jessie project:
      https://github.com/endojs/Jessie/blob/main/packages/parse/test/test-justin.js
      https://github.com/endojs/Jessie/blob/main/packages/parse/test/test-jessie.js

    The integration tests also check that the menhir-based parser recognizes
    the makeCounter, checkedCounter, and escrow2013 programs as the
    constructor-rich targets used by the proof line. *)

From Coq Require Import List String ZArith Ascii.
From Coq Require Import Lists.List.
From jessie Require Import jessica_ast jesc_parser jesc_lexer jesc_parse.
From jessie Require Import makeCounter_js escrow2013_js escrow2013_target make_counter.
Import MenhirLibParser.Inter.
Import ListNotations.
Open Scope char_scope.
Open Scope string_scope.

Module JescTests.
  Import JessicaAst.
  Import Escrow2013Target.
  Import SourceMakeCounter.

  (* [parse_jessie_str] / [parse_justin_str] come from [jesc_parse].

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

  (* Jessie module tests (mirroring test-jessie.js) *)

  Example test_jessie_const :
    parse_jessie_str "const a = 1;" =
      Some (JModule [JConst [JBind (JDef "a") (JDataNum 1)]]).
  Proof. vm_compute. reflexivity. Qed.

  Example test_jessie_let_uninitialized :
    parse_jessie_str "const f = () => { let x; };"
      = Some (JModule [JConst [JBind (JDef "f")
            (JArrow [] (JBodyBlock [JLetNames [JDef "x"]]))]]).
  Proof. vm_compute. reflexivity. Qed.

  Example test_jessie_let_initialized :
    parse_jessie_str "const f = () => { let x = 1; };"
      = Some (JModule [JConst [JBind (JDef "f")
            (JArrow [] (JBodyBlock [JLet [JBind (JDef "x") (JDataNum 1)]]))]]).
  Proof. vm_compute. reflexivity. Qed.

  Example test_jessie_import :
    parse_jessie_str "import { E } from '@endo/far';" =
      Some (JModule [JImport [JImportAs "E" "E"] "@endo/far"]).
  Proof. vm_compute. reflexivity. Qed.

  Example test_jessie_if_else :
    parse_jessie_str
      "const f = (x) => { if (x) { return 1; } else { return 0; } };"
      = Some (JModule [JConst [JBind (JDef "f")
            (JArrow [JDef "x"]
              (JBodyBlock [
                JIf (JUse "x")
                  [JReturn (JDataNum 1)]
                  (Some [JReturn (JDataNum 0)])
              ]))]]).
  Proof. vm_compute. reflexivity. Qed.

  Example test_jessie_throw :
    parse_jessie_str "const f = () => { throw 1; };"
      = Some (JModule [JConst [JBind (JDef "f")
            (JArrow [] (JBodyBlock [JThrow (JDataNum 1)]))]]).
  Proof. vm_compute. reflexivity. Qed.

  (* Integration: the menhir parser recognizes the makeCounter product,
     checkedCounter, and escrow2013 programs as the targets used by the
     proof line. *)

  Example test_jessie_makeCounter :
    parse_jessie_str makeCounter_source = Some makeCounter_jessica_program.
  Proof. vm_compute. reflexivity. Qed.

  Example test_jessie_checkedCounter :
    parse_jessie_str checkedCounter_source = Some checkedCounter_jessica_program.
  Proof. vm_compute. reflexivity. Qed.

  Example test_jessie_escrow2013 :
    parse_jessie_str escrow2013_source = Some escrow2013_program.
  Proof. vm_compute. reflexivity. Qed.

  (* Negative tests *)

  Example test_justin_rejects_two_numbers :
    parse_justin_str "1 2" = None.
  Proof. vm_compute. reflexivity. Qed.

  Example test_jessie_rejects_return_at_top :
    parse_jessie_str "return 1;" = None.
  Proof. vm_compute. reflexivity. Qed.
End JescTests.
