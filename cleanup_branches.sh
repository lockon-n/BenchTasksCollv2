#!/bin/bash

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}开始检测和清理所有分支中的指定文件/目录...${NC}"
echo "将删除以下内容："
echo "  - recorded_trajectories_v2/ 目录"
echo "  - global_preparation/accounts.md 文件"
echo "  - configs/ 目录"
echo ""

# 保存当前分支
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${YELLOW}当前分支: $CURRENT_BRANCH${NC}"
echo ""

# 获取所有分支（本地和远程）
BRANCHES=$(git branch -a | sed 's/^[* ]*//' | grep -v "HEAD" | sort -u)

# 统计信息
TOTAL_BRANCHES=0
MODIFIED_BRANCHES=0
DELETED_FILES=0

# 临时文件存储需要推送的分支
PUSH_BRANCHES=""

# 遍历所有分支
for BRANCH in $BRANCHES; do
    # 跳过远程分支引用（只处理本地分支）
    if [[ $BRANCH == remotes/* ]]; then
        # 获取对应的本地分支名
        LOCAL_BRANCH=${BRANCH#remotes/origin/}

        # 检查是否已有本地分支
        if ! git show-ref --verify --quiet refs/heads/$LOCAL_BRANCH; then
            echo -e "${YELLOW}创建本地分支: $LOCAL_BRANCH${NC}"
            git branch --track $LOCAL_BRANCH origin/$LOCAL_BRANCH 2>/dev/null || continue
        fi
        BRANCH=$LOCAL_BRANCH
    fi

    TOTAL_BRANCHES=$((TOTAL_BRANCHES + 1))
    echo -e "\n${GREEN}检查分支: $BRANCH${NC}"

    # 切换到分支
    git checkout $BRANCH --quiet 2>/dev/null || {
        echo -e "${RED}无法切换到分支 $BRANCH，跳过${NC}"
        continue
    }

    # 标记是否有修改
    HAS_CHANGES=false

    # 检查并删除 recorded_trajectories_v2 目录
    if [ -d "recorded_trajectories_v2" ]; then
        echo "  删除目录: recorded_trajectories_v2/"
        git rm -rf recorded_trajectories_v2 2>/dev/null
        HAS_CHANGES=true
        DELETED_FILES=$((DELETED_FILES + 1))
    fi

    # 检查并删除 global_preparation/accounts.md 文件
    if [ -f "global_preparation/accounts.md" ]; then
        echo "  删除文件: global_preparation/accounts.md"
        git rm -f global_preparation/accounts.md 2>/dev/null
        HAS_CHANGES=true
        DELETED_FILES=$((DELETED_FILES + 1))
    fi

    # 检查并删除 configs 目录
    if [ -d "configs" ]; then
        echo "  删除目录: configs/"
        git rm -rf configs 2>/dev/null
        HAS_CHANGES=true
        DELETED_FILES=$((DELETED_FILES + 1))
    fi

    # 如果有修改，提交更改
    if [ "$HAS_CHANGES" = true ]; then
        git commit -m "清理: 删除 recorded_trajectories_v2/, global_preparation/accounts.md 和 configs/" --quiet
        echo -e "  ${GREEN}✓ 已提交更改${NC}"
        MODIFIED_BRANCHES=$((MODIFIED_BRANCHES + 1))
        PUSH_BRANCHES="$PUSH_BRANCHES $BRANCH"
    else
        echo "  没有需要删除的文件"
    fi
done

# 切换回原始分支
echo -e "\n${YELLOW}切换回原始分支: $CURRENT_BRANCH${NC}"
git checkout $CURRENT_BRANCH --quiet

# 显示统计信息
echo -e "\n${GREEN}========== 清理完成 ==========${NC}"
echo "检查的分支数: $TOTAL_BRANCHES"
echo "修改的分支数: $MODIFIED_BRANCHES"
echo "删除的文件/目录数: $DELETED_FILES"

# 询问是否推送到远程
if [ ! -z "$PUSH_BRANCHES" ]; then
    echo -e "\n${YELLOW}以下分支有修改:${NC}"
    for BRANCH in $PUSH_BRANCHES; do
        echo "  - $BRANCH"
    done

    echo -e "\n${YELLOW}是否推送所有修改到远程仓库? (y/n)${NC}"
    read -r PUSH_CONFIRM

    if [[ $PUSH_CONFIRM == "y" || $PUSH_CONFIRM == "Y" ]]; then
        for BRANCH in $PUSH_BRANCHES; do
            echo -e "${GREEN}推送分支: $BRANCH${NC}"
            git push origin $BRANCH
        done
        echo -e "${GREEN}所有修改已推送到远程仓库${NC}"
    else
        echo -e "${YELLOW}跳过推送，修改仅保存在本地${NC}"
        echo "稍后可以使用以下命令推送："
        for BRANCH in $PUSH_BRANCHES; do
            echo "  git push origin $BRANCH"
        done
    fi
fi