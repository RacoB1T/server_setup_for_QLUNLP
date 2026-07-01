#!/usr/bin/env bash
# common.sh — 公共函数库：日志、发行版检测、包管理器抽象、幂等标记

set -euo pipefail

# ============================================================
# 颜色定义
# ============================================================
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_RESET='\033[0m'

# ============================================================
# 全局变量
# ============================================================
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SETUP_DIR

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/env-setup"
export STATE_DIR

# 安装结果汇总
declare -A INSTALL_RESULTS
INSTALL_RESULTS=()

# ============================================================
# 日志函数
# ============================================================
log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

log_success() {
    echo -e "${COLOR_GREEN}[OK]${COLOR_RESET}   $*"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"
}

log_error() {
    echo -e "${COLOR_RED}[FAIL]${COLOR_RESET} $*"
}

log_step() {
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_CYAN}[>>>]${COLOR_RESET} ${COLOR_BOLD}$*${COLOR_RESET}"
}

log_skip() {
    echo -e "${COLOR_CYAN}[SKIP]${COLOR_RESET} $*"
}

# ============================================================
# 发行版检测
# ============================================================
detect_os() {
    local id
    if [ -f /etc/os-release ]; then
        id=$(grep -oP '(?<=^ID=).*' /etc/os-release | tr -d '"')
    elif [ -f /etc/lsb-release ]; then
        id=$(grep -oP '(?<=^DISTRIB_ID=).*' /etc/lsb-release | tr -d '"')
    else
        id="unknown"
    fi
    echo "$id" | tr '[:upper:]' '[:lower:]'
}

detect_os_version() {
    if [ -f /etc/os-release ]; then
        grep -oP '(?<=^VERSION_ID=).*' /etc/os-release | tr -d '"'
    else
        echo "unknown"
    fi
}

detect_pkg_manager() {
    local os_id
    os_id=$(detect_os)

    case "$os_id" in
        ubuntu|debian|linuxmint|pop|elementary|zorin|kali|parrot|deepin|uos)
            echo "apt" ;;
        fedora|rhel|centos|rocky|almalinux|amzn|ol)
            # RHEL 8+ uses dnf, older uses yum
            if command -v dnf &>/dev/null; then
                echo "dnf"
            else
                echo "yum"
            fi ;;
        arch|manjaro|endeavouros|artix|garuda)
            echo "pacman" ;;
        opensuse-tumbleweed|opensuse-leap|opensuse|sles)
            echo "zypper" ;;
        alpine)
            echo "apk" ;;
        *)
            echo "unknown" ;;
    esac
}

# ============================================================
# 包管理器抽象
# ============================================================
pkg_install() {
    local pm
    pm=$(detect_pkg_manager)

    log_info "安装系统包: $*"

    case "$pm" in
        apt)
            sudo apt-get update -qq
            sudo apt-get install -y "$@"
            ;;
        dnf)
            sudo dnf install -y "$@"
            ;;
        yum)
            sudo yum install -y "$@"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$@"
            ;;
        zypper)
            sudo zypper install -y "$@"
            ;;
        apk)
            sudo apk add "$@"
            ;;
        *)
            log_error "不支持的包管理器。请手动安装: $*"
            return 1
            ;;
    esac
}

pkg_is_installed() {
    local pm
    pm=$(detect_pkg_manager)

    case "$pm" in
        apt|dnf|yum)
            dpkg -l "$1" &>/dev/null || rpm -q "$1" &>/dev/null
            ;;
        pacman)
            pacman -Qi "$1" &>/dev/null
            ;;
        zypper)
            rpm -q "$1" &>/dev/null
            ;;
        apk)
            apk info -e "$1" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================================
# 命令检查
# ============================================================
cmd_exists() {
    command -v "$1" &>/dev/null
}

# ============================================================
# 幂等标记
# ============================================================
mark_installed() {
    local module=$1
    mkdir -p "$STATE_DIR"
    touch "$STATE_DIR/$module.installed"
    log_success "$module 安装完成"
}

