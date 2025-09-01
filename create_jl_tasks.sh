#!/bin/bash

# 第一个commit: 2个符合模板的任务
mkdir -p tasks/jl/data-analysis
mkdir -p tasks/jl/data-analysis/docs
mkdir -p tasks/jl/data-analysis/initial_workspace
mkdir -p tasks/jl/data-analysis/evaluation

echo "Analyze weekly expense data and generate reports" > tasks/jl/data-analysis/docs/task.md
echo "def check():\n    return True" > tasks/jl/data-analysis/evaluation/check_local.py
echo "Sample data for analysis" > tasks/jl/data-analysis/initial_workspace/data.csv

mkdir -p tasks/jl/pdf-converter  
mkdir -p tasks/jl/pdf-converter/docs
mkdir -p tasks/jl/pdf-converter/initial_workspace
mkdir -p tasks/jl/pdf-converter/evaluation

echo "Convert markdown files to PDF format" > tasks/jl/pdf-converter/docs/task.md
echo "def check():\n    return True" > tasks/jl/pdf-converter/evaluation/check_local.py
echo "# Sample Document" > tasks/jl/pdf-converter/initial_workspace/sample.md

# 第二个commit: 2个符合模板的任务
mkdir -p tasks/jl/email-classifier
mkdir -p tasks/jl/email-classifier/docs
mkdir -p tasks/jl/email-classifier/initial_workspace
mkdir -p tasks/jl/email-classifier/evaluation

echo "Classify emails based on content" > tasks/jl/email-classifier/docs/task.md
echo "def check():\n    return True" > tasks/jl/email-classifier/evaluation/check_local.py
echo "Sample email content" > tasks/jl/email-classifier/initial_workspace/emails.txt

mkdir -p tasks/jl/canvas-grader
mkdir -p tasks/jl/canvas-grader/docs
mkdir -p tasks/jl/canvas-grader/initial_workspace
mkdir -p tasks/jl/canvas-grader/evaluation

echo "Grade student submissions automatically" > tasks/jl/canvas-grader/docs/task.md
echo "def check():\n    return True" > tasks/jl/canvas-grader/evaluation/check_local.py
echo "Student submission data" > tasks/jl/canvas-grader/initial_workspace/submissions.csv

# 第三个commit: 1个符合的，2个不符合的任务
mkdir -p tasks/jl/report-generator
mkdir -p tasks/jl/report-generator/docs
mkdir -p tasks/jl/report-generator/initial_workspace
mkdir -p tasks/jl/report-generator/evaluation

echo "Generate weekly progress reports" > tasks/jl/report-generator/docs/task.md
echo "def check():\n    return True" > tasks/jl/report-generator/evaluation/check_local.py
echo "Progress data" > tasks/jl/report-generator/initial_workspace/progress.json

# 不符合模板的任务（缺少必要文件）
mkdir -p tasks/jl/incomplete-task1
echo "This task is missing evaluation" > tasks/jl/incomplete-task1/README.md

mkdir -p tasks/jl/incomplete-task2/docs
echo "This task is missing initial_workspace" > tasks/jl/incomplete-task2/docs/task.md
