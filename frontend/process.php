<?php
// Database connection
$servername = "localhost";
$username = "root";
$password = "D4#diyadrashti";
$dbname = "InventoryManagement";

$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Handle placing an order
if (isset($_POST['order'])) {
    $product_id = $_POST['product_id'];
    $quantity = $_POST['quantity'];

    // Check if product exists and has enough stock
    $sql = "SELECT quantity FROM inventory WHERE product_id = $product_id";
    $result = $conn->query($sql);
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        if ($row['quantity'] >= $quantity) {
            // Update inventory
            $update_sql = "UPDATE inventory SET quantity = quantity - $quantity WHERE product_id = $product_id";
            $conn->query($update_sql);

            // Record the sale
            $insert_sql = "INSERT INTO sales (product_id, quantity_sold, sale_date) VALUES ($product_id, $quantity, NOW())";
            $conn->query($insert_sql);

            echo "Order placed successfully!";
        } else {
            echo "Not enough stock!";
        }
    } else {
        echo "Product not found!";
    }
}

// Handle viewing sales
if (isset($_GET['view_sales'])) {
    $sql = "SELECT * FROM sales";
    $result = $conn->query($sql);

    echo "<h2>Sales Records</h2>";
    echo "<table border='1'>
            <tr>
                <th>Sale ID</th>
                <th>Product ID</th>
                <th>Quantity Sold</th>
                <th>Sale Date</th>
            </tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>
                <td>{$row['sale_id']}</td>
                <td>{$row['product_id']}</td>
                <td>{$row['quantity_sold']}</td>
                <td>{$row['sale_date']}</td>
              </tr>";
    }
    echo "</table>";
}

$conn->close();
?>
