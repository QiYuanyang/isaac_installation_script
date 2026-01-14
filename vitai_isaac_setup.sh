#!/bin/bash

# ==============================================================================
# Isaac Sim & Isaac Lab 自动化安装脚本
# 版本: 1.0
# 创建日期: 2025-09-23
# 描述: 自动安装 Isaac Sim 5.0.0 和 Isaac Lab 2.2.1
# ==============================================================================

set -e  # 遇到错误时退出
# 注释掉 set -u 避免 Isaac Sim 脚本中未定义变量导致的问题
# set -u  # 使用未定义变量时退出

# ==============================================================================
# 配置变量
# ==============================================================================

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 默认配置
ISAACSIM_PATH=""
ISAACSIM_VERSION=""
ISAACSIM_PYTHON_EXE=""
ISAACSIM_IS_VALID=false
ISAACLAB_PATH=""
ISAACLAB_VERSION=""
CONDA_ENV_NAME=""

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ==============================================================================
# Logo显示函数
# ==============================================================================

show_logo() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║  ██╗   ██╗██╗████████╗ █████╗ ██╗                             ║"
    echo "║  ██║   ██║██║╚══██╔══╝██╔══██╗██║                             ║"
    echo "║  ██║   ██║██║   ██║   ███████║██║                             ║"
    echo "║  ╚██╗ ██╔╝██║   ██║   ██╔══██║██║                             ║"
    echo "║   ╚████╔╝ ██║   ██║   ██║  ██║██║                             ║"
    echo "║    ╚═══╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝                             ║"
    echo "║                                                                ║"
    echo -e "║${NC}${PURPLE}${BOLD}    Isaac Sim / Isaac Lab 一键安装脚本${NC}${CYAN}${BOLD}                    ║"
    echo "║                                                                ║"
    echo -e "║${NC}${GREEN}    🚀 自动化部署 NVIDIA Isaac 仿真环境${NC}${CYAN}${BOLD}                   ║"
    echo -e "║${NC}${YELLOW}    🔧 支持 Isaac Sim 4.x / 5.x 版本${NC}${CYAN}${BOLD}                    ║"
    echo -e "║${NC}${BLUE}    📦 集成 Isaac Lab 2.x 机器人学习框架${NC}${CYAN}${BOLD}                ║"
    echo "║                                                                ║"
    echo -e "║${NC}    版本: v1.0  |  创建: 2025-09-23  |  作者: ViTai Team${CYAN}${BOLD}    ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    # 显示系统信息
    echo -e "${BLUE}┌─ 系统信息 ─────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC} 🖥️  操作系统: $(lsb_release -d 2>/dev/null | cut -f2 || echo "$(uname -s) $(uname -r)")"
    echo -e "${BLUE}│${NC} 📁 脚本位置: $SCRIPT_DIR"
    echo -e "${BLUE}│${NC} 👤 当前用户: $USER"
    echo -e "${BLUE}│${NC} 🕒 运行时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # 等待用户确认
    while true; do
        log_prompt "是否继续进行安装? [y/n]: "
        read -r response
        
        case $response in
            [Yy]*|"")
                echo ""
                log_success "用户确认开始安装..."
                return 0
                ;;
            [Nn]*)
                echo ""
                log_warning "用户选择退出安装"
                echo ""
                echo -e "${YELLOW}┌─ 感谢使用 ViTai Isaac 安装脚本   ─┐${NC}"
                echo -e "${YELLOW}│                                │${NC}"
                echo -e "${YELLOW}│  👋 再见！                      │${NC}"
                echo -e "${YELLOW}│  📧 支持: support@vit.ai        │${NC}"
                echo -e "${YELLOW}│                                │${NC}"
                echo -e "${YELLOW}└────────────────────────────────┘${NC}"
                echo ""
                exit 0
                ;;
            *)
                log_warning "请输入 Y (继续) 或 N (退出)"
                ;;
        esac
    done
}

# ==============================================================================
# 日志函数
# ==============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_prompt() {
    echo -e "${CYAN}[PROMPT]${NC} $1"
}

