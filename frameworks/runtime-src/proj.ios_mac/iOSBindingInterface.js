/**
 * iOS native 暴露给 JS 的界面
 * 
 * 这只是一个例子，原生和 JS 那边的开发人员需要约定好接口，除了参数怎么传，错误处理和一些细节也应该标注
 */
var iOS = {

  /**
   * @property {int} - 接口版本，可用于兼容性处理
   */
  APIVersion: 7,

  /**
   * @callback ProductsListCallback
   * @param {string} listJSON - JSON 字符串，商品信息的数组
   * @param {object} error - 错误信息，没有错误为 null
   *  error code:
   *   'ILLEGAL_ARGS' 参数错误
   *    'SUBSTITUTED' 当前查询未完成就发起了一个新的查询，因而旧查询被替换掉。回调处理不应报错给用户。
   *    'TIMEOUT'     等待超时。回调处理建议提供允许用户重试的机制。
   *    'UNAVAILABLE' 当前设备不支持购买
   *    'NATIVE'      native 代码发生的其它错误
   */

  /**
   * 异步获取应用内购的商品列表
   * 
   * 如果查询传入时有无效的 ID，返回的条数会和传参数量不一致；返回商品信息的顺序和传入 ID 顺序保持一致
   * 
   * @param {string} list - 若干商品 ID，JSON 数组，数组元素是字符串
   * @param {ProductsListCallback} callback 操作完成回调
   */
  IAP_requestProductsList: (list, callback) => { },

  /**
   * @callback ProductsBuyCallback
   * @param {string} id - 购买商品的 ID
   * @param {object} error - 错误信息，没有错误为 null
   *  error code:
   *   'ILLEGAL_ARGS' 参数错误
   *    'CANCEL'      用户取消
   *    'INFO_TEMPORARILY_UNAVAILABLE' 暂时找不到商品信息。建议用户重试
   *    'DEFERRED'    等待后台处理，暂时无法完成购买
   *    'NATIVE'      native 代码发生的其它错误
   */

  /**
   * 购买内购商品
   * 
   * @param {string} id - 商品 ID
   * @param {string} user_id - 用户 ID
   * @param {ProductsBuyCallback} callback
   */
  IAP_buyProduct: (id, user_id, callback) => { }
};
