package app.vd.pay.library.alipay;vdvd

import java.util.Map;

import android.text.TextUtils;

import app.vd.framework.extend.module.vdJson;
import app.vd.framework.extend.module.vdParse;

public class PayResult {
    private String resultStatus;
    private Object result;
    private String memo;
    private String msgName;

    public PayResult(Map<String, Object> rawResult) {
        if (rawResult == null) {
            return;
        }

        for (String key : rawResult.keySet()) {
            if (TextUtils.equals(key, "resultStatus")) {
                resultStatus = vdParse.parseStr(rawResult.get(key));
            } else if (TextUtils.equals(key, "result")) {
                result = vdJson.parseObject(rawResult.get(key));
            } else if (TextUtils.equals(key, "memo")) {
                memo = vdParse.parseStr(rawResult.get(key));
            } else if (TextUtils.equals(key, "msgName")) {
                msgName = vdParse.parseStr(rawResult.get(key));
            }
        }
    }

    @Override
    public String toString() {
        return "resultStatus={" + resultStatus + "};memo={" + memo + "};result={" + result + "};msgName={" + msgName + "}";
    }

    /**
     * @return the resultStatus
     */
    public String getResultStatus() {
        return resultStatus;
    }

    /**
     * @return the memo
     */
    public String getMemo() {
        if (resultStatus.equals("9000") && memo.isEmpty()) {
            memo = "支付成功";
        }
        return memo;
    }

    /**
     * @return the msgName
     */
    public String getMsgName() {
        return msgName;
    }

    /**
     * @return the result
     */
    public Object getResult() {
        return result;
    }
}
