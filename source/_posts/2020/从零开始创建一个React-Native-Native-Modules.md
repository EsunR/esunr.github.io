---
title: 从零开始创建一个 React Native Native Modules
tags: [ReactNative]
categories:
  - Front
  - React
date: 2021-07-01 19:50:20
---

# 1. 什么是 Native Modules

首先我们要明白 Native Native 之所以能够跨端调用 Android、iOS 的能力，就是因为 Javascript 只是提供了 Bridge 层的调用，具体的实现代码还是由原生的 Android、iOS 代码来实现的：

![](https://i.loli.net/2021/07/01/rgtEAhVUc3mTiy7.png)

因此，理论上如果我们编写了一个使用 Android 或 iOS 的原生代码，只要为其建立 Javascript 层的 Bridge，那么我们就可以通过 Javascript 层的代码来调用这些原生代码的能力。而 Native Modules 正是为我们来实现这一目标的。

Native Modules 是一个很令人兴奋的能力，但是代价就是我们始终要开发并维护两套代码，并让他们在 Javascript 层合二为一。因此社区上便出现了两种包：一种是普通的组件包，其本质还是 Javascript 代码，调用的是 React Native 封装好的逻辑（如：react-native-scrollable-tab-view）；而另一种就是基于 Native Modules 的包，其不仅由 Javascript 代码进行构建，同时还会使用 Android、iOS 端的原生代码进行构建（这些包之前在社区中是由 rnpm 管理的，但是自 React Native 支持自动 link 后就不存在这种差异了）。区分这两种包的最简单方法就是看其源代码中是否有 `android` 或 `ios` 文件夹，如果有，那它就是一个基于 Native Modules 开发的包。

# 2. 开发一个 Native Module

## 2.1 安卓端 Native Module

### 2.1.1 编写原生代码

在 React Native 官方文档的 [Android 原生模块](https://reactnative.cn/docs/0.46/native-modules-android) 这一章节中，对如何封装一个 Native Modules 进行了详细的描述，按照指引我们可以封装出来一个 Toast 模块。

在这里不对文章的内容进行复述（如果你还没有看该文章，快马上看看）总结该文章，其要点分为如下几步：

1. 创建一个名为 ToastModule 的 Class，在这一步中重点是需要去复写其 `getName()` 方法来作为JavaScript 端这个模块的标记。之后我们再该类下写的所有方法（被 `@ReactMethod` 所标记的）最终都会被注册到 Javascript 层调用的这个组件之上，因此它的开发是我们的主要工作。
2. 创建一个名为 AnExampleReactPackage 的 Class，这一步主要是去注册我们上一步所创建的 Module。
3. 进入项目的 `MainApplication.java` 文件中，进行手动连接（这一步就是我们在使用第三方包时执行 react-link 所做的其中一步，我们后续会重提）。
4. 在 Javascript 中调用 Bridge。

![](https://i.loli.net/2021/07/01/M1E42L3OJKUhCXP.png)

至此，我们已经完成了一个简单的 Native Modules，打通了 Javascript 与原生层的交互。

### 2.1.2 将原生代码改造为 Android Module

在完成了官方文档的《原生模块》这一章节后，我们的 Android 目录下的 java 代码中会是这样的：

![](https://i.loli.net/2021/07/01/usFm1PkK9LSgGdI.png)

我们新增了 `xxxModule.java` 与 `xxxPackage.java` 这两个文件。这里可以发现我们编写的 Native Modules 和原生的代码杂糅在一个文件夹下了，这样不仅会~~逼死强迫症~~，同时我们无法将编写好的代码抽离为一个独立的 Modules。

我们先看一下如果我们项目中引用了别的开发者所开发的 Native Modules，项目的结构是怎么样的，注意这一步我们需要使用 Android Studio 打开项目，并且对项目进行 Sync，当 Sync 完成后我们会看到与 `app` 同级的目录下多了很多以 `react-native` 开头的包：

![](https://i.loli.net/2021/07/01/QZtdohpy2bOHxW9.png)

要想明白这些包是从哪里来的，就需要牵涉出另一个概念，所谓的 “Android 模块化开发”。在安卓应用的开发过程中，我们不可能把所有的代码都塞入到一个目录下，这样不利于项目的模块化，因此在 Android 开发中存在 **Module** 这一概念。**每一个单独的 Module 都拥有独立的 Gradle，以及独立的 Package Name，以及独立的逻辑代码**，它存在的意义仅仅是负责处理一个模块级别的功能。

当我们对项目右键时，就可以新建一个 Module：

![](https://i.loli.net/2021/07/01/1L863TWlQpMabGN.png)

如果我们要开发一个 RN 的 Native Modules，这个 Module 将不会包含任何 Active，那我们就可以选择创建一个 Android Library：

![](https://i.loli.net/2021/07/01/Nvm9CLauok31FqZ.png)

之后你便可以设置一个模块名，这个模块名按照规范应该以 `react-native` 开头，如 `react-native-tester`。当创建完成后，需要等待 Android Studio 再次 Sync，此时 Android Studio 替我们做了两步：

- 在 `android/app` 目录下，创建了一个你所命名的模块同名的文件夹，作为你所要搭建的模块的目录。
- 在 `settings.gradle` 中写入了一行 `include ':react-native-xxx'`，说明你的项目中引用了你刚才所创建的 Module（这也是 React Native 在进行第三方包自动 Link 的其中一步）。

此时再看我们的工程文件，app 的同级目录下就多了一个名为 `react-native-xxx` 的 Module。

由此，我们就可以理解，那些以 `react-native` 开头的 Module 其实都来自于我们所下载的第三方包，他们本质是存在于 `node_modules` 目录下的，在项目编译的过程中会被建立了一层链接，从而我们可以在 Android Studio 的工程目录看到他们（这也是 React Native 在进行自动 Link 的功劳）：

![](https://i.loli.net/2021/07/01/E4yjhnWLcg5Y8si.png)

我们创建了一个独立的 Module 之后，可以先把自创建的测试相关的文件删除掉，这样就得到了一个简洁的目录，同时可以将我们之前写在 app 目录下的代码抽离出去，这样不仅我们的代码结构更清晰了，又可以为单独的 Module 进行独立的 Gradle 配置，不再会依赖主项目的 Gradle 版本。此时，目录结构应该为：

![](https://i.loli.net/2021/07/01/OULeCdNKlp5QgGc.png)

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

## 2.2 IOS 端 Native Module

React Native 文档中同样有一节 [IOS 原生模块](https://reactnative.cn/docs/native-modules-ios) 的文章，但是文章内容还是不太详尽，在本文中我们会对其进行补充。

IOS 与 Android 的开发不太相同，在 IOS 端的开发过程中，使用了 `Pod` 来管理 Native 层的依赖，如果我们想运行 IOS 端的项目，你除了要创建好对应的 IOS 开发环境之外，还要在项目的 `ios` 目录下执行：

```shell
$ pod install
```

在代码的执行过程中，ReactNative 在自动为 react native module 创建 Native 层的连接，并下载相关的依赖：

![](https://i.loli.net/2021/07/01/Znj8LPe3SgN9hDH.png)

当下载完成后，使用 XCode 打开项目 ios 目录的 `.xcworkspace` 文件，然后可以在文件列表视图中看到已经下载了多个 Pod 的依赖：

![](https://i.loli.net/2021/07/01/YwE7TjFd86t2c5b.png)

之后我们就可以开发我们的 Native Module 了。首先我们右键项目文件夹，然后点击 `New group with folder` 来创建一个文件夹 `CalendarManager`，作为我们 Native Module 所属的文件夹：

![](https://i.loli.net/2021/07/01/FfPkClTArRtuaGq.png)

然后再右键新创建的文件夹，选择 `new file`，然后再在弹出的对话框中选择 `Cocoa Touch Class`：

![](https://i.loli.net/2021/07/01/Fo8MyK5SveO7qT9.png)

Class 的名称就是我们的模块名，我们在此将其写为 `CalendarManager`：

![](https://i.loli.net/2021/07/01/V6cDnh4MECZNRuY.png)

然后我们可以选择将文件创建在某一目录下，但是必须要注意选中下面的 Group 与 Targets 分别我们刚才创建的分组与当前项目：

![](https://i.loli.net/2021/07/01/ag6tmIk9H1UicsQ.png)

之后我们可以看见对应的 `CalendarManager` 分组下出现了两个文件，分别为 `CalendarManager.h` 和 `CalendarManager.m`：

![](https://i.loli.net/2021/07/01/wVmI5h1bYO4aj6L.png)

我们分别拷贝如下代码到目标文件：

```
// CalendarManager.h
#import <React/RCTBridgeModule.h>

@interface CalendarManager : NSObject <RCTBridgeModule>
@end
```

```
// CalendarManager.m
#import "CalendarManager.h"
#import <React/RCTLog.h>

@implementation CalendarManager

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(addEvent:(NSString *)name location:(NSString *)location)
{
  RCTLogInfo(@"Pretending to create an event %@ at %@", name, location);
}

@end
```

这样我们就创建了一个原生模块，这个原生模块可以向 XCode 的控制台输出一行文字，我们构建好项目后，只需要在 js 代码中调用：

```js
import { NativeModules } from 'react-native';
const CalendarManager = NativeModules.CalendarManager;
CalendarManager.addEvent(
  'Birthday Party',
  '4 Privet Drive, Surrey'
);
```

XCode 的控制台便可以输出：

![](https://i.loli.net/2021/07/01/iJpFf56t9B7Y3Xb.png)

如果在 JS 中调用的 Native Module 报错，其输出是一个 null，尝试一下清空 XCode 缓存（`调用：rm -rf ~/Library/Developer/Xcode/DerivedData/*`）然后再重新构建，如果还不行，尝试清空 Pod 缓存并重新安装 Pod 依赖：

```
# 清空 Pod 缓存
rm -rf ~/Library/Caches/CocoaPods; 
rm -rf Pods; 
rm -rf ~/Library/Developer/Xcode/DerivedData/*; 
pod deintegrate; 
pod setup; 
pod install;
```

关于更多的需求，包括如何在 Native Module 中使用变量，请参考官方文档。

> PS：IOS 可以将 Native Module 创建为一个静态库来实现模块化管理（类似 Android Module），但是由于在实验过程中，会出现无法找到 React 依赖的问题（参考：https://github.com/yorkie/react-native-wechat/issues/33，经过实验 react-native 0.63.1 通过设定 header link path 还是无法解决），这个我们后续再讲吧。

# 3. 我想要一个 NPM Package

## 3.1 关于安卓

当我们辛辛苦苦写好了一个 Native Module，肯定会想把他共享出去，最好的平台自然就是 npm。同时发布到 npm 上还有一个好处就，在讲这个好处之前我们先来再看看 React Native 进行 Link 的过程中到底 Link 了啥：

当我们下载一个 React Native 包时，如果这个包有原生代码，那么它必定是要进行 Link 才能用的，这也是有的项目的 ReadMe 中会有手动 Link 指引的这一步。在这一过程中，主要进行了对主项目 Gradle 的配置，让其识别到下载的 Native Modules，以及注册 Native Modules，让我们可以在 Javascript 层调用到原生代码的能力。这是一个繁杂的过程，但是好在这些过程都有很多重复的地方，有重复就必定有自动化。因此在早期的社区中存在 rnpm 这种工具来帮助我们实现自动化 Link。在 React Native 0.60 以上版本，自动 Link 已经成了一种特性，我们再从 npm 下载下了包之后，React Native 的构建工具 Metro 会自动的检索包，如果这个包是 Native Module，那么就会自动建立与 Android 项目以及 iOS 项目的连接。

因此将 Native Modules 作为 NPM Package 发布的额外一个好处就是，它会被 React Native 自动检测到并且进行自动化的连接。

开发一个 Native Module 的 NPM Package 其实并不难，我们可以使用一个很好用的 cli 工具来自动创建模板 [react-native-create-library](https://github.com/frostney/react-native-create-library)，按照 Readme 中的说明，我们可以创建一个如下的目录结构：

![](http://img.cdn.esunr.xyz/markdown/20200828201430.png)

我们只需要将写好的代码逻辑迁移过去就可以了，同时记得修改 Gradle 配置项，然后就是 NPM 的发包流程，这里不再赘述。

## 3.2 关于 IOS

> 由于在 IOS 的模块开发中遇到了很多坑，因此在这里记录一下。

利用 react-native-create-library 创建好一个 Native Module 框架后，其 IOS 目录是这样的：

```
├── RNMyFancyLibrary.h
├── RNMyFancyLibrary.m
├── RNMyFancyLibrary.podspec
├── RNMyFancyLibrary.xcodeproj
│   └── project.pbxproj
└── RNMyFancyLibrary.xcworkspace
    └── contents.xcworkspacedata
```

我们来看下这些文件是什么意思：

- `.h` 和 `.m` 是我们的模块代码，我们将原生模块的代码内容复制过来即可；
- `.xcodeproj` 和 `.xcworkspace` 是项目相关的配置；
- `.podspec` 是用于 描述一个 Pod 库的源代码和资源将如何被打包编译成链接库或 framework 的文件

`.podspec` 如果配置失败的话是没有办法正确解析整个 Native Module 的，因此我们来重点讲一下这个文件，我们打开 react-native-create-library 创建好的 podspec 文件看下它里面都声明了什么：

```
Pod::Spec.new do |s|
  s.name         = "RNMyFancyLibrary"
  s.version      = "1.0.0"
  s.summary      = "RNMyFancyLibrary"
  s.description  = <<-DESC
                  RNMyFancyLibrary
                   DESC
  s.homepage     = ""
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/author/RNMyFancyLibrary.git", :tag => "master" }
  s.source_files  = "RNMyFancyLibrary/**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end
```

- `name` `version` `description` `license` `author` `platform` 是指模块的基础信息
- `homepage` 是项目的主页，我们可以将其设置为 npm 包地址，如果不设置在 `pod install` 时会报错
- `source` 是项目源代码地址，我们要将其改为 github 源代码托管的地址
- `source_files` 指源码的路径，这里的路径是以当前 podspec 文件为基准的相对路径，需要设置为你开发的 Native Module 的路径，也就是 `.h`、`.m`、`.swif` 等文件的路径，对于默认生成的模块，`.h` 与 `.m` 都在当前 podspec 文件的路径下，**因此这里要改为 `/**/*.{h,m}`，否则模块在 js 引用时会报错**。
- `dependency` 为当前 Native Module 需要引用的第三方的包

# 4. 参考教程

- [原生模块](https://reactnative.cn/docs/0.46/native-modules-android) 
- [开发自己的react-native组件并发布到npm](https://juejin.im/entry/6844903670694461454)
- [原生模块的开发](https://www.kancloud.cn/guif_zhang/rn/451978)
- [How to Create a React Native iOS Native Module](https://blog.tylerbuchea.com/how-to-create-a-react-native-ios-native-module/)
- 参考封装模块: [react-native-baidu-mtj](https://github.com/EsunR/react-native-baidu-mtj)