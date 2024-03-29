---
title: 数据报告海报生成图片、PDF方案的技术调研
tags:
  - 可视化
  - PDF
  - HTML2Canvas
  - jsPDF
categories:
  - 前端
  - 技术调研
date: 2024-02-21 11:05:54
---

# 1. 需求梳理

现存在一个需求，要求用户可以通过控制左侧的表单选项，在右侧实时展示为用户生成的数据海报，在用户调整完毕后，可以生成共享链接、图片、PDF 三种可分享的媒体形式，整体效果如下图：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202402231700518.png)

# 2. 海报的实时生成与预览

## 2.1 架构设计

整体页面的组件拆分并不复杂，可以简单分为如下几个组件：

- GeneratePage：顶级父组件，承接数据获取、数据处理、子组件之间的通信等逻辑；
- ControllerForm：左侧的表单控件组件，负责组织用户可操作的表单项，对外暴露 formData；
- PosterRender：右侧海报的实时渲染区域，组件输入为一个结构化的渲染 Schema，内部对组件进行渲染，其渲染的内容又可以单独拆分为多个子组件；

拆分完组件后我们就可以考虑数据流向问题了。首先，父组件从服务端获取生成海报的数据（dataSet）；然后，等用户操作表单从而获得表单数据（formData）；将海报数据和表单数据进行结合，生成渲染 Schema，渲染 Schema 包含了要渲染的组件名称（componentName）、为组件传递的参数（componentProps），然后 PostRender 组件就可以通过这些信息来渲染内容了，整体数据流如下图：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/%E4%BC%9A%E5%91%98%E6%B5%B7%E6%8A%A5%E7%94%9F%E6%88%90.drawio.png)

PostRender 组件负责根据 Schema 来渲染对应的组件，具体代码实现示例如下：

```vue
<script lang="ts" setup>
import { PosterSchema } from './types';
import ShopData from './components/ShopData.vue';
import CoreData from './components/CoreData.vue';

defineOptions({
  name: 'PostRender',
  components: {
    ShopData,
    CoreData,
  },
});

const props = withDefaults(
	defineProps<{schema?: PosterSchema}>(),
	{
		schema: () => ({}),
	}
);

const renderSchema = ref<PosterSchema>([]);

const loadSchema = async () => {
  /**
    * 加载 Schema，具体的实现取决于父组件如何向当前组件通信。
    * 比如当前组件作为子组件给父组件，那么这里就可以通过 props 来传递 schema；
    * 如果当前组件作为一个 iframe 嵌入到父组件，那么就使用 postMessage 来传递 schema；
    */
  renderSchema.value = props.schema
};

onMounted(() => {
  loadSchema();
});
</script>

<template>
  <div>
    <div
      class="bg-red-500 text-light-50 h-30 flex flex-col items-center justify-center"
    >
      <div class="text-3xl">会员数据效果报告</div>
      <div class="border-t border-light-50 mt-2 pt-2">
        MEMBER DATA PERFORMANCE REPORT
      </div>
    </div>
    <component
      :is="item.name"
      v-for="item in renderSchema"
      :key="item.name"
      v-bind="item.props"
    ></component>
  </div>
</template>
```

## 3.2 将渲染区域作为 iframe 嵌入

上面的示例我们是将 PosterRender 组件作为子组件嵌入到父组件中的，但是考虑到需求中还存在生成预览链接的要求，那么 PosterRender 应该作为一个独立的页面来执行渲染逻辑而并非子组件，因此为了考虑系统的统一性，同时尽量减少不必要的工作，一个比较好的实现方案是将 PosterRender 写为一个独立的页面，同时使用 iframe 嵌入到 GeneratePage 中，而 GeneratePage 与 PosterRender 之间的通信则使用 [postMessage](https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage) 来进行。

GeneratePage 与 PosterRender 之间通信的示例代码如下：

