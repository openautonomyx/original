package main

import (
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// ============================================================================
// JWT Claims
// ============================================================================

type Claims struct {
	OrgID  uuid.UUID `json:"org_id"`
	UserID uuid.UUID `json:"user_id"`
	Email  string    `json:"email"`
	Role   string    `json:"role"`
	jwt.RegisteredClaims
}

// ============================================================================
// JWT Token Generation
// ============================================================================

func generateJWTToken(orgID, userID uuid.UUID, email, role, secret string) (string, error) {
	now := time.Now()
	expiresAt := now.Add(24 * time.Hour)

	claims := Claims{
		OrgID:  orgID,
		UserID: userID,
		Email:  email,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expiresAt),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			Issuer:    "creative-platform",
			Subject:   userID.String(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(secret))
	if err != nil {
		return "", fmt.Errorf("failed to sign token: %w", err)
	}

	return tokenString, nil
}

// ============================================================================
// JWT Token Validation (ENHANCED)
// ============================================================================

func validateJWTToken(tokenString, secret string) (*Claims, error) {
	if tokenString == "" {
		return nil, errors.New("empty token")
	}

	claims := &Claims{}

	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		// Verify signing method
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(secret), nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to parse token: %w", err)
	}

	if !token.Valid {
		return nil, errors.New("invalid token")
	}

	// Additional validation
	if claims.OrgID == uuid.Nil {
		return nil, errors.New("missing org_id in token")
	}

	if claims.UserID == uuid.Nil {
		return nil, errors.New("missing user_id in token")
	}

	if claims.ExpiresAt.Before(time.Now()) {
		return nil, errors.New("token expired")
	}

	return claims, nil
}

// ============================================================================
// Role-Based Access Control
// ============================================================================

type PermissionLevel int

const (
	PermissionView PermissionLevel = iota
	PermissionEdit
	PermissionApprove
	PermissionAdmin
)

func getRolePermissionLevel(role string) PermissionLevel {
	switch role {
	case "admin":
		return PermissionAdmin
	case "editor":
		return PermissionEdit
	case "approver":
		return PermissionApprove
	case "viewer":
		return PermissionView
	default:
		return PermissionView
	}
}

func canPerformAction(userRole string, requiredLevel PermissionLevel) bool {
	return getRolePermissionLevel(userRole) >= requiredLevel
}

// ============================================================================
// API Key Validation
// ============================================================================

func validateAPIKey(keyHash, providedKey string) bool {
	// TODO: Implement bcrypt comparison
	// For now, simple comparison (Week 3: upgrade to bcrypt)
	return keyHash == providedKey
}

// ============================================================================
// Token Refresh
// ============================================================================

func refreshToken(claims *Claims, secret string) (string, error) {
	// Prevent refreshing if almost expired (within 1 hour)
	if time.Until(claims.ExpiresAt.Time) < 1*time.Hour {
		return "", errors.New("token refresh window expired")
	}

	// Generate new token
	return generateJWTToken(claims.OrgID, claims.UserID, claims.Email, claims.Role, secret)
}
