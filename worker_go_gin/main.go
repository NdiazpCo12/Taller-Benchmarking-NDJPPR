package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
	"github.com/google/uuid"
)

type Item struct {
	ProductID string  `json:"productId" binding:"required"`
	Quantity  int     `json:"quantity" binding:"required,min=1"`
	Price     float64 `json:"price" binding:"required,min=0"`
}

type OrderRequest struct {
	CustomerID string  `json:"customerId" binding:"required"`
	Items      []Item  `json:"items" binding:"required,min=1,dive"`
}

type OrderResponse struct {
	OrderID     string    `json:"orderId"`
	TotalAmount float64   `json:"totalAmount"`
	ItemsCount  int       `json:"itemsCount"`
	ProcessedAt time.Time `json:"processedAt"`
}

var db *sql.DB

func initDB() {
	var err error
	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "5432")
	user := getEnv("DB_USER", "postgres")
	password := getEnv("DB_PASSWORD", "postgres")
	dbname := getEnv("DB_NAME", "orders_db")

	psqlInfo := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	db, err = sql.Open("postgres", psqlInfo)
	if err != nil {
		log.Fatal("Error connecting to database:", err)
	}

	if err = db.Ping(); err != nil {
		log.Fatal("Error pinging database:", err)
	}

	log.Println("Database connection established")
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func createOrder(c *gin.Context) {
	var req OrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var totalAmount float64
	var itemsCount int

	for _, item := range req.Items {
		itemTotal := item.Price * float64(item.Quantity)
		totalAmount += itemTotal
		itemsCount += item.Quantity
	}

	orderID := fmt.Sprintf("ORD-%s", uuid.New().String()[:8])
	processedAt := time.Now()

	tx, err := db.Begin()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start transaction"})
		return
	}
	defer tx.Rollback()

	_, err = tx.Exec(
		"INSERT INTO orders (order_id, customer_id, total_amount, items_count, created_at) VALUES ($1, $2, $3, $4, $5)",
		orderID, req.CustomerID, totalAmount, itemsCount, processedAt,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to insert order"})
		return
	}

	for _, item := range req.Items {
		_, err = tx.Exec(
			"INSERT INTO order_items (order_id, product_id, quantity, price) VALUES ($1, $2, $3, $4)",
			orderID, item.ProductID, item.Quantity, item.Price,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to insert order item"})
			return
		}
	}

	if err = tx.Commit(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit transaction"})
		return
	}

	response := OrderResponse{
		OrderID:     orderID,
		TotalAmount: totalAmount,
		ItemsCount:  itemsCount,
		ProcessedAt: processedAt,
	}

	c.JSON(http.StatusCreated, response)
}

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func main() {
	initDB()
	defer db.Close()

	router := gin.Default()

	router.POST("/api/orders", createOrder)
	router.GET("/health", healthCheck)

	port := ":5004"
	log.Printf("Server starting on port %s", port)
	if err := router.Run(port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

