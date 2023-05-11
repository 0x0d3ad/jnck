# Bug Hunting Automation Script

Ini adalah skrip bash sederhana yang akan membantu Anda melakukan bug hunting pada suatu domain. Skrip ini akan melakukan beberapa tugas seperti subdomain enumeration, memeriksa subdomain yang aktif, dan melakukan scanning vulnerabilitas menggunakan Nuclei.

## Persyaratan

Untuk menggunakan skrip ini, Anda memerlukan beberapa tools yang harus diinstall terlebih dahulu:

- [Subscraper](https://github.com/m8sec/subscraper)
- [Httpx](https://github.com/projectdiscovery/httpx)
- [Aquatone](https://github.com/michenriksen/aquatone)
- [Nuclei](https://github.com/projectdiscovery/nuclei)

Pastikan tools-tools tersebut sudah terinstall di sistem Anda sebelum menjalankan skrip ini.

## Cara Menggunakan

1. Clone repositori ini dengan perintah `git clone https://github.com/0x0d3ad/jnck.git`
2. Masuk ke direktori `jnck` dengan perintah `cd jnck`
3. Jalankan skrip dengan perintah `chmod +x jnck.sh` & `./jnck.sh`
4. Masukkan domain yang ingin di-scan
5. Masukkan lokasi direktori untuk menyimpan hasil scan
6. Skrip akan melakukan subdomain enumeration, memeriksa subdomain yang aktif, dan melakukan scanning vulnerabilitas menggunakan Nuclei
7. Setelah selesai, hasil scanning akan disimpan di direktori yang Anda tentukan pada langkah ke-5

## Catatan

- Pastikan untuk menambahkan aksesibilitas pada semua tools yang digunakan agar dapat diakses dari direktori mana pun di sistem Anda.
- Skrip ini tidak dapat menjamin 100% keamanan pada domain yang Anda scan. Skrip ini hanya berfungsi sebagai alat bantu untuk mempermudah proses bug hunting. Tetaplah berhati-hati dan bertanggung jawab dalam menggunakan skrip ini.