```ts
// iframe 的链接
const iframeSrc = window.location.origin + '... ...';

/**
 * 向 iframe 通信
 */
const postMessage2Iframe = (message: any) => {
  if (iframeRef.value) {
    iframeRef.value.contentWindow?.postMessage(
      {
        // 使用 source 字段区分来源，防止其他 message 污染通信
        source: 'posterGeneratePage',
        // Proxy 对象不能在 postMessage 中传递，这里的操作可以将 Proxy 对象进行序列化
        payload: JSON.parse(JSON.stringify(message)),
      },
      iframeSrc
    );
  }
};

/**
 * 将渲染 Schema 同步到 iframe
 */
const syncSchema2Iframe = (data?: ControllerFormData) => {
  if (dataSet.value) {
	// 根据服务端获取的海报数据和 formData 生成渲染 schema
    const schema = generateSchema(
      dataSet.value,
      data || (controllerFormRef.value?.formData ?? {})
    );
    postMessage2Iframe(schema);
  }
};
```

相对应的 PosterRender 中应该有接受 Message 的代码：

```ts
const renderSchema = ref<PosterSchema>([]);

const onReceiveMessage = (event: MessageEvent) => {
  if (event.data?.source === 'posterGeneratePage') {
    // 拿到父组件传过来的 schema
    renderSchema.value = event.data.payload;
  }
};

onMounted(() => {
  window.addEventListener('message', onReceiveMessage);
});

onUnmounted(() => {
  window.removeEventListener('message', onReceiveMessage);
});
```

对于 GeneratePage 来说，需要在如下三个阶段调用 `syncSchema2Iframe` 来通知 PosterRender 来实时渲染海报：

- 组件挂载时
- PosterRender 准备就绪时
- 表单数据更新时

其中『PosterRender 准备就绪时』需要 PosterRender 主动通知父组件，实现代码如下：

```ts
const postMessage2Parent = (message: any) => {
  if (window.parent) {
    window.parent.postMessage(
      {
        source: 'posterGenerateSubPage',
        payload: JSON.parse(JSON.stringify(message)),
      },
      '*'
    );
  }
};

onMounted(() => {
  // ... ...
  postMessage2Parent('ready');
});
```

父组件获取消息的方式与 PosterRender 类似，不再复述。

# 3. 生成海报图片、PDF

## 3.1 生成图片

