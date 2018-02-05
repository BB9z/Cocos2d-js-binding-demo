
#import "iOSBinding.h"
#import "JSBH.h"

#pragma mark - 业务方法

bool jsb_APIVersion(JSContext* cx, uint32_t argc, jsval* vp) {
    NSString *v = NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"];
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JSBH_FunctionReturnInt(v.intValue);
    return true;
}

bool demoAdd(JSContext* cx, uint32_t argc, jsval* vp) {
    JSBH_FunctionAssertArgcNumber(2);
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JSBH_FunctionAssertArgsType(0, JSTYPE_NUMBER);
    JSBH_FunctionAssertArgsType(1, JSTYPE_NUMBER);

    bool ok = false;
    int a;
    int b;
    ok = jsval_to_int(cx, args[0], &a);
    JSB_PRECONDITION2(ok, cx, false, "Error processing arguments");
    ok = jsval_to_int(cx, args[1], &b);
    JSB_PRECONDITION2(ok, cx, false, "Error processing arguments");
    
    JSBH_FunctionReturnInt(a + b);
    return true;
}

bool demoAsyncOperation(JSContext* cx, uint32_t argc, jsval* vp) {
    JSBH_FunctionAssertArgcNumber(2);
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JSBH_FunctionAssertArgsType(0, JSTYPE_STRING);
    JSBH_FunctionAssertArgsType(1, JSTYPE_FUNCTION);
    
    bool ok = false;
    std::string input;
    ok = jsval_to_std_string(cx, args[0], &input);
    JSB_PRECONDITION2(ok, cx, false, "Error processing arguments");
    
    JSBH_GenerateFuncCallback(1, callback, NSString *response, NSString *errCode, NSString *errMessage) {
        JSB_AUTOCOMPARTMENT_WITH_GLOBAL_OBJCET
        jsval largv[2];
        largv[0] = JSBH_String(cx, response);
        largv[1] = JSBH_Error(cx, errCode, errMessage);
        JS::RootedValue rval(cx);
        bool succeed = func->invoke(2, &largv[0], &rval);
        if (!succeed && JS_IsExceptionPending(cx)) {
            JS_ReportPendingException(cx);
        }
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([NSStringFromSTDString(input) isEqualToString:@"x"]) {
            callback(nil, @"TEST", @"演示错误");
            return;
        }
        callback(@"After 1s response", nil, nil);
    });
    return true;
}

#pragma mark - JS 暴露

bool js_class_constructor(JSContext *cx, uint32_t argc, jsval *vp) {
    JS_ReportError(cx, "iOS 是命名空间，不支持创建对象");
    return false;
}

void js_class_finalize(JSFreeOp *fop, JSObject *obj) {
    CCLOG("jsbindings: finalizing JS object %p (iOS)", obj);
}

JSBH_GenerateClassRegisteFunction(iOS)
static JSPropertySpec properties[] = {
    JS_PSG("APIVersion", jsb_APIVersion, JSPROP_ENUMERATE | JSPROP_PERMANENT),
    JS_PS_END
};

static JSFunctionSpec funcs[] = {
    JS_FS_END
};

static JSFunctionSpec st_funcs[] = {
    JS_FN("demoAdd", demoAdd, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
    JS_FN("demoAsyncOperation", demoAsyncOperation, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
    JS_FS_END
};
JSBH_GenerateClassRegisteFunctionEND(iOS)

void jsb_ios_load() {
    ScriptingCore* sc = ScriptingCore::getInstance();
    sc->addRegisterCallback(jsb_registe);
}
