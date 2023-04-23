echo "deploy hexo site"
cd hexo-site 
pwd
zsh ./d.sh
echo "push to github"
cd ..
zsh ./cmt.sh