使用 [html2canvas](https://html2canvas.hertzen.com/) 可以将 DOM 元素渲染到 canvas 中从而实现对 DOM 元素进行『截图』的操作。其基本原理也很简单，通过读取已经渲染好的 DOM 元素的结构和样式信息，再通过内部实现的 canvas 渲染器完成将 DOM 绘制到离屏 canvas 上，最终对外暴露出 HTMLCanvasElement 对象。

对于页面上的 iframe 元素，通过获取 `contentDocument.body` 元素，html2canvas 也可以将其很好的渲染出来，实现代码如下：

```ts
import html2canvas from 'html2canvas';

// ... ...

const onGenerateImage = () => {
  // 获取到 iframe 中的 DOM 元素
  const iframeBody = iframeRef.value?.contentDocument?.body;
  if (iframeBody) {
    html2canvas(iframeBody).then((canvas) => {
      // 创建图片
      const img = new Image();
      img.src = canvas.toDataURL('image/png');
      //  创建下载链接
      const a = document.createElement('a');
      a.href = img.src;
      a.download = 'poster.png';
      // 下载图片
      a.click();
    });
  }
};
```

但是由于 html2canvas 的工作原理，其可以正确渲染的 DOM 内容有一定的局限性，需要注意如下几点：

- 图片元素必须同源，否则会出现跨域问题
- 如果页面上有其他画布元素，且这些元素已被跨域内容污染，他们将不在被 html2canvas 读取
- 需要注意所支持渲染的 css 样式，具体查看[受支持的列表](https://html2canvas.hertzen.com/features)
- 无法读取插件内容，如 Flash 或 Java 小程序
- 低版本浏览器需要 Promise 的语法垫片
- [需要注意 Canvas 的像素限制](https://html2canvas.hertzen.com/faq)

> 注意：如果使用了 tailwind css 或者对 img 样式进行了重置，那么可能会造成生成的图片中的文本内容偏下，可以参考这个 [issue](https://github.com/niklasvh/html2canvas/issues/2775) 进行处理，**后文使用的 jsPDF 同样会出现此类问题**。

## 3.2 生成 PDF

[jsPDF](https://github.com/parallax/jsPDF) 是一个可以通过 JavaScript 在客户端环境下生成 PDF 的库，其基本原理是通过 JS 编程的方式生成 PDF 文件应有的组织形式，然后输出 base64 文件编码，提供给用户下载。

jsPDF 其内部提供了一套绘制 PDF 的 API，类似与 Canvas API（你甚至可以直接使用内部提供的  [`context2d`](https://raw.githack.com/MrRio/jsPDF/master/docs/module-context2d.html) 插件来使用 Canvas API 编写 jsPDF），来让用户以编程的方式向 PDF 写入内容，如文本、图片、表单项等；此外 jsPDF 还内置了 [html 插件](https://raw.githack.com/MrRio/jsPDF/master/docs/module-html.html#~html)，可以直接将 HTML 内容转换为 PDF 内容。

因此，如果我们想将生成的海报转为 PDF 输出，那么有两种方案：

### 方案一：将 HTML 内容转为图片后输出到 PDF

这个实现方案相对简单，并且输出的 PDF 内容与现有的 HTML 内容较为符合，但这样生成的 PDF 内容实际为一张图片，如果使用 PDF 查看工具打开后，内部的文本以及超链接内容是无法进行互动的。

其过程大致为使用 html2canvas 将 HTML 内容转为图片后，再使用 jsPDF 的 `addImage` 将图片贴入到 PDF 中，最后再输出，其具体实现如下：

```ts
const generatePdf = () => {
  const iframeBody = iframeRef.value?.contentDocument?.body;
  if (iframeBody) {
	// 根据 HTML 生成 canvas
    html2canvas(iframeBody).then((canvas) => {
      const imgData = canvas.toDataURL('image/png');
      const pdf = new jspdf({
        orientation: 'p',
        unit: 'mm',
        format: 'a4',
      });
      const imgProps = pdf.getImageProperties(imgData);
      // 获取 pdf 单页宽高
      const pdfPageWidth = pdf.internal.pageSize.getWidth();
      const pdfPageHeight = pdf.internal.pageSize.getHeight();
      // 将图片宽高按照 pdf 宽度进行等比缩放
      const imageResizeWidth = pdfPageWidth;
      const imageResizeHeight =
        (imgProps.height * pdfPageWidth) / imgProps.width;
      // 处理如果生成的图片高度超过 PDF 单页的高度，就要增加额外的 PDF 页
      if (imageResizeHeight > pdfPageHeight) {
	    // 使用 position 来记录每次向 PDF 新页面添加截图时的 y 轴起始坐标
        let position = 0;
        while (true) {
          pdf.addImage(
            imgData,
            'PNG',
            0,
            position,
            imageResizeWidth,
            imageResizeHeight
          );
          position -= pdfPageHeight;
          // 如果下一页添加截图时的 y 轴起始位置的绝对值高于图片本身，就说明下一页不需要添加图片了
          if (Math.abs(position) > imageResizeHeight) {
	        break;
          } 
          // 否则，增加 PDF 页面
          else {
            pdf.addPage();
          }
        }
      } else {
        pdf.addImage(imgData, 'PNG', 0, 0, imageResizeWidth, imageResizeHeight);
      }
      // 导出 PDF
      pdf.save('poster.pdf');
    });
  }
};
```

### 方案二：使用 jsPDF 的 `html` 插件将 HTML 内容转为 PDF

jsPDF 提供了一个内置的 `html` 插件方法，可以将 HTML 内容直接输出为 PDF，其原理是通过内部调用 html2canvas 的能力将 HTML 内容转为 Canvas，然后 jsPDF 内部实现了从 Canvas 转换到 PDF 的能力。使用该方式相对于方案一较为复杂，并且内部的转换过程对外是一个黑盒，多层转换会存在一些预期之外的问题，但是好处是生成的 PDF 内容中的文本以及超链接等都是 PDF 的原生内容，是可交互的。

#### 字体问题

jsPDF 并不提供 utf-8 编码的字体文件，因此在想 pdf 中添加中文、日文、韩文等字符时会乱码，如：

```ts
const pdf = new jspdf({
  orientation: 'portrait',
  unit: 'mm',
  format: 'a4',
});
pdf.text('[CN] 你好世界', 10, 10);
pdf.text('[JP] こんにちは世界', 10, 20);
pdf.text('[KR] 안녕하세요 세계', 10, 30);
pdf.text('[EN] Hello world', 10, 40);
// 直接在新窗口中展示 PDF 内容
pdf.output('pdfobjectnewwindow');
```

会显示为：

 ![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202402231533193.png)

官方给出的方案是通过 `setFont` 方法让用户加载自定义字体，具体参考 [官方文档的《Use of UTF-8/TTF》章节](https://artskydj.github.io/jsPDF/docs/index.html)。

选择开源字体在项目中使用是一个比较常用的方案，这里我们推荐使用 Adobe 的[思源黑体](https://github.com/adobe-fonts/source-han-sans)，其在 Github 完全开源，是可以免费使用并允许二次开发的，关于如何挑选思源黑体的各个版本可以参考：[《带你看懂思源字体的各个版本都有什么区别》](https://blog.esunr.site/2024/02/d54f000429f5.html)

我们这里直接挑选思源黑体的中文字体集，并下载 `.ttf` 格式的可变字体：[下载地址 (16.9M)](https://github.com/adobe-fonts/source-han-sans/blob/release/Variable/TTF/Subset/SourceHanSansCN-VF.ttf)。

下载完成之后我们可以按照如下方式加载字体，这样就可以正确的显示中文了：

```ts
import fontPath from '@client/assets/fonts/SourceHanSansCN-VF.ttf';

// ... ...

const pdf = new jspdf({
  orientation: 'portrait',
  unit: 'mm',
  format: 'a4',
});
// 下载字体文件
const fontRes = await fetch(fontPath);
// 将字体文件转为 Base64 编码
const fontBase64String = await fontRes.blob().then((blob) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
});
pdf.addFileToVFS(
  'SourceHanSansCN-VF',
  (fontBase64String as string).replace('data:font/ttf;base64,', '')
);
pdf.addFont('SourceHanSansCN-VF', 'SourceHanSansCN-VF', 'normal');
pdf.setFont('SourceHanSansCN-VF');
pdf.text('[CN] 你好世界', 10, 10);
pdf.text('[JP] こんにちは世界', 10, 20);
pdf.text('[KR] 안녕하세요 세계', 10, 30);
pdf.text('[EN] Hello world', 10, 40);
// 直接在新窗口中展示 PDF 内容
pdf.output('pdfobjectnewwindow');
```

显示效果如下：

![](https://esunr-image-bed.oss-cn-beijing.aliyuncs.com/picgo/202402231550332.png)

在引入字体时需要注意以下几点：

- 即使引入的是可变字体，也无法设置字重；
- jsPDF 仅支持 turetype font，也就是 `.ttf` 后缀格式的字体文件；
- 思源黑体的中文字体集中包含了日文字符，但是并不包含韩文，所以韩文是不显示的；
- 如果使用 html 生成 pdf，`setFont` API 是不生效的，`html` 方法在调用时提供了一个额外的 `fontFaces` 参数来让用户设置字体。

### 方法实现

解决了字体问题后，就可以来实现 HTML 转 PDF 的方法了，具体代码如下：

```ts
const generatePdf = () => {
  const iframeBody = iframeRef.value?.contentDocument?.body;
  if (iframeBody) {
    const pdf = new jspdf({
      orientation: 'p',
      unit: 'mm',
      format: 'a4',
    });
    // 在生成前需要指定目标 HTML 中所有元素的字体，否则会乱码
    const style = iframeBody.ownerDocument.createElement('style');
    style.innerHTML = "* { font-family: 'SourceHanSansCN-VF'; }";
    iframeBody.appendChild(style);
    // 根据 HTML 生成 PDF
    pdf.html(iframeBody, {
      // 声明字体
      fontFaces: [
        {
          family: 'SourceHanSansCN-VF',
          src: [
            {
              url: fontPath,
              format: 'truetype',
            },
          ],
        },
      ],
      // 输入到 PDF 中的内容的宽度，这里设置为 pdf 页面的宽度
      width: pdf.internal.pageSize.getWidth(),
      // 渲染 HTML 时的视口宽度，会影响渲染时的实际容器大小，这里直接设置为当前 iframe 的宽度
      windowWidth: iframeBody.clientWidth,
      callback: () => {
        style.remove();
        pdf.save('posterHtml.pdf');
      },
    });
  }
};
```

注意事项：

- jsPDF 在将 html 转为 PDF 时调用了 html2canvas，因此 html2canvas 转化过程中存在的问题，如样式兼容性、资源跨域等问题也会出现在 jsPDF 中；
- 转换出来的 PDF 中文字如果有下沉或者偏移的情况，详见 3.1 章节中的注意事项，也有可能是字体问题。