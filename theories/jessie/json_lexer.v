(** Hand-written lexer for JSON, producing a MenhirLib token buffer.

    Tokenizes: { } [ ] , : numbers double-quoted strings whitespace.
    No escape handling in strings (subset matching quasi-json.js). *)

From Coq Require Import List String ZArith Ascii NArith Bool.
From jessie Require Import json_parser.
Import MenhirLibParser.Inter.
Open Scope char_scope.
Open Scope string_scope.

(* No such thing as an empty buffer — use an infinite stream of EOF. *)
CoFixpoint TheEnd : buffer := Buf_cons (EOF tt) TheEnd.

Fixpoint ntail n s :=
  match n, s with
  | 0, _ => s
  | _, EmptyString => s
  | S n, String _ s => ntail n s
  end.

Definition ascii_eqb c c' := (N_of_ascii c =? N_of_ascii c')%N.
Definition ascii_leb c c' := (N_of_ascii c <=? N_of_ascii c')%N.

Infix "=?" := ascii_eqb : char_scope.
Infix "<=?" := ascii_leb : char_scope.

Definition is_digit c := (("0" <=? c) && (c <=? "9"))%char.

Fixpoint readnum acc s :=
  match s with
  | String "0" s => readnum (acc*10) s
  | String "1" s => readnum (acc*10+1) s
  | String "2" s => readnum (acc*10+2) s
  | String "3" s => readnum (acc*10+3) s
  | String "4" s => readnum (acc*10+4) s
  | String "5" s => readnum (acc*10+5) s
  | String "6" s => readnum (acc*10+6) s
  | String "7" s => readnum (acc*10+7) s
  | String "8" s => readnum (acc*10+8) s
  | String "9" s => readnum (acc*10+9) s
  | _ => (acc, s)
  end.

(* Read a double-quoted string, returning (content, rest_after_closing_quote).
   No escape handling. *)
Fixpoint readstring_cpt (fuel : nat) (acc : string) (s : string)
    : option (string * string) :=
  match fuel with
  | 0 => None
  | S fuel' =>
    match s with
    | EmptyString => None
    | String c s' =>
      if ascii_eqb c """"%char then Some (acc, s')
      else readstring_cpt fuel' (acc ++ String c EmptyString) s'
    end
  end.

Definition readstring s :=
  readstring_cpt (length s) EmptyString s.

Fixpoint lex_string_cpt (n : nat) (s : string) : option buffer :=
  match n with
  | 0 => None
  | S n =>
    match s with
    | EmptyString => Some TheEnd
    | String c s' =>
      match c with
      | " "%char => lex_string_cpt n s'
      | "009"%char => lex_string_cpt n s' (* \t *)
      | "010"%char => lex_string_cpt n s' (* \n *)
      | "013"%char => lex_string_cpt n s' (* \r *)
      | "{"%char => option_map (Buf_cons (LBRACE tt)) (lex_string_cpt n s')
      | "}"%char => option_map (Buf_cons (RBRACE tt)) (lex_string_cpt n s')
      | "["%char => option_map (Buf_cons (LBRACKET tt)) (lex_string_cpt n s')
      | "]"%char => option_map (Buf_cons (RBRACKET tt)) (lex_string_cpt n s')
      | ","%char => option_map (Buf_cons (COMMA tt)) (lex_string_cpt n s')
      | ":"%char => option_map (Buf_cons (COLON tt)) (lex_string_cpt n s')
      | "-"%char =>
        match s' with
        | String d s'' =>
          if is_digit d then
            let (m, s) := readnum 0 s' in
            option_map (Buf_cons (NUMBER (- Z.of_nat m))) (lex_string_cpt n s)
          else None
        | _ => None
        end
      | """"%char =>
        match readstring s' with
        | Some (str, s'') =>
          option_map (Buf_cons (STRING str)) (lex_string_cpt n s'')
        | None => None
        end
      | _ =>
        if is_digit c then
          let (m, s) := readnum 0 s in
          option_map (Buf_cons (NUMBER (Z.of_nat m))) (lex_string_cpt n s)
        else None
      end
    end
  end.

Definition lex_string s := lex_string_cpt (3 * length s) s.