# Cocos2d-x js-binding Demo (iOS)

珍爱生命，远离 Cocos2D。

吐槽在最后，直接看如何用。在 Cocos2d 项目中，JS 与 native 间相互调用有三种方法：

1. [JS 通过 jsb.reflection 调用 native 方法](#reflection)
2. [Native 通过 ScriptingCore 执行 JS 代码](#scriptingcore)
3. [Native 通过 JSB 把注入方法到 JS 环境，供 JS 调用](#jsb)

在简要介绍完这三种方法后，是对 demo 的一些说明。

## <a name="reflection"></a>使用 jsb.reflection

在 JS 中形如：

```js
var returnValue = jsb.reflection.callStaticMethod("ObjectiveCClass", "methodWithParameter:", aParameter);
```

调用 Android 方法还要多一个方法签名的参数。使用方法不多说，这部分官方文档还是能看的。

* [How to call Objective-C functions using JavaScript on iOS/Mac](http://www.cocos2d-x.org/docs/creator/en/advanced-topics/oc-reflection.html)
* [How to Call Java methods using JavaScript on Android](http://www.cocos2d-x.org/docs/creator/en/advanced-topics/java-reflection.html)

但是，不推荐大规模用这种方法，因为不同平台代码无法统一会显得繁杂，而且限制比较多，只能调用静态的、同步的方法。

## <a name="scriptingcore"></a>Native 通过 ScriptingCore 执行 JS 代码

ScriptingCore 实例有 evalString 方法，可以传入 JS 字符串执行相应代码。如

```cpp
ScriptingCore::getInstance()->evalString("console.log('Hello word!')");
```

如果要接收返回值，稍微麻烦一点，见 [JSBH_EvalJSStringReturnString()](https://github.com/BB9z/Cocos2d-js-binding-demo/blob/f78d5dc16bd0c8a5664fc435231b78e9d480d45a/frameworks/runtime-src/Classes/JSBH.mm#L45)。

ScriptingCore 除了 eval 之外，还有其它像 executeFunctionWithOwner 这样的方法，但是大都要求有一定的上下文，一般在下面提到的 JSB 注入中才能用到。

eval is evil，简单但尽量避免使用。不得不用时注意不要频繁调用，不要拼接来自用户、第三方的输入，保持简单。

## <a name="jsb"></a>Native JSB 注入

相较上面两种方式，JSB 注入就强大多了（相应也更复杂），Cocos2d-x 引擎是 C++ 写的，能被 JS 调用靠的就是 JSB。

Cosos2d 中 JSB 有两种方式：auto、manual。网上搜 cocos2d js binding 可以搜到大把的文章，要么告诉你用官方的脚本自动绑定，要么贴出大段不知从那儿来 copy 来的代码手动完成绑定。

官方的自动绑定脚本在引擎目录下 [tools/tojs/genbindings.py](https://github.com/cocos2d/cocos2d-x/tree/v3/tools/tojs)，但是不建议去用。使用它你需要下载 Android NDK，下载 python 依赖，编写一个 ini 文件。你需要足够的耐心才能搞明白这个工具怎么用，然后足够幸运让这个脆弱的脚本成功输出得到一堆看上去比较复杂的东西。还有，路径中别有空格和符号哦。

打开 AppDelegate.cpp，你会看到这里通过 ScriptingCore 的 addRegisterCallback 注册了引擎的各种方法，参数都是一个 C 函数。点进去看大都一排排的代码长得都差不多。然后怎么写、怎么用？官方有个 [The Tutorial for JSB 2.0](http://www.cocos2d-x.org/docs/creator/en/advanced-topics/jsb/JSB2.0-learning.html)，但里面的 `se::ScriptEngine` 貌似是他们 IDE 里的，只有小部分和 Cocos2d-x 引擎有关（也就是我们需要涉及的部分）。

手动绑定在我看了半天代码后，了解到自己需要的程度。我不想把事情弄复杂，注入一个类当作名字空间，把需要的方法作为这个类的静态方法添加进来，JS 能传参，有回调函数就可以满足绝大多数业务上的需求了。

其实最终我们要想添加一个新业务是件很简单的事，但看着复杂是因为没有良好的封装。Cocos2d 引擎里集成了 Firefox 浏览器的 JS 引擎——SpiderMonkey，引擎的方法都是暴露出来的，但是注入用到的参数、方法只是很小的一部分，所以在看 Cocos2d 自带的绑定文件时，有大量的重复的内容，而且是我们不需要关心的。

我写了一些宏，把不需要关心的部分隐藏掉，下面讲的都是封装后的使用。这种东西，还是例子来得清晰，在 demo 中，iOSBinding 包含所有绑定逻辑，JSBH 里是 js-binding 的辅助工具。

[iOSBinding.h](https://github.com/BB9z/Cocos2d-js-binding-demo/blob/f78d5dc16bd0c8a5664fc435231b78e9d480d45a/frameworks/runtime-src/proj.ios_mac/iOSBinding.h) 很简单，对外暴露了一个方法，调用即可完成注册。

```h
#import <Foundation/Foundation.h>

void jsb_ios_load();
```

再看 [iOSBinding.m](https://github.com/BB9z/Cocos2d-js-binding-demo/blob/f78d5dc16bd0c8a5664fc435231b78e9d480d45a/frameworks/runtime-src/proj.ios_mac/iOSBinding.mm#L65)，注入类到 JS 的部分不过 30 行

```cpp
// 保持简单，只把类当作一个名字空间，不创建实例，构造函数和析构函数即可留空
bool js_class_constructor(JSContext *cx, uint32_t argc, jsval *vp) {
    return false;
}
void js_class_finalize(JSFreeOp *fop, JSObject *obj) {}

// 这部分是描述类的属性、方法和静态方法，用宏包裹起来了三个变量，添加新东西主要就在这
JSBH_GenerateClassRegisteFunction(iOS)
static JSPropertySpec properties[] = {
    JS_PS_END
};

static JSFunctionSpec funcs[] = {
    JS_FS_END
};

static JSFunctionSpec st_funcs[] = {
    // 添加一个方法，只需关心前两个参数——JS 环境下的方法名、C 方法名
    JS_FN("demoAdd", demoAdd, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
    JS_FS_END
};
JSBH_GenerateClassRegisteFunctionEND(iOS)

// ScriptingCore 注册，没什么好说的
void jsb_ios_load() {
    ScriptingCore* sc = ScriptingCore::getInstance();
    sc->addRegisterCallback(jsb_registe);
}
```

JS 可像这样调用：

```js
if (iOS) {
    var ret = iOS.demoAdd(1, 2);
    // 3
}
```

然后就是方法的实现 [iOSBinding.m](https://github.com/BB9z/Cocos2d-js-binding-demo/blob/f78d5dc16bd0c8a5664fc435231b78e9d480d45a/frameworks/runtime-src/proj.ios_mac/iOSBinding.mm#L14)

```cpp
bool demoAdd(JSContext* cx, uint32_t argc, jsval* vp) {
    // 检查参数个数
    JSBH_FunctionAssertArgcNumber(2);

    // 检查参数类型
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JSBH_FunctionAssertArgsType(0, JSTYPE_NUMBER);
    JSBH_FunctionAssertArgsType(1, JSTYPE_NUMBER);

    // 读取参数
    bool ok = false;
    int a;
    int b;
    ok = jsval_to_int(cx, args[0], &a);
    JSB_PRECONDITION2(ok, cx, false, "Error processing arguments");
    ok = jsval_to_int(cx, args[1], &b);
    JSB_PRECONDITION2(ok, cx, false, "Error processing arguments");

    // 设置返回值
    JSBH_FunctionReturnInt(a + b);
    return true;
}
```

写新的方法照着我的代码改一下就行了，异步回调的见 [iOSBinding.m](https://github.com/BB9z/Cocos2d-js-binding-demo/blob/f78d5dc16bd0c8a5664fc435231b78e9d480d45a/frameworks/runtime-src/proj.ios_mac/iOSBinding.mm#L32)

要更复杂的可以看看 cocos2d-x/cocos/scripting/js-bindings/manual 里的实现。

## Demo 说明

写这个 demo 我的首要目标就是尽可能保持简单、清晰。我不碰 Android 开发的东西，但是这里的方案稍作修改也适用于 Android 和其它平台。

## 维护 Cocos2d 项目的建议

如果你需要写比较多的原生代码的话：

* 手动开启 ARC，目前（最新是 3.16 版本） Cocos2d 生成的项目都没开 ARC 的，你不会想写 MRC 代码吧？
* 创建必要的中间层，隔离 C++ 代码。可能是 Cocos2d 引擎符号太多，Objective-C++ 下代码提示非常迟钝，几乎不可用，写 native 代码来说这是不可接受的，至少我这 Xcode 9.2 是这样的。

  另外，因为很多 OC 的代码是没考虑 C++ 环境的，一但混编动不动就编译不过。加上 Xcode 有编译缓存，可能写出去很多了才发现 build 错误。

## 吐槽

人生苦短，不吐槽了 😂
