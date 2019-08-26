# MitImgChecker
[![](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://github.com/mcmengchen/MitUnUsedImgChecker/blob/master/LICENSE)<br>
[![](https://img.shields.io/badge/language-Swift-green.svg)](https://github.com/mcmengchen/MitUnUsedImgChecker)  <br>

| 中文 | [English](./Resources/README.md)  |
> 之前在项目中用 python 实现的，与工程绑定紧密，这次尝试用 swift 重写了一些扫描的 GUI 与逻辑，提供更多自定义功能。

## 如何使用 🚀
| 功能 | 使用方式 |
| --- |  --- |
| 扫描图片 | ![](./Resources/mv11.gif)|
| 定位图片位置 | ![](./Resources/mv22.gif)|

---

### 更多功能
| 功能  | 是否支持 |
| --- |  --- |
| 自定义扫描图片类型   | ✅ |
| 自定义被扫描文件类型   | ✅ |
| 自定义图片子路径黑名单   | ✅ |
| 自定义被扫描文件子路径黑名单   | ✅ |
| 代码片段扫描自定义图片前缀  | ✅ |
| 针对 .imageset(针对 iOS/MacOS 工程) 与实际图片命名不一致，并使用 imageset 文件时的扫描 | ✅ |
| 内容重复图片检测能力  | ✅ |

### 功能详情
+ a) 自定以扫描图片类型：
```
可以自定义增加或者删除 ```png, jpg, json...``` 格式的图片格式
```
+ b) 自定义被扫描文件类型：
```
比如要在 ```.m / .mm``` 文件中进行图片文件的扫描
```
+ c) 自定义图片子路径黑名单：
```
比如增加了 ```/123/```, 那么图片文件中带有路径 ```/123/``` 的就都会被过滤，为防止误过滤，尽量添加精确的路径。
```
+ d) 自定义被扫描文件子路径黑名单：
```
比如增加了 ```/file/```，那么会过滤掉被扫描文件路径中带有 ```/file/``` 中的文件，为防止误过滤，尽量添加精确的路径
```
+ e) 代码片段中扫描指定图片前缀
```
//图片名称可能是 a_01.png, 1_02.png ...
//代码中使用可能如下，此时无法准确匹配 a_01，那么此时添加图片代码前缀 a_ 就可以将其过滤掉
int num = 0;
[UIImage imageNamed:[NSString stringwithFormat:"a_%ld",num]]
```
+ f) 使用 .imageset 中文件与实际图片命名不一致时的兼容扫描
```
//这种关于个人代码风格问题，拖拽到 .xcaseets 中的图片之后，手动改一下 imageset 的文件名称。（恩，很头痛~）
代码是 1.png 但是拖进去之后 将生成的 1.imageset 改成了 2.imageset.
```
+ g) 内容重复图片检测能力
```
可以检测出不同名称相同内容的图片。
```

---



## 如何安装 🖥
### 下载源码，用 Xcode 运行

---

## TODO
### 优化搜索效率

---
