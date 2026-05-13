#!/bin/bash
################################################################################
# RedHat/CentOS/Fedora System Maintenance Utilities
################################################################################

update_system() {
    log_info "Updating RedHat/CentOS/Fedora system..."
    
    # Determine package manager
    local pkg_mgr="yum"
    if command -v dnf &>/dev/null; then
        pkg_mgr="dnf"
    fi
    
    # Update package lists and install updates
    log_debug "Installing package updates with ${pkg_mgr}..."
    
    if [[ "${pkg_mgr}" == "dnf" ]]; then
        # DNF (Fedora 22+) - doesn't support --skip-broken
        ${pkg_mgr} update -y || log_error "Failed to update packages"
    else
        # YUM (CentOS/RHEL) - supports --skip-broken
        ${pkg_mgr} update -y --skip-broken || log_error "Failed to update packages"
    fi
    
    # Install any available group updates
    log_debug "Checking for group updates..."
    ${pkg_mgr} groupupdate -y "@core" 2>/dev/null || log_debug "No group updates available"
    
    log_success "RedHat/CentOS/Fedora system updated"
}

update_security() {
    log_info "Installing RedHat/CentOS/Fedora security updates..."
    
    # Determine package manager
    local pkg_mgr="yum"
    if command -v dnf &>/dev/null; then
        pkg_mgr="dnf"
    fi
    
    # Install security updates only
    log_debug "Installing security updates with ${pkg_mgr}..."
    
    if [[ "${pkg_mgr}" == "dnf" ]]; then
        # DNF (Fedora 22+)
        ${pkg_mgr} update --security -y || \
            log_error "Failed to install security updates"
    else
        # YUM (CentOS/RHEL)
        ${pkg_mgr} update --security -y --skip-broken || \
            log_error "Failed to install security updates"
    fi
    
    log_success "RedHat/CentOS/Fedora security updates completed"
}

install_essential_packages() {
    log_info "Installing essential packages for RedHat/CentOS/Fedora..."
    
    local pkg_mgr="yum"
    if command -v dnf &>/dev/null; then
        pkg_mgr="dnf"
    fi
    
    local essential_packages=(
        "gcc"
        "curl"
        "wget"
        "git"
        "net-tools"
        "htop"
        "vim"
        "openssh-clients"
        "unzip"
        "yum-utils"
    )
    
    for package in "${essential_packages[@]}"; do
        if ! is_package_installed "${package}"; then
            log_info "Installing ${package}..."
            ${pkg_mgr} install -y "${package}" || log_warn "Failed to install ${package}"
        fi
    done
}

get_package_count() {
    rpm -qa | wc -l
}

get_updates_available() {
    local pkg_mgr="yum"
    if command -v dnf &>/dev/null; then
        pkg_mgr="dnf"
    fi
    
    ${pkg_mgr} check-update 2>/dev/null | grep -v "^$" | wc -l
}

get_security_updates_available() {
    local pkg_mgr="yum"
    if command -v dnf &>/dev/null; then
        pkg_mgr="dnf"
    fi
    
    ${pkg_mgr} check-update --security 2>/dev/null | grep -v "^$" | wc -l
}

fix_broken_dependencies() {
    log_info "Fixing broken dependencies..."
    
    local pkg_mgr="yum"
    if command -v dnf &>/dev/null; then
        pkg_mgr="dnf"
    fi
    
    ${pkg_mgr} check 2>/dev/null || log_warn "No dependency issues found"
}

clean_redhat_specific() {
    log_info "Performing RedHat-specific cleanup..."
    
    local pkg_mgr="yum"
    if command -v dnf &>/dev/null; then
        pkg_mgr="dnf"
    fi
    
    # Clean all cached data
    ${pkg_mgr} clean all 2>/dev/null || true
    
    # Remove old kernel packages
    log_debug "Removing old kernel packages..."
    package-cleanup --oldkernels --count=2 -y 2>/dev/null || log_debug "package-cleanup not available"
}
