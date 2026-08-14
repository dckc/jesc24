#!/usr/bin/env bash
# Ad-hoc mutation testing for the Jessie/Justin/JSON Menhir grammars.
#
# Strategy: for each mutation, apply a sed transform to a grammar file
# (jesc_parser.vy / json_parser.vy), regenerate the Coq parser with
# `menhir --coq`, rebuild, and check whether any Example test fails.
#
#   - If the build fails on an Example proof (grep "Unable to unify"),
#     the mutant was KILLED by a test (good coverage).
#   - If menhir/coq rejects the generated grammar or parser, the mutant
#     was KILLED by the pipeline (still caught, but not by the tests).
#   - If the build succeeds with no failing examples, the mutant
#     SURVIVED (coverage gap -- add a distinguishing test).
#
# Usage:
#   ./tools/mutation_test.sh                 # run all mutations
#   ./tools/mutation_test.sh <label>...      # run only the listed mutations
#
# Run from the worktree root.

set -uo pipefail

WORKDIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$WORKDIR"

# Grammars to mutate and their generated Coq parser files.
JESC_VY="theories/jessie/jesc_parser.vy"
JESC_V="theories/jessie/jesc_parser.v"
JSON_VY="theories/jessie/json_parser.vy"
JSON_V="theories/jessie/json_parser.v"

# Build command. Regenerating the grammar's parser only requires building the
# chain that depends on it; the top-level `all` target runs menhir whenever the
# generated .v is missing or older than its .vy.
build() {
  nix develop --command make -j"$(nproc)" 2>&1
}

KILLED_TEST=0
KILLED_PIPE=0
SURVIVED=0
ERRORS=0

only=("$@")

