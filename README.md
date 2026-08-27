git init
git add .
git commit -m "Initial commit with Codemagic workflow"
git branch -M main
git remote add origin https://github.com/mohe_doudou/smart_pos_app.git
git push -u origin main
git add pubspec.yaml codemagic.yaml
git commit -m "Fix dependencies version conflicts"
git push
