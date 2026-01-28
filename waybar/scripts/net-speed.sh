#!/usr/bin/env bash
# 网速组件 - 终极修复版（解决格式/编码/换行问题）
set -euo pipefail

# 1. 自动检测有效网卡
iface=""
# 优先默认网关网卡
default_iface=$(ip route | awk '$1=="default"{print $5; exit}')
# 备选网卡列表（按你的环境调整）
candidate_ifaces=("$default_iface" "eth0" "enp0s3" "wlan0" "wlp2s0" "wlo1")

for if in "${candidate_ifaces[@]}"; do
    if [ -n "$if" ] && [ -d "/sys/class/net/$if/statistics" ]; then
        iface="$if"
        break
    fi
done

# 无有效网卡时的兜底输出
if [ -z "$iface" ]; then
    printf '{"text":"↓ 0.0 B/s ↑ 0.0 B/s", "tooltip":"无有效网卡"}\n'
    exit 0
fi

# 2. 获取初始收发字节（强制转为数字，避免空值）
rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo 0)
tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo 0)
rx=$((rx + 0))
tx=$((tx + 0))

sleep 1

# 3. 获取延迟后字节数
rx2=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo 0)
tx2=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo 0)
rx2=$((rx2 + 0))
tx2=$((tx2 + 0))

# 4. 计算速率（确保非负）
dx=$(( rx2 > rx ? rx2 - rx : 0 ))
dt=$(( tx2 > tx ? tx2 - tx : 0 ))

# 5. 修复版单位换算（严格控制格式，避免特殊字符）
human() {
    local bytes=$1
    # 使用printf严格格式化，避免bc的浮点异常
    if (( bytes < 1024 )); then
        printf "%.1f B/s" 0.0
    elif (( bytes < 1048576 )); then
        printf "%.1f KB/s" "$(bc <<< "scale=1; $bytes/1024")"
    elif (( bytes < 1073741824 )); then
        printf "%.1f MB/s" "$(bc <<< "scale=1; $bytes/1048576")"
    else
        printf "%.2f GB/s" "$(bc <<< "scale=2; $bytes/1073741824")"
    fi
}

# 6. 计算上下行并转义特殊字符
down=$(human "$dx" | sed 's/[[:space:]]//g')  # 移除所有空格
up=$(human "$dt" | sed 's/[[:space:]]//g')

# 7. 输出标准JSON（严格转义换行符，避免Waybar解析错误）
printf '{"text":"↓ %s ↑ %s", "tooltip":"下载：%s\\n上传：%s\\n网卡：%s"}\n' \
    "$down" "$up" "$down" "$up" "$iface"
