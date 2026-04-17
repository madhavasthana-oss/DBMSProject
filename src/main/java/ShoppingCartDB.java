/* ShoppingCartDB.java
   JavaFX + JDBC — Shopping Cart Management System
   Oracle 21c XE | XEPDB1
   Author: Udit Asthana (240905310), CSE-D
   Compile & Run via Maven:
   mvn compile
   mvn exec:java */

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import javafx.application.Application;
import javafx.application.Platform;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.ComboBox;
import javafx.scene.control.Label;
import javafx.scene.control.Separator;
import javafx.scene.control.Tab;
import javafx.scene.control.TabPane;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.control.TextArea;
import javafx.scene.control.TextField;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import javafx.scene.layout.Region;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;

public class ShoppingCartDB extends Application {

    // ── Connection settings ──────────────────────────────────
    private static final String URL      = "jdbc:oracle:thin:@localhost:1521/XEPDB1";
    private static final String USER     = "udit";
    private static final String PASSWORD = "oracle123";

    // ── Colors ───────────────────────────────────────────────
    private static final String BG_DARK    = "#0f1117";
    private static final String BG_PANEL   = "#1a1d27";
    private static final String BG_CARD    = "#21253a";
    private static final String ACCENT     = "#4f8ef7";
    private static final String ACCENT2    = "#7c3aed";
    private static final String SUCCESS    = "#22c55e";
    private static final String DANGER     = "#ef4444";
    private static final String TEXT_MAIN  = "#e8eaf0";
    private static final String TEXT_DIM   = "#8b90a0";
    private static final String BORDER     = "#2e3248";

