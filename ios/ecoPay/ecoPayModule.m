
#import "ecoPayModule.h"
#import "Config.h"
#import <AlipaySDK/AlipaySDK.h>
#import "WXApi.h"
#import <WeexPluginLoader/WeexPluginLoader.h>

static WXModuleKeepAliveCallback alipayCallback;
static WXModuleKeepAliveCallback weixinCallback;

@implementation ecoPayModule

WX_PlUGIN_EXPORT_MODULE(ecoPay, ecoPayModule)
WX_EXPORT_METHOD(@selector(weixin:callback:))
WX_EXPORT_METHOD(@selector(alipay:callback:))

+ (void)alipayHandleOpenURL:(NSURL *) url
{
    [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
        [ecoPayModule onAlipayResp:resultDic];
    }];
}

+ (BOOL)weixinHandleOpenURL:(NSURL *) url
{
    return [WXApi handleOpenURL:url delegate:(id<WXApiDelegate>)[[ecoPayModule alloc] init]];
}

//支付宝结果回调
+ (void)onAlipayResp:(NSDictionary *)result
{
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    if (result != nil) {
        [data setObject:result[@"resultStatus"] forKey:@"status"];
        [data setObject:result[@"result"] forKey:@"result"];
        if ([data[@"status"] isEqualToString:@"9000"] && !result[@"memo"]) {
            [data setObject:@"支付成功" forKey:@"memo"];
        }else{
            [data setObject:result[@"memo"] forKey:@"memo"];
        }
    }
    if (alipayCallback != nil) {
        alipayCallback(data, NO);
        alipayCallback = nil;
    }
}

// 微信支付结果回调
- (void)onResp:(BaseResp *)resp
{
    if (weixinCallback != nil) {
        NSString *msg;
        if (resp.errCode == 0) {
            msg = @"支付成功";
        }else if (resp.errCode == -1) {
            msg = @"可能的原因：签名错误、未注册APPID、项目设置APPID不正确、注册的APPID与设置的不匹配、其他异常等";
        }else if (resp.errCode == -2) {
            msg = @"用户取消";
        }else{
            return;
        }
        weixinCallback(@{@"status":@(resp.errCode), @"msg":msg}, NO);
        weixinCallback = nil;
    }
}

/*******************************************************************************************/
/*******************************************************************************************/
/*******************************************************************************************/

//官方微信支付
- (void)weixin:(NSString *)payData callback:(WXModuleKeepAliveCallback)callback
{
    NSError *err;
    NSMutableDictionary *dic = nil;
    if ([payData isKindOfClass:[NSDictionary class]]) {
        dic = (NSMutableDictionary *)payData;
    }else{
        NSData *jsonData = [payData dataUsingEncoding:NSUTF8StringEncoding];
        dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    }
    if (!err && dic[@"appid"]) {
        NSMutableDictionary *wxpay = [Config getObject:@"wxpay"];
        NSString *universalLink = [NSString stringWithFormat:@"%@", wxpay[@"universalLink"]];
        [WXApi registerApp:dic[@"appid"] universalLink:universalLink];
    }else{
        weixinCallback(@{@"status":@(-999), @"msg":@"注册微信支付失败"}, NO);
        return;
    }
    //
    weixinCallback = callback;
    PayReq *req  = [[PayReq alloc] init];
    req.partnerId = [WXConvert NSString:dic[@"partnerid"]];
    req.prepayId = [WXConvert NSString:dic[@"prepayid"]];
    req.package = [WXConvert NSString:dic[@"package"]];
    req.nonceStr = [WXConvert NSString:dic[@"noncestr"]];
    req.timeStamp = [dic[@"timestamp"] intValue];
    req.sign = [WXConvert NSString:dic[@"sign"]];
    [WXApi sendReq:req completion:^(BOOL success) {
        if (!success && weixinCallback != nil) {
            weixinCallback(@{@"status":@(-999), @"msg":@"启动微信支付失败"}, NO);
            weixinCallback = nil;
        }
    }];
}

//官方支付宝支付
- (void)alipay:(NSString*)payData callback:(WXModuleKeepAliveCallback)callback
{
    NSString *fromScheme = @"";
    NSDictionary *infoDicNew = [NSBundle mainBundle].infoDictionary;
    for (NSDictionary *object in infoDicNew[@"CFBundleURLTypes"]) {
        if ([object[@"CFBundleURLName"] isEqualToString:@"ecoAppName"]) {
            fromScheme = object[@"CFBundleURLSchemes"][0];
            break;
        }
    }
    alipayCallback = callback;
    [[AlipaySDK defaultService] payOrder:payData fromScheme:fromScheme callback:^(NSDictionary *resultDic) {
        [ecoPayModule onAlipayResp:resultDic];
    }];
}

@end
