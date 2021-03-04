rm -rf public

hugo -t even

cd public

git init
git add -A
git commit -m "update $(date)"

git branch -M main
git remote add origin https://github.com/No-Github/no-github.github.io.git
git push -f -u origin main