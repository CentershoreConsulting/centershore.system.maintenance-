#!/bin/bash
################################################################################
# Centershore System Maintenance - Main Orchestration Script
# 
# This script provides comprehensive system-level maintenance and updates
# across multiple Linux distributions.
#
# Usage: sudo ./system-maintenance.sh [OPTIONS]
################################################################################

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/system-maintenance"
LOG_FILE="/var/log/system-maintenance.log"
LOCK_FILE="/var/run/system-maintenance.lock"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# Options
DRY_RUN=false
VERBOSE=false
SECURITY_ONLY=false
CLEANUP_ONLY=false
SKIP_BACKUP=false
FORCE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Utility Functions
################################################################################

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${timestamp} [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info() {
    log "INFO" "$@"
}

log_warn() {
    log "WARN" "${YELLOW}$@${NC}"
}

log_error() {
    log "ERROR" "${RED}$@${NC}"
}

log_success() {
    log "SUCCESS" "${GREEN}$@${NC}"
}

log_debug() {
    if [[ "${VERBOSE}" == true ]]; then
        log "DEBUG" "${BLUE}$@${NC}"
    fi
}

print_help() {
    cat << EOF
${BLUE}Centershore System Maintenance${NC}

Usage: sudo $0 [OPTIONS]

Options:
    --security-only      Only apply security updates
    --cleanup-only       Only perform cleanup tasks
    --dry-run           Preview changes without applying them
    --verbose           Enable detailed logging
    --skip-backup       Skip system backup (not recommended)
    --force             Force execution even if checks fail
    --help              Display this help message

Examples:
    # Full maintenance
    sudo $0
    
    # Security updates only
    sudo $0 --security-only
    
    # Dry-run to preview
    sudo $0 --dry-run

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --security-only)
                SECURITY_ONLY=true
                shift
                ;;
            --cleanup-only)
                CLEANUP_ONLY=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --help)
                print_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
    done
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

setup_logging() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    chmod 644 "${LOG_FILE}"
}

acquire_lock() {
    if [[ -f "${LOCK_FILE}" ]]; then
        local pid=$(cat "${LOCK_FILE}")
        if ps -p "${pid}" > /dev/null 2>&1; then
            log_error "Another maintenance session is running (PID: ${pid})"
            exit 1
        else
            rm -f "${LOCK_FILE}"
        fi
    fi
    
    echo $$ > "${LOCK_FILE}"
}

release_lock() {
    rm -f "${LOCK_FILE}"
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_VERSION="${VERSION_ID:-unknown}"
    else
        log_error "Cannot detect Linux distribution"
        exit 1
    fi
    
    log_info "Detected distribution: ${DISTRO_ID} ${DISTRO_VERSION}"
}

load_distro_utils() {
    local utils_lib="${SCRIPT_DIR}/lib/common-utils.sh"
    
    if [[ ! -f "${utils_lib}" ]]; then
        log_error "Common utilities library not found: ${utils_lib}"
        exit 1
    fi
    source "${utils_lib}"
    
    case "${DISTRO_ID}" in
        debian|ubuntu)
            utils_lib="${SCRIPT_DIR}/lib/debian-utils.sh"
            ;;
        rhel|centos|fedora)
            utils_lib="${SCRIPT_DIR}/lib/redhat-utils.sh"
            ;;
        arch)
            utils_lib="${SCRIPT_DIR}/lib/arch-utils.sh"
            ;;
        alpine)
            utils_lib="${SCRIPT_DIR}/lib/alpine-utils.sh"
            ;;
        opensuse*)
            utils_lib="${SCRIPT_DIR}/lib/opensuse-utils.sh"
            ;;
        *)
            log_error "Unsupported distribution: ${DISTRO_ID}"
            exit 1
            ;;
    esac
    
    if [[ ! -f "${utils_lib}" ]]; then
        log_error "Distribution utilities library not found: ${utils_lib}"
        exit 1
    fi
    source "${utils_lib}"
}

