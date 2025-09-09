#!/bin/bash

# ==============================================================================
# Bug Hunting Automation Script
# ==============================================================================

# Set colors for output messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Global variables
domain=""
output_dir=""
base_dir=""

# Function to display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help     Display this help message"
    echo "  -d, --domain   Domain to scan (optional, will prompt if not provided)"
    echo "  -o, --output   Output directory (optional, will prompt if not provided)"
    echo ""
    echo "If no options are provided, the script will prompt for domain and output directory."
}

# Function to check tool availability
check_tool() {
    local tool_name="$1"
    if ! command -v "$tool_name" >/dev/null 2>&1; then
        echo >&2 -e "${RED}Error: $tool_name tidak ditemukan.${NC}"
        exit 1
    fi
}

# Function to validate domain format
validate_domain() {
    local domain_input="$1"
    if [[ -z "$domain_input" ]]; then
        echo >&2 -e "${RED}Error: Domain tidak boleh kosong.${NC}"
        return 1
    fi
    
    # Simple domain validation (allows alphanumeric, dots, hyphens)
    if [[ ! "$domain_input" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]]; then
        echo >&2 -e "${RED}Error: Format domain tidak valid.${NC}"
        return 1
    fi
    
    return 0
}

# Function to validate and create output directory
validate_output_dir() {
    local dir="$1"
    if [[ -z "$dir" ]]; then
        echo >&2 -e "${RED}Error: Direktori output tidak boleh kosong.${NC}"
        return 1
    fi
    
    # Create directory with proper error handling
    if ! mkdir -p "$dir"; then
        echo >&2 -e "${RED}Error: Gagal membuat direktori $dir${NC}"
        return 1
    fi
    
    # Get absolute path
    output_dir="$(cd "$dir" && pwd)"
    if [[ $? -ne 0 ]]; then
        echo >&2 -e "${RED}Error: Gagal mengakses direktori $dir${NC}"
        return 1
    fi
    
    return 0
}

# Function to create required directories
create_directories() {
    local dirs=(
        "$base_dir"
        "$base_dir/Nuclei_Output"
        "$base_dir/Subdomain_Output"
        "$base_dir/Katana_Output"
    )
    
    for dir in "${dirs[@]}"; do
        if ! mkdir -p "$dir"; then
            echo >&2 -e "${RED}Error: Gagal membuat direktori $dir${NC}"
            return 1
        fi
    done
    
    return 0
}

# Function to run subdomain enumeration
run_subdomain_enum() {
    echo -ne "${YELLOW}Running subdomain enumeration...${NC}"
    
    local subdomain_output="$base_dir/Subdomain_Output/output_$domain.txt"
    local final_output="$base_dir/Subdomain_Output/subdomain_output_$domain.txt"
    
    # Run subdomain enumeration tools
    if ! subscraper --all "$domain" -r "$subdomain_output" &>/dev/null; then
        echo -e "${YELLOW} (subscraper encountered issues)${NC}"
    fi
    
    if ! subfinder -d "$domain" -all >> "$subdomain_output" 2>/dev/null; then
        echo -e "${YELLOW} (subfinder encountered issues)${NC}"
    fi
    
    # Sort and remove duplicates
    if [[ -f "$subdomain_output" ]]; then
        sort "$subdomain_output" | uniq > "$final_output"
        rm -f "$subdomain_output"
        echo -e "${GREEN} Done.${NC}"
    else
        echo -e "${RED} Failed - no output generated.${NC}"
        return 1
    fi
    
    return 0
}

# Function to filter active subdomains
filter_active_subdomains() {
    echo -ne "${YELLOW}Filtering active subdomains...${NC}"
    
    local input_file="$base_dir/Subdomain_Output/subdomain_output_$domain.txt"
    local output_file="$base_dir/Subdomain_Output/subdomain_active_$domain.txt"
    
    # Check if input file exists and is not empty
    if [[ ! -s "$input_file" ]]; then
        echo -e "${RED} Skipped - no subdomains found.${NC}"
        return 1
    fi
    
    # Run httpx to filter active subdomains
    if httpx -l "$input_file" -o "$output_file" -silent -mc 200,301,302,307,403 &>/dev/null; then
        echo -e "${GREEN} Done.${NC}"
    else
        echo -e "${RED} Failed.${NC}"
        return 1
    fi
    
    return 0
}

