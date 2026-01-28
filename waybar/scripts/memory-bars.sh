#!/bin/bash
# Waybar内存显示（Arch多节点纯跳动版）：16个跳动节点/无空条/永久跳动，视觉饱满动感
REFRESH_INTERVAL=0.10  # 稍快刷新率，适配多节点跳动流畅度
SINGLE_BARS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
WAVE_CHARS=("▁" "▂" "▃" "▄" "▅" "▆" "▇")
MAX_NODES=16           # 核心修改：最大跳动节点数提升至16个，视觉更饱满

# 内存使用率计算（Arch专属，精准无0%，与系统free命令一致）
get_perc() {
    MEM_DATA=$(free | sed -n '2p' 2>/dev/null)
    [ -z "$MEM_DATA" ] && { echo 0; return; }
    TOTAL=$(echo "$MEM_DATA" | awk '{print $2+0}')
    USED=$(echo "$MEM_DATA" | awk '{print $3+0}')
    [ "$TOTAL" -le 0 ] && TOTAL=1
    PERC=$((USED * 100 / TOTAL))
    [ "$PERC" -lt 0 ] && PERC=0 || [ "$PERC" -gt 100 ] && PERC=100
    echo "$PERC"
}

# 多节点永久跳动主循环（无空条、节点随使用率动态增减）
while true; do
    # 获取真实使用率，计算16节点下的实际跳动数（1%≈0.16个节点，精准匹配）
    PERC=$(get_perc)
    NODE_NUM=$((PERC * MAX_NODES / 100))
    [ "$NODE_NUM" -lt 1 ] && NODE_NUM=1  # 低使用率至少1个节点，避免无显示
    [ "$NODE_NUM" -gt "$MAX_NODES" ] && NODE_NUM="$MAX_NODES"  # 限制最大16个节点
    
    # 构建16节点动态闪烁条（每个节点随机满格/波动，动感更丰富）
    DYNAMIC_BAR=""
    for ((i=0; i<NODE_NUM; i++)); do
        # 25%满格+75%波动，多节点下闪烁更自然不杂乱
        [ $((RANDOM % 4)) -eq 0 ] && DYNAMIC_BAR+="${SINGLE_BARS[7]}" || DYNAMIC_BAR+="${WAVE_CHARS[$((RANDOM % 7))]}"
    done
    
    # 输出多节点跳动效果（内存图标+纯闪烁节点，无任何空条）
    echo "$DYNAMIC_BAR"
    sleep "$REFRESH_INTERVAL"
done
