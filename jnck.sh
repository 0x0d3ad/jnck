#!/bin/bash

# Set warna untuk output pesan
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Function untuk memeriksa ketersediaan tool
check_tool() {
    tool_name=$1
    command -v $tool_name >/dev/null 2>&1 || { echo >&2 -e "${RED}Error: $tool_name tidak ditemukan.${NC}"; exit 1; }
}

# Pengecekan ketersediaan tool
check_tool "subscraper"
check_tool "subfinder"
check_tool "httpx"
check_tool "aquatone"
check_tool "nuclei"
check_tool "katana"

# Menerima input domain yang akan discan dari pengguna
read -p "Masukkan domain yang akan di-scan: " domain

# Menerima input lokasi direktori tempat hasil pemindaian akan disimpan
read -p "Masukkan lokasi direktori untuk menyimpan hasil pemindaian: " output_dir

# Membuat direktori baru untuk menyimpan hasil pemindaian
mkdir -p "$output_dir/$domain"
mkdir -p "$output_dir/$domain/Nuclei_Output/"
mkdir -p "$output_dir/$domain/Subdomain_Output/"
mkdir -p "$output_dir/$domain/Katana_Output/"
cd "$output_dir/$domain"
echo ""

# Menampilkan pesan bahwa proses scanning dimulai
echo -e "${GREEN}Running...${NC}"
echo ""

# Menjalankan subdomain enumeration menggunakan subscraper & subfinder
echo -ne "${GREEN}Running subdomain enumeration...${NC}"
subscraper --all $domain -r $output_dir/$domain/Subdomain_Output/output_$domain.txt &> /dev/null
subfinder -d $domain -all >> $output_dir/$domain/Subdomain_Output/output_$domain.txt &> /dev/null
# Sorting & remove duplicate
sort $output_dir/$domain/Subdomain_Output/output_$domain.txt | uniq > $output_dir/$domain/Subdomain_Output/subdomain_output_$domain.txt
rm $output_dir/$domain/Subdomain_Output/output_$domain.txt
echo -e "${GREEN}Done.${NC}"
echo ""

# Menjalankan penyaringan subdomain aktif menggunakan httpx
echo -ne "${GREEN}Filtering active subdomains...${NC}"
httpx -l $output_dir/$domain/Subdomain_Output/subdomain_output_$domain.txt -o $output_dir/$domain/Subdomain_Output/subdomain_active_$domain.txt -silent -mc 200,301 &> /dev/null
echo -e "${GREEN}Done.${NC}"
echo ""

# Menjalankan proses screenshot menggunakan aquatone
echo -ne "${GREEN}Taking screenshots...${NC}"
cat $output_dir/$domain/Subdomain_Output/subdomain_active_$domain.txt | aquatone -ports xlarge -out Aquatone_$domain &> /dev/null
echo -e "${GREEN}Done.${NC}"
echo ""

# Menjalankan vulnerability scanning menggunakan nuclei
echo -ne "${GREEN}Scanning for vulnerabilities...${NC}"
nuclei -l $output_dir/$domain/Subdomain_Output/subdomain_active_$domain.txt  -o $output_dir/$domain/Nuclei_Output/Output.txt &> /dev/null
echo -e "${GREEN}Done.${NC}"
echo ""

# Menjalankan Katana
echo -ne "${GREEN}Running Katana scanning...${NC}"
katana -u $output_dir/$domain/Subdomain_Output/subdomain_active_$domain.txt -o $output_dir/$domain/Katana_Output/Output.txt &> /dev/null
echo -e "${GREEN}Done.${NC}"
echo ""

# Menampilkan jumlah subdomain yang berhasil ditemukan
total_subdomains=$(cat $output_dir/$domain/Subdomain_Output/subdomain_output_$domain.txt | wc -l)
active_subdomains=$(cat $output_dir/$domain/Subdomain_Output/subdomain_active_$domain.txt | wc -l)
echo -e "${GREEN}Scan selesai!${NC}"
echo -e "${GREEN}Total subdomain ditemukan: $total_subdomains.${NC}"
echo -e "${GREEN}Subdomain aktif yang ditemukan: $active_subdomains.${NC}"
echo ""

# Menampilkan direktori hasil pemindaian
echo -e "${GREEN}Directory of scan results:${NC}"
echo "$output_dir/$domain"
echo ""
echo -e "${GREEN}Scanning $domain selesai!${NC}"
echo ""
