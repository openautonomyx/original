package main

import (
	"fmt"
	"regexp"

	"github.com/go-playground/validator/v10"
)

// ============================================================================
// Validator Instance
// ============================================================================

var validate *validator.Validate

func init() {
	validate = validator.New()
	// Register custom validators
	validate.RegisterValidation("email", validateEmail)
	validate.RegisterValidation("slug", validateSlug)
	validate.RegisterValidation("uuid", validateUUID)
}

// ============================================================================
// Custom Validators
// ============================================================================

func validateEmail(fl validator.FieldLevel) bool {
	email := fl.Field().String()
	pattern := `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
	return regexp.MustCompile(pattern).MatchString(email)
}

func validateSlug(fl validator.FieldLevel) bool {
	slug := fl.Field().String()
	pattern := `^[a-z0-9]([a-z0-9-]*[a-z0-9])?$`
	return regexp.MustCompile(pattern).MatchString(slug)
}

func validateUUID(fl validator.FieldLevel) bool {
	value := fl.Field().String()
	pattern := `^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`
	return regexp.MustCompile(pattern).MatchString(value)
}

// ============================================================================
// Validation Helpers
// ============================================================================

func validateRequest(data interface{}) error {
	if err := validate.Struct(data); err != nil {
		if validationErrors, ok := err.(validator.ValidationErrors); ok {
			var errs []string
			for _, fe := range validationErrors {
				errs = append(errs, formatValidationError(fe))
			}
			return NewValidationError(errs)
		}
		return NewInternalError(err)
	}
	return nil
}

func formatValidationError(fe validator.FieldError) string {
	return fmt.Sprintf("field '%s' failed validation: %s", fe.Field(), fe.Tag())
}

// ============================================================================
// Validation Rules
// ============================================================================

// ValidateOrganizationCreate validates organization creation request
func ValidateOrganizationCreate(req CreateOrganizationRequest) error {
	if err := validateRequest(req); err != nil {
		return err
	}

	// Additional business logic validation
	if len(req.Name) < 3 || len(req.Name) > 255 {
		return NewValidationError([]string{"name must be between 3 and 255 characters"})
	}

	if len(req.Slug) < 3 || len(req.Slug) > 255 {
		return NewValidationError([]string{"slug must be between 3 and 255 characters"})
	}

	validTiers := map[string]bool{"free": true, "pro": true, "enterprise": true}
	if !validTiers[req.Tier] {
		return NewValidationError([]string{"tier must be free, pro, or enterprise"})
	}

	return nil
}

// ValidateUserCreate validates user creation request
func ValidateUserCreate(req CreateUserRequest) error {
	if err := validateRequest(req); err != nil {
		return err
	}

	if len(req.Password) < 8 {
		return NewValidationError([]string{"password must be at least 8 characters"})
	}

	validRoles := map[string]bool{"admin": true, "editor": true, "viewer": true, "user": true}
	if !validRoles[req.Role] {
		return NewValidationError([]string{"invalid role"})
	}

	return nil
}

// ValidateContentCreate validates content creation request
func ValidateContentCreate(req CreateContentRequest) error {
	if err := validateRequest(req); err != nil {
		return err
	}

	validTypes := map[string]bool{
		"article": true,
		"video":   true,
		"image":   true,
		"podcast": true,
		"social":  true,
	}
	if !validTypes[req.ContentType] {
		return NewValidationError([]string{"invalid content type"})
	}

	return nil
}

// ValidateWorkflowCreate validates workflow creation request
func ValidateWorkflowCreate(req CreateWorkflowRequest) error {
	if err := validateRequest(req); err != nil {
		return err
	}

	validTypes := map[string]bool{
		"content-creation": true,
		"approval":         true,
		"publishing":       true,
		"distribution":     true,
	}
	if !validTypes[req.WorkflowType] {
		return NewValidationError([]string{"invalid workflow type"})
	}

	return nil
}

// ValidateApprovalCreate validates approval creation request
func ValidateApprovalCreate(req CreateApprovalRequest) error {
	if err := validateRequest(req); err != nil {
		return err
	}

	validDecisions := map[string]bool{
		"approved":           true,
		"rejected":           true,
		"requested-changes":  true,
	}
	if !validDecisions[req.Decision] {
		return NewValidationError([]string{"invalid decision value"})
	}

	return nil
}

// ValidateAgentCreate validates agent creation request
func ValidateAgentCreate(req CreateAgentRequest) error {
	if err := validateRequest(req); err != nil {
		return err
	}

	validTypes := map[string]bool{
		"content-creator": true,
		"approver":        true,
		"publisher":       true,
		"distributor":     true,
	}
	if !validTypes[req.AgentType] {
		return NewValidationError([]string{"invalid agent type"})
	}

	return nil
}
