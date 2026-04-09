#!/bin/bash

# ============================================================
#  __run_sql__.sh
#  Runs all SQL setup files against Oracle 21c XE (XEPDB1)
#  Author: Udit Asthana (240905310), CSE-D
# ============================================================

DB_USER="udit"
DB_PASS="oracle123"
DB_HOST="localhost"
DB_PORT="1521"
DB_SID="XEPDB1"
CONN="${DB_USER}/${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_SID}"

SQL_DIR=".."

header() {
    echo ""
    echo "<<<<  $1 >>>>"
    echo ""

}

run_sql() {
    local label="$1"
    local file="$2"
    echo ""
    echo "--> Running: $label"
    echo "    File   : $file"
    sqlplus -S "$CONN" @"$file"
    if [ $? -ne 0 ]; then
        echo "    [FAILED] $label — aborting."
        exit 1
    fi
    echo "    [OK]    $label"
}

header "DBMS Project — SQL Setup Runner"
echo "  User : $DB_USER"
echo "  DB   : $DB_SID @ $DB_HOST:$DB_PORT"
echo ""
read -p "-> Run ALL SQL setup files? (y/n): " choice

if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
    echo "Aborted."
    exit 0
fi

header "Step 1/3 — Schema Setup (DDL + Triggers)"
run_sql "Schema Setup"   "$SQL_DIR/schema_setup.sql"

header "Step 2/3 — Relations (Sample Data)"
run_sql "Relations"      "$SQL_DIR/relations.sql"

header "Step 3/3 — Procedures & Functions"
run_sql "Procedures"     "$SQL_DIR/procedures.sql"

header "All steps completed successfully."
echo "  You can now run the JavaFX app via: ./utils/__run_and_compile__.sh"
echo ""