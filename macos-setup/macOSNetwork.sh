#!/usr/bin/env zsh
# =============================================================================
# macOSNetwork.sh — Detect active macOS network interfaces & configure DNS
# =============================================================================

setopt NO_UNSET

# ── Color helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { printf "${CYAN}ℹ ${NC} %s\n" "$*"; }
success() { printf "${GREEN}✔ ${NC} %s\n" "$*"; }
warn()    { printf "${YELLOW}⚠ ${NC} %s\n" "$*"; }
error()   { printf "${RED}✖ ${NC} %s\n" "$*"; }

# ── DNS server definitions ───────────────────────────────────────────────────
CLOUDFLARE_DNS="1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001"
GOOGLE_DNS="8.8.8.8 8.8.4.4 2001:4860:4860::8888 2001:4860:4860::8844"
COMBINED_DNS="1.1.1.1 8.8.8.8 1.0.0.1 8.8.4.4 2606:4700:4700::1111 2001:4860:4860::8888 2606:4700:4700::1001 2001:4860:4860::8844"
QUAD9_DNS="9.9.9.9 149.112.112.112 2620:fe::fe 2620:fe::9"

# ── Root check ───────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)."
    print "  Usage: sudo zsh $0"
    exit 1
fi

# ── Utility functions ────────────────────────────────────────────────────────

# Strip commas, collapse whitespace — so "1, 3" and "1,3" both become "1 3"
normalize_input() {
    local result="${1//,/ }"
    # Collapse runs of spaces into a single space
    while [[ "$result" == *"  "* ]]; do
        result="${result//  / }"
    done
    result="${result## }"   # trim leading space
    result="${result%% }"   # trim trailing space
    print -r -- "$result"
}

# Validate that input is a number in range [1, max]
validate_number() {
    local input="$1" max="$2"
    [[ "$input" =~ ^[0-9]+$ ]] || return 1
    [[ "$input" -ge 1 && "$input" -le "$max" ]] || return 1
    return 0
}

# ── Shared state ─────────────────────────────────────────────────────────────
# These variables are set by menu functions and consumed in main():
#   selected_interfaces — populated by menu_select_interfaces()
#   chosen_dns          — populated by menu_select_dns() / menu_custom_dns()

# ── Core functions ───────────────────────────────────────────────────────────

detect_active_interfaces() {
    local -a active_interfaces=()
    local service="" ip=""

    # Use listallnetworkservices to catch renamed/numbered service variants
    # (e.g. "USB 10/100/1000 LAN 4") that listallhardwareports omits.
    while IFS= read -r service; do
        # Skip the header line and disabled (*) services
        [[ "$service" == *"asterisk"* || "$service" == \** ]] && continue
        ip=$(networksetup -getinfo "$service" 2>/dev/null \
            | awk -F': ' '/^IP address/ {print $2}')
        if [[ -n "$ip" && "$ip" != "none" ]]; then
            active_interfaces+=("$service")
        fi
    done < <(networksetup -listallnetworkservices 2>/dev/null | tail -n +2)

    printf '%s\n' "${active_interfaces[@]}"
}

show_current_dns() {
    local iface="$1"
    local dns
    dns=$(networksetup -getdnsservers "$iface" 2>/dev/null)

    if [[ "$dns" == *"any DNS"* ]]; then
        warn "Interface '${iface}': No custom DNS configured (using DHCP defaults)"
    else
        info "Interface '${iface}' current DNS:"
        local line
        for line in ${(f)dns}; do
            print "      $line"
        done
    fi
}

apply_dns() {
    local dns_servers="$1"
    shift
    local interfaces=("$@")

    local iface
    for iface in "${interfaces[@]}"; do
        info "Setting DNS on '${iface}'..."
        # shellcheck disable=SC2086
        if networksetup -setdnsservers "$iface" ${=dns_servers}; then
            success "'${iface}' DNS updated."
        else
            error "Failed to set DNS on '${iface}'."
        fi
    done

    info "Flushing DNS cache..."
    if command -v dscacheutil &>/dev/null; then
        dscacheutil -flushcache
    fi
    killall -HUP mDNSResponder 2>/dev/null || true
    success "DNS cache flushed."
}

# ── Display functions ────────────────────────────────────────────────────────

show_banner() {
    print
    printf "${BOLD}╔══════════════════════════════════════════════╗${NC}\n"
    printf "${BOLD}║       macOS DNS Configuration Utility        ║${NC}\n"
    printf "${BOLD}╚══════════════════════════════════════════════╝${NC}\n"
    print
}

