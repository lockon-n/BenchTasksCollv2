#!/bin/bash

# 创建任务的辅助函数
create_task() {
    local task_dir="$1"
    local task_name="$2"
    local is_complete="$3"

    mkdir -p "$task_dir/docs"
    mkdir -p "$task_dir/initial_workspace"
    mkdir -p "$task_dir/evaluation"

    echo "Task: $task_name" > "$task_dir/docs/task.md"

    if [ "$is_complete" = "true" ]; then
        echo "def check():" > "$task_dir/evaluation/check_local.py"
        echo "    # Evaluation logic for $task_name" >> "$task_dir/evaluation/check_local.py"
        echo "    return True" >> "$task_dir/evaluation/check_local.py"

        echo "Sample data for $task_name" > "$task_dir/initial_workspace/data.txt"
    else
        # 不完整的任务缺少一些文件
        if [ $((RANDOM % 2)) -eq 0 ]; then
            echo "Incomplete task - missing evaluation" > "$task_dir/README.md"
        else
            rm -rf "$task_dir/initial_workspace"
            echo "def check(): return False" > "$task_dir/evaluation/check_local.py"
        fi
    fi
}

# 分支配置
declare -A branches
branches["ruige"]="ruige@mcp.com:8:3:2025-09-02 10:30:00,2025-09-04 15:20:00,2025-09-06 09:10:00"
branches["weihao-dev"]="weihao@mcp.com:9:4:2025-09-03 11:15:00,2025-09-05 14:30:00,2025-09-07 16:45:00,2025-09-09 10:00:00"
branches["wenshuo-dev"]="wenshuo@mcp.com:7:3:2025-09-02 14:00:00,2025-09-05 10:30:00,2025-09-08 11:20:00"
branches["xiaochen_dev"]="xiaochen@mcp.com:10:4:2025-09-03 09:00:00,2025-09-04 13:15:00,2025-09-06 15:30:00,2025-09-08 10:45:00"
branches["yuxuan-dev"]="yuxuan@mcp.com:8:3:2025-09-02 16:30:00,2025-09-05 11:00:00,2025-09-07 14:15:00"
branches["yuzhen-dev"]="yuzhen@mcp.com:9:4:2025-09-03 10:00:00,2025-09-04 16:20:00,2025-09-06 11:30:00,2025-09-09 09:15:00"
branches["zhaochen"]="zhaochen@mcp.com:7:3:2025-09-02 13:45:00,2025-09-05 09:30:00,2025-09-08 15:00:00"
branches["junteng_dev"]="junteng@mcp.com:10:4:2025-09-03 14:30:00,2025-09-05 16:00:00,2025-09-07 10:20:00,2025-09-09 11:45:00"
branches["junxian_dev"]="junxian@mcp.com:8:3:2025-09-02 11:00:00,2025-09-04 14:45:00,2025-09-07 09:30:00"
branches["lv"]="lv@mcp.com:9:3:2025-09-03 15:20:00,2025-09-06 10:00:00,2025-09-08 13:45:00"
branches["haoze"]="haoze@mcp.com:7:3:2025-09-02 15:00:00,2025-09-05 13:20:00,2025-09-08 09:00:00"
branches["fan-dev"]="fan@mcp.com:8:4:2025-09-03 11:30:00,2025-09-04 17:00:00,2025-09-06 14:15:00,2025-09-09 10:30:00"
branches["gyy"]="gyy@mcp.com:9:3:2025-09-02 12:15:00,2025-09-05 15:45:00,2025-09-07 11:00:00"
branches["lueyang-dev"]="lueyang@mcp.com:10:4:2025-09-03 13:00:00,2025-09-05 10:15:00,2025-09-07 15:30:00,2025-09-09 14:00:00"

# 任务名称池
task_names=(
    "data-processor"
    "email-analyzer"
    "pdf-generator"
    "canvas-assistant"
    "report-builder"
    "file-organizer"
    "web-scraper"
    "log-parser"
    "api-connector"
    "db-migrator"
    "test-runner"
    "code-formatter"
    "doc-generator"
    "cache-manager"
    "auth-validator"
    "metric-collector"
    "backup-tool"
    "config-loader"
    "scheduler-task"
    "notification-sender"
)

# 遍历每个分支
for branch in "${!branches[@]}"; do
    echo "Creating branch: $branch"

    # 解析配置
    IFS=':' read -r email task_count commit_count timestamps <<< "${branches[$branch]}"
    IFS=',' read -ra commit_times <<< "$timestamps"

    # 获取用户名（从邮箱中提取）
    username="${email%@*}"

    # 切换到main分支
    git checkout main

    # 创建新分支
    git checkout -b "$branch"

    # 设置git配置
    git config user.email "$email"
    git config user.name "${username^}"  # 首字母大写

    # 创建任务目录
    task_dir="tasks/$username"
    mkdir -p "$task_dir"

    # 计算每个commit的任务数
    tasks_per_commit=$((task_count / commit_count))
    remaining_tasks=$((task_count % commit_count))

    task_index=0

    # 创建commits
    for ((c=0; c<commit_count; c++)); do
        # 计算这个commit的任务数
        current_tasks=$tasks_per_commit
        if [ $c -lt $remaining_tasks ]; then
            current_tasks=$((current_tasks + 1))
        fi

        # 创建任务
        for ((t=0; t<current_tasks; t++)); do
            task_name="${task_names[$((task_index % ${#task_names[@]}))]}-$((task_index + 1))"

            # 决定任务是否完整（最后一个commit可能有不完整的任务）
            is_complete="true"
            if [ $c -eq $((commit_count - 1)) ] && [ $t -ge $((current_tasks - 2)) ] && [ $((RANDOM % 2)) -eq 0 ]; then
                is_complete="false"
            fi

            create_task "$task_dir/$task_name" "$task_name" "$is_complete"
            task_index=$((task_index + 1))
        done

        # 添加并提交
        git add "$task_dir"

        # 使用指定的时间戳
        commit_time="${commit_times[$c]}"
        GIT_AUTHOR_DATE="$commit_time" GIT_COMMITTER_DATE="$commit_time" \
            git commit -m "Add tasks for ${username}: commit $((c + 1))/$commit_count"
    done

    echo "Branch $branch created with $task_count tasks in $commit_count commits"
done

# 切换回main分支
git checkout main
echo "All branches created successfully!"