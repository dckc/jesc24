(* Jessie / Justin grammar for Menhir's Coq backend.

    Mirrors the grammar productions in [packages/parse/src/quasi-jessie.js.ts]
    and [packages/parse/src/quasi-justin.js] from the Jessie project:
      https://github.com/endojs/Jessie/blob/main/packages/parse/src/quasi-jessie.js.ts
      https://github.com/endojs/Jessie/blob/main/packages/parse/src/quasi-justin.js

    Only the fragments used by the current makeCounter and escrow2013
    examples are transcribed; productions that are not yet needed are
    omitted with a comment.  Each production is kept in roughly the same
    order as the upstream sources.

    Subsets of JavaScript, starting from the grammar as defined at
    http://www.ecma-international.org/ecma-262/9.0/#sec-grammar-summary

    Both start symbols share the JessicaAst types / the token type, so a
    single lexer (the Justin-style lexer, with comments) serves both. *)

%{

From Coq Require Import String ZArith.
From Coq Require Import Lists.List.
From Coq Require Import Arith.
From jessie Require Import jessica_ast.
Import ListNotations.
Open Scope string_scope.

(* ---- Cover-grammar reinterpretation ---------------------------------------
   Like ECMA-262's "Supplemental Syntax", the shared ( [expression list] )
   shape is re-interpreted once the surrounding grammar production fixes its
   meaning:
     - as arrow parameters, each cover expression must itself be a pattern;
     - as a parenthesized expression the list must be a singleton (Jessie has
       no comma / sequence expression).

   The cover grammar is deliberately permissive, so these reinterpretations
   are partial: anything that does not fit is mapped to the JBadExpr / JBadPat
   placeholders that jesc_parse.v rejects, mirroring the "must cover an
   ArrowFormalParameters" early error. *)

Fixpoint param_of_expr (e : JessicaAst.jexpr) : JessicaAst.jpat :=
  match e with
  | JessicaAst.JUse x => JessicaAst.JDef x
  | JessicaAst.JArray es =>
      JessicaAst.JMatchArray (map param_of_expr es)
  | JessicaAst.JAssign (JessicaAst.JUse x) default =>
      JessicaAst.JDefDefault x default
  | _ => JessicaAst.JBadPat
  end.

Fixpoint params_of_exprs (es : list JessicaAst.jexpr) : list JessicaAst.jpat :=
  match es with
  | nil => nil
  | e :: es' => param_of_expr e :: params_of_exprs es'
  end.

Definition paren_singleton (es : list JessicaAst.jexpr) : JessicaAst.jexpr :=
  match es with
  | e :: nil => e
  | _ => JessicaAst.JBadExpr
  end.

%}

%token LBRACE RBRACE LBRACKET RBRACKET
%token LPAREN RPAREN
%token COMMA COLON DOT SEMI
%token EQUALS ARROW PLUSEQ MINUSEQ BANG LT
%token CONST LET IFKW ELSE RETURN THROW ASSERT IMPORT FROM
%token VOID
%token<Z> NUMBER
%token<Z> BIGINT
%token<string> IDENT STRING
%token EOF

%start<JessicaAst.jmodule> parse_jessie
%start<JessicaAst.jexpr> parse_justin

(* A.2 Expressions *)
%type<JessicaAst.jexpr> expr
%type<JessicaAst.jexpr> expr_body
%type<JessicaAst.jexpr> post
%type<JessicaAst.jexpr> post_nocollision
%type<JessicaAst.jexpr> primary
%type<JessicaAst.jexpr> primary_nocollision
%type<JessicaAst.jexpr> atom
%type<JessicaAst.jexpr> paren_expr
%type<JessicaAst.jexpr> array
%type<JessicaAst.jexpr> record
%type<JessicaAst.jexpr> arrow_func
%type<list JessicaAst.jexpr> elements
%type<list JessicaAst.jexpr> args
%type<list JessicaAst.jprop> props
%type<JessicaAst.jprop> propDef
%type<list string> names
%type<JessicaAst.jbody> arrow_body

(* A.3 Statements *)
%type<JessicaAst.jstmt> stmt
%type<JessicaAst.jstmt> decl_stmt
%type<JessicaAst.jstmt> if_stmt
%type<JessicaAst.jstmt> const_stmt
%type<JessicaAst.jstmt> let_stmt
%type<JessicaAst.jstmt> return_stmt
%type<JessicaAst.jstmt> throw_stmt
%type<JessicaAst.jstmt> assert_stmt
%type<JessicaAst.jstmt> expr_stmt
%type<list JessicaAst.jstmt> block
%type<list JessicaAst.jstmt> stmts

(* Shared parenthesized contents; re-interpreted per context (cover grammar).
   [args] doubles as the cover for parenthesized expressions, call arguments,
   and arrow-parameter lists (see the Supplemental-Syntax reinterpretations in
   the actions). *)
(* Arrow / pattern parameters *)

(* A.5 Scripts and Modules *)
%type<JessicaAst.jdecl> decl
%type<list JessicaAst.jdecl> decls

%%

(*** A.5 Scripts and Modules *)

(* start <- _WS moduleBody _EOF;  moduleBody <- moduleItem*;
   (subset: const declarations and import declarations) *)
parse_jessie : decls EOF { JessicaAst.JModule $1 }

(* Justin start: a single expression, mirroring upstream justin's
   ['_WS assignExpr _EOF'].  Reuses the shared [expr] grammar (which
   includes arrow funcs, assignment and call/chains). *)
parse_justin : expr EOF { $1 }

decls :
  /* empty */           { [] }
| decl decls            { $1 :: $2 }

names :
  /* empty */           { [] }
| IDENT                 { [ $1 ] }
| names COMMA IDENT     { $3 :: $1 }

decl :
  CONST IDENT EQUALS expr SEMI
    { JessicaAst.JConst [JessicaAst.JBind (JessicaAst.JDef $2) $4] }
| CONST LBRACE names RBRACE EQUALS expr SEMI
    { JessicaAst.JConst [JessicaAst.JBind (JessicaAst.JMatchObj (rev $3)) $6] }
| IMPORT LBRACE IDENT RBRACE FROM STRING SEMI
    { JessicaAst.JImport [JessicaAst.JImportAs $3 $3] $6 }
| decl_stmt
    { JessicaAst.JStmt $1 }

(* Top-level statements other than const/let declarations (which are parsed as
   [JConst] decls above).  These mirror the statement subset the module
   grammar accepts so far.  [return] is excluded: a top-level return is an
   early error in ECMAScript. *)
decl_stmt :
  throw_stmt       { $1 }
| assert_stmt      { $1 }
| expr_stmt        { $1 }

(*** A.2 Expressions *)

(* assignExpr <-
     arrowFunc / lValue postOp / lValue (EQUALS / assignOp) assignExpr
     / super.assignExpr / primaryExpr;
   (subset: += and -= assignOp, identical-LHS arrow, "<" comparison) *)
expr :
  arrow_func                    { $1 }
| IDENT EQUALS expr
    { JessicaAst.JAssign (JessicaAst.JUse $1) $3 }
| post PLUSEQ expr
    { JessicaAst.JAssignOp "+=" $1 $3 }
| post MINUSEQ expr
    { JessicaAst.JAssignOp "-=" $1 $3 }
| post LT post
    { JessicaAst.JGreater $3 $1 }
| BANG expr
    { JessicaAst.JPreOp "!" $2 }
| VOID post
    { JessicaAst.JPreOp "void" $2 }
| post                       { $1 }

(* arrowFunc <- arrowParams _NO_NEWLINE ARROW block
             / arrowParams _NO_NEWLINE ARROW assignExpr;
   (subset: the = included in the arrow body is not allowed here;
    _NO_NEWLINE not enforced)

   The parenthesized-parameter form shares the [args] cover with
   parenthesized expressions and call arguments; the list is
   re-interpreted as patterns here (Supplemental Syntax / "must cover"). *)
arrow_func :
  IDENT ARROW arrow_body
    { JessicaAst.JArrow [JessicaAst.JDef $1] $3 }
| LPAREN args RPAREN ARROW arrow_body
    { JessicaAst.JArrow (params_of_exprs $2) $5 }

(* arrowBody <- block / parenExpr / assignExpr;
   (see the note on arrow_func: the direct expression body must not
    start with "{" or "[", matching upstream's block-first priority) *)
arrow_body :
  block                     { JessicaAst.JBodyBlock $1 }
| expr_body                 { JessicaAst.JBodyExpr $1 }

expr_body :
  arrow_func                    { $1 }
| IDENT EQUALS expr
    { JessicaAst.JAssign (JessicaAst.JUse $1) $3 }
| post_nocollision PLUSEQ expr
    { JessicaAst.JAssignOp "+=" $1 $3 }
| post_nocollision MINUSEQ expr
    { JessicaAst.JAssignOp "-=" $1 $3 }
| post_nocollision LT post
    { JessicaAst.JGreater $3 $1 }
| BANG expr
    { JessicaAst.JPreOp "!" $2 }
| VOID post_nocollision
    { JessicaAst.JPreOp "void" $2 }
| post_nocollision           { $1 }

(* primaryExpr <- super.primaryExpr / quasiExpr / LEFT_PAREN expr RIGHT_PAREN
                  / useVar; *)
primary :
  atom                 { $1 }
| array                { $1 }
| record               { $1 }
| paren_expr           { $1 }

primary_nocollision :
  atom                 { $1 }
| paren_expr           { $1 }

atom :
  STRING     { JessicaAst.JDataString $1 }
| NUMBER     { JessicaAst.JDataNum $1 }
| BIGINT     { JessicaAst.JDataBigint $1 }
| IDENT      { JessicaAst.JUse $1 }

paren_expr : LPAREN args RPAREN { paren_singleton $2 }

(* callExpr <- primaryExpr callPostOp*;  callPostOp <- memberPostOp / args;
   memberPostOp <- ... / DOT IDENT_NAME / ... *)
post :
  primary                     { $1 }
| post DOT IDENT        { JessicaAst.JGet $1 $3 }
| post LPAREN args RPAREN { JessicaAst.JCall $1 $3 }

post_nocollision :
  primary_nocollision         { $1 }
| post_nocollision DOT IDENT { JessicaAst.JGet $1 $3 }
| post_nocollision LPAREN args RPAREN { JessicaAst.JCall $1 $3 }

(* args <- LEFT_PAREN arg ** _COMMA RIGHT_PAREN;
   (cover grammar) Parenthesized expressions, call arguments and
   arrow-parameter lists all share this one "[expr list]" shape; the empty
   case covers "()" (empty call args and empty arrow params). *)
args :
  /* empty */             { [] }
| expr                     { [ $1 ] }
| expr COMMA args          { $1 :: $3 }

(* array <- LEFT_BRACKET element ** _COMMA _COMMA? RIGHT_BRACKET;
   (trailing comma is folded into elements so the grammar is LR(1)) *)
array :
  LBRACKET RBRACKET             { JessicaAst.JArray [] }
| LBRACKET elements RBRACKET    { JessicaAst.JArray (rev $2) }

elements :
  expr                        { [ $1 ] }
| elements COMMA expr         { $3 :: $1 }
| elements COMMA              { $1 }

(* record <- LEFT_BRACE propDef ** _COMMA _COMMA? RIGHT_BRACE;
   (trailing comma folded into props, as for arrays) *)
record :
  LBRACE RBRACE               { JessicaAst.JRecord [] }
| LBRACE props RBRACE         { JessicaAst.JRecord (rev $2) }

props :
  propDef                     { [ $1 ] }
| props COMMA propDef         { $3 :: $1 }
| props COMMA                 { $1 }

(* propDef <- propName COLON assignExpr;
   propName <- IDENT_NAME / NUMBER;
   (subset: numeric propNames omitted -- not used by the current examples;
    a number-to-string helper would be needed to re-add them) *)
propDef :
  IDENT COLON expr     { JessicaAst.JProp $1 $3 }
| IDENT LPAREN args RPAREN block
    { JessicaAst.JProp $1 (JessicaAst.JArrow (params_of_exprs $3) (JessicaAst.JBodyBlock $5)) }

(*** A.3 Statements *)

(* statement <- block / IF ... / breakableStatement / terminator
                / IDENT COLON statement / TRY ... / exprStatement;
   (subset below) *)
stmt :
  if_stmt                { $1 }
| const_stmt             { $1 }
| let_stmt               { $1 }
| return_stmt            { $1 }
| throw_stmt             { $1 }
| assert_stmt            { $1 }
| expr_stmt              { $1 }

(* block <- LEFT_BRACE body RIGHT_BRACE;  body <- statementItem*; *)
block : LBRACE stmts RBRACE { $2 }

stmts :
  /* empty */      { [] }
| stmt stmts       { $1 :: $2 }

(* if statement: IF LEFT_PAREN expr RIGHT_PAREN arm (ELSE elseArm)?
   (arm <- block;  elseArm <- arm) *)
if_stmt :
  IFKW LPAREN expr RPAREN block ELSE block
    { JessicaAst.JIf $3 $5 (Some $7) }
| IFKW LPAREN expr RPAREN block
    { JessicaAst.JIf $3 $5 None }

(* declaration <- declOp binding ** _COMMA SEMI;
   (subset: const and let with single binding) *)
const_stmt :
  CONST IDENT EQUALS expr SEMI
    { JessicaAst.JConstStmt [JessicaAst.JBind (JessicaAst.JDef $2) $4] }

let_stmt :
  LET IDENT EQUALS expr SEMI
    { JessicaAst.JLet [JessicaAst.JBind (JessicaAst.JDef $2) $4] }
| LET IDENT SEMI
    { JessicaAst.JLetNames [JessicaAst.JDef $2] }

(* terminator <- ... / "return" ... / "throw" ...; *)
return_stmt : RETURN expr SEMI { JessicaAst.JReturn $2 }

throw_stmt : THROW expr SEMI { JessicaAst.JThrow $2 }

(* assert_stmt: not in upstream Jessie; used by the escrow examples *)
assert_stmt : ASSERT LPAREN expr RPAREN SEMI { JessicaAst.JAssert $3 }

(* exprStatement <- ~cantStartExprStatement expr SEMI; *)
expr_stmt : expr SEMI { JessicaAst.JExprStmt $1 }