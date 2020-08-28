---
title: 从零开始创建一个 React Native Native Modules
tags: [ReactNative]
categories:
  - Front
  - React
date: 2020-08-28 15:05:20
---

# 1. 什么是 Native Modules

首先我们要明白 Native Native 之所以能够跨端调用 Android、iOS 的能力，就是因为 Javascript 只是提供了 Bridge 层的调用，具体的实现代码还是由原生的 Android、iOS 代码来实现的：

![](http://img.cdn.esunr.xyz/markdown/20200828150949.png)

因此，理论上如果我们编写了一个使用 Android 或 iOS 的原生代码，只要为其建立 Javascript 层的 Bridge，那么我们就可以通过 Javascript 层的代码来调用这些原生代码的能力。而 Native Modules 正是为我们来实现这一目标的。

Native Modules 是一个很令人兴奋的能力，但是代价就是我们始终要开发并维护两套代码，并让他们在 Javascript 层合二为一。因此社区上便出现了两种包：一种是普通的组件包，其本质还是 Javascript 代码，调用的是 React Native 封装好的逻辑（如：react-native-scrollable-tab-view）；而另一种就是基于 Native Modules 的包，其不仅由 Javascript 代码进行构建，同时还会使用 Android、iOS 端的原生代码进行构建（这些包之前在社区中是由 rnpm 管理的，但是自 React Native 支持自动 link 后就不存在这种差异了）。区分这两种包的最简单方法就是看其源代码中是否有 `android` 或 `ios` 文件夹，如果有，那它就是一个基于 Native Modules 开发的包。

# 2. 开发一个 Native Modules

> 以下以安卓端开发为示例

在 React Native 官方文档的 [原生模块](https://reactnative.cn/docs/0.46/native-modules-android) 这一章节中，对如何封装一个 Native Modules 进行了详细的描述，按照指引我们可以封装出来一个 Toast 模块。

在这里不对文章的内容进行复述（如果你还没有看该文章，快马上看看）总结该文章，其要点分为如下几步：

1. 创建一个名为 ToastModule 的 Class，在这一步中重点是需要去复写其 `getName()` 方法来作为JavaScript 端这个模块的标记。之后我们再该类下写的所有方法（被 `@ReactMethod` 所标记的）最终都会被注册到 Javascript 层调用的这个组件之上，因此它的开发是我们的主要工作。
2. 创建一个名为 AnExampleReactPackage 的 Class，这一步主要是去注册我们上一步所创建的 Module。
3. 进入项目的 `MainApplication.java` 文件中，进行手动连接（这一步就是我们在使用第三方包时执行 react-link 所做的其中一步，我们后续会重提）。
4. 在 Javascript 中调用 Bridge。

![](http://img.cdn.esunr.xyz/markdown/20200828172358.png)

至此，我们已经完成了一个简单的 Native Modules，打通了 Javascript 与原生层的交互。

# 3. 模块化开发

在完成了官方文档的《原生模块》这一章节后，我们的 Android 目录下的 java 代码中会是这样的：

![](http://img.cdn.esunr.xyz/markdown/20200828173744.png)

我们新增了 `xxxModule.java` 与 `xxxPackage.java` 这两个文件。这里可以发现我们编写的 Native Modules 和原生的代码杂糅在一个文件夹下了，这样不仅会~~逼死强迫症~~，同时我们无法将编写好的代码抽离为一个独立的 Modules。

我们先看一下如果我们项目中引用了别的开发者所开发的 Native Modules，项目的结构是怎么样的，注意这一步我们需要使用 Android Studio 打开项目，并且对项目进行 Sync，当 Sync 完成后我们会看到与 `app` 同级的目录下多了很多以 `react-native` 开头的包：

![](http://img.cdn.esunr.xyz/markdown/20200828184752.png)

要想明白这些包是从哪里来的，就需要牵涉出另一个概念，所谓的 “Android 模块化开发”。在安卓应用的开发过程中，我们不可能把所有的代码都塞入到一个目录下，这样不利于项目的模块化，因此在 Android 开发中存在 **Module** 这一概念。**每一个单独的 Module 都拥有独立的 Gradle，以及独立的 Package Name，以及独立的逻辑代码**，它存在的意义仅仅是负责处理一个模块级别的功能。

当我们对项目右键时，就可以新建一个 Module：

![](http://img.cdn.esunr.xyz/markdown/20200828185606.png)

如果我们要开发一个 RN 的 Native Modules，这个 Module 将不会包含任何 Active，那我们就可以选择创建一个 Android Library：

![](http://img.cdn.esunr.xyz/markdown/20200828185746.png)

之后你便可以设置一个模块名，这个模块名按照规范应该以 `react-native` 开头，如 `react-native-tester`。当创建完成后，需要等待 Android Studio 再次 Sync，此时 Android Studio 替我们做了两步：

- 在 `android/app` 目录下，创建了一个你所命名的模块同名的文件夹，作为你所要搭建的模块的目录。
- 在 `settings.gradle` 中写入了一行 `include ':react-native-xxx'`，说明你的项目中引用了你刚才所创建的 Module（这也是 React Native 在进行第三方包自动 Link 的其中一步）。

由此，我们就可以理解，那些以 `react-native` 开头的 Module 其实都来自于我们所下载的第三方包，他们本质是存在于 `node_modules` 目录下的，在项目编译的过程中会被建立了一层链接，从而我们可以在 Android Studio 的工程目录看到他们（这也是 React Native 在进行自动 Link 的功劳）：

![](http://img.cdn.esunr.xyz/markdown/20200828191713.png)

我们创建了一个独立的 Module 之后，可以先把自创建的测试相关的文件删除掉，这样就得到了一个简洁的目录，同时可以将我们之前写在 app 目录下的代码抽离出去，这样不仅我们的代码结构更清晰了，又可以为单独的 Module 进行独立的 Gradle 配置，不再会依赖主项目的 Gradle 版本。此时，目录结构应该为：

![](http://img.cdn.esunr.xyz/markdown/20200828193401.png)

其实在这一步还有一个难点，就是去配置 Gradle。Gradle 的配置往往比较复杂，具体可以去看官方文档，这里推荐一个配置：

```js
// 如果 gradle 版本想要与主项目一致，请删掉 buildscript 配置
buildscript {
  if (project == rootProject) {
    repositories {
      google()
      jcenter()
    }

    dependencies {
      // 这里可以单独指定 Module 的 Gradle 版本
      classpath("com.android.tools.build:gradle:3.4.2")
    }
  }
}

apply plugin: 'com.android.library'

// 使用这个方法可以获取到主项目的 compileSdkVersion、minSdkVersion 等配置，从而构建一个比较安全的 Gradle 配置
def safeExtGet(prop, fallback) {
  rootProject.ext.has(prop) ? rootProject.ext.get(prop) : fallback
}

android {
  compileSdkVersion safeExtGet('compileSdkVersion', 28)

  defaultConfig {
    minSdkVersion safeExtGet('minSdkVersion', 21)
    targetSdkVersion safeExtGet('targetSdkVersion', 28)
  }
}

repositories {
  // maven 仓库需要定位到 react-native 的目录，否则无法找到 React Native 相关的依赖
  maven {
    url "$projectDir/../node_modules/react-native/android"
  }
  mavenCentral()
  mavenLocal()
  google()
  jcenter()
}

dependencies {
  // 设置对 react-native 相关包的依赖
  implementation 'com.facebook.react:react-native:+'
  // 在这里可以配置其他依赖，如百度统计的 SDK、支付宝的 SDK 等
}
```

配置完 Gradle 后重新编译项目，Make it work.

# 3. 我想要一个 NPM Package

当我们辛辛苦苦写好了一个 Native Module，肯定会想把他共享出去，最好的平台自然就是 npm。同时发布到 npm 上还有一个好处就，在讲这个好处之前我们先来再看看 React Native 进行 Link 的过程中到底 Link 了啥：

当我们下载一个 React Native 包时，如果这个包有原生代码，那么它必定是要进行 Link 才能用的，这也是有的项目的 ReadMe 中会有手动 Link 指引的这一步。在这一过程中，主要进行了对主项目 Gradle 的配置，让其识别到下载的 Native Modules，以及注册 Native Modules，让我们可以在 Javascript 层调用到原生代码的能力。这是一个繁杂的过程，但是好在这些过程都有很多重复的地方，有重复就必定有自动化。因此在早期的社区中存在 rnpm 这种工具来帮助我们实现自动化 Link。在 React Native 0.60 以上版本，自动 Link 已经成了一种特性，我们再从 npm 下载下俩包之后，React Native 的构建工具 Metro 会自动的检索包，如果这个包是 Native Module，那么就会自动建立与 Android 项目以及 iOS 项目的连接。

因此将 Native Modules 作为 NPM Package 发布的额外一个好处就是，它会被 React Native 自动检测到并且进行自动化的连接。

开发一个 Native Module 的 NPM Package 其实并不难，我们可以使用一个很好用的 cli 工具来自动创建模板 [react-native-create-library](https://github.com/frostney/react-native-create-library)，按照 Readme 中的说明，我们可以创建一个如下的目录结构：

![](http://img.cdn.esunr.xyz/markdown/20200828201430.png)

我们只需要将写好的代码逻辑迁移过去就可以了，同时记得修改 Gradle 配置项，然后就是 NPM 的发包流程，这里不再赘述。

# 4. 参考教程

- [原生模块](https://reactnative.cn/docs/0.46/native-modules-android) 
- [开发自己的react-native组件并发布到npm](https://juejin.im/entry/6844903670694461454)
