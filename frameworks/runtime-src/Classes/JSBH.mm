
#import "JSBH.h"

NSString *NSStringFromSTDString(std::string str) {
    return @(str.c_str());
}

std::string STDStringFromNSString(NSString *str) {
    return std::string(str.UTF8String);
}

#define jsobj_addStringProperty(OBJ, NAME, VALUE) \
    JS_DefineProperty(cx, OBJ, NAME, JS::RootedValue(cx, std_string_to_jsval(cx, STDStringFromNSString(VALUE))), JSPROP_ENUMERATE | JSPROP_PERMANENT)

jsval JSBH_Error(JSContext *cx, NSString *code, NSString *message) {
    if (!code && !message) return JSVAL_NULL;
    JS::RootedObject tmp(cx, JS_NewObject(cx, NULL, JS::NullPtr(), JS::NullPtr()));
    if (!tmp) return JSVAL_NULL;
    bool ok = jsobj_addStringProperty(tmp, "code", code?: @"")
    && jsobj_addStringProperty(tmp, "message", message?: @"");
    if (ok) {
        return OBJECT_TO_JSVAL(tmp);
    }
    return JSVAL_NULL;
}

jsval JSBH_String(JSContext *cx, NSString *string) {
    return string? std_string_to_jsval(cx, STDStringFromNSString(string)) : JSVAL_NULL;
}

BOOL JSBH_EvalJSStringWithoutReturn(NSString *evalString) {
    if (!evalString.length) return nil;
    return ScriptingCore::getInstance()->evalString(evalString.UTF8String);
}

/**
 还是为了简便，只写了一个返回值是 string 的方法作为演示
 如需其它类型，查看一下还有哪些 jsval_to_ 方法稍作修改即可
 
 如果 Cocos2d-x 的版本很老的话，返回值要这样写
 jsval retVal;
 ScriptingCore::getInstance()->evalString(string, &retVal)
 http://forum.cocos.com/t/scriptingcore-getinstance-evalstring/40686
 */
NSString *JSBH_EvalJSStringReturnString(NSString *evalString) {
    if (!evalString.length) return nil;
    auto cx = ScriptingCore::getInstance()->getGlobalContext();
    JS::RootedValue retVal(cx);
    if (!ScriptingCore::getInstance()->evalString(evalString.UTF8String, &retVal)) return nil;
    std::string string;
    jsval_to_std_string(cx, retVal, &string);
    return NSStringFromSTDString(string);
}