    // ── Shared state ─────────────────────────────────────────
    private TextArea logArea;
    private ExecutorService executor = Executors.newSingleThreadExecutor();

    
    //  DB CONNECTION
    
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }

    
    //  JAVAFX ENTRY POINT
    
    @Override
    public void start(Stage stage) {
        stage.setTitle("Shopping Cart Management System — Udit Asthana");

        BorderPane root = new BorderPane();
        root.setStyle("-fx-background-color: " + BG_DARK + ";");

        // Header
        root.setTop(buildHeader());

        // Main content: sidebar + center
        HBox body = new HBox(0);
        body.setStyle("-fx-background-color: " + BG_DARK + ";");

        VBox sidebar = buildSidebar();
        TabPane tabPane = buildTabPane();
        HBox.setHgrow(tabPane, Priority.ALWAYS);

        body.getChildren().addAll(sidebar, tabPane);
        root.setCenter(body);

        // Log panel at bottom
        root.setBottom(buildLogPanel());

        Scene scene = new Scene(root, 1280, 800);
        stage.setScene(scene);
        stage.setMinWidth(1000);
        stage.setMinHeight(650);
        stage.show();

        log("✔  Application started. Connecting to Oracle...");
        testConnection();
    }

    
    //  HEADER
    
    private HBox buildHeader() {
        HBox header = new HBox();
        header.setAlignment(Pos.CENTER_LEFT);
        header.setPadding(new Insets(14, 24, 14, 24));
        header.setSpacing(12);
        header.setStyle(
            "-fx-background-color: " + BG_PANEL + ";" +
            "-fx-border-color: " + BORDER + ";" +
            "-fx-border-width: 0 0 1 0;"
        );

        // Logo block
        Label logo = new Label("🛒");
        logo.setStyle("-fx-font-size: 22px;");

        VBox titleBlock = new VBox(1);
        Label title = new Label("Shopping Cart Management System");
        title.setStyle("-fx-font-size: 16px; -fx-font-weight: bold; -fx-text-fill: " + TEXT_MAIN + "; -fx-font-family: 'Consolas';");
        Label sub = new Label("Oracle 21c XE  ·  JDBC  ·  JavaFX  ·  Udit Asthana (240905310)");
        sub.setStyle("-fx-font-size: 11px; -fx-text-fill: " + TEXT_DIM + "; -fx-font-family: 'Consolas';");
        titleBlock.getChildren().addAll(title, sub);

        // Connection status
        Region spacer = new Region();
        HBox.setHgrow(spacer, Priority.ALWAYS);

        Label connStatus = new Label("● XEPDB1");
        connStatus.setStyle("-fx-font-size: 11px; -fx-text-fill: " + SUCCESS + "; -fx-font-family: 'Consolas';");

        header.getChildren().addAll(logo, titleBlock, spacer, connStatus);
        return header;
    }

    
    //  SIDEBAR
    
    private VBox buildSidebar() {
        VBox sidebar = new VBox(4);
        sidebar.setPrefWidth(200);
        sidebar.setPadding(new Insets(20, 12, 20, 12));
        sidebar.setStyle(
            "-fx-background-color: " + BG_PANEL + ";" +
            "-fx-border-color: " + BORDER + ";" +
            "-fx-border-width: 0 1 0 0;"
        );

        Label navLabel = new Label("OPERATIONS");
        navLabel.setStyle("-fx-font-size: 10px; -fx-text-fill: " + TEXT_DIM + "; -fx-font-family: 'Consolas'; -fx-padding: 0 0 8 4;");

        String[] ops = {"📚  List Books", "🛒  View Cart", "➕  Add to Cart", "💳  Checkout", "📦  Check Stock", "🔄  Transaction"};
        sidebar.getChildren().add(navLabel);
        for (String op : ops) {
            Label item = new Label(op);
            item.setMaxWidth(Double.MAX_VALUE);
            item.setPadding(new Insets(8, 12, 8, 12));
            item.setStyle(
                "-fx-font-size: 12px; -fx-text-fill: " + TEXT_DIM + ";" +
                "-fx-font-family: 'Consolas'; -fx-cursor: hand;" +
                "-fx-background-radius: 6;"
            );
            item.setOnMouseEntered(e -> item.setStyle(
                "-fx-font-size: 12px; -fx-text-fill: " + TEXT_MAIN + ";" +
                "-fx-font-family: 'Consolas'; -fx-cursor: hand;" +
                "-fx-background-color: " + BG_CARD + "; -fx-background-radius: 6;"
            ));
            item.setOnMouseExited(e -> item.setStyle(
                "-fx-font-size: 12px; -fx-text-fill: " + TEXT_DIM + ";" +
                "-fx-font-family: 'Consolas'; -fx-cursor: hand;" +
                "-fx-background-radius: 6;"
            ));
            sidebar.getChildren().add(item);
        }

        return sidebar;
    }

    
    //  TAB PANE (all 6 operations)
    
    private TabPane buildTabPane() {
        TabPane tabPane = new TabPane();
        tabPane.setTabClosingPolicy(TabPane.TabClosingPolicy.UNAVAILABLE);
        tabPane.setStyle(
            "-fx-background-color: " + BG_DARK + ";" +
            "-fx-tab-min-width: 120px;"
        );

        tabPane.getTabs().addAll(
            buildListBooksTab(),
            buildViewCartTab(),
            buildAddToCartTab(),
            buildCheckoutTab(),
            buildCheckStockTab(),
            buildTransactionTab()
        );

        return tabPane;
    }

    // ── Helpers ──────────────────────────────────────────────
    private String cardStyle() {
        return "-fx-background-color: " + BG_CARD + ";" +
               "-fx-background-radius: 10;" +
               "-fx-border-color: " + BORDER + ";" +
               "-fx-border-radius: 10;" +
               "-fx-border-width: 1;";
    }

    private Button accentButton(String text, String color) {
        Button btn = new Button(text);
        btn.setStyle(
            "-fx-background-color: " + color + ";" +
            "-fx-text-fill: white;" +
            "-fx-font-family: 'Consolas';" +
            "-fx-font-size: 12px;" +
            "-fx-font-weight: bold;" +
            "-fx-padding: 8 20 8 20;" +
            "-fx-background-radius: 6;" +
            "-fx-cursor: hand;"
        );
        btn.setOnMouseEntered(e -> btn.setOpacity(0.85));
        btn.setOnMouseExited(e -> btn.setOpacity(1.0));
        return btn;
    }

    private TextField styledField(String prompt) {
        TextField tf = new TextField();
        tf.setPromptText(prompt);
        tf.setStyle(
            "-fx-background-color: " + BG_DARK + ";" +
            "-fx-text-fill: " + TEXT_MAIN + ";" +
            "-fx-prompt-text-fill: " + TEXT_DIM + ";" +
            "-fx-font-family: 'Consolas';" +
            "-fx-font-size: 12px;" +
            "-fx-border-color: " + BORDER + ";" +
            "-fx-border-radius: 6;" +
            "-fx-background-radius: 6;" +
            "-fx-padding: 7 10 7 10;"
        );
        return tf;
    }

    private Label sectionTitle(String text) {
        Label l = new Label(text);
        l.setStyle("-fx-font-size: 15px; -fx-font-weight: bold; -fx-text-fill: " + TEXT_MAIN + "; -fx-font-family: 'Consolas';");
        return l;
    }

    private Label dimLabel(String text) {
        Label l = new Label(text);
        l.setStyle("-fx-font-size: 11px; -fx-text-fill: " + TEXT_DIM + "; -fx-font-family: 'Consolas';");
        return l;
    }

    private <T> TableView<T> styledTable() {
        TableView<T> table = new TableView<>();
        table.setStyle(
            "-fx-background-color: " + BG_DARK + ";" +
            "-fx-border-color: " + BORDER + ";" +
            "-fx-border-radius: 8;" +
            "-fx-table-cell-border-color: " + BORDER + ";" +
            "-fx-font-family: 'Consolas';" +
            "-fx-font-size: 12px;"
        );
        table.setColumnResizePolicy(TableView.CONSTRAINED_RESIZE_POLICY);
        return table;
    }

    private <T> TableColumn<T, String> col(String title, String field) {
        TableColumn<T, String> col = new TableColumn<>(title);
        col.setCellValueFactory(new PropertyValueFactory<>(field));
        col.setStyle("-fx-alignment: CENTER-LEFT;");
        return col;
    }

    private Tab styledTab(String title, javafx.scene.Node content) {
        Tab tab = new Tab(title, content);
        return tab;
    }

    
    //  TAB 1 — LIST BOOKS
    
    public static class BookRow {
        private final String isbn, title, price, genre, author;
        public BookRow(String isbn, String title, String price, String genre, String author) {
            this.isbn = isbn; this.title = title; this.price = price;
            this.genre = genre; this.author = author;
        }
        public String getIsbn()   { return isbn; }
        public String getTitle()  { return title; }
        public String getPrice()  { return price; }
        public String getGenre()  { return genre; }
        public String getAuthor() { return author; }
    }

    private Tab buildListBooksTab() {
        TableView<BookRow> table = styledTable();
        table.getColumns().addAll(col("ISBN", "isbn"), col("Title", "title"), col("Price (₹)", "price"), col("Genre", "genre"), col("Author", "author"));
        ObservableList<BookRow> data = FXCollections.observableArrayList();
        table.setItems(data);

        Button loadBtn = accentButton("🔍  Load All Books", ACCENT);
        loadBtn.setOnAction(e -> {
            data.clear();
            log("Fetching all books...");
            runAsync(() -> {
                String sql = "SELECT b.isbn, b.title, b.price, b.genre, a.name AS author FROM BOOK b JOIN AUTHOR a ON a.name = b.author_name ORDER BY b.title";
                try (Connection con = getConnection();
                     Statement stmt = con.createStatement();
                     ResultSet rs = stmt.executeQuery(sql)) {
                    while (rs.next()) {
                        BookRow row = new BookRow(
                            rs.getString("isbn"), rs.getString("title"),
                            String.format("%.2f", rs.getDouble("price")),
                            rs.getString("genre"), rs.getString("author")
                        );
                        Platform.runLater(() -> data.add(row));
                    }
                    Platform.runLater(() -> log("✔  Loaded " + data.size() + " books."));
                } catch (SQLException ex) {
                    Platform.runLater(() -> logError("listAllBooks: " + ex.getMessage()));
                }
            });
        });

        Button copyIsbnBtn = accentButton("📋  Copy ISBN", ACCENT2);
        copyIsbnBtn.setDisable(true);
        copyIsbnBtn.setOnAction(e -> {
            BookRow selected = table.getSelectionModel().getSelectedItem();
            if (selected != null) {
                javafx.scene.input.Clipboard clipboard = javafx.scene.input.Clipboard.getSystemClipboard();
                javafx.scene.input.ClipboardContent content2 = new javafx.scene.input.ClipboardContent();
                content2.putString(selected.getIsbn());
                clipboard.setContent(content2);
                log("✔  ISBN copied: " + selected.getIsbn());
            }
        });

        table.getSelectionModel().selectedItemProperty().addListener((obs, oldVal, newVal) ->
            copyIsbnBtn.setDisable(newVal == null)
        );

        HBox toolbar = new HBox(10, loadBtn, copyIsbnBtn);
        toolbar.setAlignment(Pos.CENTER_LEFT);

        VBox content = new VBox(14);
        content.setPadding(new Insets(24));
        content.setStyle("-fx-background-color: " + BG_DARK + ";");
        content.getChildren().addAll(
            sectionTitle("📚  All Books"),
            dimLabel("Fetches all books joined with author table."),
            toolbar,
            table
        );
        VBox.setVgrow(table, Priority.ALWAYS);
        return styledTab("📚 Books", content);
    }

    
    //  TAB 2 — VIEW CART
    
    public static class CartRow {
        private final String title, quantity, lineTotal;
        public CartRow(String title, String quantity, String lineTotal) {
            this.title = title; this.quantity = quantity; this.lineTotal = lineTotal;
        }
        public String getTitle()     { return title; }
        public String getQuantity()  { return quantity; }
        public String getLineTotal() { return lineTotal; }
    }

    private Tab buildViewCartTab() {
        TableView<CartRow> table = styledTable();
        table.getColumns().addAll(col("Book Title", "title"), col("Qty", "quantity"), col("Line Total (₹)", "lineTotal"));
        ObservableList<CartRow> data = FXCollections.observableArrayList();
        table.setItems(data);

        TextField custIdField = styledField("Customer ID (e.g. 1)");
        custIdField.setMaxWidth(200);
        Label totalLabel = new Label("Cart Total: ₹0.00");
        totalLabel.setStyle("-fx-font-size: 13px; -fx-font-weight: bold; -fx-text-fill: " + ACCENT + "; -fx-font-family: 'Consolas';");

        Button loadBtn = accentButton("🛒  View Cart", ACCENT);
        loadBtn.setOnAction(e -> {
            String idText = custIdField.getText().trim();
            if (idText.isEmpty()) { logError("Please enter a Customer ID."); return; }
            int custId;
            try { custId = Integer.parseInt(idText); }
            catch (NumberFormatException ex) { logError("Customer ID must be a number."); return; }

            data.clear();
            log("Fetching cart for customer #" + custId + "...");
            runAsync(() -> {
                String sql = "SELECT b.title, b.price, ci.quantity, (b.price * ci.quantity) AS line_total " +
                             "FROM CART c JOIN CART_ITEMS ci ON ci.cart_id = c.cart_id " +
                             "JOIN BOOK b ON b.isbn = ci.isbn " +
                             "WHERE c.cust_id = ? AND c.status = 'ACTIVE'";
                try (Connection con = getConnection();
                     PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, custId);
                    ResultSet rs = ps.executeQuery();
                    double[] total = {0};
                    while (rs.next()) {
                        double lt = rs.getDouble("line_total");
                        total[0] += lt;
                        CartRow row = new CartRow(rs.getString("title"), String.valueOf(rs.getInt("quantity")), String.format("%.2f", lt));
                        Platform.runLater(() -> data.add(row));
                    }
                    Platform.runLater(() -> {
                        totalLabel.setText("Cart Total: ₹" + String.format("%.2f", total[0]));
                        log("✔  Cart loaded. Total: ₹" + String.format("%.2f", total[0]));
                    });
                } catch (SQLException ex) {
                    Platform.runLater(() -> logError("viewCart: " + ex.getMessage()));
                }
            });
        });

        HBox inputRow = new HBox(10, custIdField, loadBtn);
        inputRow.setAlignment(Pos.CENTER_LEFT);

        VBox content = new VBox(14);
        content.setPadding(new Insets(24));
        content.setStyle("-fx-background-color: " + BG_DARK + ";");
        content.getChildren().addAll(
            sectionTitle("🛒  View Cart"),
            dimLabel("Shows the active cart for a given customer ID."),
            inputRow, table, totalLabel
        );
        VBox.setVgrow(table, Priority.ALWAYS);
        return styledTab("🛒 Cart", content);
    }

    
    //  TAB 3 — ADD TO CART
    
    private Tab buildAddToCartTab() {
        TextField custIdField  = styledField("Customer ID (e.g. 3)");
        TextField isbnField    = styledField("ISBN (e.g. 978-0-06-231609-7)");
        TextField quantityField = styledField("Quantity (e.g. 2)");

        Button addBtn = accentButton("➕  Add to Cart", SUCCESS);
        Label resultLabel = new Label("");
        resultLabel.setStyle("-fx-font-family: 'Consolas'; -fx-font-size: 12px; -fx-text-fill: " + SUCCESS + ";");

        addBtn.setOnAction(e -> {
            String cid = custIdField.getText().trim();
            String isbn = isbnField.getText().trim();
            String qty  = quantityField.getText().trim();
            if (cid.isEmpty() || isbn.isEmpty() || qty.isEmpty()) {
                logError("All fields are required."); return;
            }
            int custId, quantity;
            try { custId = Integer.parseInt(cid); quantity = Integer.parseInt(qty); }
            catch (NumberFormatException ex) { logError("Customer ID and Quantity must be numbers."); return; }

            log("Adding " + quantity + " x [" + isbn + "] for customer #" + custId + "...");
            int finalCustId = custId, finalQty = quantity;
            runAsync(() -> {
                String sql = "BEGIN add_to_cart(?, ?, ?); END;";
                try (Connection con = getConnection();
                     CallableStatement cs = con.prepareCall(sql)) {
                    cs.setInt(1, finalCustId);
                    cs.setString(2, isbn);
                    cs.setInt(3, finalQty);
                    cs.execute();
                    Platform.runLater(() -> {
                        resultLabel.setText("✔  Added " + finalQty + " copy/copies of ISBN " + isbn + " to cart.");
                        log("✔  add_to_cart executed successfully.");
                    });
                } catch (SQLException ex) {
                    Platform.runLater(() -> {
                        resultLabel.setStyle("-fx-font-family: 'Consolas'; -fx-font-size: 12px; -fx-text-fill: " + DANGER + ";");
                        resultLabel.setText("✖  " + ex.getMessage());
                        logError("addToCart: " + ex.getMessage());
                    });
                }
            });
        });

        GridPane form = new GridPane();
        form.setHgap(12); form.setVgap(12);
        form.add(new Label("Customer ID") {{ setStyle("-fx-text-fill:" + TEXT_DIM + ";-fx-font-family:'Consolas';-fx-font-size:11px;"); }}, 0, 0);
        form.add(custIdField, 1, 0);
        form.add(new Label("ISBN") {{ setStyle("-fx-text-fill:" + TEXT_DIM + ";-fx-font-family:'Consolas';-fx-font-size:11px;"); }}, 0, 1);
        form.add(isbnField, 1, 1);
        form.add(new Label("Quantity") {{ setStyle("-fx-text-fill:" + TEXT_DIM + ";-fx-font-family:'Consolas';-fx-font-size:11px;"); }}, 0, 2);
        form.add(quantityField, 1, 2);
        form.add(addBtn, 1, 3);

        VBox card = new VBox(14, form, resultLabel);
        card.setPadding(new Insets(20));
        card.setMaxWidth(500);
        card.setStyle(cardStyle());

        VBox content = new VBox(16);
        content.setPadding(new Insets(24));
        content.setStyle("-fx-background-color: " + BG_DARK + ";");
        content.getChildren().addAll(
            sectionTitle("➕  Add to Cart"),
            dimLabel("Calls PL/SQL procedure: add_to_cart(cust_id, isbn, quantity)"),
            card
        );
        return styledTab("➕ Add", content);
    }

    
    //  TAB 4 — CHECKOUT
    
    private Tab buildCheckoutTab() {
        TextField custIdField  = styledField("Customer ID (e.g. 3)");
        ComboBox<String> paymentBox = new ComboBox<>();
        paymentBox.getItems().addAll("CREDIT_CARD", "DEBIT_CARD", "UPI", "NET_BANKING", "WALLET");
        paymentBox.setValue("CREDIT_CARD");
        paymentBox.setStyle(
            "-fx-background-color: " + BG_DARK + ";" +
            "-fx-text-fill: " + TEXT_MAIN + ";" +
            "-fx-font-family: 'Consolas';" +
            "-fx-font-size: 12px;" +
            "-fx-border-color: " + BORDER + ";" +
            "-fx-border-radius: 6;" +
            "-fx-background-radius: 6;"
        );

        Label resultLabel = new Label("");
        resultLabel.setStyle("-fx-font-family: 'Consolas'; -fx-font-size: 13px; -fx-font-weight: bold; -fx-text-fill: " + SUCCESS + ";");

        Button checkoutBtn = accentButton("💳  Checkout", ACCENT2);
        checkoutBtn.setOnAction(e -> {
            String cid = custIdField.getText().trim();
            if (cid.isEmpty()) { logError("Enter a Customer ID."); return; }
            int custId;
            try { custId = Integer.parseInt(cid); }
            catch (NumberFormatException ex) { logError("Customer ID must be a number."); return; }

            String payment = paymentBox.getValue();
            log("Checking out customer #" + custId + " via " + payment + "...");
            runAsync(() -> {
                String sql = "BEGIN checkout(?, ?, ?); END;";
                try (Connection con = getConnection();
                     CallableStatement cs = con.prepareCall(sql)) {
                    con.setAutoCommit(false);
                    cs.setInt(1, custId);
                    cs.setString(2, payment);
                    cs.registerOutParameter(3, Types.NUMERIC);
                    cs.execute();
                    int orderId = cs.getInt(3);
                    con.commit();
                    Platform.runLater(() -> {
                        resultLabel.setText("✔  Order placed! Order ID: " + orderId);
                        log("✔  Checkout successful. Order ID: " + orderId);
                    });
                } catch (SQLException ex) {
                    Platform.runLater(() -> {
                        resultLabel.setStyle("-fx-font-family: 'Consolas'; -fx-font-size: 13px; -fx-font-weight: bold; -fx-text-fill: " + DANGER + ";");
                        resultLabel.setText("✖  Checkout failed: " + ex.getMessage());
                        logError("checkout: " + ex.getMessage());
                    });
                }
            });
        });

        GridPane form = new GridPane();
        form.setHgap(12); form.setVgap(12);
        form.add(new Label("Customer ID") {{ setStyle("-fx-text-fill:" + TEXT_DIM + ";-fx-font-family:'Consolas';-fx-font-size:11px;"); }}, 0, 0);
        form.add(custIdField, 1, 0);
        form.add(new Label("Payment Method") {{ setStyle("-fx-text-fill:" + TEXT_DIM + ";-fx-font-family:'Consolas';-fx-font-size:11px;"); }}, 0, 1);
        form.add(paymentBox, 1, 1);
        form.add(checkoutBtn, 1, 2);

        VBox card = new VBox(14, form, resultLabel);
        card.setPadding(new Insets(20));
        card.setMaxWidth(500);
        card.setStyle(cardStyle());

        VBox content = new VBox(16);
        content.setPadding(new Insets(24));
        content.setStyle("-fx-background-color: " + BG_DARK + ";");
        content.getChildren().addAll(
            sectionTitle("💳  Checkout"),
            dimLabel("Calls PL/SQL procedure: checkout(cust_id, payment_method, OUT order_id)"),
            card
        );
        return styledTab("💳 Checkout", content);
    }

    
    //  TAB 5 — CHECK STOCK
    
    private Tab buildCheckStockTab() {
        TextField isbnField = styledField("ISBN (e.g. 978-0-07-352332-3)");
        isbnField.setMaxWidth(340);

        Label stockLabel = new Label("");
        stockLabel.setStyle("-fx-font-size: 32px; -fx-font-weight: bold; -fx-text-fill: " + ACCENT + "; -fx-font-family: 'Consolas';");
        Label stockSub = new Label("");
        stockSub.setStyle("-fx-font-size: 12px; -fx-text-fill: " + TEXT_DIM + "; -fx-font-family: 'Consolas';");

        Button checkBtn = accentButton("📦  Check Stock", ACCENT);
        checkBtn.setOnAction(e -> {
            String isbn = isbnField.getText().trim();
            if (isbn.isEmpty()) { logError("Enter an ISBN."); return; }
            log("Checking stock for ISBN: " + isbn + "...");
            runAsync(() -> {
                String sql = "BEGIN ? := get_total_stock(?); END;";
                try (Connection con = getConnection();
                     CallableStatement cs = con.prepareCall(sql)) {
                    cs.registerOutParameter(1, Types.NUMERIC);
                    cs.setString(2, isbn);
                    cs.execute();
                    int stock = cs.getInt(1);
                    Platform.runLater(() -> {
                        stockLabel.setText(stock + " units");
                        stockLabel.setStyle("-fx-font-size: 32px; -fx-font-weight: bold; -fx-font-family: 'Consolas'; -fx-text-fill: " + (stock > 0 ? SUCCESS : DANGER) + ";");
                        stockSub.setText("ISBN: " + isbn);
                        log("✔  Stock for " + isbn + ": " + stock + " units.");
                    });
                } catch (SQLException ex) {
                    Platform.runLater(() -> logError("checkStock: " + ex.getMessage()));
                }
            });
        });

        VBox stockDisplay = new VBox(4, stockLabel, stockSub);
        stockDisplay.setAlignment(Pos.CENTER_LEFT);

        VBox card = new VBox(16, isbnField, checkBtn, new Separator(), stockDisplay);
        card.setPadding(new Insets(20));
        card.setMaxWidth(500);
        card.setStyle(cardStyle());

        VBox content = new VBox(16);
        content.setPadding(new Insets(24));
        content.setStyle("-fx-background-color: " + BG_DARK + ";");
        content.getChildren().addAll(
            sectionTitle("📦  Check Stock"),
            dimLabel("Calls PL/SQL function: get_total_stock(isbn) → INTEGER"),
            card
        );
        return styledTab("📦 Stock", content);
    }

    
    //  TAB 6 — TRANSACTION DEMO
    
    private Tab buildTransactionTab() {
        TextField custIdField = styledField("Customer ID (e.g. 1)");
        custIdField.setMaxWidth(200);

        TextArea txLog = new TextArea();
        txLog.setEditable(false);
        txLog.setPrefHeight(220);
        txLog.setStyle(
            "-fx-control-inner-background: " + BG_DARK + ";" +
            "-fx-text-fill: " + TEXT_MAIN + ";" +
            "-fx-font-family: 'Consolas';" +
            "-fx-font-size: 11px;" +
            "-fx-border-color: " + BORDER + ";" +
            "-fx-border-radius: 6;" +
            "-fx-background-radius: 6;"
        );

        Label statusLabel = new Label("");
        statusLabel.setStyle("-fx-font-family: 'Consolas'; -fx-font-size: 12px; -fx-text-fill: " + TEXT_DIM + ";");

        Button runBtn = accentButton("🔄  Run Transaction Demo", DANGER);
        runBtn.setOnAction(e -> {
            String cid = custIdField.getText().trim();
            if (cid.isEmpty()) { logError("Enter a Customer ID."); return; }
            int custId;
            try { custId = Integer.parseInt(cid); } catch (NumberFormatException ex) { logError("Customer ID must be a number."); return; }

            txLog.clear();
            txLog.appendText("── Transaction Demo ──────────────────────────\n");
            txLog.appendText("Customer ID: " + custId + "\n");
            txLog.appendText("Starting manual transaction (autoCommit = false)...\n\n");
            log("Running transaction demo for customer #" + custId + "...");

            runAsync(() -> {
                Connection con = null;
                try {
                    con = getConnection();
                    con.setAutoCommit(false);
                    Platform.runLater(() -> txLog.appendText("✔  Connection acquired. AutoCommit OFF.\n"));

                    PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO CART_ITEMS (cart_id, isbn, quantity) " +
                        "SELECT c.cart_id, '978-0-07-352332-3', 99 " +
                        "FROM CART c WHERE c.cust_id = ? AND c.status = 'ACTIVE' AND ROWNUM=1"
                    );
                    ps.setInt(1, custId);
                    ps.executeUpdate();
                    Platform.runLater(() -> txLog.appendText("✔  INSERT executed (99 units added to cart).\n"));

                    throw new SQLException("Simulated payment failure — triggering rollback.");

                } catch (SQLException ex) {
                    Platform.runLater(() -> {
                        txLog.appendText("\n✖  Exception caught: " + ex.getMessage() + "\n");
                        txLog.appendText("   Executing ROLLBACK...\n");
                    });
                    try {
                        if (con != null) {
                            con.rollback();
                            Platform.runLater(() -> {
                                txLog.appendText("✔  ROLLBACK successful — data integrity preserved.\n");
                                txLog.appendText("\n── Demo complete ─────────────────────────────\n");
                                log("✔  Transaction demo: ROLLBACK executed successfully.");
                            });
                        }
                    } catch (SQLException re) {
                        Platform.runLater(() -> logError("Rollback failed: " + re.getMessage()));
                    }
                } finally {
                    try { if (con != null) con.close(); } catch (SQLException ex) { /* ignore */ }
                }
            });
        });

        HBox inputRow = new HBox(10, custIdField, runBtn);
        inputRow.setAlignment(Pos.CENTER_LEFT);

        VBox card = new VBox(14, inputRow, txLog, statusLabel);
        card.setPadding(new Insets(20));
        card.setStyle(cardStyle());

        VBox content = new VBox(16);
        content.setPadding(new Insets(24));
        content.setStyle("-fx-background-color: " + BG_DARK + ";");
        content.getChildren().addAll(
            sectionTitle("🔄  Transaction Demo"),
            dimLabel("Inserts 99 units, simulates a payment failure, then executes ROLLBACK."),
            card
        );
        VBox.setVgrow(card, Priority.ALWAYS);
        return styledTab("🔄 Transaction", content);
    }

    
    //  LOG PANEL
    
    private VBox buildLogPanel() {
        logArea = new TextArea();
        logArea.setEditable(false);
        logArea.setPrefHeight(110);
        logArea.setStyle(
            "-fx-control-inner-background: #090c12;" +
            "-fx-text-fill: #a0e080;" +
            "-fx-font-family: 'Consolas';" +
            "-fx-font-size: 11px;" +
            "-fx-border-color: " + BORDER + ";" +
            "-fx-border-width: 1 0 0 0;"
        );

        Label logTitle = new Label("CONSOLE OUTPUT");
        logTitle.setStyle("-fx-font-size: 9px; -fx-text-fill: " + TEXT_DIM + "; -fx-font-family: 'Consolas'; -fx-padding: 4 8 2 8;");

        Button clearBtn = new Button("Clear");
        clearBtn.setStyle("-fx-background-color: transparent; -fx-text-fill: " + TEXT_DIM + "; -fx-font-family: 'Consolas'; -fx-font-size: 9px; -fx-cursor: hand;");
        clearBtn.setOnAction(e -> logArea.clear());

        HBox logHeader = new HBox(logTitle);
        Region spacer = new Region();
        HBox.setHgrow(spacer, Priority.ALWAYS);
        logHeader.getChildren().addAll(spacer, clearBtn);
        logHeader.setStyle("-fx-background-color: #090c12; -fx-border-color: " + BORDER + "; -fx-border-width: 1 0 0 0;");
        logHeader.setAlignment(Pos.CENTER_LEFT);

        VBox panel = new VBox(0, logHeader, logArea);
        VBox.setVgrow(logArea, Priority.ALWAYS);
        return panel;
    }

    
    //  UTILITIES
    
    private void log(String msg) {
        Platform.runLater(() -> {
            logArea.appendText("› " + msg + "\n");
            logArea.setScrollTop(Double.MAX_VALUE);
        });
    }

    private void logError(String msg) {
        Platform.runLater(() -> {
            logArea.appendText("✖  ERROR: " + msg + "\n");
            logArea.setScrollTop(Double.MAX_VALUE);
        });
    }

    private void runAsync(Runnable task) {
        executor.submit(task);
    }

    private void testConnection() {
        runAsync(() -> {
            try (Connection con = getConnection()) {
                String ver = con.getMetaData().getDatabaseProductVersion();
                Platform.runLater(() -> log("✔  Connected to Oracle " + ver));
            } catch (SQLException e) {
                Platform.runLater(() -> logError("Connection failed: " + e.getMessage()));
            }
        });
    }

    @Override
    public void stop() {
        executor.shutdownNow();
    }

    //  MAIN
    public static void main(String[] args) {
        launch(args);
    }
}