is_marked_installed() {
    local module=$1
    [ -f "$STATE_DIR/$module.installed" ]
}

clear_mark() {
    local module=$1
    rm -f "$STATE_DIR/$module.installed"
}

# ============================================================
# 配置读取
# ============================================================
is_enabled() {
    local module=$1
    local var="INSTALL_$(echo "$module" | tr '[:lower:]' '[:upper:]')"
    case "${!var:-true}" in
        true|yes|1) return 0 ;;
        *)          return 1 ;;
    esac
}

# 读取配置项，支持默认值
get_config() {
    local key=$1
    local default=${2:-}
    echo "${!key:-$default}"
}

# ============================================================
# NVM 加载
# ============================================================
load_nvm() {
    if [ -z "${NVM_DIR:-}" ]; then
        export NVM_DIR="$HOME/.nvm"
    fi
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck disable=SC1090,SC1091
        . "$NVM_DIR/nvm.sh"
    fi
}

# ============================================================
# sudo 检查
# ============================================================
has_sudo() {
    sudo -n true &>/dev/null 2>&1
}

# ============================================================
# 模块运行器
# ============================================================
run_module() {
    local module=$1
    local func="install_${module}"
    local verify="verify_${module}"

    log_step "安装模块: $module"

    # 检查是否已通过标记安装
    if is_marked_installed "$module" && [ "${FORCE:-false}" != "true" ]; then
        log_skip "$module 已安装（标记检测），跳过"
        INSTALL_RESULTS[$module]="skipped"
        return 0
    fi

    # 执行安装函数
    if declare -f "$func" &>/dev/null; then
        if $func; then
            # 安装后验证
            if declare -f "$verify" &>/dev/null; then
                if $verify; then
                    mark_installed "$module"
                    INSTALL_RESULTS[$module]="ok"
                else
                    log_warn "$module 安装成功但验证失败"
                    mark_installed "$module"
                    INSTALL_RESULTS[$module]="ok_no_verify"
                fi
            else
                mark_installed "$module"
                INSTALL_RESULTS[$module]="ok"
            fi
        else
            log_error "$module 安装失败"
            INSTALL_RESULTS[$module]="failed"
            return 1
        fi
    else
        log_error "未找到安装函数: $func"
        INSTALL_RESULTS[$module]="missing"
        return 1
    fi
}

# ============================================================
# 安装摘要
# ============================================================
print_summary() {
    echo ""
    echo -e "${COLOR_BOLD}======= 安装摘要 =======${COLOR_RESET}"
    for module in "${!INSTALL_RESULTS[@]}"; do
        local result="${INSTALL_RESULTS[$module]}"
        case "$result" in
            ok)
                log_success "$module: 已安装" ;;
            ok_no_verify)
                log_success "$module: 已安装（验证未通过）" ;;
            skipped)
                log_skip "$module: 已跳过（已安装）" ;;
            failed)
                log_error "$module: 安装失败" ;;
            missing)
                log_error "$module: 未找到安装脚本" ;;
        esac
    done
    echo ""
}

# ============================================================
# 锁文件（防止并发运行）
# ============================================================
acquire_lock() {
    LOCKFILE="/tmp/env-setup.lock"
    exec 200>"$LOCKFILE"
    if ! flock -n 200; then
        log_error "检测到另一个 setup 进程正在运行 (lock: $LOCKFILE)"
        exit 1
    fi
}

# ============================================================
# 初始化
# ============================================================
init_setup() {
    mkdir -p "$STATE_DIR"

    echo ""
    echo -e "${COLOR_BOLD}╔══════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_BOLD}║     Environment Setup           ║${COLOR_RESET}"
    echo -e "${COLOR_BOLD}╚══════════════════════════════════╝${COLOR_RESET}"
    echo ""
    log_info "OS:     $(detect_os) $(detect_os_version)"
    log_info "包管理器: $(detect_pkg_manager)"
    log_info "状态目录: $STATE_DIR"
    log_info "Force:  ${FORCE:-false}"
    echo ""
}
