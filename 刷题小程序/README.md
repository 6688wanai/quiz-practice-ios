# 刷题练习 iOS App

这是一个原生 SwiftUI iOS 刷题 App 工程，题库来自桌面的 DOCX 文件并转换为内置 JSON。App 离线运行，每次随机抽取 150 道题，支持单选、多选、判断、交卷判分、错题本和继续上次练习。

## 工程内容

- `QuizPractice.xcodeproj`：Xcode 工程
- `QuizPractice/Resources/questions.json`：App 内置题库
- `Tools/ConvertQuestionBank.ps1`：题库转换脚本
- `QuestionBankReport.md`：题库解析报告

## 重新生成题库

在当前目录运行：

```powershell
.\Tools\ConvertQuestionBank.ps1
```

脚本默认读取：

```text
D:\Users\ASUS\Desktop\预防接种题库_完整版（全题型答案在后）(1).docx
```

## 没有 Mac 怎么打包 IPA

推荐使用 GitHub Actions 云端 macOS 构建。本项目已经包含：

```text
.github/workflows/build-ios-ipa.yml
```

步骤：

1. 在 GitHub 新建一个仓库。
2. 把本目录全部上传到仓库。
3. 打开仓库的 Actions 页面。
4. 选择 `Build iOS IPA`。
5. 点击 `Run workflow`。
6. 构建完成后，在页面底部 Artifacts 下载 `QuizPractice-unsigned-ipa`。
7. 解压后得到 `QuizPractice-unsigned.ipa`。

这个 IPA 是未签名构建产物，适合：

- 用 TrollStore 导入安装。
- 用 Sideloadly、AltStore、爱思助手、企业签名等工具重新签名后安装。

## 有 Mac 时打包 IPA

需要在 macOS 的 Xcode 中打开 `QuizPractice.xcodeproj`。

1. 打开工程后，在 Signing & Capabilities 里设置自己的 Team。
2. Bundle Identifier 可改成自己的，例如 `com.yourname.quizpractice`。
3. 选择真机或 Any iOS Device。
4. 使用 Product > Archive 导出 IPA。
5. 导出的 IPA 可用 TrollStore、Sideloadly、AltStore 或其他签名方式安装。

当前工程没有依赖第三方库。
