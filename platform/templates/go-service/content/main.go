package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	r := gin.Default()
	// Health Check
	r.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "Hello from ${{ values.name }}!"})
	})
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "version": "1.0.0"})
	})
	// Metrics handler
	r.GET("/metrics", gin.WrapH(promhttp.Handler()))
	r.Run(":8080")
}
