#!/bin/bash
################################################################################
# Common Utilities for System Maintenance
# Provides cross-distribution utility functions
################################################################################

# Global variables for distro info
DIST_PKG_MANAGER=""
DIST_UPDATE_CMD=""
DIST_INSTALL_CMD=""
DIST_REMOVE_CMD=""

################################################################################
# Disk Management Functions
################################################################################

get_disk_usage() {
    local path="${1:-.}"
    du -sh "${path}" 2>/dev/null | awk '{print $1}'
}

get_partition_usage() {
    df -h "${1:-.}" | tail -1 | awk '{print $5}' | sed 's/%//'
}

check_disk_usage() {
    log_info "Checking disk usage..."
    
    local root_usage=$(get_partition_usage /)
    local root_available=$(df -h / | tail -1 | awk '{print $4}')
    
    log_info "  Root partition: ${root_usage}% used (${root_available} available)"
    
    # Check home if exists
    if mountpoint -q /home 2>/dev/null; then
        local home_usage=$(get_partition_usage /home)
        log_info "  Home partition: ${home_usage}% used"
    fi
    
    # Check var if exists
    if mountpoint -q /var 2>/dev/null; then
        local var_usage=$(get_partition_usage /var)
        log_info "  Var partition: ${var_usage}% used"
    fi
}

find_large_files() {
    local path="${1:-.}"
    local limit="${2:-100M}"
    
    log_info "Files larger than ${limit} in ${path}:"
    find "${path}" -type f -size +"${limit}" 2>/dev/null | \
        xargs -I {} sh -c 'du -h "{}" | awk "{print \$1 \" \" \$0}"' | \
        head -20
}

################################################################################
# Log Management Functions
################################################################################

cleanup_log_files() {
    log_info "Cleaning up old log files..."
    
    # Remove logs older than 30 days
    find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null || true
    
    # Compress logs older than 7 days
    find /var/log -type f -name "*.log" -mtime +7 ! -name "*.gz" 2>/dev/null | \
        while read logfile; do
            gzip "${logfile}" 2>/dev/null || true
        done
    
    log_success "Log cleanup completed"
}

rotate_logs() {
    log_info "Rotating system logs..."
    
    if command -v logrotate &> /dev/null; then
        logrotate -f /etc/logrotate.conf 2>/dev/null || true
        log_success "Logs rotated"
    else
        log_warn "logrotate not found"
    fi
}

################################################################################
# Service Management Functions
################################################################################

optimize_services() {
    log_info "Optimizing system services..."
    
    # Disable unnecessary services
    local unnecessary_services=()
    case "${DISTRO_ID}" in
        debian|ubuntu)
            unnecessary_services=("bluetooth" "cups" "iscsid")
            ;;
        rhel|centos|fedora)
            unnecessary_services=("bluetooth" "cups" "iscsi")
            ;;
    esac
    
    for service in "${unnecessary_services[@]}"; do
        if systemctl is-enabled "${service}" &>/dev/null; then
            if ! systemctl is-active --quiet "${service}"; then
                systemctl disable "${service}" 2>/dev/null || true
                log_debug "Disabled service: ${service}"
            fi
        fi
    done
}

check_service_status() {
    local service=$1
    systemctl is-active --quiet "${service}" && echo "active" || echo "inactive"
}

check_system_health() {
    log_info "Checking system health..."
    
    # Check for failed systemd services
    local failed_units=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
    if [[ ${failed_units} -gt 0 ]]; then
        log_warn "Found ${failed_units} failed systemd units:"
        systemctl --failed --no-legend 2>/dev/null | awk '{print "  " $0}'
    fi
    
    # Check kernel messages for errors
    local kernel_errors=$(dmesg | grep -i "error\|warn" | tail -5 2>/dev/null | wc -l)
    if [[ ${kernel_errors} -gt 0 ]]; then
        log_warn "Found recent kernel errors/warnings"
    fi
}

################################################################################
# Temporary File Management
################################################################################

