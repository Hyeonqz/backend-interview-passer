#!/bin/bash
# Auto commit & push on file changes via Claude Code hooks

REPO_DIR="/Users/jinhyeongyu/single-study/backend-interview-passer"

cd "$REPO_DIR" || exit 0

# 변경사항 없으면 종료
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  exit 0
fi

# 변경된 파일 목록 수집
CHANGED_FILES=$(git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard)

# 스테이징
git add -A

# 커밋 메시지 생성 (변경 파일 기반)
FILE_COUNT=$(echo "$CHANGED_FILES" | grep -c .)
FIRST_FILE=$(echo "$CHANGED_FILES" | head -1)

if [ "$FILE_COUNT" -eq 1 ]; then
  COMMIT_MSG="docs: update $FIRST_FILE"
else
  COMMIT_MSG="docs: update $FILE_COUNT files ($FIRST_FILE, ...)"
fi

git commit -m "$COMMIT_MSG" --quiet

# Push
git push origin HEAD --quiet

echo "[auto-commit] $COMMIT_MSG → pushed to origin"