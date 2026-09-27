#!/system/bin/sh
# ============================================================
#  模块打包工具 v3.0（模板版）
#  风格：圆框标题 + 方向键选择 + 杂鱼工具箱吐槽味
#  用法：bash build.sh
# ============================================================

if [ -z "$BASH_VERSION" ]; then
    command -v bash >/dev/null 2>&1 && exec bash "$0" "$@"
    [ -x /system/bin/bash ] && exec /system/bin/bash "$0" "$@"
    echo "❌ 需要 bash，请先 pkg install bash"
    exit 1
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
[ -f "$ROOT/.buildrc" ] && . "$ROOT/.buildrc"

DIST="$ROOT/${DIST_NAME:-dist}"
STAMP="$(date +%Y%m%d-%H%M%S)"

# ---------- 杂鱼配色 ----------
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
PINK='\033[1;35m'
ORANGE='\033[1;91m'
GOLD='\033[1;33m'
GRAY='\033[38;5;245m'
DIM='\033[2m'
RESET='\033[0m'
BOLD='\033[1m'

BG_SELECT='\033[48;5;46m'
FG_SELECT='\033[97m'
BOLD_SELECT='\033[1m'

# ---------- 前置检查 ----------
if ! command -v zip >/dev/null 2>&1; then
    echo -e "${RED}❌ 缺少 zip 命令，请先安装：pkg install zip${RESET}"
    exit 1
fi

# ---------- 读 module.prop ----------
read_module_prop() {
    local key="$1"
    grep "^$key=" "$ROOT/module.prop" 2>/dev/null | cut -d= -f2 | head -1
}

MODULE_ID="$(read_module_prop id)"
MODULE_NAME="$(read_module_prop name)"
MODULE_VERSION="$(read_module_prop version)"

if [ -z "$MODULE_ID" ]; then
    echo -e "${RED}❌ module.prop 缺少 id${RESET}"
    exit 1
fi

# ---------- 圆框标题 ----------
LINE="〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓"

show_ui() {
    printf '\033[H\033[2J'
    printf '%b\n' \
        "${PINK}" \
        "    ╭───────────────────────────────────────╮" \
        "    │      🎮 小杂鱼的模块打包工具 🎮       │" \
        "    │              build v3.0               │" \
        "    ╰───────────────────────────────────────╯" \
        "${RESET}" \
        "${GRAY}        📁 目录: $ROOT${RESET}" \
        "${GRAY}        📦 模块: $MODULE_NAME ($MODULE_ID)${RESET}" \
        "${GRAY}        🏷️  版本: $MODULE_VERSION${RESET}" \
        "${GRAY}        📤 输出: $DIST${RESET}" \
        "" \
        "${BLUE}${LINE}${RESET}" \
        ""
}

print_line() {
    printf '%b\n' "${BLUE}${LINE}${RESET}"
}

