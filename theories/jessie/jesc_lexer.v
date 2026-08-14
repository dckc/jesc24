(** Hand-written lexer for Justin/Jessie, producing a MenhirLib token buffer.

    Tokenizes the JavaScript subset accepted by [jesc_parser.vy]: line
    comments, single- and double-quoted strings (no escapes), numbers,
    identifiers/keywords, and the punctuation of the grammar.

    Following ECMA-262, [LPAREN] / [RPAREN] are emitted unconditionally; the
    grammar distinguishes arrow-parameter lists from parenthesized
    expressions and call arguments by re-interpreting a shared cover
    nonterminal after the parse (see [jesc_parser.vy] and [jesc_parse.v]). *)

From Coq Require Import List String ZArith Ascii NArith Bool.
From jessie Require Import jesc_parser.
Import MenhirLibParser.Inter.
Open Scope char_scope.
Open Scope string_scope.

(* No such thing as an empty buffer — use an infinite stream of EOF. *)
CoFixpoint TheEnd : buffer := Buf_cons (EOF tt) TheEnd.

Definition ascii_eqb c c' := (N_of_ascii c =? N_of_ascii c')%N.
Definition ascii_leb c c' := (N_of_ascii c <=? N_of_ascii c')%N.

Infix "=?" := ascii_eqb : char_scope.
Infix "<=?" := ascii_leb : char_scope.

Definition is_digit c := (("0" <=? c) && (c <=? "9"))%char.

Definition is_ws c :=
  ascii_eqb c " "%char || ascii_eqb c "009"%char
  || ascii_eqb c "010"%char || ascii_eqb c "013"%char.

Definition is_ident_start c :=
  (("a" <=? c) && (c <=? "z"))%char
  || (("A" <=? c) && (c <=? "Z"))%char
  || ascii_eqb c "_"%char || ascii_eqb c "$"%char.

Definition is_ident_char c := is_ident_start c || is_digit c.

(* Drop a line comment: skip to (but not including) the line terminator. *)
Fixpoint drop_to_newline (s : string) : string :=
  match s with
  | EmptyString => EmptyString
  | String c s' =>
      if ascii_eqb c "010"%char then s'
      else if ascii_eqb c "013"%char then s'
      else drop_to_newline s'
  end.

(* Read a quoted string whose closing quote is [q], returning
   (content, rest_after_closing_quote).  No escape handling. *)
Fixpoint readstring_cpt (fuel : nat) (q : ascii) (acc : string) (s : string)
    : option (string * string) :=
  match fuel with
  | 0 => None
  | S fuel' =>
    match s with
    | EmptyString => None
    | String c s' =>
      if ascii_eqb c q then Some (acc, s')
      else readstring_cpt fuel' q (acc ++ String c EmptyString) s'
    end
  end.

Definition readstring (q : ascii) (s : string) : option (string * string) :=
  readstring_cpt (length s) q EmptyString s.

Fixpoint readnum (acc : Z) (s : string) : (Z * string) :=
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

(* Read an identifier (letters, digits, "_", "$"), returning the ident and
   the rest of the input. *)
Fixpoint readident (acc : string) (s : string) : (string * string) :=
  match s with
  | String c s' =>
      if is_ident_char c then readident (acc ++ String c EmptyString) s'
      else (acc, s)
  | EmptyString => (acc, EmptyString)
  end.

(* Map an identifier to its keyword token, if any. *)
Definition tok_of_ident (s : string) : token :=
  if String.eqb s "const" then CONST tt else
  if String.eqb s "let" then LET tt else
  if String.eqb s "if" then IFKW tt else
  if String.eqb s "else" then ELSE tt else
  if String.eqb s "return" then RETURN tt else
  if String.eqb s "throw" then THROW tt else
  if String.eqb s "assert" then ASSERT tt else
  if String.eqb s "import" then IMPORT tt else
  if String.eqb s "from" then FROM tt else
  IDENT s.

Fixpoint lex_string_cpt (fuel : nat) (s : string) : option buffer :=
  match fuel with
  | 0 => None
  | S fuel' =>
    match s with
    | EmptyString => Some TheEnd
    | String c s' =>
      if is_ws c then lex_string_cpt fuel' s'
      else match c with
      | "/"%char =>
        match s' with
        | String "/"%char s'' => lex_string_cpt fuel' (drop_to_newline s'')
        | _ => None
        end
      | "{"%char => option_map (Buf_cons (LBRACE tt)) (lex_string_cpt fuel' s')
      | "}"%char => option_map (Buf_cons (RBRACE tt)) (lex_string_cpt fuel' s')
      | "["%char => option_map (Buf_cons (LBRACKET tt)) (lex_string_cpt fuel' s')
      | "]"%char => option_map (Buf_cons (RBRACKET tt)) (lex_string_cpt fuel' s')
      | "("%char => option_map (Buf_cons (LPAREN tt)) (lex_string_cpt fuel' s')
      | ")"%char => option_map (Buf_cons (RPAREN tt)) (lex_string_cpt fuel' s')
      | ","%char => option_map (Buf_cons (COMMA tt)) (lex_string_cpt fuel' s')
      | ":"%char => option_map (Buf_cons (COLON tt)) (lex_string_cpt fuel' s')
      | ";"%char => option_map (Buf_cons (SEMI tt)) (lex_string_cpt fuel' s')
      | "."%char => option_map (Buf_cons (DOT tt)) (lex_string_cpt fuel' s')
      | "!"%char => option_map (Buf_cons (BANG tt)) (lex_string_cpt fuel' s')
      | "<"%char => option_map (Buf_cons (LT tt)) (lex_string_cpt fuel' s')
      | "="%char =>
        match s' with
        | String ">"%char rest =>
          option_map (Buf_cons (ARROW tt)) (lex_string_cpt fuel' rest)
        | _ =>
          option_map (Buf_cons (EQUALS tt)) (lex_string_cpt fuel' s')
        end
      | "+"%char =>
        match s' with
        | String "="%char rest =>
          option_map (Buf_cons (PLUSEQ tt)) (lex_string_cpt fuel' rest)
        | _ => None
        end
      | "-"%char =>
        match s' with
        | String "="%char rest =>
          option_map (Buf_cons (MINUSEQ tt)) (lex_string_cpt fuel' rest)
        | String d rest =>
          if is_digit d then
            let (m, tail) := readnum 0 s' in
            option_map (Buf_cons (NUMBER (- m))) (lex_string_cpt fuel' tail)
          else None
        | _ => None
        end
      | """"%char =>
        match readstring """"%char s' with
        | Some (str, rest) =>
          option_map (Buf_cons (STRING str)) (lex_string_cpt fuel' rest)
        | None => None
        end
      | "'"%char =>
        match readstring "'"%char s' with
        | Some (str, rest) =>
          option_map (Buf_cons (STRING str)) (lex_string_cpt fuel' rest)
        | None => None
        end
      | _ =>
        if is_digit c then
          let (m, rest) := readnum 0 s in
          option_map (Buf_cons (NUMBER m)) (lex_string_cpt fuel' rest)
        else if is_ident_start c then
          let (str, rest) := readident EmptyString s in
          option_map (Buf_cons (tok_of_ident str)) (lex_string_cpt fuel' rest)
        else None
      end
    end
  end.

Definition lex_string (s : string) : option buffer :=
  lex_string_cpt (3 * length s) s.
