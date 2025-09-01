#!/bin/bash

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Git仓库敏感信息扫描工具 ===${NC}"
echo ""

# 检查是否安装了必要工具
check_tools() {
    if ! command -v trufflehog &> /dev/null; then
        echo -e "${YELLOW}TruffleHog未安装，正在安装...${NC}"
        # 根据系统选择安装方式
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install trufflehog
        else
            # Linux系统
            curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
        fi
    fi

    if ! command -v gitleaks &> /dev/null; then
        echo -e "${YELLOW}Gitleaks未安装，正在安装...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install gitleaks
        else
            # Linux系统
            wget https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_linux_x64 -O /usr/local/bin/gitleaks
            chmod +x /usr/local/bin/gitleaks
        fi
    fi
}

# 扫描所有分支
scan_all_branches() {
    echo -e "${GREEN}开始扫描所有分支...${NC}"
    echo ""

    # 获取所有分支
    branches=$(git branch -a | grep -E 'remotes/origin/' | sed 's/.*origin\///' | grep -v 'HEAD')

    # 创建结果目录
    mkdir -p scan_results
    timestamp=$(date +%Y%m%d_%H%M%S)

    # 使用TruffleHog扫描
    echo -e "${YELLOW}使用TruffleHog扫描...${NC}"
    trufflehog git file://. --json > "scan_results/trufflehog_${timestamp}.json" 2>/dev/null

    # 使用Gitleaks扫描
    echo -e "${YELLOW}使用Gitleaks扫描...${NC}"
    gitleaks detect --source . -v --report-path "scan_results/gitleaks_${timestamp}.json"

    # 分析结果
    echo ""
    echo -e "${GREEN}=== 扫描结果汇总 ===${NC}"

    # 解析TruffleHog结果
    if [ -f "scan_results/trufflehog_${timestamp}.json" ]; then
        secrets_count=$(grep -c "DetectorType" "scan_results/trufflehog_${timestamp}.json" 2>/dev/null || echo "0")
        echo -e "TruffleHog发现: ${RED}${secrets_count}${NC} 个潜在密钥"
    fi

    # 解析Gitleaks结果
    if [ -f "scan_results/gitleaks_${timestamp}.json" ]; then
        leaks_count=$(jq 'length' "scan_results/gitleaks_${timestamp}.json" 2>/dev/null || echo "0")
        echo -e "Gitleaks发现: ${RED}${leaks_count}${NC} 个潜在泄露"
    fi

    echo ""
    echo -e "${GREEN}详细结果保存在 scan_results/ 目录${NC}"
}

# 清理敏感信息（使用BFG Repo-Cleaner）
clean_secrets() {
    echo ""
    echo -e "${YELLOW}是否要清理发现的敏感信息？(y/n)${NC}"
    read -r answer

    if [[ "$answer" == "y" ]]; then
        echo -e "${GREEN}清理敏感信息需要使用BFG Repo-Cleaner${NC}"
        echo "建议步骤："
        echo "1. 备份仓库: git clone --mirror <repo-url> backup.git"
        echo "2. 下载BFG: wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar"
        echo "3. 创建敏感词列表文件 secrets.txt"
        echo "4. 运行清理: java -jar bfg.jar --replace-text secrets.txt <repo>"
        echo "5. 清理和推送: cd <repo> && git reflog expire --expire=now --all && git gc --prune=now --aggressive"
        echo ""
        echo -e "${RED}警告：这会重写Git历史，需要force push！${NC}"
    fi
}

# 自定义规则扫描
custom_scan() {
    echo ""
    echo -e "${GREEN}=== 自定义规则扫描 ===${NC}"

    # 常见的敏感信息模式
    patterns=(
        "api[_-]?key"
        "api[_-]?secret"
        "access[_-]?token"
        "auth[_-]?token"
        "private[_-]?key"
        "secret[_-]?key"
        "password"
        "passwd"
        "pwd"
        "credentials"
        "AKIA[0-9A-Z]{16}"  # AWS Access Key
        "sk_live_[0-9a-zA-Z]{24}"  # Stripe
        "ghp_[0-9a-zA-Z]{36}"  # GitHub Personal Token
        "ghs_[0-9a-zA-Z]{36}"  # GitHub Secret
    )

    echo "正在搜索以下模式："
    for pattern in "${patterns[@]}"; do
        echo "  - $pattern"
        count=$(git grep -i "$pattern" $(git rev-list --all) 2>/dev/null | wc -l)
        if [ "$count" -gt 0 ]; then
            echo -e "    ${RED}发现 $count 个匹配${NC}"
        fi
    done
}

# 主函数
main() {
    # 检查是否在git仓库中
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}错误：当前目录不是git仓库${NC}"
        exit 1
    fi

    check_tools
    scan_all_branches
    custom_scan
    clean_secrets
}

main "$@"