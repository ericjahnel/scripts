# scripts

mk_partion_for_nixos.sh

Script Description

Purpose:
This script automates the creation of partitions for a NixOS installation using the minimal boot image, ensuring compatibility with UEFI systems. It includes flexible options for creating a swap partition, with support for automatic sizing based on system RAM, no swap, or a custom-defined size.

Key Features:

    Partition Scheme:
        Creates an EFI System Partition (ESP) for booting.
        Allocates a root partition formatted as ext4.
        Optionally creates a swap partition suitable for Hibernation (Suspend-to-Disk).

    Swap Options:
        auto: Swap size is automatically set to system RAM + 1 GiB for Hibernation.
        none: No swap partition is created.
        custom=X: A custom swap size (in MiB) can be specified.

    Flexibility:
        The target disk is provided as a parameter, allowing usage on various systems.
        Ensures safety with a confirmation prompt before modifying the disk.

    Compatibility:
        Designed for UEFI-based systems with a GPT partition table.
        Works seamlessly with NixOS minimal images for reproducible installations.

Usage:

sudo bash partition-script.sh <disk> <swap-option>

Examples:

    Automatically determine swap size (RAM + 1 GiB):

sudo bash partition-script.sh /dev/sda swap=auto

No swap partition:

sudo bash partition-script.sh /dev/sda swap=none

Custom swap size of 8 GiB:

    sudo bash partition-script.sh /dev/sda swap=custom=8192

Why This Script?

This script simplifies the partitioning process for NixOS installations by:

    Automating partition creation to save time and avoid manual errors.
    Providing flexible swap configuration options to suit various system requirements.
    Ensuring a reproducible setup for systems using the NixOS minimal image.