display_interface_list() {
    local -a ifaces=("$@")
    print "  Active interfaces detected:"
    print
    local i
    for (( i = 1; i <= ${#ifaces[@]}; i++ )); do
        printf "    ${GREEN}[%d]${NC}  %s\n" "$i" "${ifaces[$i]}"
    done
    printf "    ${GREEN}[A]${NC}  All of the above\n"
    print

    local iface
    for iface in "${ifaces[@]}"; do
        show_current_dns "$iface"
    done
    print
}

verify_dns() {
    local -a ifaces=("$@")
    print
    info "Verifying new DNS settings..."
    print
    local iface
    for iface in "${ifaces[@]}"; do
        show_current_dns "$iface"
    done
}

# ── Menu functions ───────────────────────────────────────────────────────────

menu_select_interfaces() {
    local -a ifaces=("$@")
    local cleaned

    while true; do
        printf "${BOLD}Select interface(s)${NC} (e.g. 1, 1 3, or A for all, Q to quit): "
        read -r iface_choice

        [[ "${(L)iface_choice}" == "q" ]] && return 1

        if [[ "${(L)iface_choice}" == "a" ]]; then
            selected_interfaces=("${ifaces[@]}")
            return 0
        fi

        cleaned=$(normalize_input "$iface_choice")
        selected_interfaces=()

        for token in ${=cleaned}; do
            if validate_number "$token" "${#ifaces[@]}"; then
                selected_interfaces+=("${ifaces[$token]}")
            else
                warn "Invalid selection: '$token' — skipping."
            fi
        done

        if [[ ${#selected_interfaces[@]} -gt 0 ]]; then
            return 0
        fi

        error "No valid interfaces selected. Please try again."
        print
    done
}

menu_select_dns() {
    while true; do
        print
        printf "${BOLD}Choose DNS configuration:${NC}\n"
        print
        printf "    ${CYAN}[1]${NC}  Cloudflare DNS    (1.1.1.1 / 1.0.0.1)\n"
        printf "    ${CYAN}[2]${NC}  Google DNS         (8.8.8.8 / 8.8.4.4)\n"
        printf "    ${CYAN}[3]${NC}  Both combined      (Cloudflare + Google)\n"
        printf "    ${CYAN}[4]${NC}  Quad9 DNS          (9.9.9.9 / 149.112.112.112)\n"
        printf "    ${CYAN}[5]${NC}  Custom DNS         (enter your own servers)\n"
        printf "    ${CYAN}[6]${NC}  Reset to DHCP      (remove custom DNS)\n"
        printf "    ${CYAN}[B]${NC}  Back to interface selection\n"
        print
        printf "${BOLD}Enter choice:${NC} "
        read -r dns_choice

        case "${(L)dns_choice}" in
            1) chosen_dns="$CLOUDFLARE_DNS"; return 0 ;;
            2) chosen_dns="$GOOGLE_DNS"; return 0 ;;
            3) chosen_dns="$COMBINED_DNS"; return 0 ;;
            4) chosen_dns="$QUAD9_DNS"; return 0 ;;
            5)
                if menu_custom_dns; then
                    return 0
                fi
                ;;
            6) chosen_dns="DHCP"; return 0 ;;
            b) return 1 ;;
            *) error "Invalid choice. Please try again." ;;
        esac
    done
}

menu_custom_dns() {
    print
    printf "${BOLD}Enter DNS server addresses separated by spaces:${NC}\n"
    printf "  (e.g. 208.67.222.222 208.67.220.220)\n"
    printf "${BOLD}> ${NC}"
    read -r custom_input

    local -a servers=()
    local addr
    for addr in ${=custom_input}; do
        if [[ "$addr" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
           [[ "$addr" =~ ^[0-9a-fA-F]*:[0-9a-fA-F:]+$ ]]; then
            servers+=("$addr")
        else
            warn "Skipping invalid address: $addr"
        fi
    done

    if [[ ${#servers[@]} -eq 0 ]]; then
        error "No valid DNS addresses entered."
        return 1
    fi

    chosen_dns="${servers[*]}"
    info "Custom DNS: $chosen_dns"
    return 0
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    show_banner
    info "Scanning for active network interfaces..."
    print

    local -a interfaces=()
    while IFS= read -r line; do
        interfaces+=("$line")
    done < <(detect_active_interfaces)

    if [[ ${#interfaces[@]} -eq 0 ]]; then
        error "No active network interfaces found."
        exit 1
    fi

    local state="interfaces"
    local -a selected_interfaces=()
    local chosen_dns=""
    local iface again

    while true; do
        case "$state" in
            interfaces)
                display_interface_list "${interfaces[@]}"
                if menu_select_interfaces "${interfaces[@]}"; then
                    print
                    info "Selected: ${selected_interfaces[*]}"
                    state="dns"
                else
                    print
                    info "Exiting."
                    exit 0
                fi
                ;;
            dns)
                if menu_select_dns; then
                    state="apply"
                else
                    state="interfaces"
                fi
                ;;
            apply)
                print
                if [[ "$chosen_dns" == "DHCP" ]]; then
                    info "Resetting DNS to DHCP defaults..."
                    for iface in "${selected_interfaces[@]}"; do
                        networksetup -setdnsservers "$iface" "Empty"
                        success "'${iface}' DNS reset to DHCP."
                    done
                else
                    apply_dns "$chosen_dns" "${selected_interfaces[@]}"
                fi

                verify_dns "${selected_interfaces[@]}"

                print
                printf "${BOLD}Configure another interface? [y/N]:${NC} "
                read -r again
                if [[ "${(L)again}" == "y" ]]; then
                    state="interfaces"
                else
                    print
                    success "Done! DNS configuration complete."
                    print
                    exit 0
                fi
                ;;
        esac
    done
}

main "$@"
