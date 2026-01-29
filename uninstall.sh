#!/bin/bash
set -euo pipefail

INSTALL_CONFIGS=(
  "$HOME/.config/mako"
  "$HOME/.config/waybar"
  "$HOME/.config/cava"
)

BACKUP_DIR="$HOME/.config_backup"

INSTALL_PACKAGES=(
  waybar cava mako
  ttf-font-awesome ttf-jetbrains-mono-nerd ttf-jetbrains-mono
)

INSTALL_SERVICES=(
  "mako.service"
)

INSTALL_LINKS=(
  "/usr/bin/waybar-custom"
)

INSTALL_ENVS=(
  "export WAYBAR_CONFIG_PATH=$HOME/.config/waybar"
)

echo -e "\033[31m⚠️  警告：即将执行镜像卸载！\033[0m"
echo "卸载逻辑完全匹配安装脚本，将执行："
echo "1. 有备份则恢复，无备份则跳过；"
echo "2. 无备份时删除安装部署的配置文件；"
echo "3. 卸载安装时安装的软件包；"
echo "4. 禁用/停止安装时启用的服务；"
echo "5. 删除安装时创建的软链接/环境变量；"
read -p "确认继续？(输入 y 回车，其他键取消)：" -r CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo -e "\033[32m✅ 卸载操作已取消\033[0m"
  exit 0
fi

echo -e "\033[33mℹ️  检查配置备份...\033[0m"
LATEST_BACKUP=$(ls -t "${BACKUP_DIR}/config_backup_"*.tar.gz 2>/dev/null | head -n1 || true)
LATEST_BACKUP=${LATEST_BACKUP:-}
if [ -n "$LATEST_BACKUP" ]; then
  echo -e "\n\033[34m📂 开始恢复配置备份...\033[0m"
  echo "🔍 找到安装时的备份：${LATEST_BACKUP}"
  tar -xzf "${LATEST_BACKUP}" -C "$HOME" && echo -e "\033[32m✅ 备份恢复成功\033[0m" || echo -e "\033[33m⚠️  备份恢复失败，跳过此步骤\033[0m"
fi

echo -e "\n\033[34m🗑️  清理安装部署的配置文件...\033[0m"
if [ -z "$LATEST_BACKUP" ]; then
  for config in "${INSTALL_CONFIGS[@]}"; do
    if [ -e "$config" ]; then
      rm -rf "$config"
      echo -e "\033[32m✅ 已删除：$config\033[0m"
    else
      echo -e "\033[33mℹ️  跳过：$config 不存在\033[0m"
    fi
  done
else
  echo -e "\033[33mℹ️  已恢复备份，跳过配置文件删除\033[0m"
fi

echo -e "\n\033[34m📦 卸载安装的软件包...\033[0m"
if [ ${#INSTALL_PACKAGES[@]} -gt 0 ]; then
  echo -e "\033[33mℹ️  需管理员权限，即将执行sudo pacman卸载...\033[0m"
  sudo pacman -Rns --noconfirm "${INSTALL_PACKAGES[@]}" || echo -e "\033[33m⚠️  部分软件包卸载失败（可能已提前卸载/非本脚本安装）\033[0m"
  echo -e "\033[32m✅ 软件包卸载流程执行完成\033[0m"
fi

echo -e "\n\033[34m🔧 停止并禁用相关服务...\033[0m"
for service in "${INSTALL_SERVICES[@]}"; do
  systemctl stop --user "$service" 2>/dev/null || true
  systemctl disable --user "$service" 2>/dev/null || true
  echo -e "\033[32m✅ 已处理服务：$service\033[0m"
done

echo -e "\n\033[34m🔗 清理安装创建的软链接...\033[0m"
for link in "${INSTALL_LINKS[@]}"; do
  if [ -L "$link" ]; then
    sudo rm -f "$link"
    echo -e "\033[32m✅ 已删除软链接：$link\033[0m"
  else
    echo -e "\033[33mℹ️  跳过：$link 不存在或非软链接\033[0m"
  fi
done

echo -e "\n\033[34m🔤 清理安装添加的环境变量...\033[0m"
BASHRC="$HOME/.bashrc"
if [ -f "$BASHRC" ]; then
  for env_line in "${INSTALL_ENVS[@]}"; do
    sed -i "\|$env_line|d" "$BASHRC" 2>/dev/null || true
    echo -e "\033[32m✅ 已尝试移除环境变量：$env_line\033[0m"
  done
fi

echo -e "\n\033[32m========================================"
echo "✅ 镜像卸载操作全部执行完成！"
echo "========================================\033[0m"
read -p "是否重启系统使配置生效？(输入 y 回车重启，其他键取消)：" -r REBOOT
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
  echo -e "\n\033[34m🔄 正在重启系统...\033[0m"
  sudo reboot
else
  echo -e "\n\033[32m✅ 已取消重启，手动重启建议执行：sudo reboot\033[0m"
fi
