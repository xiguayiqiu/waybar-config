#!/bin/bash
# Waybar 麦克风终极版检测脚本（适配你的PipeWire环境，精准提取设备）
# 直接提取pactl中非monitor的第一个有效麦克风，无冗余过滤

# 核心函数：精准提取麦克风设备名（已验证适配你的系统）
detect_microphone() {
    pactl list sources short | grep -v monitor | head -n1 | awk '{print $2}'
}

# 检测当前麦克风设备
MIC_DEVICE=$(detect_microphone)

# 处理点击切换静音
if [ "$1" = "toggle" ]; then
    if [ -n "$MIC_DEVICE" ]; then
        pactl set-source-mute "$MIC_DEVICE" toggle >/dev/null 2>&1
    fi
    exit 0
fi

# 无设备异常处理
if [ -z "$MIC_DEVICE" ]; then
    echo '{"text": "", "tooltip": "未检测到麦克风", "class": "no-mic"}'
    exit 0
fi

# 获取静音状态并输出Waybar识别的JSON
MIC_MUTE=$(pactl get-source-mute "$MIC_DEVICE" | awk '{print $2}')
if [ "$MIC_MUTE" = "yes" ]; then
    echo "{\"text\": \"\", \"tooltip\": \"麦克风已静音\\n设备：$MIC_DEVICE\", \"class\": \"muted\"}"
else
    echo "{\"text\": \"\", \"tooltip\": \"麦克风已开启\\n设备：$MIC_DEVICE\", \"class\": \"unmuted\"}"
fi
