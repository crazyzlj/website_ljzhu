+++
title= "如何利用Github Pages, Doxygen和Travis CI构建自动更新文档系统"
date = "2016-04-12"
tags = ["doxygen", "CI", "Github"]
summary = """利用持续构建工具（Travis CI）及Doxygen自动构建并更新在线文档。"""
[header]
image = ""
caption = ""
+++

+ 参考资料：

  + 1.[Creating Project Pages manually by Github](https://help.github.com/articles/creating-project-pages-manually/)
  + 2.[Automatic Documentation Publishing with GitHub and TravisCI](http://blog.gockelhut.com/2014/09/automatic-documentation-publishing-with.html "Automatic Documentation Publishing with GitHub and TravisCI")
  + 3.[Deploying Docs on Github with Travis-CI](https://djw8605.github.io/2017/02/08/deploying-docs-on-github-with-travisci/)


# 1 手工创建Github Pages

```
# 克隆一个纯净仓库
git clone github.com/user/repository.git
# 创建gh-pages分支
cd repository
git checkout --orphan gh-pages
# 这个gh-pages分支不会影响其他分支，因为它是orphan！
# 删除所有库内文件
git rm -rf .
# 创建一个html并push到gh-pages分支
echo "My Page" > index.html
git add index.html
git commit -a -m "First pages commit"
git push origin gh-pages
```

这样，就可以通过`http(s)://<username>.github.io/<projectname>`访问项目主页了，比如[https://lreis2415.github.io/SEIMS/](https://lreis2415.github.io/SEIMS/)，注意，repository大小写敏感！

# 2 在Travis CI中添加库
使用Github账号登录[Travis CI](https://travis-ci.org/)，进入“Account”，找到你想创建文档的Github库，启用它。

这样就让Travis CI知道了，将来这个库每次push的时候，都要根据库根目录下的`.travis.yml`配置进行自动构建（文档、程序之类的）。
# 3 为Travis CI创建SSH key

```
cd repository
mkdir doc
ssh-keygen -t rsa -C "youremail@example.com" -f doc/travisci_rsa
# travisci_rsa和travisci_rsa.pub会生成在当前仓库目录doc/
```

+ 3.1.将`travisci_rsa.pub`中的内容添加至Github库的设置中，即Settings -> Deploy Keys，当然，记得要选中“Allow write access”。
+ 3.2.使用Travis CI提供的加密文件的方案，即Travis CI CLI，对`travisci_rsa`文件进行加密。
    + 3.2.1.从Ruby Gem安装`travis`，Windows下请首先安装[Ruby](http://rubyinstaller.org/downloads)，替换掉官方的sources，参考[这篇博客](http://zhulj.net/others/2016/03/17/Github-jekyll-blog.html)。

    + 3.2.2.Windows下操作（P.S.在我电脑上反正是出错！**推荐使用linux**！）：

	```
	gem sources --add http://gems.ruby-china.org/ --remove https://rubygems.org/
	gem install travis
	travis login
	# 然后输入Github的用户名、密码进行验证
	# 创建.travis.yml
	cd <path/to/your/github/repository>
	echo "before_install:" > .travis.yml
	# 然后便可以加密文件了
	travis encrypt-file doc/travisci_rsa --add
	# Output:
	# encrypting travisci_rsa for lreis/SEIMS
	# storing result as travisci_rsa.enc
	# storing secure env variables for decryption
	# Make sure to add super_secret.txt.enc to the git repository.
	# Make sure not to add super_secret.txt to the git repository.
	# Commit all changes to your .travis.yml.
	
	# 将travisci_rsa.enc上传至Github，而不要讲travisci_rsa上传，可以将travisci_rsa删掉
	rm doc/travisci_rsa
	
	# 将以下两行添加至.travis.yml
	- chmod 0600 travisci_rsa
	- cp doc/travisci_rsa ~/.ssh/id_rsa
	```

    + 3.2.3.CentOS下操作：

	```
	# 安装ruby和gem以安装travis
	sudo yum install ruby rubygems
	# 但是这样安装之后，设置好中国的ruby源，安装travis依然遇到各种问题，比如SSL，hostname等。
	# ERROR:  While executing gem ...
	# (Gem::RemoteFetcher::FetchError)
	#    hostname was not match with the server certificate (https://gems-10023966.file.myqcloud.com/quick/Marshal.4.8/travis-1.8.2.gemspec.rz)
	
	# 因此推荐采用如下Linux服务器RVM安装脚本
	# https://github.com/huacnlee/init.d/blob/master/install_rvm
	vim install_rvm
	# 粘贴脚本内容
	chomd 700 install_rvm
	# 执行脚本
	./install_rvm 
	# 剩下的操作与Windows类似
	gem install travis
	travis login
	cd <path/to/your/github/repository>
	echo "before_install:" > .travis.yml
	travis encrypt-file doc/travisci_rsa --add
	rm doc/travisci_rsa
	```
+ 3.3.上一步操作中`travis encrypt-file doc/travisci_rsa --add`之后，打开Travis CI的库设置页面，发现环境变量里多了2个值，分别为`encrypted*_iv`和`encrypted*_key`，这是`openssl`解密`travisci_rsa.enc`需要的参数，需要在`.yml`文件中设置。

# 4 配置Travis CI

上一步中，我们已经在库的根目录下创建了`.travis.yml`文件，接下来要对其进行进一步编辑。

```
dist: trusty
branches:
  only:
    - master
before_install:
  - openssl aes-256-cbc -K $encrypted_9c89c5b645f3_key -iv $encrypted_9c89c5b645f3_iv
    -in doc/travisci_rsa.enc -out doc/travisci_rsa -d
  - sudo apt-get install doxygen graphviz
  - chmod 0600 doc/travisci_rsa
  - cp doc/travisci_rsa ~/.ssh/id_rsa
  # push automatically generated doxygen html files to gh-pages branch
  - chmod 700 doc/publish-doxygen
  - "./doc/publish-doxygen"
notifications:
  email:false
```

# 5 配置Doxygen
上一步中，构建Doxygen文档使用了`doc/publish-doxygen`，具体如何配置的呢？

主要分为以下几步：
+ 5.1.设置Github库地址、Doxygen文档地址等
+ 5.2.克隆一份现有的gh-pages，并清空，以防更新后有旧版本残留
+ 5.3.调用`doxygen`生成代码文档
+ 5.4.将`html`文件夹push到gh-pages分支

示例代码如下：

```
#!/bin/bash -e

# Settings
REPO_PATH=git@github.com:lreis2415/SEIMS.git
HTML_PATH=doc/html
COMMIT_USER="YOUR USERNAME"
COMMIT_EMAIL="YOUR EMAIL"
CHANGESET=$(git rev-parse --verify HEAD)

# Get a clean version of the HTML documentation repo.
rm -rf ${HTML_PATH}
mkdir -p ${HTML_PATH}
git clone -b gh-pages "${REPO_PATH}" --single-branch ${HTML_PATH}

# rm all the files through git to prevent stale files.
cd ${HTML_PATH}
git rm -rf .
cd -

# Generate the HTML documentation.

#make doxygen
doxygen ./doc/Doxyfile
echo "Doxygen generated done!"
# Create and commit the documentation repo.
cd ${HTML_PATH}
git add .
git config user.name "${COMMIT_USER}"
git config user.email "${COMMIT_EMAIL}"
git commit -m "Automated doc for changeset ${CHANGESET}."
git push origin gh-pages
cd -
```

# 6 测试

push到master分支，等待一会，打开项目主页看看效果吧，如[https://lreis2415.github.io/SEIMS/](https://lreis2415.github.io/SEIMS/)。

当然，如果对Doxygen默认的样式不满意，你还有很多种途径进行定制，这里就不介绍啦。
