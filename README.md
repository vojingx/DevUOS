# DevUOS —— 基于 UOS / Deepin 的自定义开发操作系统

一个**可启动的 Linux ISO**：以统信 UOS 的开源上游 **Deepin 20.9（代号 apricot）** 为底座，定制 **DDE 图形桌面 + 终端 + 完整开发工具链**，定位为开箱即用的开发操作系统。

> 为什么是 Deepin？UOS（统信）商业版闭源且需授权，其开源技术底座就是 Deepin。Deepin 20.9 = UOS 20 的同源上游，用它能合法、免费地做出“基于 UOS”的发行版，且桌面体验与 UOS 一致（同为 DDE）。

---

## 技术路线

| 层 | 选型 |
|---|---|
| 发行底座 | Deepin 20.9 `apricot`（基于 Debian 10） |
| 图形桌面 | **DDE**（Deepin Desktop Environment，与 UOS 同款） |
| 终端 | `deepin-terminal` |
| 显示管理 | LightDM + GTK greeter，自动登录 |
| 开发栈 | GCC/Clang、Make/CMake、Git、Python3、Node.js、Go、OpenJDK |
| 中文 | fcitx 输入法、文泉驿/Noto 字体、`zh_CN.UTF-8` |
| 浏览器 | Chromium、`firefox-esr` |
| 内核 | `linux-image-amd64`（Deepin 4.19 系列） |
| 输出 | `iso-hybrid`，同时支持 Legacy BIOS + UEFI |

---

## 目录结构

```
uos-dev-os/
├── build.sh                # 一键构建（检测依赖、注册源、调 live-build）
├── README.md
├── config/
│   ├── auto/
│   │   ├── config          # live-build 配置（源、架构、桌面、ISO 参数）
│   │   └── build           # 构建入口
│   ├── archives/
│   │   └── deepin.list.chroot   # 写入最终系统的 apt 源
│   ├── package-lists/      # 分阶段安装的软件包
│   │   ├── 01-base.list        # 基础 + live 运行
│   │   ├── 02-desktop.list      # DDE 桌面 + 显示管理
│   │   ├── 03-develop.list       # 开发工具链
│   │   └── 04-chinese.list       # 中文 + 输入法 + 常用应用
│   ├── includes.chroot/    # 直接注入最终系统的配置文件
│   │   ├── etc/lightdm/lightdm.conf   # 自动登录 developer
│   │   └── etc/default/locale         # 默认中文 locale
│   ├── hooks/live/         # chroot 内执行脚本
│   │   ├── 00-setup.chroot     # locale / 主机名 / keyring / lightdm
│   │   └── 01-user.chroot      # 创建 developer 用户 + 免密 sudo
│   └── bootloaders/        # （留空则用 live-build 默认启动菜单）
└── scripts/                # 进阶/备用脚本目录
```

---

## 环境要求

- **Linux amd64** 环境（Windows 用户请用 **WSL2 Ubuntu 22.04+**，或开一个原生 Linux 虚拟机；macOS 不行）
- **root 权限**（debootstrap / chroot 必需）
- 磁盘 ≥ 25 GB，内存 ≥ 4 GB
- 网络可访问 `https://community-packages.deepin.com/deepin`

> ⚠️ 沙箱（Windows）或你本机 Windows 都无法直接生成 Linux ISO。**两条路任选其一**：① 本机装 WSL2 Ubuntu / 原生 Linux 虚拟机后跑 `build.sh`；②（**推荐，零本机 Linux 负担**）把仓库推到 GitHub，用内置的 `Build DevUOS ISO (cloud)` 工作流在云端自动构建并发布 ISO（见下节）。

---

## Windows / macOS 用户：GitHub 云端构建（推荐，零本机 Linux 负担）

你本机**不需要装 Linux / WSL2**。把仓库推到 GitHub 后，**GitHub 的 Linux 服务器会自动拉包、构建，并把 ISO 发布到 Release**，你下载即可。工作流文件已内置：`.github/workflows/build-iso.yml`。

1. 在 GitHub 新建一个仓库（例如 `vojingx/DevUOS`）。
2. 在你本机（Windows）的终端里执行：
   ```bash
   cd uos-dev-os
   git init
   git add -A
   git commit -m "DevUOS build toolchain"
   git branch -M main
   git remote add origin https://github.com/vojingx/DevUOS.git
   git push -u origin main
   ```
   > 推送时用 GitHub 账号 + **PAT（个人访问令牌）** 作为密码；PAT 需勾选 `repo` 权限。你的 PAT 在 `D:\新建文件夹 (3)\api.txt`。
