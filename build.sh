#!/usr/bin/env bash
# DevUOS 一键构建脚本
# 在 Linux (amd64) 上运行，生成基于 UOS/Deepin 上游的可启动开发系统 ISO
set -euo pipefail

# 确保脚本自身、auto 配置与 chroot 钩子具备可执行权限
cd "$(dirname "$0")"
chmod +x build.sh config/auto/* config/hooks/live/* 2>/dev/null || true

echo "========================================================"
echo "  DevUOS —— 基于 UOS/Deepin 的自定义开发操作系统构建"
echo "========================================================"

# 1) 必须在 Linux 上（需要 chroot / debootstrap）
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "错误：本构建必须在 Linux (amd64) 上进行，Windows/macOS 无法直接生成 Linux ISO。"
  echo "推荐：Windows 用户安装 WSL2 (Ubuntu) 或开一个原生 Linux 虚拟机后再跑本脚本。"
  exit 1
fi

# 2) 需要 root（debootstrap/chroot 必需）
if [[ "$(id -u)" -ne 0 ]]; then
  echo "提示：构建需要 root 权限，正在尝试用 sudo 重新执行..."
  exec sudo "$0" "$@"
fi

# 3) 依赖检测
DEPS=(live-build debootstrap xorriso squashfs-tools mtools grub-common git curl python3)
echo ">> 检测构建依赖..."
MISSING=()
for d in "${DEPS[@]}"; do
  if ! command -v "$d" >/dev/null 2>&1; then MISSING+=("$d"); fi
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "缺少依赖: ${MISSING[*]}"
  echo "请先安装（Debian/Ubuntu）："
  echo "  apt-get update && apt-get install -y live-build debootstrap xorriso squashfs-tools mtools grub-common git curl python3"
  exit 1
fi

# 4) 注册 debootstrap 的 apricot 脚本（Deepin 20.9 基于 Debian 10 buster）
SCRIPT_DIR=/usr/share/debootstrap/scripts
if [[ ! -e "$SCRIPT_DIR/apricot" ]]; then
  echo ">> 注册 debootstrap apricot 脚本..."
  if [[ -e "$SCRIPT_DIR/buster" ]]; then
    ln -sf "$SCRIPT_DIR/buster" "$SCRIPT_DIR/apricot"
  elif [[ -e "$SCRIPT_DIR/bookworm" ]]; then
    ln -sf "$SCRIPT_DIR/bookworm" "$SCRIPT_DIR/apricot"
  else
    echo "错误：debootstrap 缺少 buster/bookworm 脚本，请升级 debootstrap。" >&2
    exit 1
  fi
fi

# 5) 准备 Deepin GPG 公钥（容错：拿不到就用 --apt-secure false 继续）
echo ">> 准备 Deepin 源签名密钥..."
mkdir -p config/archives
KEYURL="https://community-packages.deepin.com/deepin/project/deepin-keyring.gpg"
if curl -fsSL --max-time 30 "$KEYURL" -o config/archives/deepin-archive-keyring.gpg 2>/dev/null; then
  echo "   已下载 Deepin 公钥"
elif [[ -f /usr/share/keyrings/deepin-archive-keyring.gpg ]]; then
  cp /usr/share/keyrings/deepin-archive-keyring.gpg config/archives/deepin-archive-keyring.gpg
  echo "   已使用本机已有 Deepin 公钥"
else
  echo "   警告：未能获取 Deepin 公钥，将以 --apt-secure false 继续构建（源本身可信）。"
fi

# 6) 配置 + 构建
echo ">> 运行 live-build 配置 (auto/config)..."
lb config

echo ">> 开始构建 ISO（视网速约 20-60 分钟）..."
lb build

echo ">> 构建完成，产物："
ls -lh ./*.iso 2>/dev/null || echo "未找到 .iso，请检查上方构建日志。"
