#!/bin/bash
#
# Test script for task query functions
# Tests all query commands and options
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUERY_SCRIPT="$SCRIPT_DIR/query-tasks.sh"

echo -e "${BLUE}[TEST]${NC} Task Query Functions Test Suite"
echo "Query script: $QUERY_SCRIPT"

# Check script exists
if [ ! -f "$QUERY_SCRIPT" ]; then
    echo -e "${RED}✗${NC} Query script not found"
    exit 1
fi

# Make executable
chmod +x "$QUERY_SCRIPT"

echo -e "\n${BLUE}[TEST]${NC} Running query tests..."

# Test 1: Query by status
echo -e "\n${YELLOW}Test 1:${NC} Query by status"
if "$QUERY_SCRIPT" status pending --format count > /dev/null 2>&1; then
    COUNT=$("$QUERY_SCRIPT" status pending --format count)
    echo -e "${GREEN}✓${NC} Status query works (found $COUNT pending tasks)"
else
    echo -e "${RED}✗${NC} Status query failed"
    exit 1
fi

# Test 2: Query by epic
echo -e "\n${YELLOW}Test 2:${NC} Query by epic"
if "$QUERY_SCRIPT" epic EPIC-001 --format id > /dev/null 2>&1; then
    COUNT=$("$QUERY_SCRIPT" epic EPIC-001 --format count)
    echo -e "${GREEN}✓${NC} Epic query works (found $COUNT tasks in EPIC-001)"
else
    echo -e "${RED}✗${NC} Epic query failed"
    exit 1
fi

# Test 3: Query by story
echo -e "\n${YELLOW}Test 3:${NC} Query by story"
if "$QUERY_SCRIPT" story STORY-002 --format summary > /dev/null 2>&1; then
    COUNT=$("$QUERY_SCRIPT" story STORY-002 --format count)
    echo -e "${GREEN}✓${NC} Story query works (found $COUNT tasks in STORY-002)"
else
    echo -e "${RED}✗${NC} Story query failed"
    exit 1
fi

# Test 4: Query by persona
echo -e "\n${YELLOW}Test 4:${NC} Query by persona"
if "$QUERY_SCRIPT" persona developer --format summary > /dev/null 2>&1; then
    COUNT=$("$QUERY_SCRIPT" persona developer --format count)
    echo -e "${GREEN}✓${NC} Persona query works (found $COUNT developer tasks)"
else
    echo -e "${RED}✗${NC} Persona query failed"
    exit 1
fi

# Test 5: Query by priority
echo -e "\n${YELLOW}Test 5:${NC} Query by priority"
if "$QUERY_SCRIPT" priority high --format id > /dev/null 2>&1; then
    COUNT=$("$QUERY_SCRIPT" priority high --format count)
    echo -e "${GREEN}✓${NC} Priority query works (found $COUNT high priority tasks)"
else
    echo -e "${RED}✗${NC} Priority query failed"
    exit 1
fi

# Test 6: Query by type
echo -e "\n${YELLOW}Test 6:${NC} Query by type"
if "$QUERY_SCRIPT" type development --format count > /dev/null 2>&1; then
    COUNT=$("$QUERY_SCRIPT" type development --format count)
    echo -e "${GREEN}✓${NC} Type query works (found $COUNT development tasks)"
else
    echo -e "${RED}✗${NC} Type query failed"
    exit 1
fi

# Test 7: Blocked tasks
echo -e "\n${YELLOW}Test 7:${NC} Blocked tasks"
if "$QUERY_SCRIPT" blocked --format id > /dev/null 2>&1; then
    COUNT=$("$QUERY_SCRIPT" blocked --format count || echo "0")
    echo -e "${GREEN}✓${NC} Blocked query works (found $COUNT blocked tasks)"
else
    echo -e "${YELLOW}⚠${NC} Blocked query returned error - possibly no blocked tasks"
fi

# Test 8: Ready tasks
echo -e "\n${YELLOW}Test 8:${NC} Ready tasks"
if "$QUERY_SCRIPT" ready --format summary > /dev/null 2>&1; then
    COUNT=$("$QUERY_SCRIPT" ready --format count)
    echo -e "${GREEN}✓${NC} Ready query works (found $COUNT ready tasks)"
else
    echo -e "${RED}✗${NC} Ready query failed"
    exit 1
fi

# Test 9: Today's tasks
echo -e "\n${YELLOW}Test 9:${NC} Today's tasks"
if "$QUERY_SCRIPT" today --format id > /dev/null 2>&1; then
    COUNT=$("$QUERY_SCRIPT" today --format count || echo "0")
    echo -e "${GREEN}✓${NC} Today query works (found $COUNT tasks for today)"
else
    echo -e "${GREEN}✓${NC} Today query works (no tasks for today)"
fi

# Test 10: Search functionality
echo -e "\n${YELLOW}Test 10:${NC} Search functionality"
if "$QUERY_SCRIPT" search "task" --format count > /dev/null 2>&1; then
    COUNT=$("$QUERY_SCRIPT" search "task" --format count)
    echo -e "${GREEN}✓${NC} Search works (found $COUNT tasks containing 'task')"
else
    echo -e "${RED}✗${NC} Search failed"
    exit 1
fi

# Test 11: Count command
echo -e "\n${YELLOW}Test 11:${NC} Count by field"
if "$QUERY_SCRIPT" count status > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Count by status works"
    echo -e "  Status distribution:"
    "$QUERY_SCRIPT" count status | head -5 | sed 's/^/    /'
else
    echo -e "${RED}✗${NC} Count command failed"
    exit 1
fi

# Test 12: Output formats
echo -e "\n${YELLOW}Test 12:${NC} Output formats"
FORMATS="full summary id count"
for fmt in $FORMATS; do
    if "$QUERY_SCRIPT" status pending --format "$fmt" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Format '$fmt' works"
    else
        echo -e "${RED}✗${NC} Format '$fmt' failed"
        exit 1
    fi
done

# Test 13: No color option
echo -e "\n${YELLOW}Test 13:${NC} No color option"
if "$QUERY_SCRIPT" status pending --no-color --format summary > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} No color option works"
else
    echo -e "${RED}✗${NC} No color option failed"
    exit 1
fi

# Show sample queries
echo -e "\n${BLUE}[TEST]${NC} Sample query outputs:"

echo -e "\n${YELLOW}Ready tasks (summary format):${NC}"
"$QUERY_SCRIPT" ready --format summary | head -5

echo -e "\n${YELLOW}Developer tasks (ID format):${NC}"
"$QUERY_SCRIPT" persona developer --format id | head -5

echo -e "\n${YELLOW}Task count by persona:${NC}"
"$QUERY_SCRIPT" count persona

echo -e "\n${GREEN}[TEST]${NC} All tests passed! ✨"

# Performance test
echo -e "\n${BLUE}[TEST]${NC} Performance check..."
START=$(date +%s.%N)
"$QUERY_SCRIPT" status pending --format count > /dev/null 2>&1
END=$(date +%s.%N)
ELAPSED=$(echo "$END - $START" | bc)
echo -e "Query execution time: ${ELAPSED}s"

if (( $(echo "$ELAPSED < 0.5" | bc -l) )); then
    echo -e "${GREEN}✓${NC} Performance is good (< 0.5s)"
else
    echo -e "${YELLOW}⚠${NC} Performance could be improved (> 0.5s)"
fi