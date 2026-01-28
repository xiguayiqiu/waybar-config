#!/bin/bash
set -euo pipefail # 开启严格模式，遇到错误立即退出

# ===================== 配置区（与install.sh保持一致） =====================
# 要恢复/删除的配置文件夹（和安装脚本对应）
TARGETS=("mako" "cava" "waybar")
# 备份文件存放目录（和安装脚本一致）
BACKUP_DIR="$HOME/.config_backups"
# ==========================================================================

# 友好提示 & 确认卸载（避免误操作）
echo -e "\n⚠️  警告：即将执行卸载操作！"
echo "此操作会：1. 尝试恢复备份的配置文件 2. 卸载相关软件包 3. 清理当前配置"
read -p "确认继续？(输入 y 并回车，其他键取消)：" -r CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "✅ 操作已取消"
  exit 0
fi

# -------------------------- 第一步：尝试恢复备份 --------------------------
echo -e "\n📂 正在检查备份文件..."
# 查找最新的备份压缩包（按时间排序，取最新的）
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/config_backup_*.tar.gz 2>/dev/null | head -n1)

if [ -n "$LATEST_BACKUP" ]; then
  echo "🔍 找到最新备份：$LATEST_BACKUP"
  echo "🔄 正在恢复备份到 ~/.config/..."

  # 解压备份文件（覆盖原位置，保留tar的目录结构）
  tar -xzf "$LATEST_BACKUP" -C "$HOME" || {
    echo "❌ 恢复备份失败！将仅删除当前配置"
    # 恢复失败则标记为无备份，继续执行删除逻辑
    LATEST_BACKUP=""
  }

  if [ -n "$LATEST_BACKUP" ]; then
    echo "✅ 备份恢复成功！"
  fi
else
  echo "⚠️  未找到任何备份文件，将直接删除当前配置"
fi

# -------------------------- 第二步：清理当前配置（无备份时执行） --------------------------
if [ -z "$LATEST_BACKUP" ]; then
  echo -e "\n🗑️  正在删除 ~/.config 下的配置文件夹..."
  for target in "${TARGETS[@]}"; do
    CONFIG_PATH="$HOME/.config/$target"
    if [ -d "$CONFIG_PATH" ]; then
      rm -rf "$CONFIG_PATH"
      echo "✅ 已删除：$CONFIG_PATH"
    else
      echo "ℹ️  跳过：$CONFIG_PATH 不存在"
    fi
  done
fi

# -------------------------- 第三步：卸载相关软件包 --------------------------
echo -e "\n📦 正在卸载相关软件包..."
# 卸载命令说明：
# -R：移除包  -n：删除配置文件  -s：删除不再需要的依赖  --noconfirm：自动确认
sudo pacman -Rns --noconfirm \
  waybar procps-ng iproute2 bc pipewire wireplumber pulseaudio-utils cava \
  ttf-font-awesome ttf-jetbrains-mono-nerd ttf-noto-sans-cjk-sc mako || {
  echo "⚠️  部分软件包卸载失败（可能已提前卸载），继续执行后续操作"
}

# -------------------------- 第四步：清理mako服务 --------------------------
echo -e "\n🔧 正在停止并禁用mako服务..."
systemctl stop --user mako.service 2>/dev/null || true
systemctl disable --user mako.service 2>/dev/null || true

# -------------------------- 第五步：重启询问（新增核心逻辑） --------------------------
echo -e "\n========================================"
echo "✅ 卸载/恢复操作已全部完成！"
echo "💡 按下【回车键】将立即重启系统，按 Ctrl+C 取消重启"
echo "========================================\n"

# 等待用户按下回车键（无输入要求，仅等待回车）
read -p "请确认是否重启：" -r

# 用户按下回车后执行重启（需root权限，sudo确保重启生效）
echo -e "\n🔄 正在重启系统...\n"
sudo reboot

exit 0
