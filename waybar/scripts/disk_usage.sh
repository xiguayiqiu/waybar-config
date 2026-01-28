#!/bin/bash

# 配置要监控的磁盘分区（默认根目录 /）
MOUNT_POINT="/"

# 修复：正确提取df字段（Use% Used Avail Size），兼容不同系统的df输出格式
DISK_USAGE=$(df -h "$MOUNT_POINT" | awk '
    NR==2 {
        gsub(/%/, "", $5);  # 去掉百分比符号
        # 输出顺序：使用率 已使用 剩余 总容量
        print $5, $3, $4, $2
    }
')

# 修复：去掉多余的SPACE变量，确保字段一一对应
read -r USAGE_PERCENT USED LEFT TOTAL <<< "$DISK_USAGE"

# 容错：如果字段为空，填充默认值避免显示异常
USAGE_PERCENT=${USAGE_PERCENT:-0}
USED=${USED:-"0B"}
LEFT=${LEFT:-"0B"}
TOTAL=${TOTAL:-"0B"}

# 设置颜色规则（和你的主题色匹配）
if [ "$USAGE_PERCENT" -ge 85 ]; then
    COLOR="#f38ba8"  # @critical
elif [ "$USAGE_PERCENT" -ge 70 ]; then
    COLOR="#89b4fa"  # @accent
else
    COLOR="#a6e3a1"  # @success
fi

# 构建tooltip信息（修复换行符转义）
TOOLTIP="💿 磁盘使用情况 ($MOUNT_POINT)\n总容量: $TOTAL\n已使用: $USED ($USAGE_PERCENT%)\n剩余: $LEFT"

# 输出waybar格式的JSON（移除无用的ANIMATION变量）
echo "{
    \"text\": \"💿 $USAGE_PERCENT%\",
    \"tooltip\": \"$TOOLTIP\",
    \"class\": \"$( [ $USAGE_PERCENT -ge 85 ] && echo "critical" || echo "" )\",
    \"color\": \"$COLOR\"
}"
