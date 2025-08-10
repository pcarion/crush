# Makefile for crush - Terminal-based AI assistant for software development

# Variables
BINARY_NAME = crush
BUILD_DIR = build
INSTALL_DIR = /usr/local/bin
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)
LDFLAGS = -ldflags "-X github.com/charmbracelet/crush/internal/version.Version=$(VERSION) -s -w"

# Default target
.PHONY: all
all: build

# Build the application
.PHONY: build
build: $(BUILD_DIR)
	@echo "Building $(BINARY_NAME) for $(GOOS)/$(GOARCH)..."
	@go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) .
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

# Create build directory
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Build for Mac (Intel)
.PHONY: build-mac-intel
build-mac-intel:
	@GOOS=darwin GOARCH=amd64 make build

# Build for Mac (Apple Silicon)
.PHONY: build-mac-arm64
build-mac-arm64:
	@GOOS=darwin GOARCH=arm64 make build

# Build for both Mac architectures
.PHONY: build-mac
build-mac: build-mac-intel build-mac-arm64

# Install to system directory (requires sudo)
.PHONY: install
install: build
	@echo "Installing $(BINARY_NAME) to $(INSTALL_DIR)..."
	cp $(BUILD_DIR)/$(BINARY_NAME) $(INSTALL_DIR)/
	chmod +x $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "Installation complete. You can now run '$(BINARY_NAME)' from anywhere."

# Uninstall from system directory (requires sudo)
.PHONY: uninstall
uninstall:
	@echo "Removing $(BINARY_NAME) from $(INSTALL_DIR)..."
	rm -f $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "Uninstallation complete."

# Install to user's local bin directory
.PHONY: install-local
install-local: build
	@echo "Installing $(BINARY_NAME) to ~/.local/bin..."
	@mkdir -p ~/.local/bin
	@cp $(BUILD_DIR)/$(BINARY_NAME) ~/.local/bin/
	@chmod +x ~/.local/bin/$(BINARY_NAME)
	@echo "Installation complete. Make sure ~/.local/bin is in your PATH."

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@go clean -cache
	@echo "Clean complete."

# Run tests
.PHONY: test
test:
	@echo "Running tests..."
	@go test -v ./...

# Run tests with coverage
.PHONY: test-coverage
test-coverage:
	@echo "Running tests with coverage..."
	@go test -v -coverprofile=coverage.out ./...
	@go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

# Run linter
.PHONY: lint
lint:
	@echo "Running linter..."
	@golangci-lint run

# Format code
.PHONY: fmt
fmt:
	@echo "Formatting code..."
	@gofumpt -w .
	@go mod tidy

# Generate man page
.PHONY: man
man:
	@echo "Generating man page..."
	@mkdir -p manpages
	@go run . man | gzip -c > manpages/$(BINARY_NAME).1.gz
	@echo "Man page generated: manpages/$(BINARY_NAME).1.gz"

# Install man page (requires sudo)
.PHONY: install-man
install-man: man
	@echo "Installing man page..."
	mkdir -p /usr/local/share/man/man1
	cp manpages/$(BINARY_NAME).1.gz /usr/local/share/man/man1/
	mandb
	@echo "Man page installed. You can now run 'man $(BINARY_NAME)'."

# Development mode with profiling
.PHONY: dev
dev:
	@echo "Running in development mode with profiling..."
	@CRUSH_PROFILE=true go run .

# Show help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build          - Build the application"
	@echo "  build-mac-intel - Build for Mac (Intel)"
	@echo "  build-mac-arm64 - Build for Mac (Apple Silicon)"
	@echo "  build-mac      - Build for both Mac architectures"
	@echo "  install        - Install to $(INSTALL_DIR) (requires sudo)"
	@echo "  install-local  - Install to ~/.local/bin"
	@echo "  uninstall      - Remove from $(INSTALL_DIR) (requires sudo)"
	@echo "  clean          - Clean build artifacts"
	@echo "  test           - Run tests"
	@echo "  test-coverage  - Run tests with coverage report"
	@echo "  lint           - Run linter"
	@echo "  fmt            - Format code"
	@echo "  man            - Generate man page"
	@echo "  install-man    - Install man page (requires sudo)"
	@echo "  dev            - Run in development mode with profiling"
	@echo "  help           - Show this help message"