# ==============================================================================
# Isaac Sim 安装地址及版本确认
# ==============================================================================
get_isaac_sim_dir(){
    echo ""
    log_info "获取isaac sim安装地址及版本信息......"
    echo ""
    
    # 先检测isaacsim的安装目录是否在脚本所在目录中，文件名中一般包含isaac sim这两个词
    local isaac_sim_dirs=()
    
    while IFS= read -r -d '' dir; do
        local dirname=$(basename "$dir")
        if [[ "$dirname" =~ [Ii]saac.*[Ss]im|[Ss]im.*[Ii]saac|isaacsim ]]; then
            isaac_sim_dirs+=("$dirname")
        fi
    done < <(find "$SCRIPT_DIR" -maxdepth 1 -type d -print0 2>/dev/null)
    
    # 输出找到的Isaac Sim目录路径
    if [[ ${#isaac_sim_dirs[@]} -gt 0 ]]; then
        log_info "找到以下Isaac Sim目录："
        for i in "${!isaac_sim_dirs[@]}"; do
            echo "  $((i+1)). ${isaac_sim_dirs[$i]} -> $SCRIPT_DIR/${isaac_sim_dirs[$i]}"
        done
        
        # 自动选择第一个目录
        ISAACSIM_PATH="$SCRIPT_DIR/${isaac_sim_dirs[0]}"
        log_success "自动选择目录: ${isaac_sim_dirs[0]}"
        
        return 0
    else
        log_warning "未找到Isaac Sim目录"
        
        # 手动输入路径
        while true; do
            log_prompt "请输入Isaac Sim的完整路径: "
            read -r manual_path
            
            # 去除路径两端的引号和空格
            manual_path=$(echo "$manual_path" | sed 's/^["'"'"']\|["'"'"']$//g' | xargs)
            
            if [[ -z "$manual_path" ]]; then
                log_warning "路径不能为空，请重新输入"
                continue
            fi
            
            # 展开波浪号
            manual_path="${manual_path/#\~/$HOME}"
            
            # 检查目录是否存在
            if [[ ! -d "$manual_path" ]]; then
                log_error "目录不存在: $manual_path"
                continue
            fi
            
            # 转换为绝对路径
            ISAACSIM_PATH=$(cd "$manual_path" && pwd)
            log_success "设置ISAACSIM_PATH为 $ISAACSIM_PATH 成功"
            return 0
        done
    fi
}

get_isaac_sim_version(){
    # 根据获得的ISAAC_SIM_PATH 获取版本信息
    echo ""
    log_info "正在检测Isaac Sim版本信息..."
    
    # 方法1: 从VERSION文件读取
    if [[ -f "$ISAACSIM_PATH/VERSION" ]]; then
        ISAACSIM_VERSION=$(cat "$ISAACSIM_PATH/VERSION" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [[ -n "$ISAACSIM_VERSION" ]]; then
            log_success "从VERSION文件读取到版本: $ISAACSIM_VERSION"
            return 0
        fi
    fi
    
    # 方法2: 从目录名推断
    local dirname=$(basename "$ISAACSIM_PATH")
    if [[ "$dirname" =~ isaacsim([0-9]+) ]]; then
        case "${BASH_REMATCH[1]}" in
            "50") ISAACSIM_VERSION="5.0.0" ;;
            "41") ISAACSIM_VERSION="4.1.0" ;;
            "40") ISAACSIM_VERSION="4.0.0" ;;
            *) ISAACSIM_VERSION="${BASH_REMATCH[1]}.x.x" ;;
        esac
        log_success "从目录名推断版本: $ISAACSIM_VERSION"
        return 0
    fi
    
    # 如果都没找到，设置为未知版本
    ISAACSIM_VERSION="未知版本"
    log_warning "无法检测版本，设置为: $ISAACSIM_VERSION"
}

get_isaac_sim_exe_path(){
    local isaac_sim_exe_path="$ISAACSIM_PATH/python.sh"
    # 检查isaac_sim_exe_path是否存在，如果存在就赋值给ISAAC_SIM_EXE_PATH 否则报错
    if [[ -f "$isaac_sim_exe_path" ]]; then
        ISAACSIM_PYTHON_EXE="$isaac_sim_exe_path"
        log_success "找到 Isaac Sim 可执行文件: $ISAACSIM_PYTHON_EXE"
    else
        log_error "未找到 Isaac Sim 可执行文件: $isaac_sim_exe_path"
        return 1
    fi
}

test_isaac_sim(){
    echo ""
    log_info "正在测试 Isaac Sim 是否可以正常运行..."
    
    # 检查 ISAACSIM_PYTHON_EXE 是否已设置
    if [[ -z "$ISAACSIM_PYTHON_EXE" ]]; then
        log_error "ISAACSIM_PYTHON_EXE 未设置"
        ISAACSIM_IS_VALID=false
        return 1
    fi
    
    # 尝试运行测试命令
    if ${ISAACSIM_PYTHON_EXE} -c "print('Isaac Sim configuration is now complete.')" >/dev/null 2>&1; then
        log_success "Isaac Sim 测试成功！"
        ISAACSIM_IS_VALID=true
        return 0
    else
        log_error "Isaac Sim 测试失败！"
        ISAACSIM_IS_VALID=false
        return 1
    fi
}

