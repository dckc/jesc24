(* JSON grammar for Menhir's Coq backend.

    Mirrors the grammar in
    https://github.com/endojs/Jessie/blob/main/packages/parse/src/quasi-json.js

    Subsets of JavaScript, starting from the grammar as defined at
    http://www.ecma-international.org/ecma-262/9.0/#sec-grammar-summary *)

%{

From Coq Require Import String ZArith.
From Coq Require Import Lists.List.
From jessie Require Import jessica_ast.
Import ListNotations.
Open Scope string_scope.

%}

%token LBRACE RBRACE LBRACKET RBRACKET COMMA COLON EOF
%token<Z> NUMBER
%token<string> STRING

%start<JessicaAst.jexpr> parse_json
%type<JessicaAst.jexpr> value
%type<JessicaAst.jexpr> array
%type<JessicaAst.jexpr> record
%type<list JessicaAst.jexpr> elements
%type<list JessicaAst.jprop> props

%%

parse_json : value EOF     { $1 }

value :
  NUMBER                     { JessicaAst.JDataNum $1 }
| STRING                     { JessicaAst.JDataString $1 }
| array                      { $1 }
| record                     { $1 }

array :
  LBRACKET RBRACKET          { JessicaAst.JArray [] }
| LBRACKET elements RBRACKET { JessicaAst.JArray (rev $2) }

elements :
  value                      { $1 :: [] }
| elements COMMA value       { $3 :: $1 }

record :
  LBRACE RBRACE              { JessicaAst.JRecord [] }
| LBRACE props RBRACE        { JessicaAst.JRecord (rev $2) }

props :
  STRING COLON value         { JessicaAst.JProp $1 $3 :: [] }
| props COMMA STRING COLON value { JessicaAst.JProp $3 $5 :: $1 }