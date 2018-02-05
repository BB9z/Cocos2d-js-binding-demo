/*!
 Cocos2d-x js-binding 辅助工具
 
 */
#pragma once

#import "scripting/js-bindings/manual/jsb_helper.h"
#import "scripting/js-bindings/manual/ScriptingCore.h"
#import "scripting/js-bindings/manual/cocos2d_specifics.hpp"

/**
 生成类注册方法，一个文件只能用一次
 
 使用，需要 js_class_constructor，js_class_finalize 方法已定义
 @code
 JSBH_GenerateClassRegisteFunction(iOS)
 static JSPropertySpec properties[] = {
     JS_PS_END
 };
 static JSFunctionSpec funcs[] = {
     JS_FS_END
 };
 static JSFunctionSpec st_funcs[] = {
     JS_FS_END
 };
 JSBH_GenerateClassRegisteFunctionEND(iOS)
 @endcode
 
 生成的方法通过 addRegisterCallback 注入 JS 环境
 @code
 ScriptingCore *sc = ScriptingCore::getInstance();
 sc->addRegisterCallback(jsb_registe);
 @endcode
 */
#define JSBH_GenerateClassRegisteFunction(CLASS_NAME) \
    JSClass *js_class;\
    JSObject *js_class_prototype;\
    void jsb_registe(JSContext *cx, JS::HandleObject global) {\
        js_class = (JSClass *)calloc(1, sizeof(JSClass));\
        js_class->name = #CLASS_NAME;\
        js_class->addProperty = JS_PropertyStub;\
        js_class->delProperty = JS_DeletePropertyStub;\
        js_class->getProperty = JS_PropertyStub;\
        js_class->setProperty = JS_StrictPropertyStub;\
        js_class->enumerate = JS_EnumerateStub;\
        js_class->resolve = JS_ResolveStub;\
        js_class->convert = JS_ConvertStub;\
        js_class->finalize = js_class_finalize;\
        js_class->flags = JSCLASS_HAS_RESERVED_SLOTS(2);

#define JSBH_GenerateClassRegisteFunctionEND(CLASS_NAME) \
        js_class_prototype = JS_InitClass(cx, global, JS::NullPtr(), js_class,\
            js_class_constructor, 0,\
            nullptr, funcs, properties, st_funcs);\
        anonEvaluate(cx, global, "(function () { return " #CLASS_NAME "; })()").toObjectOrNull();\
    }

#define JSBH_GenerateFuncCallback(ARGS_INDEX, CALLBACK_NAME, ...)\
    JS::RootedObject jstarget(cx, args.thisv().toObjectOrNull());\
    std::shared_ptr<JSFunctionWrapper> func(new JSFunctionWrapper(cx, jstarget, args.get(ARGS_INDEX), args.thisv()));\
    auto CALLBACK_NAME = [=](__VA_ARGS__) -> void

/**
 设置返回给 JS 的方法返回值，字符串类型
 
 参数必须是 C string
 */
#define JSBH_FunctionReturnString(C_STR)\
    args.rval().set(STRING_TO_JSVAL(JS_NewStringCopyZ(cx, C_STR)));

/**
 设置返回给 JS 的方法返回值，整型
 */
#define JSBH_FunctionReturnInt(INT)\
    args.rval().set(INT_TO_JSVAL(INT));

/**
 设置返回给 JS 的方法返回值，null
 */
#define JSBH_FunctionReturnNull()\
    args.rval().set(JSVAL_NULL);

/**
 断言参数个数
 */
#define JSBH_FunctionAssertArgcNumber(NUM)\
    if (argc != NUM) {\
        JS_ReportError(cx, "%s: 参数个数错误", __FUNCTION__);\
        return false;\
    }

/**
 断言参数类型
 */
#define JSBH_FunctionAssertArgsType(NUM, JSTYPE)\
    if (JS_TypeOfValue(cx, args.get(NUM)) != JSTYPE) {\
        JS_ReportError(cx, "%s: 参数不是 %s", __FUNCTION__, #JSTYPE);\
        return false;\
    }

/// 转换 std::string => NSString
extern NSString *NSStringFromSTDString(std::string str);

/// 转换 NSString => std::string
extern std::string STDStringFromNSString(NSString *str);

/**
 生成约定的错误格式
 
 如果 code 和 message 都为空，返回 JSVAL_NULL
 */
extern jsval JSBH_Error(JSContext *cx, NSString *code, NSString *message);

/// 转换 NSString => jsval
extern jsval JSBH_String(JSContext *cx, NSString *string);

/**
 调用无返回值的 JS 代码
 
 @param evalString JS 脚本字符串
 @return 脚本执行失败返回 NO
 */
BOOL JSBH_EvalJSStringWithoutReturn(NSString *evalString);

/**
 调用返回值是 string 类型的 JS 代码
 
 @param evalString JS 脚本字符串
 @return 脚本执行失败返回 nil
 */
NSString *JSBH_EvalJSStringReturnString(NSString *evalString);

