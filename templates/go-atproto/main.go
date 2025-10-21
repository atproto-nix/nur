package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	version   = "dev"
	buildTime = "unknown"
)

// Config holds the application configuration
type Config struct {
	Port     int    `mapstructure:"port"`
	Host     string `mapstructure:"host"`
	LogLevel string `mapstructure:"log_level"`
}

// AtprotoRequest represents a generic ATProto request
type AtprotoRequest struct {
	DID        string      `json:"did"`
	Collection string      `json:"collection"`
	Record     interface{} `json:"record,omitempty"`
}

// AtprotoResponse represents a generic ATProto response
type AtprotoResponse struct {
	Success bool   `json:"success"`
	URI     string `json:"uri,omitempty"`
	CID     string `json:"cid,omitempty"`
	Message string `json:"message,omitempty"`
}

// HealthResponse represents the health check response
type HealthResponse struct {
	Status    string `json:"status"`
	Version   string `json:"version"`
	BuildTime string `json:"build_time"`
	Timestamp string `json:"timestamp"`
}

// Server represents the ATProto service server
type Server struct {
	config *Config
	logger *logrus.Logger
	router *mux.Router
}

// NewServer creates a new server instance
func NewServer(config *Config) *Server {
	logger := logrus.New()
	
	// Configure logger
	level, err := logrus.ParseLevel(config.LogLevel)
	if err != nil {
		level = logrus.InfoLevel
	}
	logger.SetLevel(level)
	logger.SetFormatter(&logrus.JSONFormatter{})

	server := &Server{
		config: config,
		logger: logger,
		router: mux.NewRouter(),
	}

	server.setupRoutes()
	return server
}

// setupRoutes configures the HTTP routes
func (s *Server) setupRoutes() {
	// Health check endpoint
	s.router.HandleFunc("/health", s.handleHealth).Methods("GET")

	// ATProto XRPC endpoints
	xrpc := s.router.PathPrefix("/xrpc").Subrouter()
	xrpc.HandleFunc("/com.atproto.repo.createRecord", s.handleCreateRecord).Methods("POST")
	xrpc.HandleFunc("/com.atproto.repo.getRecord", s.handleGetRecord).Methods("GET")
	// Add more ATProto methods as needed

	// Middleware
	s.router.Use(s.loggingMiddleware)
	s.router.Use(handlers.CORS(
		handlers.AllowedOrigins([]string{"*"}),
		handlers.AllowedMethods([]string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}),
		handlers.AllowedHeaders([]string{"*"}),
	))
}

// loggingMiddleware logs HTTP requests
func (s *Server) loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		
		next.ServeHTTP(w, r)
		
		s.logger.WithFields(logrus.Fields{
			"method":     r.Method,
			"path":       r.URL.Path,
			"duration":   time.Since(start),
			"user_agent": r.UserAgent(),
			"remote_ip":  r.RemoteAddr,
		}).Info("HTTP request")
	})
}

// handleHealth handles health check requests
func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	response := HealthResponse{
		Status:    "healthy",
		Version:   version,
		BuildTime: buildTime,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// handleCreateRecord handles ATProto record creation
func (s *Server) handleCreateRecord(w http.ResponseWriter, r *http.Request) {
	var req AtprotoRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		s.logger.WithError(err).Error("Failed to decode request")
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	s.logger.WithFields(logrus.Fields{
		"did":        req.DID,
		"collection": req.Collection,
	}).Info("Creating record")

	// TODO: Implement your record creation logic here
	// This is where you would:
	// 1. Validate the DID and authentication
	// 2. Validate the record against the lexicon
	// 3. Store the record in your database
	// 4. Return the appropriate response

	// Placeholder implementation
	response := AtprotoResponse{
		Success: true,
		URI:     fmt.Sprintf("at://%s/%s/placeholder", req.DID, req.Collection),
		CID:     "bafyreigbtj4x7ip5legnfznufuopl4sg4knzc2cof6duas4b3q2fy6swua", // placeholder CID
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// handleGetRecord handles ATProto record retrieval
func (s *Server) handleGetRecord(w http.ResponseWriter, r *http.Request) {
	repo := r.URL.Query().Get("repo")
	collection := r.URL.Query().Get("collection")
	rkey := r.URL.Query().Get("rkey")

	if repo == "" || collection == "" || rkey == "" {
		http.Error(w, "Missing required parameters: repo, collection, rkey", http.StatusBadRequest)
		return
	}

	s.logger.WithFields(logrus.Fields{
		"repo":       repo,
		"collection": collection,
		"rkey":       rkey,
	}).Info("Getting record")

	// TODO: Implement your record retrieval logic here
	// This is where you would:
	// 1. Validate the parameters
	// 2. Retrieve the record from your database
	// 3. Return the record data

	// Placeholder implementation
	response := map[string]interface{}{
		"uri": fmt.Sprintf("at://%s/%s/%s", repo, collection, rkey),
		"cid": "bafyreigbtj4x7ip5legnfznufuopl4sg4knzc2cof6duas4b3q2fy6swua",
		"value": map[string]interface{}{
			"text":      "Hello ATProto!",
			"createdAt": time.Now().UTC().Format(time.RFC3339),
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Start starts the HTTP server
func (s *Server) Start() error {
	addr := fmt.Sprintf("%s:%d", s.config.Host, s.config.Port)
	
	server := &http.Server{
		Addr:         addr,
		Handler:      s.router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	s.logger.WithField("address", addr).Info("Starting ATProto service")

	// Start server in a goroutine
	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			s.logger.WithError(err).Fatal("Failed to start server")
		}
	}()

	// Wait for interrupt signal to gracefully shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	s.logger.Info("Shutting down server...")

	// Graceful shutdown with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		s.logger.WithError(err).Error("Server forced to shutdown")
		return err
	}

	s.logger.Info("Server exited")
	return nil
}

// loadConfig loads configuration from environment and config files
func loadConfig() (*Config, error) {
	viper.SetDefault("port", 8080)
	viper.SetDefault("host", "localhost")
	viper.SetDefault("log_level", "info")

	viper.SetEnvPrefix("ATPROTO")
	viper.AutomaticEnv()

	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("/etc/atproto/")

	// Read config file if it exists
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("failed to read config file: %w", err)
		}
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	return &config, nil
}

// rootCmd represents the base command
var rootCmd = &cobra.Command{
	Use:   "my-atproto-go-service",
	Short: "My ATProto Go service",
	Long:  "A Go-based ATProto service for handling decentralized social networking protocols",
	RunE: func(cmd *cobra.Command, args []string) error {
		config, err := loadConfig()
		if err != nil {
			return fmt.Errorf("failed to load config: %w", err)
		}

		server := NewServer(config)
		return server.Start()
	},
}

func init() {
	rootCmd.Flags().IntP("port", "p", 8080, "Port to listen on")
	rootCmd.Flags().String("host", "localhost", "Host to bind to")
	rootCmd.Flags().String("log-level", "info", "Log level (debug, info, warn, error)")

	viper.BindPFlag("port", rootCmd.Flags().Lookup("port"))
	viper.BindPFlag("host", rootCmd.Flags().Lookup("host"))
	viper.BindPFlag("log_level", rootCmd.Flags().Lookup("log-level"))
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}