# Function to run vulnerability scanning
run_vulnerability_scan() {
    echo -ne "${YELLOW}Scanning for vulnerabilities...${NC}"
    
    local input_file="$base_dir/Subdomain_Output/subdomain_output_$domain.txt"
    local output_file="$base_dir/Nuclei_Output/Output.txt"
    
    # Check if input file exists and is not empty
    if [[ ! -s "$input_file" ]]; then
        echo -e "${RED} Skipped - no subdomains found.${NC}"
        return 1
    fi
    
    # Run nuclei scan
    if nuclei -l "$input_file" -ept ssl -es info -o "$output_file" &>/dev/null; then
        echo -e "${GREEN} Done.${NC}"
    else
        echo -e "${YELLOW} Completed with issues.${NC}"
    fi
    
    return 0
}

# Function to run katana scanning
run_katana_scan() {
    echo -ne "${YELLOW}Running Katana scanning...${NC}"
    
    local input_file="$base_dir/Subdomain_Output/subdomain_active_$domain.txt"
    local output_file="$base_dir/Katana_Output/Output.txt"
    
    # Check if input file exists and is not empty
    if [[ ! -s "$input_file" ]]; then
        echo -e "${RED} Skipped - no active subdomains found.${NC}"
        return 1
    fi
    
    # Run katana
    if katana -u "$input_file" -o "$output_file" &>/dev/null; then
        echo -e "${GREEN} Done.${NC}"
    else
        echo -e "${YELLOW} Completed with issues.${NC}"
    fi
    
    return 0
}

# Function to display scan results
display_results() {
    local total_subdomains=0
    local active_subdomains=0
    
    local subdomain_file="$base_dir/Subdomain_Output/subdomain_output_$domain.txt"
    local active_file="$base_dir/Subdomain_Output/subdomain_active_$domain.txt"
    
    # Count subdomains
    if [[ -f "$subdomain_file" ]]; then
        total_subdomains=$(wc -l < "$subdomain_file")
    fi
    
    if [[ -f "$active_file" ]]; then
        active_subdomains=$(wc -l < "$active_file")
    fi
    
    echo -e "${GREEN}Scan selesai!${NC}"
    echo -e "${GREEN}Total subdomain ditemukan: $total_subdomains.${NC}"
    echo -e "${GREEN}Subdomain aktif yang ditemukan: $active_subdomains.${NC}"
    echo ""
    echo -e "${GREEN}Directory of scan results:${NC}"
    echo "$base_dir"
    echo ""
    echo -e "${GREEN}Scanning $domain selesai!${NC}"
    echo ""
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -d|--domain)
                domain="$2"
                shift 2
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            *)
                echo >&2 -e "${RED}Error: Unknown option $1${NC}"
                usage
                exit 1
                ;;
        esac
    done
}

# Function to get user input if not provided via arguments
get_user_input() {
    # Get domain if not provided
    while [[ -z "$domain" ]]; do
        read -p "Masukkan domain yang akan di-scan: " domain
        if ! validate_domain "$domain"; then
            domain=""
        fi
    done
    
    # Get output directory if not provided
    while [[ -z "$output_dir" ]]; do
        read -p "Masukkan lokasi direktori untuk menyimpan hasil pemindaian: " output_dir
        if ! validate_output_dir "$output_dir"; then
            output_dir=""
        fi
    done
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Display banner
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}     Bug Hunting Automation Script      ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # Check tool availability
    echo -e "${YELLOW}Checking required tools...${NC}"
    check_tool "subscraper"
    check_tool "subfinder"
    check_tool "httpx"
    check_tool "nuclei"
    check_tool "katana"
    echo -e "${GREEN}All tools are available.${NC}"
    echo ""
    
    # Get user input
    get_user_input
    
    # Set base directory
    base_dir="$output_dir/$domain"
    
    # Create required directories
    echo -e "${YELLOW}Creating directories...${NC}"
    if ! create_directories; then
        echo >&2 -e "${RED}Error: Failed to create required directories${NC}"
        exit 1
    fi
    echo -e "${GREEN}Directories created successfully.${NC}"
    echo ""
    
    # Change to base directory
    cd "$base_dir" || exit 1
    
    # Display start message
    echo -e "${GREEN}Starting scan for domain: $domain${NC}"
    echo ""
    
    # Run scanning processes
    run_subdomain_enum
    filter_active_subdomains
    run_vulnerability_scan
    run_katana_scan
    
    # Display results
    display_results
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
