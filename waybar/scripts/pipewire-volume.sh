#!/bin/bash
# 屏蔽错误输出，获取默认音频设备音量信息
WPCTL_OUTPUT=$(wpctl get-volume @DEFAULT_SINK@ 2>/dev/null)
# 提取纯数字音量+去除前导0，兜底赋值0避免空值
VOLUME=$(echo "$WPCTL_OUTPUT" | awk '{print $2}' | tr -cd '0-9' | head -n1 | sed 's/^0*//')
[ -z "$VOLUME" ] && VOLUME=0
# 判断静音状态（仅用于图标/音量逻辑，不再输出）
if echo "$WPCTL_OUTPUT" | grep -q '\[MUTED\]'; then
    MUTED_STATE=1
else
    MUTED_STATE=0
fi
# 按音量/静音状态分配图标（静音/0-30% | 31-70% | 71-100%）
if [ $MUTED_STATE -eq 1 ] || [ "$VOLUME" -le 30 ]; then
    ICON=""
elif [ "$VOLUME" -le 70 ]; then
    ICON=""
else
    ICON=""
fi
# 仅输出：图标 音量（2字段，无其他内容）
echo "$ICON $VOLUME"