3. 打开仓库的 **Actions** 页，等待 `Build DevUOS ISO (cloud)` 跑完（约 20–60 分钟，视网速）。
4. 进入仓库 **Releases** 页，下载 `devuos-amd64.hybrid.iso`。

重新构建：改完代码 `git push` 会自动触发；或在 Actions 页点 **Run workflow** 手动触发。

---

## 一键构建

```bash
git clone <本仓库> uos-dev-os && cd uos-dev-os
sudo ./build.sh
```

脚本会自动：检测依赖 → 注册 `apricot` 给 debootstrap → 准备 Deepin 公钥（失败则降级）→ `lb config` → `lb build`。
构建完成后在当前目录生成 `devuos-amd64.hybrid.iso`（文件名以 `--image-name` 为准）。

---

## 手动构建（等效步骤）

```bash
sudo apt-get update
sudo apt-get install -y live-build debootstrap xorriso squashfs-tools mtools grub-common git curl python3

# Deepin 20.9 基于 Debian 10(buster)，让 debootstrap 认识 apricot
sudo ln -sf /usr/share/debootstrap/scripts/buster /usr/share/debootstrap/scripts/apricot

chmod +x config/auto/* config/hooks/live/* build.sh
lb config      # 读取 auto/config
lb build       # 生成 ISO（约 20–60 分钟，取决于网速）
```

---

## 测试 ISO

- **QEMU（最快验证）**
  ```bash
  qemu-system-x86_64 -m 4096 -smp 2 -boot d -cdrom devuos-amd64.hybrid.iso
  ```
- **VirtualBox**：新建 Linux 虚拟机，光驱挂载 ISO，启动即可体验 Live。
- **实体机 / U 盘**：用 [Ventoy](https://www.ventoy.net/) 把 ISO 拷进 U 盘，从 U 盘启动。

**默认账户**：`developer` / 密码 `developer`，开机自动登录，`sudo` 免密。

---

## 自定义

| 想改什么 | 改哪里 |
|---|---|
| 预装更多软件 | `config/package-lists/*.list`（一行一个包） |
| 桌面 / 自动登录 / locale | `config/includes.chroot/etc/` |
| 用户、密码、sudo | `config/hooks/live/01-user.chroot` |
| locale / 主机名 / keyring | `config/hooks/live/00-setup.chroot` |
| 换软件源（如切到你的 UOS 授权源） | `build.sh` 与 `config/archives/deepin.list.chroot` 的 mirror 地址 |
| 启动菜单标题/背景 | 在 `config/bootloaders/isolinux/` 放自定义菜单（见 live-build 文档） |

> 改完包列表后若某包在所选源不存在，`lb build` 会报错；按提示从对应 `.list` 移除即可。

---

## 升级到 UOS 商业版

若你持有统信 UOS 商业授权：
1. 把 `build.sh` 与 `config/archives/deepin.list.chroot` 的 mirror 改为官方授权源；
2. 将官方 `uos-keyring` 装入 `config/archives/` 并去掉 `--apt-secure false`；
3. 在 `02-desktop.list` 用 UOS 桌面元包替换 `dde`（如有）。

其余流程不变。

---

## 故障排查

- **构建报某包不存在**：编辑对应 `config/package-lists/*.list` 移除该包后重跑 `lb build`。
- **桌面起不来 / 黑屏**：QEMU 启动项追加 `nomodeset`；检查 `config/includes.chroot/etc/lightdm/lightdm.conf` 的 `user-session=deepin`。
- **磁盘空间不足**：清理 `sudo lb clean`（或直接 `rm -rf chroot binary`）后重来。
- **apt 校验警告**：这是 `--apt-secure false` 的预期行为（源为官方可信源）。装好 `deepin-keyring` 后可在最终系统恢复严格校验。
- **debootstrap: unknown suite apricot**：确认已执行 `ln -sf .../buster .../apricot`。

---

## 安全说明

Deepin 社区源的标准 GPG 公钥 URL 当前不可达，因此构建阶段使用 `--apt-secure false` 拉取软件包。Deepin 官方源本身可信，该设置仅跳过签名校验以便构建顺利进行；在最终系统安装 `deepin-keyring` 后，可将 apt 校验改回严格模式（`--apt-secure true`）。

---

## 许可证

本构建配置按 MIT 许可证发布。Deepin / UOS 及其组件遵循各自上游许可证。
