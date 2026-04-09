# DBMS Project — Shopping Cart System Management

Standard implementation of a Shopping Cart Management System built as a
Mini Project for the Database Management Systems lab (CSE2102).
The system demonstrates practical DBMS concepts end-to-end: schema design,
normalisation, constraints, PL/SQL, transactions, and Java DB connectivity.

---

**Name**     : Udit Asthana  
**Class**    : CSE-D  
**Reg. No.** : 240905310  
**Roll No.** : 31  

---

## Objective

This project extends the bookstore E-R schema of Exercise 6.21 (Silberschatz,
*Database System Concepts*, 7th ed.) into a fully functional shopping cart
system. The emphasis is on database correctness — integrity constraints,
atomic transactions, and PL/SQL-driven business logic — rather than
front-end polish.

---

## Features

- **Browse books** — all titles fetched with author and publisher via JOIN
- **Cart management** — add items, update quantities, remove items from an active cart
- **Stock verification** — inventory checked before every cart operation and at checkout
- **Atomic checkout** — order placement, inventory decrement, and payment recorded in a single transaction; ROLLBACK on any failure
- **PL/SQL layer** — stored procedures (`add_to_cart`, `checkout`, `update_cart_qty`, `remove_from_cart`) and functions (`get_total_stock`, `get_cart_total`) encapsulate all business logic
- **Triggers** — auto-decrement stock on order, lock checked-out carts, prevent negative inventory
- **JavaFX UI** — dark-themed dashboard with one tab per operation and a live console output panel
- **JDBC connectivity** — `Statement`, `PreparedStatement`, `CallableStatement`, manual transaction control

---

## Folder Structure

```
DBMSPROJECT/
│
├── LaTeX/                            # Report source (compile via pdflatex or Overleaf)
│   ├── main.tex                      # Root document — \input's all sections
│   ├── preamble.tex                  # Packages, lstlisting SQL style, page geometry
│   ├── problem_statement.tex         # Problem statement section
│   ├── image.png                     # Original E-R schema (Exercise 6.21)
│   ├── ss_books.png                  # UI screenshot — Books tab
│   ├── ss_addToCart.png              # UI screenshot — Add to Cart tab
│   ├── ss_viewCart.png               # UI screenshot — View Cart tab
│   ├── ss_stock.png                  # UI screenshot — Check Stock tab
│   ├── ss_transaction.png            # UI screenshot — Checkout tab
│   ├── ss_transactionDemo.png        # UI screenshot — Transaction Demo tab
│   ├── SchemaAndNormalization/
│   │   └── tables.tex                # Relational schema + normalisation argument
│   └── SQLQueries/
│       ├── Basic/
│       │   ├── activeCarts.tex       # Q: active cart summary
│       │   ├── allBooksWithAuthor.tex # Q: all books with author JOIN
│       │   └── totalStock.tex        # Q: total stock per book
│       └── Complex/
│           ├── availableStock.tex    # Q: availability check for cart items
│           ├── cartSummary.tex       # Q: cart value aggregation
│           └── revenuePerPublisher.tex # Q: revenue grouped by publisher
│
├── src/                              # Java source (Maven standard layout)
│
├── target/                           # Maven build output (auto-generated, do not edit)
│
├── schema_setup.sql                  # DDL — tables, sequences, constraints, triggers
├── relations.sql                     # DML — sample data inserts
├── queries.sql                       # All SQL queries (basic + complex)
├── procedures.sql                    # PL/SQL procedures, functions, extra triggers
│
├── pom.xml                           # Maven build config (ojdbc11 + JavaFX deps)
├── README.md                         # This file
│
└── utils/
    ├── __compile_and_run__.sh        # Prompts recompile (y/n), then launches JavaFX app
    ├── __run_sql__.sh                # Prompts confirmation, runs all SQL files in order
    └── seek.bat                      # Windows batch file to check and seek SQL credentials
```

---

## Setup

### 1. Oracle 21c XE

Install Oracle 21c XE and connect to `XEPDB1`. Create the project user:

```sql
sqlplus sys/oracle123@localhost:1521/XEPDB1 as sysdba

CREATE USER udit IDENTIFIED BY oracle123;
GRANT CONNECT, RESOURCE, UNLIMITED TABLESPACE TO udit;
```

### 2. Run SQL files

From the `utils/` folder:

```bash
chmod +x __run_sql__.sh
./__run_sql__.sh
```

This runs `schema_setup.sql` → `relations.sql` → `procedures.sql` in order
(all at project root). Re-running is safe — the schema script drops and
recreates all objects cleanly.

### 3. Run the JavaFX app

Requires Java 24 and Maven. From the `utils/` folder:

```bash
chmod +x __compile_and_run__.sh
./__compile_and_run__.sh
```

You will be prompted:
```
-> recompile? input(y/n):
```
Enter `y` on first run or after any code change. Enter `n` to launch directly.

---

## Compiling the Report

Open the `LaTeX/` folder in [Overleaf](https://overleaf.com) or compile locally:

```bash
pdflatex main.tex
pdflatex main.tex    # second pass fixes TOC page numbers
```

Each SQL query and PL/SQL block is in its own `.tex` file under `SQLQueries/`
and `PLSQL/`, using a shared `lstlisting` style defined in `preamble.tex`.
This makes it easy to include, exclude, or reorder individual listings without
touching the main document.

---

## Dependencies

| Tool | Version | Purpose |
|---|---|---|
| Oracle XE | 21c | Database |
| Java | 24 | Runtime |
| Maven | 3.x | Build + dependency management |
| JavaFX SDK | 26 | UI framework |
| ojdbc11 | 21.9.0.0 | Oracle JDBC driver (pulled by Maven) |
| MiKTeX / TeX Live | latest | LaTeX compilation |