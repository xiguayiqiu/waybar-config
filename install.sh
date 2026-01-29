#!/bin/bash
# 获取脚本所在的绝对路径（解决cp路径找不到的核心问题）
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
echo "开始安装~"
sleep 1
echo "正在安装依赖..."
# 修正Arch Linux正确包名：pulseaudio-utils→pulseaudio，ttf-noto-sans-cjk-sc→noto-fonts-cjk
sudo pacman -S --noconfirm waybar procps-ng iproute2 bc pipewire wireplumber pulseaudio cava ttf-font-awesome ttf-jetbrains-mono-nerd noto-fonts-cjk mako ttf-jetbrains-mono
echo "正在准备备份文件..."
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

# 检查并创建备份目录（仅创建，失败才终止，因后续无依赖）
if [ ! -d "$BACKUP_DIR" ]; then
  echo "提示：备份目录 $BACKUP_DIR 不存在，正在创建..."
  mkdir -p "$BACKUP_DIR" || {
    echo "错误：无法创建备份目录 $BACKUP_DIR"
    exit 1
  }
fi

# 核心步骤1：筛选出~/.config下**实际存在**的目标目录
exist_targets=()
for target in "${BACKUP_TARGETS[@]}"; do
  target_path="$HOME/.config/$target"
  if [ -d "$target_path" ]; then
    exist_targets+=("$target")
  fi
done

# 核心步骤2：无实际备份目标则跳过备份，直接执行后续
if [ ${#exist_targets[@]} -eq 0 ]; then
  echo "提示：~/.config下无需要备份的目录，跳过备份步骤"
else
  echo "提示：将备份以下目录：${exist_targets[*]}"
  # 执行备份（失败不终止，仅提示）
  echo "开始备份 ~/.config 下的指定文件夹到 $BACKUP_DIR/$BACKUP_FILENAME..."
  tar -czf "$BACKUP_DIR/$BACKUP_FILENAME" \
    --exclude="*.log" \
    --exclude="*.tmp" \
    "${exist_targets[@]/#/.config/}"

  # 验证备份结果（仅提示，不终止）
  if [ -f "$BACKUP_DIR/$BACKUP_FILENAME" ]; then
    FILE_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILENAME" | awk '{print $1}')
    echo "✅ 备份成功！"
    echo "备份文件路径：$BACKUP_DIR/$BACKUP_FILENAME"
    echo "备份文件大小：$FILE_SIZE"
  else
    echo "⚠️  备份警告：备份文件未生成，跳过备份，继续执行后续步骤"
  fi
fi

# 后续步骤：不受备份结果影响，正常执行
echo "正在复制文件..."
# 强制删除原有目录（不存在则无操作，不报错）
rm -rf ~/.config/cava/ ~/.config/mako/ ~/.config/waybar

# 检查脚本目录下的配置目录是否存在，避免cp报错
missing_configs=()
for dir in "cava" "mako" "waybar"; do
  if [ ! -d "$SCRIPT_DIR/$dir" ]; then
    missing_configs+=("$dir")
  fi
done

if [ ${#missing_configs[@]} -gt 0 ]; then
  echo "⚠️  警告：脚本目录下缺少以下配置目录，跳过复制：${missing_configs[*]}"
else
  # 用脚本绝对路径复制，解决"找不到文件"问题
  cp -r "$SCRIPT_DIR"/{cava,mako,waybar} ~/.config/
  echo "✅ 配置文件复制成功！"
fi

# 启用并立即启动mako服务
systemctl enable --now mako.service
sleep 1
echo "安装完成！"
echo -e "\n========================================"
echo "✅ 任务已全部执行完成！"
echo "💡 按下[回车键|ENTER] 将立即重启系统，按 Ctrl+C 取消重启"
echo "========================================\n"

# 等待用户确认（无输入要求，仅等待回车）
read -p "请确认是否重启：" -r

# 执行重启（sudo确保权限）
echo -e "\n🔄 正在重启系统...\n"
sudo reboot
