#!/bin/bash

# Set warna untuk output pesan
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Menerima input domain yang akan discan dari pengguna
read -p "Masukkan domain yang akan di-scan: " domain

# Menerima input lokasi direktori tempat hasil pemindaian akan disimpan
read -p "Masukkan lokasi direktori untuk menyimpan hasil pemindaian: " output_dir

# Membuat direktori baru untuk menyimpan hasil pemindaian
mkdir -p "$output_dir/$domain"
cd "$output_dir/$domain"
echo ""

# Menampilkan pesan bahwa proses scanning dimulai
echo -e "${GREEN}Running...${NC}"
echo ""

# Menjalankan subdomain enumeration menggunakan subscraper
echo -ne "${GREEN}Running subdomain enumeration...${NC}"
subscraper --http -M search,certsh,archiveorg -T 80 $domain -r output_$domain.txt > /dev/null
echo -e "${GREEN} Done.${NC}"
echo ""

# Menjalankan penyaringan subdomain aktif menggunakan httpx
echo -ne "${GREEN}Filtering active subdomains...${NC}"
httpx -l output_$domain.txt -o active_$domain.txt -silent -mc 200 > /dev/null
echo -e "${GREEN} Done.${NC}"
echo ""

# Menjalankan vulnerability scanning menggunakan nuclei
echo -ne "${GREEN}Scanning for vulnerabilities...${NC}"
nuclei -l active_$domain.txt -es info -o nuclei_$domain.txt &>/dev/null
echo -e "${GREEN} Done.${NC}"
echo ""

# Menjalankan proses screenshot menggunakan aquatone
echo -ne "${GREEN}Taking screenshots...${NC}"
cat active_$domain.txt | aquatone -ports xlarge -out aqua_$domain > /dev/null
echo -e "${GREEN} Done.${NC}"
echo ""

# Menampilkan output dari nuclei
echo -e "${GREEN}Hasil scanning menggunakan Nuclei:${NC}"
cat nuclei_$domain.txt
echo ""
echo -e "${GREEN}Scanning $domain selesai!${NC}"
