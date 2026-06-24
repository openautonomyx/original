package main

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
)

// ============================================================================
// Enhanced Middleware Chain (Week 2)
// ============================================================================

func loggingMiddlewareEnhanced(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		requestID := r.Context().Value("request_id").(string)

		// Wrap response writer to capture status code
		wrapped := &LoggedResponseWriter{statusCode: 200}

		next.ServeHTTP(wrapped, r)

		duration := time.Since(start)
		logRequest(r.Method, r.RequestURI, wrapped.statusCode, duration, requestID)
	})
}

func corsMiddlewareEnhanced(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Request-ID")
		w.Header().Set("Access-Control-Max-Age", "3600")

		// Security headers
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("X-XSS-Protection", "1; mode=block")
		w.Header().Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func requestIDMiddlewareEnhanced(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestID := r.Header.Get("X-Request-ID")
		if requestID == "" {
			requestID = uuid.New().String()
		}

		w.Header().Set("X-Request-ID", requestID)
		ctx := context.WithValue(r.Context(), "request_id", requestID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func recoveryMiddlewareEnhanced(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			requestID := r.Context().Value("request_id").(string)
			if err := recover(); err != nil {
				logPanic("panic in http handler", err)
				appErr := NewInternalError(fmt.Errorf("%v", err))
				writeError(w, appErr, requestID)
			}
		}()
		next.ServeHTTP(w, r)
	})
}

// ============================================================================
// Enhanced JWT Authentication Middleware
// ============================================================================

func authMiddlewareEnhanced(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestID := r.Context().Value("request_id").(string)

		// Get authorization header
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			appErr := NewUnauthorizedError("missing authorization header")
			logError("auth failed: missing header", appErr, requestID)
			writeError(w, appErr, requestID)
			return
		}

		// Extract token from "Bearer {token}"
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			appErr := NewUnauthorizedError("invalid authorization format")
			logError("auth failed: invalid format", appErr, requestID)
			writeError(w, appErr, requestID)
			return
		}

		token := parts[1]

		// Validate JWT (NOW USES REAL JWT VALIDATION)
		secret := os.Getenv("JWT_SECRET")
		if secret == "" {
			secret = "dev-secret-key-change-in-prod"
		}

		claims, err := validateJWTToken(token, secret)
		if err != nil {
			appErr := NewUnauthorizedError(fmt.Sprintf("invalid token: %v", err))
			logAuthAttempt(claims.Subject, claims.OrgID.String(), false)
			writeError(w, appErr, requestID)
			return
		}

		// Log successful auth
		logAuthAttempt(claims.UserID.String(), claims.OrgID.String(), true)

		// Add claims to context
		ctx := context.WithValue(r.Context(), ContextKeyOrgID, claims.OrgID)
		ctx = context.WithValue(ctx, ContextKeyUserID, claims.UserID)
		ctx = context.WithValue(ctx, ContextKeyUserRole, claims.Role)

		// Set PostgreSQL org_id for RLS
		if err := setPostgreSQLOrgID(ctx, claims.OrgID.String()); err != nil {
			logger.Warnw("failed to set postgresql org_id", "error", err)
		}

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// ============================================================================
// Optional Auth Middleware (for public endpoints)
// ============================================================================

func optionalAuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")

		if authHeader != "" {
			parts := strings.Split(authHeader, " ")
			if len(parts) == 2 && parts[0] == "Bearer" {
				token := parts[1]
				secret := os.Getenv("JWT_SECRET")
				if secret == "" {
					secret = "dev-secret-key-change-in-prod"
				}

				if claims, err := validateJWTToken(token, secret); err == nil {
					ctx := context.WithValue(r.Context(), ContextKeyOrgID, claims.OrgID)
					ctx = context.WithValue(ctx, ContextKeyUserID, claims.UserID)
					ctx = context.WithValue(ctx, ContextKeyUserRole, claims.Role)
					r = r.WithContext(ctx)
				}
			}
		}

		next.ServeHTTP(w, r)
	})
}

// ============================================================================
// Panicking Middleware Chain (Week 2)
// ============================================================================

func setupMiddlewareEnhanced() {
	// Initialize components
	initRateLimiter()
}

// ============================================================================
// Cleanup
// ============================================================================

func cleanupMiddleware() {
	if globalRateLimiter != nil {
		globalRateLimiter.Stop()
	}
}
