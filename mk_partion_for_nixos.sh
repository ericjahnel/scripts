#!/bin/bash

# Überprüfen, ob die Ziel-Festplatte übergeben wurde
if [ -z "$1" ]; then
  echo "Fehler: Bitte die Ziel-Festplatte als Argument angeben, z.B.:"
  echo "  $0 /dev/sda swap=auto"
  exit 1
fi

# Argumente
DISK="$1"                # Ziel-Festplatte (z. B. /dev/sda)
SWAP_OPTION="$2"         # Swap-Option (auto, none, custom)

# Standardwerte
SWAP_SIZE=0              # Standard: Kein Swap

# Verarbeiten der Swap-Option
case "$SWAP_OPTION" in
  swap=auto)
    # Automatische Ermittlung der RAM-Größe in MiB
    RAM_SIZE=$(free --mebi | awk '/^Mem:/ {print $2}')
    SWAP_SIZE=$((RAM_SIZE + 1024)) # RAM-Größe + 1 GiB als Sicherheitspuffer
    echo "RAM erkannt: $RAM_SIZE MiB. Swap wird automatisch mit $SWAP_SIZE MiB erstellt (inkl. Puffer für Hibernation)."
    ;;
  swap=none)
    # Kein Swap erstellen
    SWAP_SIZE=0
    echo "Kein Swap wird erstellt."
    ;;
  swap=custom=*)
    # Benutzerdefinierte Swap-Größe aus der Eingabe extrahieren
    SWAP_SIZE=$(echo "$SWAP_OPTION" | cut -d= -f3)
    # Überprüfen, ob die Eingabe eine gültige Zahl ist
    if [[ ! "$SWAP_SIZE" =~ ^[0-9]+$ ]]; then
      echo "Fehler: Ungültige benutzerdefinierte Swap-Größe. Beispiel: swap=custom=8192"
      exit 1
    fi
    echo "Benutzerdefinierte Swap-Größe: $SWAP_SIZE MiB."
    ;;
  *)
    # Ungültige Option
    echo "Fehler: Ungültige Swap-Option. Erlaubte Werte:"
    echo "  swap=auto    - Automatische Swap-Größe (basierend auf RAM + 1 GiB)"
    echo "  swap=none    - Kein Swap"
    echo "  swap=custom=X - Benutzerdefinierte Swap-Größe in MiB"
    echo "Beispiele:"
    echo "  Erkennt den RAM automatisch und fügt 1 GiB hinzu."
    echo "  sudo bash partition-with-swap.sh /dev/sda swap=auto"
    echo "  "
    echo "  Kein Swap wird erstellt."
    echo "  sudo bash partition-with-swap.sh /dev/sda swap=none"
    echo " "
    echo "  Erstellt eine Swap-Partition mit 8192 MiB (8 GiB)."
    echo "  sudo bash partition-with-swap.sh /dev/sda swap=custom=8192"
    exit 1
    ;;
esac

# Warnung und Bestätigung, bevor die Festplatte überschrieben wird
echo "WARNUNG: Alle Daten auf $DISK werden gelöscht!"
read -p "Fortfahren? (ja/nein): " CONFIRM
if [ "$CONFIRM" != "ja" ]; then
  echo "Abbruch."
  exit 0
fi

# Starten der Partitionierung
echo "Partitioniere $DISK..."
parted --script "$DISK" mklabel gpt

# Erstellen der ESP-Partition (512 MiB für den Bootloader)
parted --script "$DISK" mkpart ESP fat32 1MiB 512MiB
parted --script "$DISK" set 1 boot on

# Swap-Partition erstellen, falls benötigt
if [ "$SWAP_SIZE" -gt 0 ]; then
  # Swap-Partition nach der ESP-Partition
  parted --script "$DISK" mkpart primary linux-swap 512MiB "$((512 + SWAP_SIZE))MiB"
  SWAP_PART="${DISK}2" # Swap-Partition wird als 2. Partition erstellt
  ROOT_PART="${DISK}3" # Root-Partition wird als 3. Partition erstellt
  parted --script "$DISK" mkpart primary ext4 "$((512 + SWAP_SIZE))MiB" 100%
else
  # Falls kein Swap: Root-Partition direkt nach der ESP
  ROOT_PART="${DISK}2"
  parted --script "$DISK" mkpart primary ext4 512MiB 100%
fi

# Partitionen formatieren
echo "Formatiere Partitionen..."
mkfs.fat -F 32 "${DISK}1"   # Formatieren der ESP-Partition
if [ "$SWAP_SIZE" -gt 0 ]; then
  mkswap "$SWAP_PART"        # Formatieren der Swap-Partition
  swapon "$SWAP_PART"        # Swap aktivieren
fi
mkfs.ext4 "$ROOT_PART"       # Formatieren der Root-Partition

# Partitionen mounten
echo "Mounten der Partitionen..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "${DISK}1" /mnt/boot

# Fertigmeldung
echo "Partitionierung abgeschlossen."
if [ "$SWAP_SIZE" -gt 0 ]; then
  echo "Swap ist aktiviert (${SWAP_SIZE} MiB)."
else
  echo "Kein Swap wurde erstellt."
fi

