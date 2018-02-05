

// 还是为了简便，把所有 demo 都写在这了，也只演示 iOS 的
if (sys.os === sys.OS_IOS) {
    var log = console.log;
    log('\nJSB demo start 🔜\n');

    // 调用 native 静态方法
    var ret = jsb.reflection.callStaticMethod('AppController', 'demoReverseListString:', 'foo,bar,apple,tree');
    log('🔶 jsb.reflection return: ' + ret);

    // 演示 native 通过 ScriptingCore 调用 JS
    // 代码在 native 项目中，这里只触发
    jsb.reflection.callStaticMethod('AppController', 'demoScriptingCore');

    // 调用 JSB 注入的方法
    log('🔶 iOS.APIVersion: ' + iOS.APIVersion);
    log('🔶 1 + 1 = ' + iOS.demoAdd(1, 1));
    iOS.demoAsyncOperation('x', deomCallbackHandler);
    iOS.demoAsyncOperation('this will success', function(response, error) {
        log('🔶 native response: ' + response);
        log('\nJSB demo end 🔚\n');
    });

    log('JSB demo EOF');
}

function deomCallbackHandler (response, error) {
    if (error) {
        if (error.code === 'TEST') {
            console.log('🔶 operation failed with error: TEST');
            return;
        }
        throw error;
    }
    console.log('🔶 operation succeed with response: ' + response);
}


var HelloWorldLayer = cc.Layer.extend({
    sprite:null,
    ctor:function () {
        //////////////////////////////
        // 1. super init first
        this._super();

        /////////////////////////////
        // 2. add a menu item with "X" image, which is clicked to quit the program
        //    you may modify it.
        // ask the window size
        var size = cc.winSize;

        /////////////////////////////
        // 3. add your codes below...
        // add a label shows "Hello World"
        // create and initialize a label
        var helloLabel = new cc.LabelTTF("Hello World", "Arial", 38);
        // position the label on the center of the screen
        helloLabel.x = size.width / 2;
        helloLabel.y = size.height / 2 + 200;
        // add the label as a child to this layer
        this.addChild(helloLabel, 5);

        // add "HelloWorld" splash screen"
        this.sprite = new cc.Sprite(res.HelloWorld_png);
        this.sprite.attr({
            x: size.width / 2,
            y: size.height / 2
        });
        this.addChild(this.sprite, 0);

        return true;
    }
});

var HelloWorldScene = cc.Scene.extend({
    onEnter:function () {
        this._super();
        var layer = new HelloWorldLayer();
        this.addChild(layer);
    }
});

