#!/bin/bash

# =============================================
# Paperly Database Migration Script
# Version: 2.0.0
# =============================================

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default database configuration
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-paperly}
DB_USER=${DB_USER:-paperly_user}
DB_SCHEMA=${DB_SCHEMA:-paperly}

# Log function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if psql is available
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v psql &> /dev/null; then
        error "psql (PostgreSQL client) is not installed or not in PATH"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# Test database connection
test_connection() {
    log "Testing database connection..."
    
    if ! PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c '\q' 2>/dev/null; then
        error "Cannot connect to database. Please check your credentials and ensure PostgreSQL is running."
        echo "Connection details:"
        echo "  Host: $DB_HOST"
        echo "  Port: $DB_PORT"
        echo "  Database: $DB_NAME"
        echo "  User: $DB_USER"
        echo "  Schema: $DB_SCHEMA"
        exit 1
    fi
    
    success "Database connection successful"
}

# Create schema if it doesn't exist
create_schema() {
    log "Creating paperly schema if it doesn't exist..."
    
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
        CREATE SCHEMA IF NOT EXISTS paperly;
        SET search_path TO paperly, public;
        COMMENT ON SCHEMA paperly IS 'Paperly AI 맞춤형 학습 앱 스키마 v2.0';
    "
    
    success "Schema created/verified"
}

# Run a single migration file
run_migration() {
    local file=$1
    local filename=$(basename "$file")
    
    log "Running migration: $filename"
    
    if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$file"; then
        success "Migration $filename completed successfully"
        return 0
    else
        error "Migration $filename failed"
        return 1
    fi
}

# Main migration function
run_migrations() {
    local migration_dir="$(dirname "$0")"
    local failed_migrations=()
    
    log "Starting Paperly database migrations..."
    log "Migration directory: $migration_dir"
    
    # Create schema first
    create_schema
    
    # List of migration files in correct order
    local migrations=(
        "000_create_paperly_schema.sql"
        "001_paperly_master_schema.sql"
        "002_recommendation_system.sql"
        "003_user_behavior_analytics.sql"
        "004_security_system.sql"
    )
    
    log "Found ${#migrations[@]} migrations to run"
    
    # Run each migration
    for migration in "${migrations[@]}"; do
        local file_path="$migration_dir/$migration"
        
        if [[ -f "$file_path" ]]; then
            if ! run_migration "$file_path"; then
                failed_migrations+=("$migration")
                if [[ "$CONTINUE_ON_ERROR" != "true" ]]; then
                    error "Migration failed. Stopping execution."
                    break
                fi
            fi
        else
            warning "Migration file not found: $migration (skipping)"
        fi
    done
    
    # Summary
    echo ""
    log "Migration Summary:"
    if [[ ${#failed_migrations[@]} -eq 0 ]]; then
        success "All migrations completed successfully!"
    else
        error "Some migrations failed:"
        for failed in "${failed_migrations[@]}"; do
            echo "  - $failed"
        done
        exit 1
    fi
}

# Verify database structure
verify_database() {
    log "Verifying database structure..."
    
    local table_count=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
        SELECT COUNT(*) 
        FROM information_schema.tables 
        WHERE table_schema = 'paperly'
    " | xargs)
    
    local view_count=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
        SELECT COUNT(*) 
        FROM information_schema.views 
        WHERE table_schema = 'paperly'
    " | xargs)
    
    local function_count=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
        SELECT COUNT(*) 
        FROM information_schema.routines 
        WHERE routine_schema = 'paperly'
    " | xargs)
    
    log "Database verification results:"
    echo "  - Tables created: $table_count"
    echo "  - Views created: $view_count"
    echo "  - Functions created: $function_count"
    
    if [[ $table_count -gt 20 ]]; then
        success "Database structure verification passed"
    else
        warning "Database structure may be incomplete (only $table_count tables found)"
    fi
}

# Backup function (optional)
backup_database() {
    if [[ "$BACKUP_BEFORE_MIGRATION" == "true" ]]; then
        log "Creating database backup..."
        local backup_file="paperly_backup_$(date +%Y%m%d_%H%M%S).sql"
        
        if PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME > "$backup_file"; then
            success "Database backup created: $backup_file"
        else
            warning "Failed to create database backup"
        fi
    fi
}

# Show help
show_help() {
    echo "Paperly Database Migration Script v2.0"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Environment Variables:"
    echo "  DB_HOST              Database host (default: localhost)"
    echo "  DB_PORT              Database port (default: 5432)"
    echo "  DB_NAME              Database name (default: paperly)"
    echo "  DB_USER              Database user (default: paperly_user)"
    echo "  DB_PASSWORD          Database password (required)"
    echo "  DB_SCHEMA            Database schema (default: paperly)"
    echo "  CONTINUE_ON_ERROR    Continue on migration errors (default: false)"
    echo "  BACKUP_BEFORE_MIGRATION  Create backup before migration (default: false)"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  --verify-only        Only verify database structure"
    echo "  --backup-only        Only create database backup"
    echo ""
    echo "Examples:"
    echo "  # Run all migrations"
    echo "  DB_PASSWORD=mypass $0"
    echo ""
    echo "  # Run with backup"
    echo "  DB_PASSWORD=mypass BACKUP_BEFORE_MIGRATION=true $0"
    echo ""
    echo "  # Continue on errors"
    echo "  DB_PASSWORD=mypass CONTINUE_ON_ERROR=true $0"
}

# Main execution
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        --verify-only)
            check_prerequisites
            test_connection
            verify_database
            exit 0
            ;;
        --backup-only)
            check_prerequisites
            test_connection
            backup_database
            exit 0
            ;;
        *)
            if [[ -z "$DB_PASSWORD" ]]; then
                error "DB_PASSWORD environment variable is required"
                echo ""
                show_help
                exit 1
            fi
            
            check_prerequisites
            test_connection
            backup_database
            run_migrations
            verify_database
            
            echo ""
            success "Paperly database migration completed successfully!"
            log "Your database is now ready for Google/Facebook-level recommendation system!"
            ;;
    esac
}

# Run main function with all arguments
main "$@"