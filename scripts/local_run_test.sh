#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# run_test.sh  —  CS340400 HW3 local test runner
# Usage:
#   run_test                              → runs all testcases
#   run_test array_decl_wo_init           → runs testcases/array_decl_wo_init only
#   run_test debug array_decl_wo_init     → compile and print raw output, no diff
# ─────────────────────────────────────────────────────────────

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/../src"
TESTCASE_DIR="$SCRIPT_DIR/../testcases"
BUILD_DIR="$SCRIPT_DIR/tmp_build"
trap 'rm -rf "$BUILD_DIR"' EXIT
PASS=0
FAIL=0
ERRORS=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   CS340400 HW3 — Local Test Runner       ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── Step 1: Check scanner.l and parser.y exists ───────────────────────────
echo -e "${CYAN}[1/4] Checking source files...${NC}"

if [ ! -f "$SRC_DIR/scanner.l" ]; then
    echo -e "${RED}  ✗ scanner.l not found in ./src/${NC}"
    echo -e "    Make sure your file is at: ./src/scanner.l"
    exit 1
fi

echo -e "${GREEN}  ✓ scanner.l found${NC}"

if [ ! -f "$SRC_DIR/parser.y" ]; then
    echo -e "${RED}  ✗ parser.y not found in ./src/${NC}"
    echo -e "    Make sure your file is at: ./src/parser.y"
    exit 1
fi

echo -e "${GREEN}  ✓ parser.y found${NC}"

# ── Step 2: Compile ───────────────────────────────────────────
echo ""
echo -e "${CYAN}[2/4] Compiling...${NC}"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cp "$SRC_DIR/scanner.l" "$BUILD_DIR/scanner.l"
cp "$SRC_DIR/parser.y" "$BUILD_DIR/parser.y"
cp "$SRC_DIR/Makefile" "$BUILD_DIR/Makefile"
cd "$BUILD_DIR"

COMPILE_OUTPUT=$(make 2>&1)
COMPILE_EXIT=$?

if [ $COMPILE_EXIT -ne 0 ]; then
    echo -e "${RED}  ✗ Compilation failed:${NC}"
    echo "$COMPILE_OUTPUT"
    exit 1
fi

if echo "$COMPILE_OUTPUT" | grep -qi "warning"; then
    echo -e "${YELLOW}  ⚠ Compilation succeeded but with WARNINGS:${NC}"
    echo "$COMPILE_OUTPUT" | grep -i "warning"
    echo -e "${YELLOW}    Warnings carry a -20pt penalty on the server!${NC}"
else
    echo -e "${GREEN}  ✓ Compiled cleanly (no warnings)${NC}"
fi

if [ ! -f "$BUILD_DIR/codegen" ]; then
    echo -e "${RED}  ✗ 'codegen' binary not found after make.${NC}"
    exit 1
fi

# ── Debug mode: side-by-side your output and golden ──────────
if [ "${1:-}" = "debug" ]; then
    TESTCASE="${2:-}"
    if [ -z "$TESTCASE" ]; then
        echo -e "${RED}  Usage: run_test debug <testcase_name>${NC}"
        exit 1
    fi
    input_file="$TESTCASE_DIR/${TESTCASE}.txt"
    if [ ! -f "$input_file" ]; then
        echo -e "${RED}  ✗ Testcase not found: $input_file${NC}"
        exit 1
    fi
    echo ""
    echo -e "${CYAN}[3/4] Debug: $TESTCASE${NC}"
    echo ""
    echo -e "${YELLOW}--- Your output ---${NC}"
    "$BUILD_DIR/codegen" < "$input_file" 2>&1
    echo ""
    echo -e "${YELLOW}--- Golden output ---${NC}"
    cat "$TESTCASE_DIR/answers/${TESTCASE}_answer.txt"
    exit 0
fi

# ── Step 3: Run testcases ─────────────────────────────────────
echo ""
echo -e "${CYAN}[3/4] Running testcases...${NC}"
echo ""

FILTER="${1:-}"

for input_file in "$TESTCASE_DIR"/*.txt; do
    testname=$(basename "$input_file" .txt)

    if [ -n "$FILTER" ] && [ "$testname" != "$FILTER" ]; then
        continue
    fi

    student_out=$("$BUILD_DIR/codegen" < "$input_file" 2>/dev/null) || {
        echo -e "${RED}  CRASH ${testname} — codegen exited with error${NC}"
        ERRORS=$((ERRORS + 1))
        continue
    }

    golden_out=$(cat "$TESTCASE_DIR/answers/${testname}_answer.txt")

    diff_result=$(diff <(printf '%s' "$student_out") <(printf '%s' "$golden_out") || true)

    if [ -z "$diff_result" ]; then
        echo -e "${GREEN}  PASS  ${testname}${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}  FAIL  ${testname}${NC}"
        echo -e "${YELLOW}  --- your output vs golden output (first 20 diff lines) ---${NC}"
        echo "$diff_result" | head -20
        echo ""
        FAIL=$((FAIL + 1))
    fi
done

# ── Step 4: Summary ───────────────────────────────────────────
echo ""
echo -e "${CYAN}[4/4] Summary${NC}"
echo -e "  ${GREEN}Passed: $PASS${NC}"
echo -e "  ${RED}Failed: $FAIL${NC}"
if [ $ERRORS -gt 0 ]; then
    echo -e "  ${RED}Crashed: $ERRORS${NC}"
fi

TOTAL=$((PASS + FAIL + ERRORS))
echo -e "  Total:  $TOTAL"
echo ""

if [ $TOTAL -eq 0 ]; then
    echo -e "${YELLOW}${BOLD}  No testcases found in $TESTCASE_DIR${NC}"
    echo -e "  Make sure testcases/*.txt files exist."
elif [ $FAIL -eq 0 ] && [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}  All testcases passed! ✓${NC}"
else
    echo -e "${RED}${BOLD}  Some testcases failed. Keep debugging!${NC}"
fi

echo ""