# ==============================================================================
# Isaac Lab 
# ==============================================================================
get_isaac_lab_path(){
    # 获取当前目录下的isaaclab代码
    echo ""
    log_info "获取Isaac Lab安装地址......"
    echo ""
    
    local isaac_lab_dirs=()
    while IFS= read -r -d '' dir; do
        local dirname=$(basename "$dir")
        if [[ "$dirname" =~ [Ii]saac.*[Ll]ab|[Ll]ab.*[Ii]saac|isaaclab ]]; then
            isaac_lab_dirs+=("$dirname")
        fi
    done < <(find "$SCRIPT_DIR" -maxdepth 1 -type d -print0 2>/dev/null)
    
    # 输出找到的Isaac lab目录路径
    if [[ ${#isaac_lab_dirs[@]} -gt 0 ]]; then
        log_info "找到以下Isaac Lab目录："
        for i in "${!isaac_lab_dirs[@]}"; do
            echo "  $((i+1)). ${isaac_lab_dirs[$i]} -> $SCRIPT_DIR/${isaac_lab_dirs[$i]}"
        done
        
        # 自动选择第一个目录
        ISAACLAB_PATH="$SCRIPT_DIR/${isaac_lab_dirs[0]}"
        log_success "自动选择目录: ${isaac_lab_dirs[0]}"
    else
        log_info "未找到Isaac Lab目录"
        ISAACLAB_PATH=""
    fi
}

get_isaac_lab_version(){
    # 获取isaaclab_path后，获取版本信息
    if [[ -f "$ISAACLAB_PATH/VERSION" ]]; then
        ISAACLAB_VERSION=$(cat "$ISAACLAB_PATH/VERSION" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [[ -n "$ISAACLAB_VERSION" ]]; then
            log_success "检测到Isaac Lab版本: $ISAACLAB_VERSION"
            return 0
        fi
    fi
    
    # 从目录名推断版本
    local dirname=$(basename "$ISAACLAB_PATH")
    if [[ "$dirname" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        ISAACLAB_VERSION="${BASH_REMATCH[1]}"
        log_success "从目录名推断版本: $ISAACLAB_VERSION"
        return 0
    fi
    
    ISAACLAB_VERSION="未知版本"
    log_warning "无法检测Isaac Lab版本"
}

# ==============================================================================
# Python版本检测
# ==============================================================================
detect_expected_python_version(){
    echo ""
    log_info "检测Isaac Sim版本以确定Python版本..."
    
    # 检查Isaac Sim版本
    if [[ -z "$ISAACSIM_VERSION" ]]; then
        log_warning "Isaac Sim版本未知，将由Isaac Lab自动选择Python版本"
        return 0
    fi
    
    # 解析主版本号和次版本号
    local major_version minor_version
    if [[ "$ISAACSIM_VERSION" =~ ^([0-9]+)\.([0-9]+) ]]; then
        major_version="${BASH_REMATCH[1]}"
        minor_version="${BASH_REMATCH[2]}"
    else
        log_warning "无法解析Isaac Sim版本: $ISAACSIM_VERSION"
        return 0
    fi
    
    # 根据版本确定Python版本
    local expected_python_version
    if [[ $major_version -eq 4 && $minor_version -eq 5 ]]; then
        expected_python_version="3.10"
        log_info "检测到 Isaac Sim 4.5.x → Isaac Lab将自动安装 Python 3.10"
    elif [[ $major_version -ge 5 ]] || [[ $major_version -eq 4 && $minor_version -gt 5 ]]; then
        expected_python_version="3.11"
        log_info "检测到 Isaac Sim ${major_version}.${minor_version} → Isaac Lab将自动安装 Python 3.11"
    else
        expected_python_version="未知"
        log_warning "Isaac Sim版本 $ISAACSIM_VERSION 可能不受支持"
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📋 Python版本选择说明${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "Isaac Sim版本: $ISAACSIM_VERSION"
    echo "预期Python版本: $expected_python_version"
    echo ""
    echo "Isaac Lab会根据Isaac Sim版本自动选择Python版本:"
    echo "  • Isaac Sim 4.5.x  → Python 3.10"
    echo "  • Isaac Sim ≥ 5.0  → Python 3.11"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    return 0
}

create_isaac_sim_symbolic_link(){
    echo ""
    log_info "创建Isaac Sim符号链接..."
    
    if [[ -z "$ISAACLAB_PATH" ]]; then
        log_error "Isaac Lab路径未设置"
        return 1
    fi
    
    local isaac_sim_link="$ISAACLAB_PATH/_isaac_sim"
    
    # 如果符号链接已存在，先删除
    if [[ -L "$isaac_sim_link" ]]; then
        log_info "删除现有符号链接..."
        rm "$isaac_sim_link"
    fi
    
    # 创建符号链接
    log_info "创建符号链接: $isaac_sim_link -> $ISAACSIM_PATH"
    ln -s "$ISAACSIM_PATH" "$isaac_sim_link"
    
    if [[ -L "$isaac_sim_link" ]]; then
        log_success "符号链接创建成功"
    else
        log_error "符号链接创建失败"
        return 1
    fi
}

set_conda_env_name(){
    # 用户输入conda env name，不输入默认env_isaaclab_test，检测所有conda env里是否有重名的env，已经有了的话提醒用户重新输入
    echo ""
    log_info "设置Conda环境名称..."
    
    # 默认环境名
    local default_env_name="env_isaaclab_test"
    local env_name=""
    
    # 检查conda是否可用
    if ! command -v conda >/dev/null 2>&1; then
        log_error "未找到Conda，请先安装Conda"
        return 1
    fi
    
    # 获取现有conda环境列表
    local existing_envs=$(conda env list | awk '{print $1}' | grep -v '^#' | grep -v '^$' | grep -v 'base' 2>/dev/null || true)
    
    echo ""
    if [[ -n "$existing_envs" ]]; then
        log_info "现有Conda环境："
        echo "$existing_envs" | while read -r env; do
            echo "  - $env"
        done
        echo ""
    fi
    
    while true; do
        log_prompt "请输入Conda环境名称 [默认: $default_env_name]: "
        read -r env_name
        
        # 如果用户没有输入，使用默认值
        if [[ -z "$env_name" ]]; then
            env_name="$default_env_name"
        fi
        
        # 验证环境名称格式（只允许字母、数字、下划线、连字符）
        if [[ ! "$env_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            log_warning "环境名称只能包含字母、数字、下划线和连字符，请重新输入"
            continue
        fi
        
        # 检查环境是否已存在
        if conda env list | grep -q "^$env_name " 2>/dev/null; then
            log_warning "Conda环境 '$env_name' 已存在"
            echo ""
            log_prompt "请选择操作："
            echo "  1) 删除现有环境并重新创建"
            echo "  2) 重新输入环境名称"
            echo "  3) 退出"
            echo ""
            log_prompt "请输入选择 [1/2/3]: "
            read -r choice
            
            case $choice in
                1)
                    log_info "删除现有环境 '$env_name'..."
                    if conda env remove -n "$env_name" -y; then
                        log_success "环境 '$env_name' 删除成功"
                        break
                    else
                        log_error "删除环境失败，请重新选择"
                        continue
                    fi
                    ;;
                2)
                    log_info "请重新输入环境名称"
                    continue
                    ;;
                3)
                    log_warning "用户选择退出"
                    return 1
                    ;;
                *)
                    log_warning "无效选择，请输入 1、2 或 3"
                    continue
                    ;;
            esac
        else
            # 环境名称可用
            break
        fi
    done
    
    # 设置全局变量
    CONDA_ENV_NAME="$env_name"
    
    echo ""
    log_success "Conda环境名称设置为: $CONDA_ENV_NAME"
    echo ""
    
    return 0
}

setup_conda_env(){
    # 根据tutorial里面设置conda环境
    echo ""
    log_info "根据官方教程设置Conda环境..."
    
    # 检查Isaac Lab路径是否存在
    if [[ -z "$ISAACLAB_PATH" ]]; then
        log_error "Isaac Lab路径未设置"
        return 1
    fi
    
    if [[ ! -d "$ISAACLAB_PATH" ]]; then
        log_error "Isaac Lab目录不存在: $ISAACLAB_PATH"
        return 1
    fi
    
    # 检查Conda环境名称是否已设置
    if [[ -z "$CONDA_ENV_NAME" ]]; then
        log_error "Conda环境名称未设置"
        return 1
    fi
    
    # 进入Isaac Lab目录
    log_info "进入Isaac Lab目录: $ISAACLAB_PATH"
    cd "$ISAACLAB_PATH" || {
        log_error "无法进入目录: $ISAACLAB_PATH"
        return 1
    }
    
    # 检查isaaclab.sh脚本是否存在
    if [[ ! -f "./isaaclab.sh" ]]; then
        log_error "未找到 isaaclab.sh 脚本"
        return 1
    fi
    
    # 确保脚本有执行权限
    if [[ ! -x "./isaaclab.sh" ]]; then
        log_info "添加执行权限到 isaaclab.sh..."
        chmod +x "./isaaclab.sh"
    fi
    
    # 设置ISAACSIM_PATH环境变量（Isaac Lab需要）
    export ISAACSIM_PATH="$ISAACSIM_PATH"
    log_info "设置环境变量: ISAACSIM_PATH=$ISAACSIM_PATH"
    
    # 检测预期的Python版本
    detect_expected_python_version
    
    echo ""
    log_info "开始创建Conda环境..."
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📦 Isaac Lab Conda 环境安装${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "环境名称: $CONDA_ENV_NAME"
    echo "安装路径: $ISAACLAB_PATH"
    echo "Isaac Sim: $ISAACSIM_PATH ($ISAACSIM_VERSION)"
    echo "Python版本: 自动选择 (由Isaac Lab根据Isaac Sim版本决定)"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # 检查当前conda环境状态
    local current_conda_env="${CONDA_DEFAULT_ENV:-base}"
    local conda_shlvl="${CONDA_SHLVL:-0}"
    
    log_info "当前Conda状态检查:"
    echo "  - 当前环境: $current_conda_env"
    echo "  - Shell层级: $conda_shlvl"
    
    # 获取conda安装路径
    local conda_base=$(conda info --base 2>/dev/null)
    if [[ -z "$conda_base" ]]; then
        log_error "无法获取Conda安装路径"
        return 1
    fi
    
    # 加载conda环境
    log_info "加载Conda环境..."
    source "$conda_base/etc/profile.d/conda.sh"
    
    # 如果shell层级过深（>2），回到base环境
    if [[ $conda_shlvl -gt 2 ]]; then
        log_warning "Conda shell层级过深 ($conda_shlvl)，正在重置到base环境..."
        
        # 多次deactivate回到base
        while [[ ${CONDA_SHLVL:-0} -gt 1 ]]; do
            conda deactivate 2>/dev/null || break
        done
        
        # 确保在base环境
        conda activate base 2>/dev/null || true
        
        log_success "已重置到base环境"
    elif [[ "$current_conda_env" != "base" ]]; then
        log_info "切换到base环境..."
        conda activate base 2>/dev/null || true
    fi
    
    # 运行Isaac Lab安装脚本
    log_info "执行命令: ./isaaclab.sh --conda $CONDA_ENV_NAME"
    echo ""
    
    # 临时禁用严格模式，避免Isaac Sim脚本中的未定义变量问题
    set +u 2>/dev/null || true
    
    # 执行安装命令
    if ./isaaclab.sh --conda "$CONDA_ENV_NAME"; then
        echo ""
        log_success "Conda环境创建成功！"
        
        # 验证环境是否创建成功
        if conda env list | grep -q "^$CONDA_ENV_NAME "; then
            log_success "环境 '$CONDA_ENV_NAME' 验证成功"
            
            # 验证Python版本
            echo ""
            log_info "验证已安装的Python版本..."
            local installed_python_version
            installed_python_version=$(conda run -n "$CONDA_ENV_NAME" python --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
            if [[ -n "$installed_python_version" ]]; then
                log_success "已安装Python版本: $installed_python_version"
            else
                log_warning "无法检测Python版本"
            fi
            
            echo ""
            echo -e "${GREEN}✅ 环境创建完成！${NC}"
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}📋 使用方法:${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo "1. 激活环境:"
            echo "   conda activate $CONDA_ENV_NAME"
            echo ""
            echo "2. 进入Isaac Lab目录:"
            echo "   cd $ISAACLAB_PATH"
            echo ""
            echo "3. 运行示例 (环境激活后):"
            echo "   ./isaaclab.sh -p source/standalone/demos/quadrupeds.py"
            echo ""
            echo "4. 查看更多示例:"
            echo "   ls source/standalone/demos/"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            
        else
            log_warning "环境创建成功但验证失败"
        fi
        
        return 0
    else
        echo ""
        log_error "Conda环境创建失败！"
        
        echo ""
        echo -e "${RED}❌ 安装失败排查建议:${NC}"
        echo "1. 检查网络连接是否正常"
        echo "2. 检查磁盘空间是否充足"
        echo "3. 检查Conda是否正确安装"
        echo "4. 检查Isaac Sim路径是否正确"
        echo ""
        echo "手动安装命令:"
        echo "  cd $ISAACLAB_PATH"
        echo "  export ISAACSIM_PATH=$ISAACSIM_PATH"
        echo "  ./isaaclab.sh --conda $CONDA_ENV_NAME"
        echo ""
        
        return 1
    fi
}

# ==============================================================================
# IsaacLab 安装
# ==============================================================================
install_isaaclab(){
    echo ""
    log_info "开始安装Isaac Lab依赖和扩展..."
    log_info "请先将isaacsim和isaaclab的文件准备好放在当前脚本所在的文件夹，例如HOME/isaac/isaacsim 以及HOME/isaac/isaaclab"
    # 检查Isaac Lab路径是否存在
    if [[ -z "$ISAACLAB_PATH" ]]; then
        log_error "Isaac Lab路径未设置"
        return 1
    fi
    
    if [[ ! -d "$ISAACLAB_PATH" ]]; then
        log_error "Isaac Lab目录不存在: $ISAACLAB_PATH"
        return 1
    fi
    
    # 进入Isaac Lab目录
    log_info "进入Isaac Lab目录: $ISAACLAB_PATH"
    cd "$ISAACLAB_PATH" || {
        log_error "无法进入目录: $ISAACLAB_PATH"
        return 1
    }
    
    # 检查isaaclab.sh脚本是否存在
    if [[ ! -f "./isaaclab.sh" ]]; then
        log_error "未找到 isaaclab.sh 脚本"
        return 1
    fi
    
    # 确保脚本有执行权限
    if [[ ! -x "./isaaclab.sh" ]]; then
        log_info "添加执行权限到 isaaclab.sh..."
        chmod +x "./isaaclab.sh"
    fi
    
    # 检查Conda环境是否存在
    if [[ -z "$CONDA_ENV_NAME" ]]; then
        log_error "Conda环境名称未设置"
        return 1
    fi
    
    if ! conda env list | grep -q "^$CONDA_ENV_NAME "; then
        log_error "Conda环境 '$CONDA_ENV_NAME' 不存在，请先创建环境"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📦 Isaac Lab 依赖安装${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "环境名称: $CONDA_ENV_NAME"
    echo "安装路径: $ISAACLAB_PATH"
    echo "Isaac Sim: $ISAACSIM_PATH"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # 设置ISAACSIM_PATH环境变量
    export ISAACSIM_PATH="$ISAACSIM_PATH"
    log_info "设置环境变量: ISAACSIM_PATH=$ISAACSIM_PATH"
    
    # 步骤1: 安装系统依赖 (仅Linux)
    if [[ "$(uname)" == "Linux" ]]; then
        log_info "步骤1: 安装系统依赖..."
        echo ""
        log_info "安装cmake和build-essential依赖..."
        
        # 检查是否有sudo权限
        if sudo -n true 2>/dev/null; then
            # 有sudo权限，直接安装
            if sudo apt update && sudo apt install -y cmake build-essential; then
                log_success "系统依赖安装成功"
            else
                log_warning "系统依赖安装失败，但继续执行Isaac Lab安装"
            fi
        else
            # 没有sudo权限，提示用户
            log_warning "需要sudo权限安装系统依赖"
            echo ""
            echo "请手动运行以下命令安装系统依赖:"
            echo "  sudo apt update"
            echo "  sudo apt install cmake build-essential"
            echo ""
            log_prompt "是否已经安装了系统依赖? [y/N]: "
            read -r deps_installed
            case $deps_installed in
                [Yy]*)
                    log_info "用户确认已安装系统依赖，继续执行..."
                    ;;
                *)
                    log_error "需要先安装系统依赖才能继续"
                    return 1
                    ;;
            esac
        fi
    else
        log_info "非Linux系统，跳过apt依赖安装"
    fi
    
    echo ""
    log_info "步骤2: 激活Conda环境..."
    
    # 获取conda安装路径并激活环境
    local conda_base=$(conda info --base 2>/dev/null)
    if [[ -z "$conda_base" ]]; then
        log_error "无法获取Conda安装路径"
        return 1
    fi
    
    # 加载conda环境
    source "$conda_base/etc/profile.d/conda.sh"
    
    # 激活Isaac Lab环境
    log_info "激活Conda环境: $CONDA_ENV_NAME"
    if ! conda activate "$CONDA_ENV_NAME"; then
        log_error "无法激活Conda环境: $CONDA_ENV_NAME"
        return 1
    fi
    
    log_success "Conda环境激活成功"
    
    echo ""
    log_info "步骤3: 安装Isaac Lab扩展和依赖..."
    echo ""
    
    # 显示即将安装的内容
    log_info "即将安装的学习框架包括:"
    echo "  - rl_games (强化学习)"
    echo "  - rsl_rl (机器人学习)"
    echo "  - sb3 (Stable Baselines3)"
    echo "  - skrl (强化学习)"
    echo "  - robomimic (模仿学习)"
    echo ""
    
    # 执行Isaac Lab安装命令
    log_info "执行命令: ./isaaclab.sh --install"
    echo ""
    
    # 临时禁用严格模式
    set +u 2>/dev/null || true
    
    # 运行安装命令
    if ./isaaclab.sh --install; then
        echo ""
        log_success "Isaac Lab安装成功！"
        
        # 验证安装
        echo ""
        log_info "验证安装..."
        
        # 检查Python包是否正确安装
        if python -c "import omni.isaac.lab; print('Isaac Lab导入成功')" 2>/dev/null; then
            log_success "Isaac Lab Python包验证成功"
        else
            log_warning "Isaac Lab Python包验证失败，但安装可能仍然成功"
        fi
        
        echo ""
        echo -e "${GREEN}✅ Isaac Lab安装完成！${NC}"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}📋 使用说明:${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo "1. 激活环境:"
        echo "   conda activate $CONDA_ENV_NAME"
        echo ""
        echo "2. 进入Isaac Lab目录:"
        echo "   cd $ISAACLAB_PATH"
        echo ""
        echo "3. 运行基础示例:"
        echo "   ./isaaclab.sh -p source/standalone/demos/quadrupeds.py"
        echo ""
        echo "4. 运行强化学习训练:"
        echo "   ./isaaclab.sh -p source/standalone/workflows/rl_games/train.py --task Isaac-Cartpole-v0"
        echo ""
        echo "5. 查看所有示例:"
        echo "   ls source/standalone/demos/"
        echo "   ls source/standalone/workflows/"
        echo ""
        echo "6. 运行测试 (可选):"
        echo "   ./isaaclab.sh -p -m pytest source/extensions/omni.isaac.lab/test"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        return 0
    else
        echo ""
        log_error "Isaac Lab安装失败！"
        
        echo ""
        echo -e "${RED}❌ 安装失败排查建议:${NC}"
        echo "1. 检查网络连接是否正常"
        echo "2. 检查磁盘空间是否充足 (需要约15GB)"
        echo "3. 检查Conda环境是否正确"
        echo "4. 检查Isaac Sim路径是否正确"
        echo "5. 检查系统依赖是否已安装"
        echo ""
        echo "手动安装命令:"
        echo "  cd $ISAACLAB_PATH"
        echo "  conda activate $CONDA_ENV_NAME"
        echo "  export ISAACSIM_PATH=$ISAACSIM_PATH"
        echo "  ./isaaclab.sh --install"
        echo ""
        echo "如果是网络问题，可以尝试:"
        echo "  pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/"
        echo ""
        
        return 1
    fi
}

# ==============================================================================
# CUDA依赖处理
# ==============================================================================
clean_cuda(){
    echo ""
    log_info "检查和清理CUDA依赖..."
    
    # 检查Conda环境是否存在并激活
    if [[ -z "$CONDA_ENV_NAME" ]]; then
        log_error "Conda环境名称未设置，无法清理CUDA依赖"
        return 1
    fi
    
    if ! conda env list | grep -q "^$CONDA_ENV_NAME "; then
        log_error "Conda环境 '$CONDA_ENV_NAME' 不存在"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🔧 CUDA 依赖清理${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "环境名称: $CONDA_ENV_NAME"
    echo "问题: RuntimeError: nvrtc: error: invalid value for --gpu-architecture (-arch)"
    echo "解决方案: 升级CUDA 12.8并卸载过时的CUDA 11.8相关包"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # 获取conda安装路径并激活环境
    local conda_base=$(conda info --base 2>/dev/null)
    if [[ -z "$conda_base" ]]; then
        log_error "无法获取Conda安装路径"
        return 1
    fi
    
    # 加载conda环境
    source "$conda_base/etc/profile.d/conda.sh"
    
    # 激活Isaac Lab环境
    log_info "激活Conda环境: $CONDA_ENV_NAME"
    if ! conda activate "$CONDA_ENV_NAME"; then
        log_error "无法激活Conda环境: $CONDA_ENV_NAME"
        return 1
    fi
    
    log_success "Conda环境激活成功"
    
    echo ""
    log_info "步骤1: 检查当前CUDA包状态..."
    
    # 检查是否存在CUDA 11相关包
    log_info "检查CUDA相关包: pip list | grep -i cuda"
    local cuda_packages=$(pip list | grep -i cuda 2>/dev/null || true)
    
    if [[ -n "$cuda_packages" ]]; then
        echo ""
        log_info "找到以下CUDA相关包："
        echo "$cuda_packages"
        echo ""
        
        # 检查是否存在CUDA 11包
        local cuda11_packages=$(pip list | grep -i cuda | grep -E "(cu11|cuda-11)" 2>/dev/null || true)
        
        if [[ -n "$cuda11_packages" ]]; then
            log_warning "发现CUDA 11相关包，这可能导致架构兼容性问题"
            echo ""
            log_info "需要卸载的CUDA 11包："
            echo "$cuda11_packages"
            echo ""
            
            log_prompt "是否自动卸载这些CUDA 11包? [Y/n]: "
            read -r remove_cuda11
            
            case $remove_cuda11 in
                [Nn]*)
                    log_info "用户选择不自动卸载，将显示手动卸载命令"
                    ;;
                *)
                    log_info "步骤2: 卸载CUDA 11相关包..."
                    echo ""
                    
                    # 常见的需要卸载的CUDA 11包
                    local cuda11_package_names=(
                        "nvidia-cuda-cupti-cu11"
                        "nvidia-cuda-nvrtc-cu11" 
                        "nvidia-cuda-runtime-cu11"
                        "nvidia-cublas-cu11"
                        "nvidia-curand-cu11"
                        "nvidia-cusolver-cu11"
                        "nvidia-cusparse-cu11"
                        "nvidia-cufft-cu11"
                        "nvidia-cudnn-cu11"
                        "torch-tensorrt-cu11"
                    )
                    
                    # 卸载找到的CUDA 11包
                    for package in "${cuda11_package_names[@]}"; do
                        if pip list | grep -q "^$package "; then
                            log_info "卸载包: $package"
                            if pip uninstall "$package" -y; then
                                log_success "成功卸载: $package"
                            else
                                log_warning "卸载失败: $package"
                            fi
                        fi
                    done
                    
                    echo ""
                    log_success "CUDA 11包卸载完成"
                    ;;
            esac
        else
            log_success "未发现CUDA 11包，跳过卸载步骤"
        fi
    else
        log_info "未找到CUDA相关包"
    fi
    
    echo ""
    log_info "步骤3: 验证CUDA环境..."
    
    # 再次检查CUDA包状态
    local remaining_cuda=$(pip list | grep -i cuda 2>/dev/null || true)
    if [[ -n "$remaining_cuda" ]]; then
        echo ""
        log_info "清理后剩余的CUDA包："
        echo "$remaining_cuda"
        
        # 检查是否还有CUDA 11包
        local remaining_cuda11=$(pip list | grep -i cuda | grep -E "(cu11|cuda-11)" 2>/dev/null || true)
        if [[ -n "$remaining_cuda11" ]]; then
            log_warning "仍然存在CUDA 11包，可能需要手动处理"
            echo "$remaining_cuda11"
        else
            log_success "CUDA 11包已全部清理"
        fi
    else
        log_info "当前环境中无CUDA包"
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📋 手动清理命令参考:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "1. 激活环境:"
    echo "   conda activate $CONDA_ENV_NAME"
    echo ""
    echo "2. 检查CUDA包:"
    echo "   pip list | grep -i cuda"
    echo ""
    echo "3. 卸载CUDA 11包 (如果存在):"
    echo "   pip uninstall nvidia-cuda-cupti-cu11"
    echo "   pip uninstall nvidia-cuda-nvrtc-cu11"
    echo "   pip uninstall nvidia-cuda-runtime-cu11"
    echo ""
    echo "4. 重新安装Isaac Lab (如果需要):"
    echo "   cd $ISAACLAB_PATH"
    echo "   ./isaaclab.sh --install"
    echo ""
    echo "5. 测试非headless模式:"
    echo "   ./isaaclab.sh -p source/standalone/demos/quadrupeds.py"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    log_success "CUDA依赖清理完成"
    echo ""
    log_info "如果仍然遇到架构错误，请考虑："
    echo "  1. 检查系统CUDA版本: nvidia-smi"
    echo "  2. 更新显卡驱动"
    echo "  3. 重新安装Isaac Lab环境"
    echo ""
    
    return 0
}

# ==============================================================================
# 主函数
# ==============================================================================

main() {
    # 显示启动Logo
    show_logo
    
    log_info "🚀 开始 Isaac Sim 环境配置..."
    echo ""
    
    # Isaac Sim 目录确认
    log_info "第一步: 确认 Isaac Sim 安装目录"
    echo ""
    
    if ! get_isaac_sim_dir; then
        log_error "Isaac Sim 目录确认失败"
        exit 1
    fi
    get_isaac_sim_exe_path
    get_isaac_sim_version
    test_isaac_sim

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Isaac Sim 检测结果"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "Isaac Sim Path:     $ISAACSIM_PATH"
    log_info "Isaac Sim Version:  $ISAACSIM_VERSION"
    log_info "Isaac Sim Exe Path: $ISAACSIM_PYTHON_EXE"
    log_info "Isaac Sim Valid:    $ISAACSIM_IS_VALID"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ "$ISAACSIM_IS_VALID" != "true" ]]; then
        log_error "Isaac Sim setup went wrong, check sim install"
        exit 1
    fi

    get_isaac_lab_path
    get_isaac_lab_version
    
    echo ""
    log_info "Isaac Lab Path:     $ISAACLAB_PATH"
    log_info "Isaac Lab Version:  $ISAACLAB_VERSION"
    echo ""
    log_info "💡 Python版本将由Isaac Lab根据Isaac Sim版本自动选择"
    log_info "   Isaac Sim 4.5.x  → Python 3.10"
    log_info "   Isaac Sim ≥ 5.0  → Python 3.11"

    if [[ -n "$ISAACLAB_PATH" ]]; then
        create_isaac_sim_symbolic_link
        set_conda_env_name
        
        # 设置Conda环境
        log_info "第二步: 设置Isaac Lab Conda环境"
        if ! setup_conda_env; then
            log_error "Conda环境设置失败"
            exit 1
        fi
        
        # 安装Isaac Lab (可选)
        echo ""
        log_prompt "是否继续安装Isaac Lab依赖包? [Y/n]: "
        read -r install_deps_choice
        
        case $install_deps_choice in
            [Nn]*)
                log_info "跳过Isaac Lab依赖安装"
                ;;
            *)
                log_info "第三步: 安装Isaac Lab依赖和扩展"
                if ! install_isaaclab; then
                    log_warning "Isaac Lab依赖安装失败，但环境已创建"
                fi
                ;;
        esac
        
        # CUDA依赖清理 (可选)
        echo ""
        log_prompt "是否需要清理CUDA 11依赖以解决架构兼容性问题? [y/N]: "
        read -r clean_cuda_choice
        
        case $clean_cuda_choice in
            [Yy]*)
                log_info "第四步: 清理CUDA依赖"
                clean_cuda
                ;;
            *)
                log_info "跳过CUDA依赖清理"
                ;;
        esac
    else
        log_warning "未找到Isaac Lab，跳过Lab配置"
    fi
    
    echo ""
    log_success "🎉 Isaac Lab安装脚本执行完成！"
    echo ""
    echo -e "${GREEN}恭喜！您已成功完成Isaac Lab环境配置${NC}"
    if [[ -n "$CONDA_ENV_NAME" ]]; then
        echo -e "${CYAN}请运行以下命令开始使用Isaac Lab：${NC}"
        echo -e "${CYAN}conda activate $CONDA_ENV_NAME${NC}"
        echo -e "${CYAN}cd $ISAACLAB_PATH${NC}"
        echo -e "${CYAN}./isaaclab.sh -p source/standalone/demos/quadrupeds.py${NC}"
    fi
    echo ""
    
    # 最终提示
    echo -e "${YELLOW}💡 如果遇到以下错误:${NC}"
    echo -e "${RED}RuntimeError: nvrtc: error: invalid value for --gpu-architecture (-arch)${NC}"
    echo -e "${YELLOW}请重新运行此脚本并选择清理CUDA依赖选项${NC}"
    echo ""
}

# ==============================================================================
# 脚本入口
# ==============================================================================

# 检查是否为 root 用户
if [[ $EUID -eq 0 ]]; then
    log_error "请不要以 root 用户运行此脚本"
    exit 1
fi

# 显示帮助信息
if [[ $# -gt 0 && ("$1" == "-h" || "$1" == "--help") ]]; then
    echo "ViTai Isaac Sim & Isaac Lab 一键安装脚本"
    echo ""
    echo "用法: $0"
    echo ""
    echo "功能:"
    echo "  - 自动检测 Isaac Sim 安装目录"
    echo "  - 版本识别和确认"
    echo "  - Isaac Lab Conda环境创建"
    echo "  - 依赖包安装"
    echo "  - CUDA兼容性问题修复"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    exit 0
fi

# 运行主函数
main "$@"