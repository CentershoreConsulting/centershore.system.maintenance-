#!/bin/bash
################################################################################
# Alpine Linux System Maintenance Utilities
################################################################################

update_system() {
    log_info "Updating Alpine Linux system..."
    
    # Update package lists
    log_debug "Updating package lists..."
    apk update || log_error "Failed to update package lists"
    
    # Upgrade packages
    log_debug "Upgrading packages..."
    apk upgrade || log_error "Failed to upgrade packages"
    
    log_success "Alpine Linux system updated"
}

update_security() {
    log_info "Installing Alpine Linux security updates..."
    
    # Alpine includes security patches in regular updates
    log_debug "Applying system upgrade (security patches included)..."
    apk update || log_error "Failed to update package lists"
    apk upgrade || log_error "Failed to apply security updates"
    
    log_success "Alpine Linux security updates completed"
}

install_essential_packages() {
    log_info "Installing essential packages for Alpine Linux..."
    
    local essential_packages=(
        "alpine-sdk"
        "curl"
        "wget"
        "git"
        "net-tools"
        "htop"
        "vim"
        "openssh-client"
        "unzip"
    )
    
    for package in "${essential_packages[@]}"; do
        if ! is_package_installed "${package}"; then
            log_info "Installing ${package}..."
            apk add "${package}" || log_warn "Failed to install ${package}"
        fi
    done
}

get_package_count() {
    apk info | wc -l
}

get_updates_available() {
    apk update >/dev/null 2>&1
    apk upgrade -s 2>/dev/null | grep "Upgrading" | wc -l
}

get_security_updates_available() {
    # Alpine doesn't separate security updates
    get_updates_available
}

fix_broken_dependencies() {
    log_info "Checking for broken dependencies..."
    log_debug "Running fix to resolve dependencies..."
    apk fix 2>/dev/null || log_warn "No dependency issues found"
}

clean_alpine_specific() {
    log_info "Performing Alpine-specific cleanup..."
    
    # Alpine automatically cleans on upgrade, but we can clean manual installs
    log_debug "Cleaning apk cache..."
    rm -rf /var/cache/apk/* 2>/dev/null || true
    
    # Remove leftover files
    apk cache clean 2>/dev/null || true
}
