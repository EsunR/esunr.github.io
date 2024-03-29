#!/bin/sh

scriptDir=$(
    cd "$(dirname "$0")"
    pwd
)
postDir=$(
    cd "$scriptDir/../source/_posts"
    pwd
)

read -p "请输入文章标题：" postTitle
read -p "请输入文章分类(多级分类中间用『/』分割)：" postCategory

postFileName=$(echo $postTitle | tr ' ' '-')

# 判断 postDir 目录下是否有对应的文章分类文件夹，否则创建
if [ ! -d "$postDir/$postCategory" ]; then
    mkdir -p "$postDir/$postCategory"
fi

currentTime=$(date "+%Y-%m-%d %H:%M:%S")

# 创建 markdown 文件
cat >$postDir/$postCategory/$postFileName.md <<EOF
---
title: $postTitle
tags: []
categories:
$(
    for category in $(echo $postCategory | tr '/' ' '); do
        echo "  - $category"
    done
)
date: $currentTime
---
EOF

echo "文件创建成功!"
echo "$postDir/$postCategory/$postFileName.md"
