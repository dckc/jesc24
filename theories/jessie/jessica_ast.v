From Coq Require Import List String ZArith.

Import ListNotations.
Open Scope string_scope.
Open Scope Z_scope.

Module JessicaAst.
  Inductive jimport_bind :=
  | JImportAs (local imported : string).

  Inductive jpat :=
  | JDef (x : string)
  | JMatchArray (ps : list jpat)
  | JMatchObj (names : list string)
  | JDefDefault (x : string) (default : jexpr)
  (* Cover-grammar placeholder: a parenthesized arrow-parameter list whose
     contents are not valid patterns (e.g. [(1) => {}]).  The parser may
     produce it while parsing the permissive cover grammar; jesc_parse.v
     rejects it during the "must cover an ArrowFormalParameters" check that
     mirrors ECMAScript's early-error rule. *)
  | JBadPat
  with jexpr :=
  | JUse (x : string)
  | JDataNum (n : Z)
  | JDataBigint (n : Z)
  | JDataString (s : string)
  | JArray (xs : list jexpr)
  (* TODO: consider whether the lhs of JAssignOp should be a narrower pattern
     or l-value category rather than a full expression. *)
  | JAssignOp (op : string) (lhs rhs : jexpr)
  | JAssign (lhs rhs : jexpr)
  | JGet (obj : jexpr) (field : string)
  | JCall (callee : jexpr) (args : list jexpr)
  | JGreater (lhs rhs : jexpr)
  | JPreOp (op : string) (arg : jexpr)
  | JRecord (fields : list jprop)
  | JArrow (params : list jpat) (body : jbody)
  | JLambda (params : list jpat) (body : jbody)
  (* Cover-grammar placeholder: a parenthesized expression that is not a
     single expression, e.g. "()" or "(a, b)" used in expression position.
     Jessie has no comma / sequence expression, so only a singleton is
     meaningful; jesc_parse.v rejects this during validation. *)
  | JBadExpr
  with jprop :=
  | JProp (name : string) (value : jexpr)
  (* TODO: consider a distinct AST node for method shorthand (incr() { ... })
     since the resulting arrow body is this-ful, unlike a plain property whose
     value is an ordinary expression. *)
  with jbody :=
  | JBodyExpr (e : jexpr)
  | JBodyBlock (ss : list jstmt)
  with jstmt :=
  | JConstStmt (bindings : list jbind)
  | JLet (bindings : list jbind)
  | JLetNames (names : list jpat)
  | JExprStmt (e : jexpr)
  | JAssert (e : jexpr)
  | JIf (cond : jexpr) (then_branch : list jstmt) (else_branch : option (list jstmt))
  | JThrow (e : jexpr)
  | JReturn (e : jexpr)
  with jbind :=
  | JBind (lhs : jpat) (rhs : jexpr).

  Inductive jdecl :=
  | JImport (bindings : list jimport_bind) (from : string)
  | JConst (bindings : list jbind)
  | JStmt (s : jstmt).

  Inductive jmodule :=
  | JModule (decls : list jdecl).
End JessicaAst.
