#!/bin/bash
################################################################################
# openSUSE System Maintenance Utilities
################################################################################

update_system() {
    log_info "Updating openSUSE system..."
    
    # Refresh package metadata
    log_debug "Refreshing package metadata..."
    zypper refresh || log_error "Failed to refresh package metadata"
    
    # Upgrade packages
    log_debug "Upgrading packages..."
    zypper update -y || log_error "Failed to upgrade packages"
    
    log_success "openSUSE system updated"
}

update_security() {
    log_info "Installing openSUSE security updates..."
    
    # Refresh package metadata
    log_debug "Refreshing package metadata..."
    zypper refresh || log_error "Failed to refresh package metadata"
    
    # Apply security updates only
    log_debug "Installing security updates..."
    zypper patch -y 2>/dev/null || log_error "Failed to install security updates"
    
    log_success "openSUSE security updates completed"
}

install_essential_packages() {
    log_info "Installing essential packages for openSUSE..."
    
    local essential_packages=(
        "gcc"
        "curl"
        "wget"
        "git"
        "net-tools"
        "htop"
        "vim"
        "openssh"
        "unzip"
    )
    
    for package in "${essential_packages[@]}"; do
        if ! is_package_installed "${package}"; then
            log_info "Installing ${package}..."
            zypper install -y "${package}" || log_warn "Failed to install ${package}"
        fi
    done
}

get_package_count() {
    rpm -qa | wc -l
}

get_updates_available() {
    zypper list-updates 2>/dev/null | tail -n +5 | wc -l
}

get_security_updates_available() {
    zypper list-patches --category security 2>/dev/null | tail -n +5 | wc -l
}

fix_broken_dependencies() {
    log_info "Checking for broken dependencies..."
    log_debug "Running verify to check dependencies..."
    zypper verify 2>/dev/null || log_warn "No dependency issues found"
}

clean_opensuse_specific() {
    log_info "Performing openSUSE-specific cleanup..."
    
    # Clean cached packages
    log_debug "Cleaning package cache..."
    zypper clean 2>/dev/null || true
    
    # Remove unused dependencies
    log_debug "Removing unused packages..."
    zypper rm-orphans -y 2>/dev/null || log_debug "No orphaned packages found"
}
