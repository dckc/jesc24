(** Parse helpers on top of the Menhir-generated [jesc_parser] and the
    hand-written [jesc_lexer]: parse a whole Jessie module source, or a single
    Justin expression, into a [JessicaAst]. *)

From Coq Require Import String.
From Coq Require Import Lists.List.
From jessie Require Import jessica_ast jesc_parser jesc_lexer.
Import ListNotations.
Import MenhirLibParser.Inter.

(* ---- "must cover" validation ----------------------------------------------
   The cover grammar is deliberately permissive: a parenthesized arrow-parameter
   list or parenthesized expression is parsed as a shared [args] list and
   re-interpreted in the semantic action.  Anything that does not fit is mapped
   to the JBadExpr / JBadPat placeholders.  These predicates reject any AST that
   still contains a placeholder, mirroring ECMA-262's "must cover an
   ArrowFormalParameters" / "must cover an Expression" early errors. *)

Fixpoint valid_pat (p : JessicaAst.jpat) : bool :=
  match p with
  | JessicaAst.JDef _ => true
  | JessicaAst.JMatchArray ps => forallb valid_pat ps
  | JessicaAst.JBadPat => false
  end.

Fixpoint valid_expr (e : JessicaAst.jexpr) : bool :=
  match e with
  | JessicaAst.JUse _ => true
  | JessicaAst.JDataNum _ => true
  | JessicaAst.JDataString _ => true
  | JessicaAst.JArray xs => forallb valid_expr xs
  | JessicaAst.JAssignOp _ l r => valid_expr l && valid_expr r
  | JessicaAst.JAssign l r => valid_expr l && valid_expr r
  | JessicaAst.JGet o _ => valid_expr o
  | JessicaAst.JCall c args => valid_expr c && forallb valid_expr args
  | JessicaAst.JGreater l r => valid_expr l && valid_expr r
  | JessicaAst.JPreOp _ a => valid_expr a
  | JessicaAst.JRecord fields => forallb valid_prop fields
  | JessicaAst.JArrow ps body => forallb valid_pat ps && valid_body body
  | JessicaAst.JLambda ps body => forallb valid_pat ps && valid_body body
  | JessicaAst.JBadExpr => false
  end

with valid_prop (p : JessicaAst.jprop) : bool :=
  match p with
  | JessicaAst.JProp _ v => valid_expr v
  end

with valid_body (b : JessicaAst.jbody) : bool :=
  match b with
  | JessicaAst.JBodyExpr e => valid_expr e
  | JessicaAst.JBodyBlock ss => forallb valid_stmt ss
  end

with valid_stmt (s : JessicaAst.jstmt) : bool :=
  match s with
  | JessicaAst.JConstStmt bs => forallb valid_bind bs
  | JessicaAst.JLet bs => forallb valid_bind bs
  | JessicaAst.JLetNames ps => forallb valid_pat ps
  | JessicaAst.JExprStmt e => valid_expr e
  | JessicaAst.JAssert e => valid_expr e
  | JessicaAst.JIf c t e =>
      valid_expr c && forallb valid_stmt t &&
      match e with
      | Some ss => forallb valid_stmt ss
      | None => true
      end
  | JessicaAst.JThrow e => valid_expr e
  | JessicaAst.JReturn e => valid_expr e
  end

with valid_bind (b : JessicaAst.jbind) : bool :=
  match b with
  | JessicaAst.JBind p v => valid_pat p && valid_expr v
  end.

Fixpoint valid_decl (d : JessicaAst.jdecl) : bool :=
  match d with
  | JessicaAst.JImport _ _ => true
  | JessicaAst.JConst bs => forallb valid_bind bs
  end.

Definition valid_module (m : JessicaAst.jmodule) : bool :=
  match m with
  | JessicaAst.JModule decls => forallb valid_decl decls
  end.

Definition parse_jessie_str (s : string) : option JessicaAst.jmodule :=
  match option_map (parse_jessie 50) (lex_string s) with
  | Some (Parsed_pr m _) =>
      if valid_module m then Some m else None
  | _ => None
  end.

Definition parse_justin_str (s : string) : option JessicaAst.jexpr :=
  match option_map (parse_justin 50) (lex_string s) with
  | Some (Parsed_pr e _) =>
      if valid_expr e then Some e else None
  | _ => None
  end.