cleanup_temporary_files() {
    log_info "Cleaning up temporary files..."
    
    # Clean /tmp
    find /tmp -type f -atime +7 -delete 2>/dev/null || true
    find /tmp -type d -empty -delete 2>/dev/null || true
    
    # Clean /var/tmp
    find /var/tmp -type f -atime +7 -delete 2>/dev/null || true
    find /var/tmp -type d -empty -delete 2>/dev/null || true
    
    log_success "Temporary file cleanup completed"
}

cleanup_package_cache() {
    log_info "Cleaning up package cache..."
    
    case "${DISTRO_ID}" in
        debian|ubuntu)
            apt-get clean 2>/dev/null || true
            apt-get autoclean 2>/dev/null || true
            ;;
        rhel|centos|fedora)
            yum clean all 2>/dev/null || dnf clean all 2>/dev/null || true
            ;;
        arch)
            pacman -Sc --noconfirm 2>/dev/null || true
            ;;
        alpine)
            rm -rf /var/cache/apk/* 2>/dev/null || true
            ;;
        opensuse*)
            zypper clean 2>/dev/null || true
            ;;
    esac
    
    log_success "Package cache cleanup completed"
}

cleanup_unused_packages() {
    log_info "Removing unused packages..."
    
    case "${DISTRO_ID}" in
        debian|ubuntu)
            apt-get autoremove -y 2>/dev/null || true
            ;;
        rhel|centos|fedora)
            yum autoremove -y 2>/dev/null || dnf autoremove -y 2>/dev/null || true
            ;;
        arch)
            pacman -Rns $(pacman -Qdtq) --noconfirm 2>/dev/null || true
            ;;
        alpine)
            apk del -r --purge /var/cache/distfiles/* 2>/dev/null || true
            ;;
        opensuse*)
            zypper rm -u 2>/dev/null || true
            ;;
    esac
    
    log_success "Unused packages removed"
}

################################################################################
# Package Management Functions
################################################################################

install_package() {
    local package=$1
    
    case "${DISTRO_ID}" in
        debian|ubuntu)
            apt-get install -y "${package}" 2>/dev/null || true
            ;;
        rhel|centos|fedora)
            yum install -y "${package}" 2>/dev/null || dnf install -y "${package}" 2>/dev/null || true
            ;;
        arch)
            pacman -S --noconfirm "${package}" 2>/dev/null || true
            ;;
        alpine)
            apk add "${package}" 2>/dev/null || true
            ;;
        opensuse*)
            zypper install -y "${package}" 2>/dev/null || true
            ;;
    esac
}

is_package_installed() {
    local package=$1
    
    case "${DISTRO_ID}" in
        debian|ubuntu)
            dpkg -l | grep -q "^ii.*${package}" && return 0 || return 1
            ;;
        rhel|centos|fedora)
            rpm -q "${package}" &>/dev/null && return 0 || return 1
            ;;
        arch)
            pacman -Q "${package}" &>/dev/null && return 0 || return 1
            ;;
        alpine)
            apk info | grep -q "^${package}" && return 0 || return 1
            ;;
        opensuse*)
            zypper se -i "${package}" | grep -q "^i" && return 0 || return 1
            ;;
    esac
}

################################################################################
# System Information Functions
################################################################################

get_system_info() {
    log_info "System Information:"
    log_info "  Hostname: $(hostname)"
    log_info "  Kernel: $(uname -r)"
    log_info "  Uptime: $(uptime -p)"
    log_info "  CPU Cores: $(nproc)"
    log_info "  Total Memory: $(free -h | awk 'NR==2 {print $2}')"
    log_info "  Available Memory: $(free -h | awk 'NR==2 {print $7}')"
}

################################################################################
# Distro-specific function stubs (to be overridden)
################################################################################

# These functions should be implemented in distro-specific libs
update_system() {
    log_error "update_system() not implemented for ${DISTRO_ID}"
    return 1
}

update_security() {
    log_error "update_security() not implemented for ${DISTRO_ID}"
    return 1
}
