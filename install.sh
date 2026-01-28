#!bin/bash
echo "开始安装~"
sleep 1
echo "正在安装依赖..."
sudo pacman -S --noconfirm waybar procps-ng iproute2 bc pipewire wireplumber pulseaudio-utils cava ttf-font-awesome ttf-jetbrains-mono-nerd ttf-noto-sans-cjk-sc
echo "正在备份文件..."
sleep 1
# ===================== 配置区（可根据需要修改） =====================
# 要备份的目标文件夹（相对~/.config的路径）
BACKUP_TARGETS=("mako" "cava" "waybar")
# 备份文件存放目录（默认放在用户主目录下的.config_backups）
BACKUP_DIR="$HOME/.config_backups"
# 备份文件的时间戳格式（YYYYMMDD_HHMMSS）
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
# 备份压缩包名称
BACKUP_FILENAME="config_backup_${TIMESTAMP}.tar.gz"
# ==================================================================

# 切换到用户主目录，避免路径问题
cd "$HOME" || {
  echo "错误：无法进入用户主目录 $HOME"
  exit 1
}

# 检查并创建备份目录
if [ ! -d "$BACKUP_DIR" ]; then
  echo "提示：备份目录 $BACKUP_DIR 不存在，正在创建..."
  mkdir -p "$BACKUP_DIR" || {
    echo "错误：无法创建备份目录 $BACKUP_DIR"
    exit 1
  }
fi

# 检查要备份的文件夹是否存在
missing_targets=()
for target in "${BACKUP_TARGETS[@]}"; do
  if [ ! -d "$HOME/.config/$target" ]; then
    missing_targets+=("$target")
  fi
done

# 如果有文件夹不存在，给出提示但继续执行（避免因单个文件夹缺失导致备份失败）
if [ ${#missing_targets[@]} -gt 0 ]; then
  echo "警告：以下文件夹不存在，将跳过备份：${missing_targets[*]}"
fi

# 执行备份（使用tar打包并压缩）
echo "开始备份 ~/.config 下的指定文件夹到 $BACKUP_DIR/$BACKUP_FILENAME..."
tar -czf "$BACKUP_DIR/$BACKUP_FILENAME" \
  --exclude="*.log" \
  --exclude="*.tmp" \
  "${BACKUP_TARGETS[@]/#/.config/}" || {
  echo "错误：备份过程失败"
  exit 1
}

# 验证备份文件是否生成
if [ -f "$BACKUP_DIR/$BACKUP_FILENAME" ]; then
  # 显示备份文件大小（人性化格式）
  FILE_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILENAME" | awk '{print $1}')
  echo "✅ 备份成功！"
  echo "备份文件路径：$BACKUP_DIR/$BACKUP_FILENAME"
  echo "备份文件大小：$FILE_SIZE"
else
  echo "❌ 备份失败：未生成备份文件"
  exit 1
fi

exit 0
sleep 1
echo "正在复制文件..."
rm -r ~/.config/cava/ ~/.config/mako/ ~/.config/waybar
cp -r {cava,mako,waybar} ~/.config/
systemctl enable --now mako.service
sleep 1
echo "安装完成！"
echo -e "\n========================================"
echo "✅ 任务已全部执行完成！"
echo "💡 按下[回车键|ENTER] 将立即重启系统，按 Ctrl+C 取消重启"
echo "========================================\n"

# 等待用户按下回车键（无输入要求，仅等待回车）
read -p "请确认是否重启：" -r

# 用户按下回车后执行重启（需root权限，sudo确保重启生效）
echo -e "\n🔄 正在重启系统...\n"
sudo reboot