# ---------- 杂鱼吐槽 ----------
fish_say() {
    local emojis=("🐟" "🐠" "🐡" "🎣" "📱" "🔍" "📦")
    local idx=$((RANDOM % ${#emojis[@]}))
    printf '%b\n' "${CYAN}[${emojis[$idx]}]${RESET} ${1}${RESET}"
}
fish_warn() {
    local warnings=("⚠️" "🚧" "📢" "💡" "🤔")
    local idx=$((RANDOM % ${#warnings[@]}))
    printf '%b\n' "${YELLOW}[${warnings[$idx]}]${RESET} ${1}${RESET}"
}
fish_error() {
    local errors=("❌" "💥" "🚫" "😱" "💀")
    local idx=$((RANDOM % ${#errors[@]}))
    printf '%b\n' "${RED}[${errors[$idx]}]${RESET} ${1}${RESET}"
}
fish_success() {
    local successes=("✅" "🎉" "✨" "👍" "💯")
    local idx=$((RANDOM % ${#successes[@]}))
    printf '%b\n' "${GREEN}[${successes[$idx]}]${RESET} ${1}${RESET}"
}

# ---------- 确认 ----------
confirm_installation() {
    printf '%b\n' "" \
        "${ORANGE}${BOLD}🤔 杂鱼${RESET}${CYAN}真的要继续吗？确认之后就别反悔哦！🤓${RESET}" \
        "${CYAN}✨ 输入 '${GREEN}${BOLD}y${RESET}${CYAN}' 确认 ${RED}⚡ ${CYAN}输入 '${RED}${BOLD}n${RESET}${CYAN}' 取消 ${PINK}(｡>∀<｡)${RESET}"
    printf '%b' "${YELLOW}🎮 请选择 [y/n]: ${RESET}"
    local choice
    read -r choice
    case "$choice" in
        y|Y|yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

# ---------- 进度条 ----------
show_progress() {
    local text="$1" pct="$2"
    local filled=$((pct / 5))
    local empty=$((20 - filled))
    local bar=""
    local i=0
    while [ "$i" -lt "$filled" ]; do bar="${bar}█"; i=$((i + 1)); done
    i=0
    while [ "$i" -lt "$empty" ]; do bar="${bar}░"; i=$((i + 1)); done
    printf '%b\n' "${CYAN}🐟 ${text} ${RESET}${GREEN}[${bar}]${RESET} ${BOLD}$(printf '%3d' "$pct")%${RESET}"
}

# ---------- 键盘读取 ----------
read_key() {
    local key=""
    IFS= read -r -n 1 key 2>/dev/null

    if [ "$key" = "$(printf '\033')" ]; then
        local seq1="" seq2=""
        IFS= read -r -n 1 -t 1 seq1 2>/dev/null
        IFS= read -r -n 1 -t 1 seq2 2>/dev/null
        if [ "$seq1" = "[" ]; then
            case "$seq2" in
                A) echo "UP" ;;
                B) echo "DOWN" ;;
                C) echo "RIGHT" ;;
                D) echo "LEFT" ;;
                *) echo "OTHER" ;;
            esac
        else
            echo "OTHER"
        fi
    elif [ -z "$key" ]; then
        echo "ENTER"
    elif [ "$key" = " " ]; then
        echo "SPACE"
    elif [ "$key" = "a" ] || [ "$key" = "A" ]; then
        echo "ALL"
    elif [ "$key" = "n" ] || [ "$key" = "N" ]; then
        echo "NONE"
    elif [ "$key" = "q" ] || [ "$key" = "Q" ]; then
        echo "QUIT"
    elif [ "$key" = "$(printf '\n')" ] || [ "$key" = "$(printf '\r')" ]; then
        echo "ENTER"
    else
        echo "OTHER"
    fi
}

read_user_input() {
    local saved
    saved=$(stty -g 2>/dev/null)

    stty echo icanon 2>/dev/null
    read -r "$@"
    local ret=$?

    [ -n "$saved" ] && stty "$saved" 2>/dev/null
    return $ret
}

ui_input() {
    local prompt="$1" default="$2"

    printf '%b\n' "${YELLOW}${prompt}${RESET}" >&2
    printf '%b\n' "${GRAY}   默认: ${default}${RESET}" >&2
    printf '%b' "${PINK}   > ${RESET}" >&2

    local saved
    saved=$(stty -g 2>/dev/null)

    stty echo icanon 2>/dev/null

    local ans
    read -r ans

    [ -n "$saved" ] && stty "$saved" 2>/dev/null

    if [ -z "$ans" ]; then
        printf '%s\n' "$default"
    else
        printf '%s\n' "$ans"
    fi
}

# ---------- 箭头菜单 ----------
MENU_INDEX=0
MENU_INDEX=0
arrow_menu() {
    local title="$1"
    shift
    local items=("$@")
    local count=${#items[@]}
    MENU_INDEX=0

    local menu_stty
    menu_stty=$(stty -g 2>/dev/null)
    stty -echo -icanon min 1 time 0 2>/dev/null

    while true; do
        show_ui
        printf '%b\n' "${GOLD}${BOLD}${title}${RESET}" ""

        local i=0
        while [ "$i" -lt "$count" ]; do
            if [ "$i" -eq "$MENU_INDEX" ]; then
                printf '%b\n' "   ${BG_SELECT}${FG_SELECT}${BOLD} ▶ ${items[$i]}  ${RESET}"
            else
                printf '%b\n' "     ${GRAY}${items[$i]}${RESET}"
            fi
            i=$((i + 1))
        done

        printf '%b\n' "" "${BLUE}${LINE}${RESET}" "" \
            "${GRAY}   ↑/↓ 移动   Enter 确认   q 退出${RESET}" ""

        local key
        key=$(read_key)
        case "$key" in
            UP)   MENU_INDEX=$((MENU_INDEX - 1)); [ "$MENU_INDEX" -lt 0 ] && MENU_INDEX=$((count - 1)) ;;
            DOWN) MENU_INDEX=$((MENU_INDEX + 1)); [ "$MENU_INDEX" -ge "$count" ] && MENU_INDEX=0 ;;
            ENTER)
                [ -n "$menu_stty" ] && stty "$menu_stty" 2>/dev/null
                return 0
                ;;
            QUIT)
                [ -n "$menu_stty" ] && stty "$menu_stty" 2>/dev/null
                MENU_INDEX=-1
                return 1
                ;;
        esac
    done
}

# ---------- 自动扫描打包文件 ----------
auto_scan_pack_files() {
    local list=""

    for f in module.prop customize.sh post-fs-data.sh post-mount.sh \
             service.sh uninstall.sh; do
        [ -f "$ROOT/$f" ] && list="$list $f"
    done

    for d in bin webroot system payload; do
        if [ -d "$ROOT/$d" ]; then
            list="$list $(cd "$ROOT" && find "$d" -type f)"
        fi
    done

    echo "$list"
}

# ---------- 文件检查 ----------
check_files() {
    local list="$1"
    local missing=0

    for f in $list; do
        if [ ! -f "$ROOT/$f" ]; then
            fish_error "缺少文件: $f"
            missing=$((missing + 1))
        fi
    done

    if [ "$missing" -gt 0 ]; then
        return 1
    fi
    fish_success "所有文件齐全"
    return 0
}

# ---------- 打包单个变体 ----------
build_one() {
    local variant="$1"
    local brand="$2"
    local keep_anim="$3"
    local file_list="$4"

    local tmp="$ROOT/.build-tmp-$variant"
    local out_zip="$DIST/${MODULE_ID}-${variant}-${STAMP}.zip"

    rm -rf "$tmp"
    mkdir -p "$tmp"

    # 复制所有要打包的文件
    for f in $file_list; do
        local dst_dir="$tmp/$(dirname "$f")"
        mkdir -p "$dst_dir"
        cp -fp "$ROOT/$f" "$tmp/$f"
    done

    # 变体品牌
    if [ -n "$brand" ] && [ -d "$tmp/payload" ]; then
        printf '%b' "$brand" > "$tmp/payload/.brand"
    fi

    # 变体资源
    if [ -n "$keep_anim" ] && [ -f "$ROOT/$keep_anim" ]; then
        mkdir -p "$tmp/payload"
        local anim_name=$(basename "$keep_anim")
        if ! ln -f "$ROOT/$keep_anim" "$tmp/payload/$anim_name" 2>/dev/null; then
            cp -fp "$ROOT/$keep_anim" "$tmp/payload/"
        fi
    fi

    # 权限
    find "$tmp" -name "*.sh" -exec chmod 0755 {} \; 2>/dev/null
    find "$tmp" -name "*.prop" -exec chmod 0644 {} \; 2>/dev/null

    # 打包
    ( cd "$tmp" && zip -rq "$out_zip" . -x ".*" -x "*/.*" 2>/dev/null )

    rm -rf "$tmp"

    if [ -f "$out_zip" ]; then
        echo "$out_zip"
        return 0
    fi
    return 1
}

# ---------- 打包流程 ----------
do_build() {
    local mode="$1"

    show_ui

    local out_dir
    out_dir=$(ui_input "🎯 输出目录（回车用默认，输入 N 可自定义）：" "$DIST")

    if [ "$out_dir" = "N" ] || [ "$out_dir" = "n" ]; then
        out_dir=$(ui_input "📁 请输入自定义输出路径：" "$DIST")
    fi

    if [ -e "$out_dir" ]; then
        if [ ! -d "$out_dir" ]; then
            fish_error "路径已存在但不是目录：$out_dir"
            printf '%b' "${GRAY}按回车键继续...${RESET}"; read_user_input _
            return 1
        fi
    else
        if ! mkdir -p "$out_dir" 2>/dev/null; then
            fish_error "无法创建目录：$out_dir"
            printf '%b' "${GRAY}按回车键继续...${RESET}"; read_user_input _
            return 1
        fi
    fi

    DIST="$out_dir"

    # 扫描要打包的文件
    local file_list=""
    if [ -n "$PACK_FILES" ]; then
        file_list="$PACK_FILES"
    else
        file_list=$(auto_scan_pack_files)
    fi

    if [ -z "$file_list" ]; then
        fish_error "没有找到可打包的文件"
        printf '%b' "${GRAY}按回车键继续...${RESET}"; read_user_input _
        return 1
    fi

    # 解析变体
    local variants=()
    if [ -n "$VARIANTS" ]; then
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            variants+=("$line")
        done <<< "$VARIANTS"
    fi

    printf '%b\n' "${PINK}🐟 准备打包${RESET}" ""
    printf '%b\n' "${GRAY}   模块: $MODULE_NAME ($MODULE_ID)${RESET}"
    printf '%b\n' "${GRAY}   版本: $MODULE_VERSION${RESET}"
    printf '%b\n' "${GRAY}   文件: $(echo "$file_list" | wc -w) 个${RESET}"
    if [ ${#variants[@]} -gt 0 ]; then
        printf '%b\n' "${GRAY}   变体: ${#variants[@]} 个${RESET}"
    fi
    printf '%b\n' "${GRAY}   输出: $DIST${RESET}" ""

    if ! confirm_installation; then
        fish_warn "取消打包"
        return 0
    fi

    printf '\n'
    print_line
    printf '\n'

    check_files "$file_list" || { printf '%b' "${GRAY}按回车键继续...${RESET}"; read_user_input _; return 1; }

    printf '\n'

    mkdir -p "$DIST"

    local results=()

    if [ ${#variants[@]} -eq 0 ]; then
        # 无变体，直接打一个包
        show_progress "正在打包..." 0
        local out=$(build_one "default" "" "" "$file_list")
        show_progress "正在打包..." 100
        printf '\n'
        if [ -n "$out" ] && [ -f "$out" ]; then
            results+=("$out")
        fi
    else
        # 多变体
        for v in "${variants[@]}"; do
            IFS=':' read -r vname vbrand vkeep <<< "$v"
            show_progress "正在打包 $vname..." 0
            local out=$(build_one "$vname" "$vbrand" "$vkeep" "$file_list")
            show_progress "正在打包 $vname..." 100
            printf '\n'
            if [ -n "$out" ] && [ -f "$out" ]; then
                results+=("$out")
            fi
        done
    fi

    print_line
    printf '\n'
    fish_success "打包完成！"
    printf '\n'

    for out in "${results[@]}"; do
        printf '%b\n' \
            "${GREEN}   ✅ $(basename "$out")${RESET}" \
            "${GRAY}      大小: $(du -h "$out" | cut -f1)${RESET}" ""
    done

    if [ ${#results[@]} -eq 0 ]; then
        fish_error "没有生成任何包"
    fi

    printf '%b\n' \
        "${CYAN}   📁 输出: $DIST${RESET}" "" \
        "${YELLOW}   💡 把 zip 传到手机，用 Magisk/KernelSU/APatch 刷入${RESET}" ""

    printf '%b' "${PINK}按回车键继续...${RESET}"
    read_user_input _
}

# ---------- 清理 ----------
do_clean() {
    show_ui
    printf '%b\n' \
        "${YELLOW}⚠️  将删除：${RESET}" \
        "${GRAY}   $DIST${RESET}" \
        "${GRAY}   $ROOT/.build-tmp*${RESET}" ""

    if confirm_installation; then
        rm -rf "$DIST" "$ROOT"/.build-tmp*
        fish_success "已清理"
    else
        fish_warn "取消"
    fi
    printf '\n'
    printf '%b' "${PINK}按回车键继续...${RESET}"
    read_user_input _
}

# ---------- 查看已有包 ----------
do_list() {
    show_ui

    if [ ! -d "$DIST" ]; then
        fish_warn "dist/ 目录不存在"
    else
        local files
        files=$(ls -1 "$DIST"/*.zip 2>/dev/null)
        if [ -z "$files" ]; then
            fish_warn "dist/ 为空"
        else
            fish_say "已有包："
            printf '\n'
            for f in $files; do
                printf '%b\n' \
                    "${GREEN}   📦 $(basename "$f")${RESET}" \
                    "${GRAY}      $(du -h "$f" | cut -f1)${RESET}"
            done
        fi
    fi
    printf '\n'
    printf '%b' "${PINK}按回车键继续...${RESET}"
    read_user_input _
}

# ---------- 检查文件 ----------
do_check() {
    show_ui
    fish_say "检查文件完整性..."
    printf '\n'

    local file_list=""
    if [ -n "$PACK_FILES" ]; then
        file_list="$PACK_FILES"
    else
        file_list=$(auto_scan_pack_files)
    fi

    if check_files "$file_list"; then
        printf '%b\n' "" "${YELLOW}📊 源码目录：${RESET}" "" \
            "${GRAY}   文件数: $(echo "$file_list" | wc -w) 个${RESET}" \
            "${GRAY}   总大小: $(du -sh "$ROOT" 2>/dev/null | cut -f1)${RESET}"
    fi
    printf '\n'
    printf '%b' "${PINK}按回车键继续...${RESET}"
    read_user_input _
}

# ---------- 主菜单 ----------

while true; do
    arrow_menu "✨ 请选择操作 (◕‿◕✿)" \
        "🚀 打包模块" \
        "🧹 清理 dist/ 和临时文件" \
        "📋 查看已有包" \
        "🔍 检查文件完整性" \
        "🚪 退出"

    case "$MENU_INDEX" in
        0) do_build "all" ;;
        1) do_clean ;;
        2) do_list ;;
        3) do_check ;;
        4|-1)
            stty "$_STTY_SAVED" 2>/dev/null
            printf '%b\n' "${PINK}🐟 再见啦～ (´｡• ω •｡\`) ♡${RESET}"
            exit 0
            ;;
    esac
done

stty "$_STTY_SAVED" 2>/dev/null