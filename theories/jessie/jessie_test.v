(** Jessie parser tests, mirroring upstream test-jessie.js from the Jessie
    project:
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

Module JessieTests.
  Import JessicaAst.
  Import Escrow2013Target.
  Import SourceMakeCounter.

  (* [parse_jessie_str] comes from [jesc_parse]. *)

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

  Example test_jessie_rejects_return_at_top :
    parse_jessie_str "return 1;" = None.
  Proof. vm_compute. reflexivity. Qed.
End JessieTests.