perform_preflight_checks() {
    log_info "Performing pre-flight system checks..."
    
    # Check disk space
    local root_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ ${root_usage} -gt 90 ]]; then
        log_warn "Root partition is ${root_usage}% full"
        if [[ "${FORCE}" != true ]]; then
            log_error "Not enough disk space for maintenance"
            exit 1
        fi
    fi
    
    # Check available memory
    local mem_available=$(free -h | awk 'NR==2 {print $7}')
    log_debug "Available memory: ${mem_available}"
    
    # Check network connectivity
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_warn "Network connectivity check failed"
        if [[ "${FORCE}" != true ]]; then
            log_error "Network connectivity required for package updates"
            exit 1
        fi
    fi
    
    log_success "Pre-flight checks completed"
}

perform_backup() {
    if [[ "${SKIP_BACKUP}" == true ]]; then
        log_warn "Skipping backup as requested"
        return 0
    fi
    
    log_info "Creating system backup..."
    
    # Create backup of important system files
    local backup_dir="${LOG_DIR}/backup_${TIMESTAMP}"
    mkdir -p "${backup_dir}"
    
    cp -R /etc/apt* "${backup_dir}/" 2>/dev/null || true
    cp -R /etc/yum* "${backup_dir}/" 2>/dev/null || true
    cp /etc/os-release "${backup_dir}/" 2>/dev/null || true
    
    log_success "Backup created at: ${backup_dir}"
}

perform_updates() {
    log_info "Starting system updates..."
    
    if [[ "${SECURITY_ONLY}" == true ]]; then
        log_info "Applying security updates only..."
        update_security
    else
        log_info "Applying all available updates..."
        update_system
    fi
    
    log_success "System updates completed"
}

perform_cleanup() {
    log_info "Starting cleanup tasks..."
    
    cleanup_package_cache
    cleanup_temporary_files
    cleanup_unused_packages
    cleanup_log_files
    
    log_success "Cleanup completed"
}

perform_maintenance() {
    log_info "Starting maintenance tasks..."
    
    optimize_services
    check_disk_usage
    check_system_health
    
    log_success "Maintenance completed"
}

generate_report() {
    log_info ""
    log_info "========== Maintenance Report =========="
    log_info "Timestamp: $(date)"
    log_info "Distribution: ${DISTRO_ID} ${DISTRO_VERSION}"
    log_info "Hostname: $(hostname)"
    log_info "Kernel: $(uname -r)"
    log_info ""
    log_info "Disk Usage:"
    df -h | tail -n +2 | awk '{log_info "  " $0}'
    log_info ""
    log_info "System Uptime:"
    uptime >> "${LOG_FILE}"
    log_info ""
    log_info "For detailed logs, see: ${LOG_FILE}"
    log_info "========================================"
}

main() {
    parse_arguments "$@"
    
    check_root
    setup_logging
    acquire_lock
    trap release_lock EXIT
    
    log_info "============================================"
    log_info "Centershore System Maintenance Started"
    log_info "============================================"
    log_info "Dry-run mode: ${DRY_RUN}"
    log_info "Verbose logging: ${VERBOSE}"
    
    detect_distro
    load_distro_utils
    perform_preflight_checks
    
    if [[ "${DRY_RUN}" == false ]]; then
        perform_backup
    else
        log_info "DRY-RUN: Skipping actual backup"
    fi
    
    if [[ "${CLEANUP_ONLY}" != true ]]; then
        if [[ "${DRY_RUN}" == false ]]; then
            perform_updates
        else
            log_info "DRY-RUN: Would perform system updates"
        fi
    fi
    
    if [[ "${SECURITY_ONLY}" != true ]]; then
        if [[ "${DRY_RUN}" == false ]]; then
            perform_cleanup
            perform_maintenance
        else
            log_info "DRY-RUN: Would perform cleanup and maintenance"
        fi
    fi
    
    generate_report
    
    log_success "============================================"
    log_success "Centershore System Maintenance Completed"
    log_success "============================================"
}

main "$@"
