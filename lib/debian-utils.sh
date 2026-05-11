#!/bin/bash
################################################################################
# Debian/Ubuntu System Maintenance Utilities
################################################################################

update_system() {
    log_info "Updating Debian/Ubuntu system..."
    
    # Update package lists
    log_debug "Updating package lists..."
    apt-get update || log_error "Failed to update package lists"
    
    # Upgrade packages
    log_debug "Installing package upgrades..."
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
        -o Dpkg::Options::="--force-confnew" || \
        log_error "Failed to upgrade packages"
    
    # Full upgrade (includes dependency changes)
    log_debug "Performing full distribution upgrade..."
    DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y \
        -o Dpkg::Options::="--force-confnew" || \
        log_error "Failed to perform dist-upgrade"
    
    log_success "Debian/Ubuntu system updated"
}

update_security() {
    log_info "Installing Debian/Ubuntu security updates..."
    
    # Update package lists
    apt-get update || log_error "Failed to update package lists"
    
    # Install security updates only
    log_debug "Installing security updates..."
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
        -o Dpkg::Options::="--force-confnew" \
        -o "APT::Default-Release=$(lsb_release -cs)-security" || \
        log_error "Failed to install security updates"
    
    log_success "Debian/Ubuntu security updates completed"
}

install_essential_packages() {
    log_info "Installing essential packages for Debian/Ubuntu..."
    
    local essential_packages=(
        "build-essential"
        "curl"
        "wget"
        "git"
        "net-tools"
        "htop"
        "vim"
        "openssh-client"
        "unzip"
        "apt-utils"
    )
    
    for package in "${essential_packages[@]}"; do
        if ! is_package_installed "${package}"; then
            log_info "Installing ${package}..."
            apt-get install -y "${package}" || log_warn "Failed to install ${package}"
        fi
    done
}

get_package_count() {
    dpkg -l | grep "^ii" | wc -l
}

get_updates_available() {
    apt-get update >/dev/null 2>&1
    apt-get upgrade -s 2>/dev/null | grep "^Inst" | wc -l
}

get_security_updates_available() {
    apt-get update >/dev/null 2>&1
    apt-get upgrade -s 2>/dev/null | grep -i "security" | wc -l
}

fix_broken_dependencies() {
    log_info "Fixing broken dependencies..."
    apt-get install -f -y 2>/dev/null || log_warn "No broken dependencies to fix"
}

clean_debian_specific() {
    log_info "Performing Debian-specific cleanup..."
    
    # Remove old kernel images
    log_debug "Removing old kernel images..."
    if command -v purge-old-kernels &>/dev/null; then
        purge-old-kernels --keep 2 2>/dev/null || true
    fi
    
    # Remove old initrd.img
    find /boot -name "initrd.img*" -type f 2>/dev/null | while read file; do
        if [[ ! "${file}" =~ "initrd.img-$(uname -r)$" ]]; then
            rm -f "${file}"
            log_debug "Removed: ${file}"
        fi
    done
}
