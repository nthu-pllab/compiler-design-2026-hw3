#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# run_test.sh  —  CS340400 HW3 local test runner
# Usage:
#   run_test                   → runs all testcases
#   run_test Basic/0           → runs a single testcase
#   run_test.sh ArithmeticExpression/1  → run a single testcase
#   run_test debug Basic/0     → debug mode (print assembly + run spike)
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

SPIKE="spike --isa=rv32imafc pk"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   CS340400 HW3 — Local Test Runner       ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── Step 1: Check files ───────────────────────────────────────
echo -e "${CYAN}[1/4] Checking source files...${NC}"

if [ ! -f "$SRC_DIR/scanner.l" ]; then
    echo -e "${RED}  ✗ scanner.l missing${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ scanner.l found${NC}"

if [ ! -f "$SRC_DIR/parser.y" ]; then
    echo -e "${RED}  ✗ parser.y missing${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ parser.y found${NC}"

if [ ! -f "$SRC_DIR/main.c" ]; then
    echo -e "${RED}  ✗ main.c missing${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ main.c found${NC}"

# ── Step 2: Compile ───────────────────────────────────────────
echo ""
echo -e "${CYAN}[2/4] Compiling...${NC}"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cp "$SRC_DIR/"* "$BUILD_DIR/" 2>/dev/null || true
cd "$BUILD_DIR"

COMPILE_OUTPUT=$(make 2>&1)
COMPILE_EXIT=$?

if [ $COMPILE_EXIT -ne 0 ]; then
    echo -e "${RED}  ✗ Compilation failed:${NC}"
    echo "$COMPILE_OUTPUT"
    exit 1
fi

echo -e "${GREEN}  ✓ Compiled successfully${NC}"

if [ ! -f "$BUILD_DIR/codegen" ]; then
    echo -e "${RED}  ✗ codegen binary not found${NC}"
    exit 1
fi

# ── Debug mode ───────────────────────────────────────────────
if [ "${1:-}" = "debug" ]; then
    TESTCASE="${2:-}"
    input_file="$TESTCASE_DIR/${TESTCASE}.c"

    echo ""
    echo -e "${CYAN}[DEBUG] $TESTCASE${NC}"

    rm -f codegen.S a.out golden.S

    "$BUILD_DIR/codegen" < "$input_file" >/dev/null 2>&1

    echo ""
    echo "--- Your assembly ---"
    cat codegen.S

    echo ""
    echo "--- Golden assembly ---"
    riscv32-unknown-elf-gcc -S -c "$input_file" -o golden.S
    cat golden.S

    echo ""
    echo "--- Run ---"
    riscv32-unknown-elf-gcc main.c codegen.S -o a.out
    $SPIKE a.out

    exit 0
fi

# ── Step 3: Run tests ─────────────────────────────────────────
echo ""
echo -e "${CYAN}[3/4] Running tests...${NC}"
echo ""

FILTER="${1:-}"

for input_file in "$TESTCASE_DIR"/*.c; do
    testname=$(basename "$input_file" .c)

    if [ -n "$FILTER" ] && [ "$testname" != "$FILTER" ]; then
        continue
    fi

    rm -f codegen.S a.out golden.S

    "$BUILD_DIR/codegen" < "$input_file" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}  CRASH $testname (codegen failed)${NC}"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    riscv32-unknown-elf-gcc main.c codegen.S -o a.out >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}  CRASH $testname (gcc failed)${NC}"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    student_out=$($SPIKE a.out 2>/dev/null)

    riscv32-unknown-elf-gcc -S -c "$input_file" -o golden.S >/dev/null 2>&1
    golden_out=$($SPIKE golden.S 2>/dev/null)

    diff_result=$(diff <(printf "%s" "$student_out") <(printf "%s" "$golden_out") || true)

    if [ -z "$diff_result" ]; then
        echo -e "${GREEN}  PASS $testname${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}  FAIL $testname${NC}"
        echo "$diff_result" | head -20
        FAIL=$((FAIL + 1))
    fi
done

# ── Step 4: Summary ───────────────────────────────────────────
echo ""
echo -e "${CYAN}[4/4] Summary${NC}"
echo -e "  Passed: $PASS"
echo -e "  Failed: $FAIL"
echo -e "  Crashed: $ERRORS"
echo ""

TOTAL=$((PASS + FAIL + ERRORS))

if [ $FAIL -eq 0 ] && [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}All tests passed ✓${NC}"
else
    echo -e "${RED}${BOLD}Some tests failed${NC}"
fi

echo ""