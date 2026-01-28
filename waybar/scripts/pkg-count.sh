#!/bin/bash
pacman_count=$(pacman -Qe 2>/dev/null | wc -l)
yay_count=$(command -v yay &>/dev/null && yay -Qm 2>/dev/null | wc -l || echo 0)
total=$((pacman_count + yay_count))
echo " $total (P$pacman_count A$yay_count)"
