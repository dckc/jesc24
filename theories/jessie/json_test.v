(** JSON parser tests, mirroring test/test-json.js from the Jessie project:
    https://github.com/endojs/Jessie/blob/main/packages/parse/test/test-json.js *)

From Coq Require Import List String ZArith.
From Coq Require Import Lists.List.
From jessie Require Import jessica_ast json_parser json_lexer.
Import MenhirLibParser.Inter.
Import ListNotations.
Open Scope string_scope.

Module JsonTests.
  Import JessicaAst.

  Definition parse_json_str (s : string) : option jexpr :=
    match option_map (parse_json 50) (lex_string s) with
    | Some (Parsed_pr f _) => Some f
    | _ => None
    end.

  (* test('data', ...) : parse('{}') -> ['record', []] *)
  Example test_empty_record :
    parse_json_str "{}" = Some (JRecord []).
  Proof. vm_compute. reflexivity. Qed.

  (* parse('[]') -> ['array', []] *)
  Example test_empty_array :
    parse_json_str "[]" = Some (JArray []).
  Proof. vm_compute. reflexivity. Qed.

  (* parse('123') -> ['data', 123] *)
  Example test_number :
    parse_json_str "123" = Some (JDataNum 123).
  Proof. vm_compute. reflexivity. Qed.

  (* parse('{"abc": 123}') ->
     ['record', [['prop', ['data', 'abc'], ['data', 123]]]] *)
  Example test_record_with_prop :
    parse_json_str "{ ""abc"": 123 }" =
      Some (JRecord [JProp "abc" (JDataNum 123)]).
  Proof. vm_compute. reflexivity. Qed.

  (* parse('["abc", 123]') ->
     ['array', [['data', 'abc'], ['data', 123]]] *)
  Example test_array_with_elems :
    parse_json_str "[""abc"", 123]" =
      Some (JArray [JDataString "abc"; JDataNum 123]).
  Proof. vm_compute. reflexivity. Qed.

  (* Extra tests beyond upstream *)

  Example test_negative_number :
    parse_json_str "-7" = Some (JDataNum (-7)).
  Proof. vm_compute. reflexivity. Qed.

  Example test_nested :
    parse_json_str "{ ""a"": [1, 2] }" =
      Some (JRecord [JProp "a" (JArray [JDataNum 1; JDataNum 2])]).
  Proof. vm_compute. reflexivity. Qed.

  Example test_whitespace :
    parse_json_str "  {  ""x""  :  42  }  " =
      Some (JRecord [JProp "x" (JDataNum 42)]).
  Proof. vm_compute. reflexivity. Qed.

  Example test_multiple_props :
    parse_json_str "{ ""a"": 1, ""b"": 2 }" =
      Some (JRecord [JProp "a" (JDataNum 1); JProp "b" (JDataNum 2)]).
  Proof. vm_compute. reflexivity. Qed.

  (* Negative tests *)

  Example test_rejects_unclosed_record :
    parse_json_str "{ ""a"": 1" = None.
  Proof. vm_compute. reflexivity. Qed.

  Example test_rejects_unclosed_array :
    parse_json_str "[1, 2" = None.
  Proof. vm_compute. reflexivity. Qed.

  Example test_rejects_trailing_garbage :
    parse_json_str "1 2" = None.
  Proof. vm_compute. reflexivity. Qed.
End JsonTests.