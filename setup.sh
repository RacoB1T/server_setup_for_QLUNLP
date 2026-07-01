#!/usr/bin/env bash
# setup.sh — 一键环境安装脚本
#
# 用法:
#   bash setup.sh            # 安装所有启用的工具
#   bash setup.sh --force    # 强制重装所有工具
#
# 描述:
#   在新机器上一键安装 Clash、Git、Claude Code、Codex CLI。
#   每个模块独立安装，支持幂等（重复运行安全）。
#   通过 config 文件自定义安装选项。

set -euo pipefail

# ============================================================
# 解析参数
# ============================================================
FORCE=false
case "${1:-}" in
    --force|-f|--reinstall|-r)
        FORCE=true
        ;;
esac
export FORCE

# ============================================================
# 加载公共库
# ============================================================
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SETUP_DIR

# shellcheck disable=SC1090
source "$SETUP_DIR/modules/common.sh"

# ============================================================
# 加载配置
# ============================================================
CONFIG_FILE="$SETUP_DIR/config"
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    log_warn "未找到配置文件 $CONFIG_FILE，使用默认值"
fi

# ============================================================
# 加载各模块
# ============================================================
MODULES_DIR="$SETUP_DIR/modules"

# shellcheck disable=SC1090
source "$MODULES_DIR/gcc.sh"
# shellcheck disable=SC1090
source "$MODULES_DIR/node.sh"
# shellcheck disable=SC1090
source "$MODULES_DIR/git.sh"
# shellcheck disable=SC1090
source "$MODULES_DIR/clash.sh"
# shellcheck disable=SC1090
source "$MODULES_DIR/claude.sh"
# shellcheck disable=SC1090
source "$MODULES_DIR/codex.sh"

# ============================================================
# 主流程
# ============================================================
main() {
    acquire_lock
    trap release_lock EXIT
    init_setup

    # 按依赖顺序执行各模块
    # node 必须在 claude/codex 之前
    local modules=(gcc node git clash claude codex)
    local has_error=false

    for module in "${modules[@]}"; do
        if is_enabled "$module"; then
            if ! run_module "$module"; then
                has_error=true
            fi
        else
            log_skip "$module（已在 config 中禁用）"
            INSTALL_RESULTS[$module]="disabled"
        fi
    done

    print_summary

    if $has_error; then
        log_warn "部分模块安装失败，请查看上方日志"
        exit 1
    else
        log_success "全部完成！"
    fi

    echo ""
    log_info "请手动执行以下命令使环境变量生效："
    echo -e "  ${COLOR_BOLD}source ~/.bashrc${COLOR_RESET}"
    echo ""
}

main "$@"
