# 持續整合 & 持續交付 Docker 至 AWS Elastic Beanstalk

這篇文章將一步一步介紹如何使用 Docker、GitHub、CircleCI、AWS Elastic Beanstalk 與 Slack 來完成**持續整合**與**持續交付**（Continuous Integration & Continous Delivery）的開發流程。

## Step By Step：

1. Node.js
  - 在本地端執行 Node.js
  - 在本地端測試 Node.js
2. GitHub
3. CircleCI
  - 在 CircleCI 測試 Node.js
4. Code Review
  - GitHub Flow
5. Docker
  - 在 Docker 執行 Node.js
  - 在 CircleCI 測試 Docker
6. AWS Elastic Beanstalk
  - 在本地端部屬 AWS
  - 在 CircleCI 部屬 AWS
7. Slack

> 作業環境：
> 
> - MacBook Pro (13-inch, Mid 2012)
> - OS X Yosemite 10.10.3

## Node.js

![node]()

> 安裝：
> 
> - [node](https://nodejs.org/): 0.10

### 建立新專案

1. 建立一個專案資料夾（這裡以 `hello-ci-workflow` 為例）：

```bash
$ mkdir hello-ci-workflow
$ cd hello-ci-workflow
```

### 在本地端執行 Node.js

1. 初始化 Node.js 的環境，填寫一些資料之後會在目錄下產生一個 `package.json` 的檔案：

```bash
$ npm init
```

2. 安裝 Node.js 的 web framework，以 [Express](http://expressjs.com/) 為例：

```bash
$ npm install express --save
```

> `--save`: 寫入 `package.json` 的 dependencies。

```json
// package.json
{
  "name": "hello-ci-workflow",
  "main": "index.js",
  "dependencies": {
    "express": "^4.12.3"
  },
  "scripts": {
    "start": "node index.js"
  }
}
```

3. 在 `index.js` 裡寫一段簡單顯示 Hello World! 的程式：

```javascript
// index.js
var express = require('express');
var app = express();

app.get('/', function (req, res) {
  res.send('Hello World!');
});

var server = app.listen(3000, function () {

  var host = server.address().address;
  var port = server.address().port;

  console.log('Example app listening at http://%s:%s', host, port);

});
```

4. 執行 `npm start`：

```bash
$ npm start
```

5. 打開瀏覽器 `http://localhost:3000` 看結果：

![01]()

### 在本地端測試 Node.js

1. 安裝 Node.js 的單元測試，以 [Mocha](http://mochajs.org/) 為例：

```bash
$ npm install mocha --save-dev
```

> `--save-dev`: 寫入 `package.json` 的 devDependencies，正式上線環境不會安裝。

```json
// package.json
{
  "name": "hello-ci-workflow",
  "main": "index.js",
  "dependencies": {
    "express": "^4.12.3"
  },
  "devDependencies": {
    "mocha": "^2.2.4"
  },
  "scripts": {
    "start": "node index.js"
  }
}
```

2. 根目錄 `test` 資料夾，並新增一個測試腳本 `test.js`：

```bash
$ mkdir test
$ cd test
$ touch test.js
```

3. 加入一筆錯誤的測試 `assert.equal(1, [1,2,3].indexOf(0))`：

```javascript
// test/test.js
var assert = require("assert")
describe('Array', function(){
  describe('#indexOf()', function(){
    it('should return -1 when the value is not present', function(){
      assert.equal(1, [1,2,3].indexOf(0));
    })
  })
})
```

4. 執行 mocha 測試：

```bash
$ ./node_modules/.bin/mocha


  Array
    #indexOf()
      1) should return -1 when the value is not present


  0 passing (9ms)
  1 failing
```

結果顯示 `1 failing`，測試沒通過，因為 `[1,2,3].indexOf(0)` 回傳的值不等於 `-1`。

5. 將 `test.js` 的測試修正：

```javascript
// test/test.js
assert.equal(-1, [1,2,3].indexOf(0));
```

6. 再次執行 mocha 測試：

```bash
$ ./node_modules/.bin/mocha


  Array
    #indexOf()
      ✓ should return -1 when the value is not present


  1 passing (6ms)
```

結果顯示 `1 passing`，通過測試。

## GitHub

![github]()

> 安裝：
> 
> - [git](http://git-scm.com/): 2.3.2

> 帳號：
> 
> - [GitHub](https://github.com/)

1. 初始化 git 環境：

```bash
$ git init .
```

2. 輸入 `git status` 會顯示目前哪些檔案有過更動：

```bash
$ git status
On branch master

Initial commit

Untracked files:
  (use "git add <file>..." to include in what will be committed)

  index.js
  node_modules/
  package.json
  test/
```

3. 將 `node_modules` 加到 `.gitignore` 黑名單，因為這個資料夾是由 `npm install` 自動產生的，不需要放到 GitHub 上：

```
# .gitignore

# Dependency directory
# https://www.npmjs.org/doc/misc/npm-faq.html#should-i-check-my-node_modules-folder-into-git
node_modules
```

4. 將更動 commit：

```bash
$ git add .
$ git commit -m "first commit"
```

5. 打開 GitHub，新增一個 repository：

![02]()

6. 輸入 repository 的名稱，以 `hello-ci-workflow` 為例：

![03]()

7. 使用 `git remote add` 將新創建的 GitHub repository 加入到 remote：

```bash
$ git remote add origin https://github.com/<USER_NAME>/hello-ci-workflow.git
```

> `<USER_NAME>` 改成自己的帳號。

8. 使用 `git push` 將程式碼傳到 GitHub：

```bash
$ git push -u origin master
```

成功之後前往 `https://github.com/<USER_NAME>/hello-ci-workflow` 就可以看到剛才上傳的檔案：

![04]()

## CircleCI

![circleci]()

> 帳號：
> 
> - [CircleCI](https://circleci.com/)

### 加入 GitHub repository

1. 點選左邊欄的 `Add Projects` 按鈕：

![05]()

2. 選擇自己的 GitHub 帳號：

![06]()

3. 搜尋要加入的 GitHub repository，然後點選 `Build project` 按鈕，以 `hello-ci-workflow` 為例：

![07]()

4. 完成之後 CircleCI 就會自動執行第一次的建構，不過因為還沒加入測試腳本，所以建構結果會顯示 no test：

![08]()

### 在 CircleCI 測試 Node.js

1. 在專案根目錄底下建立一個 `circle.yml`，並加入 mocha test：

```yaml
# circle.yml
machine:
  node:
    version: 0.10

test:
  override:
    - ./node_modules/.bin/mocha
```

2. 完成之後將檔案 push 上 GitHub：

```bash
$ git add circle.yml
$ git cimmit "add circle.yml"
$ git push
```

3. Push 成功之後，CircleCI 會自動觸發建構和測試：

![09]()

4. 測試通過，建構成功：

![10]()

## 代碼審查（Code Review）with GitHub Flow

![github-flow]()

### 建立一條分支

1. 為了確保 master 這條主線上的程式碼都是穩定的，所以建議開發者依照不同的功能、建立不同的分支，這裡以 `test-github-flow` 為例，使用 `git branch` 新增分支、然後 `git checkout` 切換分支：

```bash
$ git branch test-github-flow
$ git checkout test-github-flow
```

### Add commits

1. 在 `test.js` 裡加入一行錯誤的測試 `assert.equal(3, [1,2,3].indexOf(5))`：

```javascript
// test/test.js
// ...
assert.equal(3, [1,2,3].indexOf(5));
```

```bash
$ git add test/test.js
$ git commit -m "add a error test case"
```

### Open a Pull Request

1. Push 到 GitHub 的 test-github-flow 分支：

```bash
$ git push -u origin test-github-flow
```

2. 打開 GitHub 之後，會出現 `test-github-flow` 分支的 push commits，點選旁邊的 `Compare & pull request` 按鈕：

![13]()

3. 點選之後會進入 Open a pull request 的填寫頁面，選擇想要 merge 的分支、輸入描述之後，點選 `Create pull request` 按鈕：

![14]()

### Discuss and review your code

1. 新增一個 pull request 之後，其他人就會在 GitHub 上出現通知：

![15]()

2. 點進去之後可以看見相關的 commits 與留言，但是下面有一個紅紅大大的叉叉；因為每次 GitHub 只要有新的 push，就會觸發 CircleCI 的自動建置和測試，並且顯示結果在 GitHub 上：

![18]()

3. 點選叉叉，前往 CircleCI 查看錯誤原因：

![19]()

4. 就會發現剛剛 push 到 test-github-flow 的測試沒通過：

![12]()

![11]()

回到 GitHub，因為測試沒通過，所以審查者不能讓這筆 pull request 被 merge 回 master。

5. 找到剛剛 commit 的那段程式碼，留言告知請開發者修正錯誤之後，再重新 commit push 上來：

![21]()

![22]()

![23]()

6. 修正 `test.js` 的測試腳本：

```javascript
// test/test.js
// ...
assert.equal(-1, [1,2,3].indexOf(5));
```

7. 再次 commit & push：

```bash
$ git add test/test.js
$ git commit -m "fix error test case"
$ git push
```

8. 回到 GitHub 的 pull request 頁面，可以看到最新一筆的 commit 成功通過 CircleCI 的測試了：

![26]()

![24]()

![25]()

### Merge and deploy

1. 審查之後，確定沒有問題，就可以點選 `Merge pull request` 的按鈕，將 `test-github-flow` 的程式碼 merge 回主線 `master`：

![27]()

![28]()

![29]()

## Docker

![docker]()

> 安裝：
> 
> - [boot2docker](https://github.com/boot2docker/boot2docker)
> - [docker](https://www.docker.com/)

### 在 Docker 執行 Node.js

1. 在專案根目錄底下建立一個 `Dockerfile`：

```
# Dockerfile

# 從 [Docker Hub](https://hub.docker.com/) 安裝 Node.js image。
FROM node:0.10

# 設定 container 的預設目錄位置
WORKDIR /hello-ci-workflow

# 將專案根目錄的檔案加入至 container
# 安裝 npm package
ADD . /hello-ci-workflow
RUN npm install

# 開放 container 的 3000 port
EXPOSE 3000
CMD npm start
```

2. 使用 `docker build` 建構您的 image：

```bash
$ docker build -t hello-ci-workflow .
```

> `-t hello-ci-workflow` 是 image 名稱。

3. 使用 `docker run` 執行您的 image：

```bash
$ docker run -p 3000:3000 -d hello-ci-workflow
```

> `-d` 在背景執行 node，可以使用 `docker logs` 看執行結果。

4. 打開瀏覽器 `http://localhost:3000` 看結果：

![01]()

### 在 CircleCI 測試 Docker

1. 修改 `circle.yml`：

```yaml
# circle.yml
machine:
  # 環境改成 docker
  services:
    - docker

dependencies:
  override:
    # 建構方式使用 docker build
    - docker build -t hello-ci-workflow .

test:
  override:
    - ./node_modules/.bin/mocha
    # 使用 curl 測試 docker 是否有順利執行 node
    - docker run -d -p 3000:3000 hello-ci-workflow; sleep 10
    - curl --retry 10 --retry-delay 5 -v http://localhost:3000
```

2. Push 更新到 GitHub：

```bash
$ git add Dockerfile circle.yml
$ git commit -m "add Docker"
$ git push
```

3. 查看 CircleCI 建構＆測試結果：

![30]()

## AWS Elastic Beanstalk

![beanstalk]()

> 帳號：
> 
> - [Amazon Web Services](https://aws.amazon.com/)

> 安裝：
> 
> - [AWS EB CLI](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-getting-set-up.html#eb_cli3-install-with-pip): 3.x

1. 初始化 EB 環境：

```bash
$ eb init -p docker
```

> `-p` 可以指定 EB 的應用平台，例如 php 之類；這裡使用 docker。

該命令將提示您配置各種設置。 按 Enter 鍵接受預設值。

> 如果你已經存有一組 AWS EB 權限的憑證，該命令會自動使用它。
> 否則，它會提示您輸入 `Access key ID` 和 `Secret access key`，必須前往 AWS IAM 建立一組。

2. 初始化成功之後，可以使用 `eb create` 快速建立各種不同的環境，例如：development, staging, production；這裡我們以 `env-development` 為例：

```bash
$ eb create env-development
```

等待 Elastic Beanstalk 完成環境的建立。 當它完成之後，您的應用已經備有負載均衡（load-balancing）與自動擴展（autoscaling）的功能了。

![31]()

4. 使用 `eb open` 前往目前版本的執行結果：

```bash
$ eb open env-development
```

![32]()

### 在本地端部屬 AWS

1. 稍微修改 `index.js`：

```javascript
// index.js
// ...
app.get('/', function (req, res) {
  res.send('Hello env-development!');
});
// ...
```

2. 執行 `eb deploy` 部屬新版本到 AWS Elastic Beanstalk：

```bash
$ eb deploy env-development
```

![34]()

3. 部屬完成之後，執行 `eb open` 打開網頁：

```bash
$ eb open env-development
```

![33]()

`env-development` 上的應用程式更新完成。

## 在 CircleCI 部屬 AWS

1. `git checkout` 將分支切換回主線 master：

```bash
$ git checkout master
```

2. `eb create` 新增一組新的環境，作為產品上線用，命名為 `env-production`：

```bash
$ eb create env-production
```

```bash
$ eb open env-production
```

![35]()

這樣就成功啟動第二組機器了，目前我們有 `env-development` 和 `env-production` 兩組環境。

### 前往 [AWS IAM](https://console.aws.amazon.com/iam/home) 新增一組帳號給 CircleCI 使用：

1. `Dashboard` > `Users`
2. `Create New Users`
3. Enter User Names: **CircleCI** > `Create`
4. `Download Credentials`
5. `Dashboard` > `Users` > `CircleCI`
6. `Attach Pollcy`
7. `AWSElasticBeanstalkFullAccess` > `Attach Pollcy`

前往 CircleCI，設定您的 AWS 權限：

1. `Project Settings`
2. `Permissions` > `AWS Permissions`
3. 打開剛才下載的 `credentials.csv`，輸入 `Access Key ID` & `Secret Access Key`
4. `Save AWS keys`

1. 在 `.elasticbeanstalk` 目錄底下，建立 `config.global.yml`：

```yaml
# .elasticbeanstalk/config.global.yml
global:
  application_name: hello-ci-workflow
  default_region: us-west-2 # EB 所在的 region，預設是 us-west-2
```

2. 修改 `circle.yml`：

```yaml
# circle.yml
machine:
  # 安裝 eb 需要 python
  python:
    version: 2.7
  services:
    - docker

dependencies:
  pre:
    # 安裝 eb
    - sudo pip install awsebcli
  override:
    - docker build -t hello-ci-workflow .

test:
  override:
    - npm test
    - docker run -d -p 3000:3000 hello-ci-workflow; sleep 10
    - curl --retry 10 --retry-delay 5 -v http://localhost:3000

# 新增一筆部屬腳本
deployment:
  production:
    branch: master
    commands:
      - eb deploy env-production
```

這樣就能在 GitHub 的 master 支線有更新時，觸發 CircleCI 的自動建置、測試、然後部屬。

3. 接下來馬上來試試看流程，修改 `index.js`：

```javascript
// index.js
// ...
app.get('/', function (req, res) {
  res.send('Hello env-production!');
});
// ...
```

4. Commit & Push：

```bash
$ git add .
$ git cimmit "test deploy production"
$ git push
```

5. 前往 CircleCI 看結果：

![36]()

6. 部屬成功，`eb open` 打開瀏覽器來看看結果：

```bash
$ eb open env-production
```

![37]()

## Slack

![slack]()

1. 登入 Slack 頁面
2. 點選 `Configure Integrations` > `CircleCI`

![38]()

![39]()

1. 選擇要接收 CircleCI 通知的 channel 
2. 點選 `Add CircleCI Integration` 按鈕
3. 複製畫面上的 `webhook URL`

![40]()

![44]()

1. 返回 CircleCI
2. 點選 `Project settings` > `Chat Notifications`
3. 貼上將複製的 `Webhook URL` > `Save`

![41]()

![42]()

![43]()

1. 類似的步驟，將 GitHub 的通知加入 Slack：

![45]()

![46]()

![47]()

![48]()

1. 測試 Slack 通知，是否能夠順利運作，新增一條 `test-slack` 分支：

```bash
$ git branch test-slack
$ git checkout test-slack
```

2. 修改 `index.js`：

```javascript
// index.js
// ...
app.get('/', function (req, res) {
  res.send('Hello Slack!');
});
// ...
```

3. Commit & Push：

```bash
$ git add index.js
$ git commit -m "index.js: update to test slack"
$ git push -u origin test-slack
```

1. CircleCI 通過測試，開啟一個 Pull Request
2. 將 `test-slack` merge 回 `master`，觸發 CircleCI 自動部屬

![50]()

![51]()

That’s it! On your next build, you’ll start seeing CircleCI build notifications in your Slack chatroom.

結束！可以看見 Slack channel 會顯示每一個步驟的通知過程：

![49]()

`eb open` 打開瀏覽器查看結果，成功自動部屬新版本：

```bash
$ eb open env-production
```

![52]()

## 參考

- [Understanding the GitHub Flow · GitHub Guides](https://guides.github.com/introduction/flow/)
- [Dockerizing a Node.js Web App](https://docs.docker.com/examples/nodejs_web_app)
- [Integration with Docker Containers - CircleCI](https://circleci.com/integrations/docker)
- [Continuous Integration and Delivery with Docker](https://circleci.com/docs/docker)
- [Getting Started with EB CLI 3.x](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-getting-started.html)
- [Slack Integration | The Circle Blog](http://blog.circleci.com/slack-integration/)
- [CircleCIからAWS Elastic Beanstalkにpush](http://qiita.com/sawanoboly/items/28e98827bc044abdc32f)
- [深入浅出Docker（四）：Docker的集成测试部署之道](http://www.infoq.com/cn/articles/docker-integrated-test-and-deployment)
- [Integrate CircleCI with GitHub](http://rettamkrad.blogspot.tw/2014/11/integrate-circleci-with-github.html)
- [Docker in Action - Fitter, Happier, More Productive](https://realpython.com/blog/python/docker-in-action-fitter-happier-more-productive/)[中文](http://segmentfault.com/a/1190000002598713)
- [Delivery pipeline and zero downtime release](http://waytothepiratecove.blogspot.tw/2015/03/delivery-pipeline-and-zero-downtime.html)
- [Re-Blog: CI & CD With Docker, Beanstalk, CircleCI, Slack, & Gantree](http://sauceio.com/index.php/2014/12/ci-cd-with-docker-beanstalk-circleci-slack-gantree/)
- [Node With Docker - Continuous Integration and Delivery](http://mherman.org/blog/2015/03/06/node-with-docker-continuous-integration-and-delivery)
- [山姆鍋對持續整合、持續部署、持續交付的定義](http://blog.eavatar.com/post/2013/10/continuous-integration-deployment-delivery/)