run_mutation() {
  local name="$1" file="$2" gen="$3" sed_expr="$4" desc="$5"

  # Selective run support: ./tools/mutation_test.sh <label>...
  if ((${#only[@]} > 0)) && ! printf '%s\n' "${only[@]}" | grep -qx "$name"; then
    return
  fi

  echo "=== MUTATION: $name ==="
  echo "  file: $file"
  echo "  desc: $desc"
  echo "  sed:  $sed_expr"

  cp "$file" "$file.bak"
  if sed -i "$sed_expr" "$file"; then
    # Force regeneration of the Coq parser from the mutated grammar.
    rm -f "$gen"
    local output
    output="$(build 2>&1)" || true

    if echo "$output" | grep -q "Unable to unify"; then
      echo "  KILLED (Example proof failed -- test caught it)"
      KILLED_TEST=$((KILLED_TEST + 1))
    elif echo "$output" | grep -q "Error:"; then
      echo "  KILLED (menhir/coq rejected the mutated grammar)"
      KILLED_PIPE=$((KILLED_PIPE + 1))
    else
      echo "  SURVIVED -- no test caught this mutation!"
      SURVIVED=$((SURVIVED + 1))
    fi
  else
    echo "  ERROR (sed failed)"
    ERRORS=$((ERRORS + 1))
  fi

  cp "$file.bak" "$file"
  rm -f "$file.bak" "$gen"
  echo ""
}

echo "Starting mutation testing..."
echo "=============================="
echo ""

# --- json_parser.vy mutations (caught by json_test.v) ---

# Killed: test_empty_array  -- "[]" must no longer parse
run_mutation "json-no-empty-array" "$JSON_VY" "$JSON_V" \
  '/LBRACKET RBRACKET.*JArray \[\]/d' \
  "array: remove empty-alternative so [] is rejected"

# Killed: test_empty_record -- "{}" must no longer parse
run_mutation "json-no-empty-record" "$JSON_VY" "$JSON_V" \
  '/LBRACE RBRACE.*JRecord \[\]/d' \
  "record: remove empty-alternative so {} is rejected"

# Killed: test_array_with_elems, test_nested -- arrays with >1 element
run_mutation "json-no-multi-elements" "$JSON_VY" "$JSON_V" \
  '/^| elements COMMA value/d' \
  "array: only single-element arrays"

# Killed: test_multiple_props -- records with >1 prop
run_mutation "json-no-multi-props" "$JSON_VY" "$JSON_V" \
  '/^| props COMMA STRING COLON value/d' \
  "record: only single-prop records"

# Killed: test_record_with_prop, test_array_with_elems
run_mutation "json-no-string-value" "$JSON_VY" "$JSON_V" \
  '/^| STRING .*JDataString/d' \
  "value: strings are not a value"

# Killed: test_number, test_negative_number
run_mutation "json-no-number-value" "$JSON_VY" "$JSON_V" \
  '/^| NUMBER .*JDataNum/d' \
  "value: numbers are not a value"

# Killed: test_rejects_trailing_garbage (negative test) -- "1 2" must be rejected
run_mutation "json-reject-trailing-garbage" "$JSON_VY" "$JSON_V" \
  's/parse_json : value EOF/parse_json : value/' \
  "parse_json: drop the EOF guard so trailing garbage is accepted"

# Killed: test_array_with_elems -- AST order differs (drops rev)
run_mutation "json-array-no-rev" "$JSON_VY" "$JSON_V" \
  's/JArray (rev \$2)/JArray \$2/' \
  "array: action drops rev, so element order in the AST is wrong"

# --- jesc_parser.vy mutations (caught by jesc_test.v) ---

# Killed: test_jessie_import
run_mutation "jesc-no-import" "$JESC_VY" "$JESC_V" \
  '/^| IMPORT LBRACE IDENT RBRACE FROM STRING SEMI/,+1d' \
  "decl: remove import declarations"

# Killed: test_jessie_let_uninitialized
run_mutation "jesc-no-let-names" "$JESC_VY" "$JESC_V" \
  '/^| LET IDENT SEMI/,+1d' \
  "let_stmt: remove uninitialized let (let x;)"

# Killed: test_jessie_if_else
run_mutation "jesc-no-if-else" "$JESC_VY" "$JESC_V" \
  '/^  IFKW LPAREN expr RPAREN block ELSE block/,+1d' \
  "if_stmt: remove the else arm"

# Killed: test_justin_get, test_justin_get_call
run_mutation "jesc-no-member-access" "$JESC_VY" "$JESC_V" \
  '/^| post DOT IDENT /d' \
  "post: remove .field member access (x.y)"

# Killed: test_justin_call -- f(1,2) with arguments
run_mutation "jesc-no-multi-arg-call" "$JESC_VY" "$JESC_V" \
  '/^| post LPAREN args RPAREN/d' \
  "post: remove call-with-args, only f()"

# Killed: test_justin_array_empty
run_mutation "jesc-no-empty-array" "$JESC_VY" "$JESC_V" \
  '/^  LBRACKET RBRACKET.*JArray \[\]/d' \
  "array: remove empty array so [] is rejected"

# Killed: test_justin_array_trailing_comma
run_mutation "jesc-no-trailing-comma-elements" "$JESC_VY" "$JESC_V" \
  '/^| elements COMMA *{/d' \
  "elements: remove trailing-comma alternative"

# Killed: test_justin_record_trailing_comma
run_mutation "jesc-no-trailing-comma-props" "$JESC_VY" "$JESC_V" \
  '/^| props COMMA *{/d' \
  "props: remove trailing-comma alternative"

# Killed: test_justin_not
run_mutation "jesc-no-prefix-not" "$JESC_VY" "$JESC_V" \
  '/^| BANG expr/,+1d' \
  "expr: remove the ! prefix (both expr and expr_body)"

# Killed: test_justin_less -- 0 < c.incr()
run_mutation "jesc-no-less-than" "$JESC_VY" "$JESC_V" \
  '/^| post LT post/,+1d' \
  "expr: remove the < comparison"

# Killed: test_justin_assign_op -- x += 1 builds JAssignOp -=
run_mutation "jesc-pluseq-builds-minus" "$JESC_VY" "$JESC_V" \
  's/JAssignOp "+="/JAssignOp "-="/g' \
  "expr: PLUSEQ action builds -= instead of += (AST change)"

# Killed: test_justin_arrow -- x => 1
run_mutation "jesc-no-single-ident-arrow" "$JESC_VY" "$JESC_V" \
  '/^  IDENT ARROW arrow_body/,+1d' \
  "arrow_func: remove single-ident arrow (x => ...)"

# Killed: test_justin_arrow_empty -- () => 1
run_mutation "jesc-no-empty-params-arrow" "$JESC_VY" "$JESC_V" \
  '/^| LPAREN_ARROW RPAREN_ARROW ARROW arrow_body/,+1d' \
  "arrow_func: remove empty-parens arrow (() => ...)"

# Killed: test_justin_arrow_params -- (a, b) => a
run_mutation "jesc-no-multi-param-arrow" "$JESC_VY" "$JESC_V" \
  '/^| LPAREN_ARROW param_list RPAREN_ARROW ARROW arrow_body/,+1d' \
  "arrow_func: remove multi-param arrow ((a, b) => ...)"

# Killed: test_justin_number, test_justin_negative_number
run_mutation "jesc-no-number-atom" "$JESC_VY" "$JESC_V" \
  '/^| NUMBER .*JDataNum/d' \
  "atom: numbers are not an atom"

# Killed: test_justin_rejects_two_numbers (negative test) -- "1 2" must be rejected
run_mutation "jesc-reject-trailing-garbage-justin" "$JESC_VY" "$JESC_V" \
  's/parse_justin : expr EOF/parse_justin : expr/' \
  "parse_justin: drop the EOF guard so trailing garbage is accepted"

echo "=============================="
echo "Mutation testing complete."
echo "  KILLED (test caught):  $KILLED_TEST"
echo "  KILLED (menhir/coq):   $KILLED_PIPE"
echo "  SURVIVED:              $SURVIVED  (coverage gap -- add a test)"
echo "  ERRORS:                $ERRORS"
echo ""

# Restore/log note: each mutation restores its grammar; a final plain build
# leaves the pristine grammars' parsers regenerated.
echo "Note: surviving mutants are coverage gaps. If a mutant is not"
echo "semantically equivalent, add a test that distinguishes it."
echo "Run 'make' (or 'nix develop --command make') to rebuild the pristine parsers."

# TODO(parser): each jesc_* mutation rebuilds make_counter.vo because
# jesc_test.v imports make_counter just to get the SourceMakeCounter AST
# defs, dragging in ~25s of parser-irrelevant Iris proofs. Factor the
# SourceMakeCounter module (and similar source-target modules) into their
# own small files so parser mutations only rebuild the cheap jesc chain.
exit 0