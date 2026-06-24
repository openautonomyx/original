package main

import (
	"testing"
	"time"

	"github.com/google/uuid"
)

// ============================================================================
// JWT Token Tests
// ============================================================================

func TestGenerateJWTToken(t *testing.T) {
	secret := "test-secret-key"
	orgID := uuid.New()
	userID := uuid.New()
	email := "test@example.com"
	role := "admin"

	token, err := generateJWTToken(orgID, userID, email, role, secret)
	if err != nil {
		t.Fatalf("failed to generate token: %v", err)
	}

	if token == "" {
		t.Fatal("generated token is empty")
	}
}

func TestValidateJWTToken(t *testing.T) {
	secret := "test-secret-key"
	orgID := uuid.New()
	userID := uuid.New()
	email := "test@example.com"
	role := "admin"

	// Generate token
	token, err := generateJWTToken(orgID, userID, email, role, secret)
	if err != nil {
		t.Fatalf("failed to generate token: %v", err)
	}

	// Validate token
	claims, err := validateJWTToken(token, secret)
	if err != nil {
		t.Fatalf("failed to validate token: %v", err)
	}

	// Verify claims
	if claims.OrgID != orgID {
		t.Errorf("org_id mismatch: got %v, want %v", claims.OrgID, orgID)
	}

	if claims.UserID != userID {
		t.Errorf("user_id mismatch: got %v, want %v", claims.UserID, userID)
	}

	if claims.Email != email {
		t.Errorf("email mismatch: got %v, want %v", claims.Email, email)
	}

	if claims.Role != role {
		t.Errorf("role mismatch: got %v, want %v", claims.Role, role)
	}
}

func TestValidateJWTTokenInvalid(t *testing.T) {
	tests := []string{
		"",                    // Empty token
		"invalid.token.here",  // Malformed token
		"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzb21lIjoicGF5bG9hZCJ9.TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ", // Invalid signature
	}

	secret := "test-secret-key"

	for _, token := range tests {
		_, err := validateJWTToken(token, secret)
		if err == nil {
			t.Errorf("expected error for token: %s, got nil", token)
		}
	}
}

func TestTokenExpiration(t *testing.T) {
	secret := "test-secret-key"
	orgID := uuid.New()
	userID := uuid.New()
	email := "test@example.com"
	role := "admin"

	token, err := generateJWTToken(orgID, userID, email, role, secret)
	if err != nil {
		t.Fatalf("failed to generate token: %v", err)
	}

	// Should be valid initially
	claims, err := validateJWTToken(token, secret)
	if err != nil {
		t.Fatalf("token should be valid: %v", err)
	}

	if time.Until(claims.ExpiresAt.Time) <= 0 {
		t.Fatal("token should not be expired")
	}
}

// ============================================================================
// Role-Based Access Control Tests
// ============================================================================

func TestRolePermissionLevels(t *testing.T) {
	tests := []struct {
		role     string
		expected PermissionLevel
	}{
		{"admin", PermissionAdmin},
		{"editor", PermissionEdit},
		{"approver", PermissionApprove},
		{"viewer", PermissionView},
		{"unknown", PermissionView},
	}

	for _, test := range tests {
		got := getRolePermissionLevel(test.role)
		if got != test.expected {
			t.Errorf("role %s: got %v, want %v", test.role, got, test.expected)
		}
	}
}

func TestCanPerformAction(t *testing.T) {
	tests := []struct {
		userRole     string
		requiredLevel PermissionLevel
		expected     bool
	}{
		{"admin", PermissionView, true},
		{"admin", PermissionAdmin, true},
		{"editor", PermissionEdit, true},
		{"editor", PermissionAdmin, false},
		{"viewer", PermissionView, true},
		{"viewer", PermissionEdit, false},
	}

	for _, test := range tests {
		got := canPerformAction(test.userRole, test.requiredLevel)
		if got != test.expected {
			t.Errorf("user %s, level %v: got %v, want %v", test.userRole, test.requiredLevel, got, test.expected)
		}
	}
}

// ============================================================================
// Benchmarks
// ============================================================================

func BenchmarkGenerateJWTToken(b *testing.B) {
	secret := "test-secret-key"
	orgID := uuid.New()
	userID := uuid.New()
	email := "test@example.com"
	role := "admin"

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		generateJWTToken(orgID, userID, email, role, secret)
	}
}

func BenchmarkValidateJWTToken(b *testing.B) {
	secret := "test-secret-key"
	orgID := uuid.New()
	userID := uuid.New()
	email := "test@example.com"
	role := "admin"

	token, _ := generateJWTToken(orgID, userID, email, role, secret)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		validateJWTToken(token, secret)
	}
}
