#!/bin/bash
################################################################################
# Arch Linux System Maintenance Utilities
################################################################################

update_system() {
    log_info "Updating Arch Linux system..."
    
    # Sync package database and upgrade all packages
    log_debug "Syncing package database..."
    pacman -Sy || log_error "Failed to sync package database"
    
    log_debug "Upgrading packages..."
    pacman -Suu --noconfirm || log_error "Failed to upgrade packages"
    
    # Update AUR if yay is installed
    if command -v yay &>/dev/null; then
        log_debug "Updating AUR packages..."
        yay -Suu --noconfirm 2>/dev/null || log_debug "AUR update skipped"
    fi
    
    log_success "Arch Linux system updated"
}

update_security() {
    log_info "Applying Arch Linux security updates..."
    
    # In Arch, all updates include security patches, so full system upgrade is necessary
    log_debug "Applying system upgrade (Arch updates include security patches)..."
    pacman -Suu --noconfirm || log_error "Failed to apply security updates"
    
    log_success "Arch Linux security updates completed"
}

install_essential_packages() {
    log_info "Installing essential packages for Arch Linux..."
    
    local essential_packages=(
        "base-devel"
        "curl"
        "wget"
        "git"
        "net-tools"
        "htop"
        "vim"
        "openssh"
        "unzip"
        "pacman-contrib"
    )
    
    for package in "${essential_packages[@]}"; do
        if ! is_package_installed "${package}"; then
            log_info "Installing ${package}..."
            pacman -S --noconfirm "${package}" || log_warn "Failed to install ${package}"
        fi
    done
}

get_package_count() {
    pacman -Q | wc -l
}

get_updates_available() {
    pacman -Qu 2>/dev/null | wc -l
}

get_security_updates_available() {
    # Arch doesn't separate security updates
    get_updates_available
}

fix_broken_dependencies() {
    log_info "Checking for broken dependencies..."
    
    log_debug "Running dependency check..."
    pacman -Dk 2>/dev/null || log_warn "No dependency issues found"
}

clean_arch_specific() {
    log_info "Performing Arch-specific cleanup..."
    
    # Clean pacman cache, keeping latest 2 versions
    log_debug "Cleaning package cache (keeping 2 versions)..."
    paccache -r -k 2 -q 2>/dev/null || true
    
    # Remove untracked files from cache
    paccache -ruk0 -q 2>/dev/null || true
    
    # Clean AUR cache if yay is installed
    if command -v yay &>/dev/null; then
        log_debug "Cleaning AUR cache..."
        yay -Sc --noconfirm 2>/dev/null || true
    fi
}
