#!/bin/bash
# 适配CAVA 0-7强度/14列/立体声/raw模式，Waybar专属
BARS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")  # 0-7对应8个条形
CAVA_MAX=7                              # 与cava配置的ascii_max_range = 7一致
COLUMNS=14                              # 与cava配置的bars = 14一致

# 纯原生语法解析，无正则/无[[ ]]，0兼容问题
cava | while read -r line; do
    # 过滤空行
    if [ -z "$line" ]; then
        continue
    fi
    # 过滤仅含分号的行
    only_semicolon=1
    for ((i=0; i<${#line}; i++)); do
        char="${line:$i:1}"
        if [ "$char" != ";" ]; then
            only_semicolon=0
            break
        fi
    done
    if [ "$only_semicolon" -eq 1 ]; then
        continue
    fi
    # 过滤无数字的行
    has_digit=0
    for ((i=0; i<${#line}; i++)); do
        char="${line:$i:1}"
        case "$char" in
            0|1|2|3|4|5|6|7) has_digit=1; break ;;
        esac
    done
    if [ "$has_digit" -eq 0 ]; then
        continue
    fi

    # 拆分14列强度值，直接映射为对应条形（0→▁，7→█）
    IFS=';' read -ra VALUES <<< "$line"
    CAVA_BAR=""
    for ((i=0; i<COLUMNS; i++)); do
        # 兼容行尾空值/数组越界，默认0
        val=${VALUES[$i]:-0}
        # 强制转为整数，限制范围0-7
        val=$((val + 0))
        [ "$val" -lt 0 ] && val=0
        [ "$val" -gt "$CAVA_MAX" ] && val="$CAVA_MAX"
        # 直接映射：强度值=条形数组索引，无多余阈值
        CAVA_BAR+="${BARS[$val]}"
    done

    # 输出Waybar JSON格式（替换为Nerd Font音频图标，更适配）
    echo "{\"text\": \" $CAVA_BAR\", \"class\": \"cava-visual\"}"
done
