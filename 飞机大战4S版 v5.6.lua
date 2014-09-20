-- require "math"
-- require "zjLib"

-- 适用屏幕参数
SCREEN_RESOLUTION="640x960";
SCREEN_COLOR_BITS=32;

-- 全局变量
g_FightCnt = 0;     -- 每一轮比赛次数
bGoldFinish = 0;    -- 每日金币完成
bTaskFinish = 0;    -- 每日任务完成
bGivePower = 0;     -- 给好友送体力
bNoPower = false;   -- 标记是否没有体力
bFightTogether = 0; -- 找好友合体
isPowerEnough = false  -- 每日赠送体力已达上限

-- 配置初始化
mode=0;         -- 1-经典模式 2-剧情模式 3-PK模式
field=0;        -- 888-金币场 2888-超级金币场
login = 1       -- 登录模式, 1-QQ登录 2-微信登录
bBasicDrv = false;
bSuperDrv = false;
bGetAwards = true;
bGetMail = true;

g_ucUserDeviceId = "C8PK8GA6DTC0";

-- 界面
UI = {
    { 'DropList{QQ登录|微信登录}','LOGIN','登录模式: ' },
    { 'DropList{经典模式|剧情模式|PK模式888金币场|PK模式2888金币场}', 'MODE', '运行模式: ' },
    { 'DropList{1-2|2-3|3-5|5-8|8-13|13-21|21-34}','ROUND','一轮飞行的场次数目: ' },
    { 'DropList{是|否}','TASK','是否收取任务奖励: ' },
    { 'DropList{是|否}','MAIL','是否收取邮件: ' },
    { 'DropList{否|是}','BasicDriver','是否使用狂热驱动: ' },
    { 'DropList{否|是}','SuperDriver','是否使用超级狂热驱动: ' },        
    { 'TextView{脚本调试选项, 不了解请使用默认值.}'},
    { 'InputBox{10}','checkCnt','首页检查任务循环次数：' },
    { 'InputBox{100}','checkSleep','首页检查任务间隔(ms)：' },
    { 'InputBox{1000}','DELAY','页面读取延迟(ms): ' },
    { 'InputBox{90}','ac','精确度(%)：' },
    { 'InputBox{2}','og','寻址(px)：' },
    { 'TextView{全民飞机大战脚本v5.3}'},
    { 'TextView{作者：zhaojys}'},
    { 'TextView{邮件：zhaojys@qq.com}'},
    { 'TextView{更新时间：2014/09/15}'},
};

-- 初始化
function autoInit()

    math.randomseed(os.time())

    ac = tonumber(ac);
    og = tonumber(og);
    delay = tonumber(DELAY);
    min_fights = tonumber(min_fights);
    max_fights = tonumber(max_fights);

    if string.find(MODE, "经典模式") then
        mode = 1;
    elseif string.find(MODE, "剧情模式") then
        mode = 2;
    elseif string.find(MODE, "PK模式888金币场") then
        mode = 3;
        field = 888;
    elseif string.find(MODE, "PK模式2888金币场") then
        mode = 3;
        field = 2888;
    end

    if string.find(LOGIN, "微信登录") then login = 2 end
    if string.find(TASK, "否") then bGetAwards = false end
    if string.find(MAIL, "否") then bGetMail = false end
    if string.find(BasicDriver, "是") then bBasicDrv = true end
    if string.find(SuperDriver, "是") then  bSuperDrv = true end
    
    first, last, min_fights, max_fights = string.find(ROUND, "(%d+)%s*-%s*(%d+)")
    
    initRound();

    logDebug(string.format("INIT: login=%d, mode=%d, field=%d, ac=%d, og=%d, delay=%d, round=%d.", login, mode, field, ac, og, delay, round));
    logDebug(string.format("INIT: bGetAwards=%s, bGetMail=%s, bBasicDrv=%s, bSuperDrv=%s.", bGetAwards, bGetMail, bBasicDrv, bSuperDrv));

    return;
end

-- 检查飞机游戏是否运行, 没有则启动游戏
function checkAppRunning()
    if not appRunning("com.tencent.feiji") then
        appRun("com.tencent.feiji"); -- 启动飞机游戏
        logDebug(string.format("APP: com.tencent.feiji is stopped, run it."));
    end
end

function checkLicense()
    ucDeviceId = getDeviceID();
    if ucDeviceId == g_ucUserDeviceId then
        logDebug(string.format("License Check passed, Device ID is %s.", ucDeviceId));
        return true;
    else
        logDebug(string.format("License Check Faild, Invalid Device ID %s, EXIT!!!", ucDeviceId));
        return false;
    end
end

function initRound()
    g_FightCnt = 0;
    round = math.random(min_fights, max_fights); -- 最大比赛轮数，超过后领取奖励
end

-- 点击函数
function myClick(x, y)
    touchDown(0, x + math.random(-5, 5), y + math.random(-5, 5));
    mSleep(100 + math.random(-50, 50));
    touchUp(0);
end

function myMove(x1, y1, x2, y2)
    local step = 20;
    if y2 > y1 then step = -20 end

    local cnt = math.abs((y2 - y1) / 20);
    if cnt == 0 then
        cnt = 1;
        step = math.abs(y2 - y1);
    end

    touchDown(0, x1, y1);
	mSleep(50);
    for i = 1, cnt do
        mSleep(100);
        y1 = y1 - step;
        touchMove(0, x1, y1);
    end
    touchUp(0);
    mSleep(100);
end

-- 点击函数
function myClickWait(a1, b1, c1, x, y)
    while myFind(a1, b1, c1) == 1 do
        myClick(x, y);    -- 点击
        mSleep(1000);
    end
end

-- 本函数的功能：单点模糊找色判断
function myFind(x, y, color)
    x1,y1 = findColorInRegionFuzzy(color, ac, x - og, y - og, x + og, y + og)
    if x1 ~= -1 and y1 ~= -1 then
        return 1;
    else
        return 0;
    end
end

-- 多点模糊查找函数, 变参, 输入如下格式的参数: x1, y1, color1, x2, y2, color2...
function myMultiFind(...)

    arg={...};
    for i = 1, #arg - 2, 3 do
        -- logDebug(string.format("total = %d, arg[%d] = %d, arg[%d] = %d, arg[%d] = %d.",
        --                        #arg, i, arg[i], i + 1, arg[i + 1], i + 2, arg[i + 2]));
        if myFind(arg[i], arg[i + 1], arg[i + 2]) == 0 then
            return 0;
        end
    end

    return 1;
end

-- 主页面判断函数
function isHomePage()
    if myMultiFind(70,710,0x18385A,79,693,0x9C2042,583,671,0x186DAD) == 1 then
        return true;
    else
        return false;
    end
end

-- 判断主页面是否有任务完成函数
function isTaskFinish()
    if isHomePage() == true then -- 主界面
        for i = 1, checkCnt do
            if myFind(570,131,0x73797B) ~= 1 then
                logDebug(string.format("i = %d, find task finished, get awards.", i));
                return true;
            end
            mSleep(checkSleep);
        end
    end
    return false;
end

-- 领取邮件
function handleMail()

    -- 主界面有邮件
    if myMultiFind(70,729,0x18345A,504,102,0x8C1818) == 1 then
        myClick(480,105);     -- 进邮件界面
        logDebug("MAIL: Try to get mail.");
        mSleep(3000);

        while true  do
            -- 好友邮件条目存在
            if myMultiFind(572,360,0x8C1818) == 1 then
                bNoPower = false;
                logDebug("MAIL: Get friend mail successfully.");
                myClick(485,900);    -- 全部收取好友体力

            -- 有新好友邮件
            elseif myMultiFind(394,228,0x8C1818) == 1 then
                logDebug("MAIL: New friend mail exist.");
                myClick(320,236);    -- 点击好友邮件

            -- 系统邮件条目存在
            elseif myMultiFind(572,360,0x8C1818) == 1 then
                logDebug("MAIL: Get system mail successfully.");
                myClick(560,955);    -- 全部收取邮件

            -- 有新系统邮件
            elseif myMultiFind(598,228,0x8C1818) == 1 then
                logDebug("MAIL: New system mail exist.");
                myClick(590,250);     -- 点击系统邮件

            -- 弹出错误窗口,点击确认, 返回主界面
            elseif myMultiFind(231,582,0xF7C763,407,584,0xFFDF4A) == 1 then
                logDebug("MAIL: Failed to get system mail, return home.");
                myClick(324,586);
                mSleep(2000);
                break;
            else
                logDebug("MAIL: No more mail to get, return home.");
                break;
            end
            mSleep(1000);
        end
        mSleep(2000);
        logDebug("MAIL: Finish to get mail, return home.");
        myClick(60,900);    -- 返回主界面
        mSleep(1000);
    else
        logDebug("MAIL: No new mail to get, return home.");
    end
end

-- 领取奖励
function handleTask()

    -- 主界面
    if isHomePage() == true then
        logDebug("TASK: Try to get awards.");
        myClick(572,105);     --进任务界面
        mSleep(3000);

        while true do
        
            -- 每日任务已完成
            if myMultiFind(218,390,0xA51C00) == 1 then
                logDebug("TASK: Daily task has finished.");
                bTaskFinish = 1;
            end
            
            mSleep(100)
            
            -- 每日任务是向好友送体力
            if myMultiFind(253,274,0xD67D08,238,313,0x844508) == 1 then
                logDebug("TASK: Daily task is to give friend power.");
                if isPowerEnough == false then bGivePower = 6 end
            else
                bGivePower = 0
            end
            
            mSleep(100)
            
            -- 奖励任务是向好友送体力
            if myMultiFind(312,609,0xF7DF5A,313,634,0xFFA621,295,653,0xA57D52) == 1 then
                logDebug("TASK: Bonus task is to give friend power.");
                if isPowerEnough == false then bGivePower = 6 end
            else
                bGivePower = 0
            end
            
            mSleep(100)
            
            -- 每日任务是合体
            if myMultiFind(474,282,0x946D52,465,291,0x9C7963,484,291,0xC6AA8C,468,303,0xC6A284) == 1 and
               myMultiFind(481,303,0xC6AA8C,491,303,0xB59A7B,501,303,0xC6AE94) == 1 then  --找好友合体
                logDebug("TASK: Daily task, Choose friend to work together.");
                bFightTogether = 3;
            else
                bFightTogether = 0
            end
            
            mSleep(100)
            
            -- 奖励任务是合体
            if myMultiFind(474,581,0x946952,465,590,0xA5755A,484,590,0xC6AE8C,468,601,0x946952) == 1 and
               myMultiFind(481,601,0x946952,491,601,0x946D52,501,601,0x946952) == 1 then  --找好友合体
                logDebug("TASK: Bonus task, Choose friend to work together.");
                bFightTogether = 3;
            else
                bFightTogether = 0
            end
            
            mSleep(100)
            
            -- 领取每日任务奖励
            if myMultiFind(446,231,0xE79210) == 1 then
                logDebug("TASK: Get daily task awards successfully.");
                myClick(518,220);

            -- 领取赏金任务
            elseif myMultiFind(449,530,0xE79A18) == 1 then
                logDebug("TASK: Get bonus awards successfully.");
                myClick(523,520);

            -- 弹出错误窗口,点击确认, 返回主界面
            elseif myMultiFind(231,582,0xF7C763,407,584,0xFFDF4A) == 1 then
                logDebug("TASK: Failed to get task awards, return home.");
                myClick(324,586);
                mSleep(500);
                break;
            else
                logDebug("TASK: No more awards to get, return home.");
                break;
            end
            mSleep(1000);
        end

        mSleep(2000);
        logDebug("TASK: Finish to get awards, return home.");
        myClick(60,900);    -- 返回主界面
        mSleep(1000);
    else
        logDebug("TASK: No new awards to get, return home.");
    end
end

function handleClassic()

    -- logDebug("Handle Classic mode.");

    -- 金币刷完，任务做完，则退出进程
    if bGoldFinish == 1 and bTaskFinish == 1 then
        logDebug("WARNING: Classic Mode, Gold and task finished, EXIT!!!");
        os.exit();
    end

    if isHomePage() == true then -- 主界面
        logDebug("PAGE: Home, Enter classic mode.");
        myClick(530, 890);  -- 进经典模式
    end
end

function handleStory()

    -- logDebug("Handle story mode.");

end

function handlePK()

    -- logDebug("Handle PK mode.");

    -- 主界面
    if isHomePage() == true then
        logDebug("PAGE: HOME, Enter PK mode.");
        myClick(172, 904);         -- 进PK对战

    -- PK主界面
    elseif myMultiFind(447,314,0xCE5900,450,555,0x6300C6,445,794,0x0055C6) == 1 then
        if g_FightCnt >= round then
            logDebug("PAGE: Main PK, Return home, reach max fights.");
            myClickWait(447,314,0xCE5900,60,900); -- 返回
        else
            logDebug("PAGE: Main PK, Enter world PK.");
            myClick(332, 216);     -- 进世界对战
        end

    -- 世界对战界面
    elseif myMultiFind(447,215,0x103C9C,119,468,0xD67D10,216,752,0xEF2018) == 1 then
        if g_FightCnt >= round then
            logDebug("PAGE: World PK, Return home, reach max fights.");
            myClick(60, 900);     -- 返回
        elseif field == 888 then
            logDebug("PAGE: World PK, Enter 888 gold field.");
            myClick(162, 335);     -- 入888场
        elseif field == 2888 then
            logDebug("PAGE: World PK, Enter 2888 gold field.");
            myClick(162, 495);     -- 入2888场
        else
            myClick(60, 900);    -- 返回
        end
    end
end

function ChooseFriendFight()
    for i = 1, 3 do
        x1,y1 = findColorInRegionFuzzy(0x5A9600, ac, 612 - og, 230 - og, 612 + og, 710 + og)
        if x1 ~= -1 and y1 ~= -1 then
            logDebug("PAGE: Get friend, Choose a friend successfully.");
            return x1, y1;
        end
        logDebug("PAGE: Get friend, move friend list.");
        myMove(323,787,323,164);
        mSleep(100)
    end
    return -1, -1;
end

function handleCommon()

    -- logDebug("Handle Common mode.");

    -- 选择好友合体界面
    if myMultiFind(387,808,0xE7E3E7,373,91,0x5A5D63,416,91,0x73717B) == 1 then
        if g_FightCnt >= round then
            logDebug("PAGE: Get friend, Return home, reach max fights.");
            myClick(60, 900);     -- 返回
        else
            if bFightTogether > 0 then
                logDebug("PAGE: Get friend, Choose friend to fight together.");
                x1, y1 = ChooseFriendFight();
                if x1 ~= -1 and y1 ~= -1 then
                    bFightTogether = bFightTogether - 1;
                    myClick(x1 - 200, y1);   -- 点击好友合体
                    mSleep(100);
                end
            end
            logDebug("PAGE: Get friend, starting game.");
            myClick(480, 900);     -- 开始游戏
        end

    -- 购买道具界面
    elseif myMultiFind(254,104,0xCECFE7,400,105,0xCEC7D6,616,342,0x9CD721) == 1 then
        if g_FightCnt >= round then
            logDebug("PAGE: Buy property, return home, reach max fights.");
            myClick(60, 900);     -- 返回
        else
            logDebug("PAGE: Buy property, starting game.");
            myClickWait(254,104,0xCECFE7,480,900);   -- 开始游戏
        end

    -- 分数结算中
    elseif myMultiFind(233,454,0xFFE318,402,135,0xFFFFFF,412,135,0xFFFFFF) == 1 then
        logDebug(string.format("PAGE: Counting score now, %d/%d fights finished.", g_FightCnt, round));
        myClickWait(233,454,0xFFE318,60,900);

    -- 失败页面
    elseif myMultiFind(356,224,0xFFEBD6,356,30,0x425984,455,220,0x424D7B) == 1 then
        logDebug("PAGE: You are DEFEATED by someone.");
        myClickWait(356,224,0xFFEBD6,60,900);

    -- 胜利页面
    elseif myMultiFind(352,212,0x182039,450,185,0xFFEBDE,511,107,0x39385A) == 1 then
        logDebug("PAGE: You DEFEAT someone.");
        myClickWait(352,212,0x182039,60,900);

    -- 弹出窗口:你战胜了某某, 确定
    elseif myMultiFind(250,540,0x08AAFF,382,540,0xEFB631,170,408,0xA52C29) == 1 then
        logDebug("WIN: You DEFEAT someone.");
        myClickWait(250,540,0x08AAFF,208,538);

    -- 弹出窗口:你败于某某人,确定
    elseif myMultiFind(260,537,0x10A6FF,377,537,0xEFCF42,165,420,0x6B96AD) == 1 then
        logDebug("WIN: You are DEFEATED by someone.");
        myClickWait(260,537,0x10A6FF,208,538);

    -- 存在一个标准狂热驱动，使用
    elseif myMultiFind(334,285,0x188A7B) == 1 and bBasicDrv == true then
        logDebug("PAGE: Standard crazy driver exist, use it.");
        myClick(334,285);

    -- 存在两个狂热驱动，使用标准
    elseif myMultiFind(220,279,0x188A7B) == 1 and bBasicDrv == true then
        logDebug("PAGE: Two drivers exist, use standard crazy driver.");
        myClick(220, 279);

    -- 存在一个超级狂热驱动，使用
    elseif myMultiFind(330,281,0x7B14A5) == 1 and bSuperDrv == true then
        logDebug("PAGE: Super crazy driver exist, use it.");
        myClick(334,285);

    -- 存在两个狂热驱动，使用超级
    elseif myMultiFind(450,279,0x7B14A5) == 1 and bSuperDrv == true then
        logDebug("PAGE: Two drivers exist, use super crazy driver.");
        myClick(450, 279);

    -- 恭喜你获得以下物品页面
    elseif myMultiFind(92,46,0xD66D10,565,46,0xDE6910,482,139,0x6B1410) == 1 then
        logDebug(string.format("PAGE: Congratulations, You get something."));
        myClickWait(92,46,0xD66D10,345,703);

    -- 排名上升了,确定
    elseif myMultiFind(163,70,0xFFD329,482,70,0xFFDF39,482,85,0x631821) == 1 then
        logDebug("PAGE: Rank go up, confirm.");
        myClick(60, 900);

    -- 破纪录,确定
    elseif myMultiFind(313,240,0xFFEFCE,303,274,0x73414A,126,310,0x5A2021) == 1 then
        logDebug("PAGE: new record, ok.");
        myClick(60, 900);

    -- 你升级啦, 领取奖励
    elseif myMultiFind(314,144,0xEF7131,410,459,0x52386B,482,324,0x94969C) == 1 then
        logDebug("PAGE: You upgrade, get awards.");
        myClick(327, 833);

    -- 继续游戏
    elseif myMultiFind(199,343,0xFF9E00,180,343,0xFFEB94,199,517,0x008EE7) == 1 then
        logDebug("PAGE: Continue game.");
        myClick(322, 340);

    -- 体力商店, 返回
    elseif myMultiFind(436,190,0x2165A5,120,266,0xFFFB73,94,785,0x946139) == 1 then
        logDebug("PAGE: Power shop, return.");
        myClick(60, 900);

    -- 购买钻石, 返回
    elseif myMultiFind(170,220,0x009EFF,170,330,0x00A6FF,170,553,0x00A6FF,170,776,0x009EFF) == 1 then
        logDebug("PAGE: Diamond shop, return.");
        myClick(60, 900);

    -- 金币商店, 返回
    elseif myMultiFind(160,218,0xEFA608,160,328,0xCE7908,160,436,0xEFAA18,160,766,0xF7BA10) == 1 then
        logDebug("PAGE: Gold shop, return.");
        myClick(60, 900);

    -- 弹出窗口:只有一个中间的确定按钮,异常情况，需返回
    elseif myMultiFind(231,582,0xF7C763,407,582,0xF7DF4A,336,571,0xD67900) == 1 then
        logDebug("WIN: Something is wrong, return to home.");
        g_FightCnt = round;
        myClick(324, 586);

    -- 弹出窗口:体力不足, 取消
    elseif myMultiFind(93,601,0x08AAFF,550,606,0xF7CF39,158,417,0x080408) == 1 and
           myMultiFind(188,417,0x080408,167,438,0x63869C,175,432,0x100C10) == 1 then
        logDebug("WIN: not enough power, need to get mail.");
        g_FightCnt = round;
        bNoPower = true;
        myClick(177, 584);

    -- 弹出窗口:网络超时, 确定
    elseif myMultiFind(100,600,0x18AEFF,550,600,0xF7D742,110,424,0x31495A) == 1 and
           myMultiFind(278,424,0x31495A,447,421,0x395D73,451,433,0x000408) == 1 then
        logDebug("WIN: network delay, confirm.");
        myClick(464, 584);

    -- 系统设置和邀请好友界面, 返回主界面
    elseif myMultiFind(84,689,0x08B6EF,133,726,0x187DBD,318,747,0x525D63) == 1 then
        logDebug("PAGE: setting or invite friend, return home.");
        myClick(60, 900);

    -- 邮件界面, 返回主界面,并且收取邮件
    elseif myMultiFind(40,197,0xC66D08,280,170,0xDEFFA5,291,87,0x7B7D84) == 1 then
        logDebug("PAGE: mail, return home.");
        g_FightCnt = round;
        myClick(60, 900);

    -- 任务界面, 返回主界面
    elseif myMultiFind(111,236,0xCE9E63,111,535,0xC69E6B,333,86,0x9C92A5) == 1 then
        logDebug("PAGE: task, return home.");
        myClick(60, 900);

    -- 本周登陆礼包
    elseif myMultiFind(220,168,0x9C9EAD,221,151,0xADAEBD,236,142,0x949AA5) == 1 and
           myMultiFind(204,776,0x848A8C,206,776,0xFFEFA5,207,776,0xFFC752) == 1 then
        logDebug("PAGE: get weekly bonus, OK.");
        myClick(314,783);

    -- 累计登陆页面
    elseif myMultiFind(203,890,0xBDC7C6,208,890,0x8C8E8C,210,890,0xF7EFA5,211,890,0xFFCB5A) == 1 then
        logDebug("PAGE: weekly login, OK.");
        myClick(320, 900);

    -- 活动页面
    elseif myMultiFind(198,900,0xB5BEBD,199,900,0x84827B,201,900,0xFFEB94) == 1 then
        logDebug("PAGE: activity, OK.");
        myClick(320, 900);

    -- 选择微信还是QQ好友界面
    elseif myMultiFind(374,803,0xFFEB39,355,822,0x2182BD,367,821,0xDE6152,
                       393,822,0x2182BD,386,831,0xF78E08,361,831,0xD68210) == 1 then
        logDebug(string.format("LOGIN: login in game with mode %d.", login));
        if login == 1 then
            myClick(473,817); -- 选择QQ登录
        else
            myClick(177,817); -- 选择微信登录
        end
    end

    return 0;
end

-- 以下三个页面会记录一场比赛结束，需要统计比赛场次
function handleComplete()

      -- 加油哦!!!页面
    if myMultiFind(313,240,0xFFEFCE,305,279,0x8479A5,145,334,0x632429) == 1 then
        g_FightCnt = g_FightCnt + 1;
        logDebug(string.format("PAGE: Come on, %d/%d fights finished.", g_FightCnt, round));

        -- 金币已刷完
        if myMultiFind(136,611,0x393839,509,610,0x393839,320,546,0x393839,320,571,0x393839) == 1 then
            logDebug("PAGE: Come on, NO more gold to get per day.");
            bGoldFinish = 1;

            -- 任务也完成,并且是金币模式，则需要退出刷机
            if bTaskFinish == 1 and mode == 1 then
                g_FightCnt = round;
            end
        end
        logDebug("PAGE: Come on, return home.");
        myClickWait(313,240,0xFFEFCE,60,900); -- 回主界面

    -- 本周最高，单人
    elseif myMultiFind(313,240,0xFFEFCE,318,274,0x5A1C21,128,272,0x5A3842) == 1 then
        g_FightCnt = g_FightCnt + 1;
        logDebug(string.format("PAGE: Highest in week, %d/%d fights finished.", g_FightCnt, round));
        myClickWait(313,240,0xFFEFCE,60,900); -- 回主界面

    -- 本周最高，双人
    elseif myMultiFind(320,325,0xDE6531,171,42,0xEFD34A,490,42,0xB5C3C6) == 1 then
        logDebug(string.format("PAGE: Highest two people in week, %d/%d fights finished.", g_FightCnt, round));
        myClickWait(320,325,0xDE6531,60,900); -- 回主界面
    end

    return;
end

function GiveFriendPower()
    local i = 3;
    while bGivePower > 0 do
        x1,y1 = findColorInRegionFuzzy(0xD6A673, ac, 555 - og, 150 - og, 573 + og, 560 + og)
        if x1 ~= -1 and y1 ~= -1 then
            logDebug("PAGE: POWER, Choose a friend to give power.");
            myClick(x1, y1)
            bGivePower = bGivePower - 1
            
        -- 赠送体力成功, 下次吧
        elseif myMultiFind(231,577,0x08AAFF,231,617,0x08AAFF,411,617,0x00AEFF,411,576,0x08A6FF) == 1 then
            logDebug("PAGE: POWER, give power successfully, OK.");
            myClick(320,599)
            
        -- 赠送体力成功, 告诉TA
        elseif myMultiFind(377,576,0xEFC329,377,617,0xDE9218,554,614,0xF7CF39,554,573,0xF7EF63) == 1 then
            logDebug("PAGE: POWER, give power successfully, Tell him.");
            myClick(476,592)
            
        -- 每天只能赠送50点体力
        elseif myMultiFind(118,424,0x000808,117,428,0x080408,377,420,0x080000) == 1 and 
               myMultiFind(387,437,0x31495A,524,434,0x5A86A5,522,418,0x213439) == 1 then
            logDebug("PAGE: POWER, reach max 50 power.");
            isPowerEnough = true
            myClick(323,583)
            break
        else
            logDebug("PAGE: POWER, move friend list.");
            myMove(323,540,323,200)
            i = i - 1
            if i == 0 then break end
        end
        mSleep(1000)
    end
    
    if bGivePower == 0 then bTaskFinish = true end  
    
    return
end

function AutoRun()

    if isHomePage() == true then  -- 主界面
    
        -- 需要送体力
        if bGivePower > 0 then GiveFriendPower() end
        
        -- 达到最大轮次或者有任务完成，则去领取任务奖励
        if g_FightCnt >= round or isTaskFinish() == true then
            logDebug(string.format("PAGE: Home, Need to get awards and mail, reach max %d/%d fights.", g_FightCnt, round));
            return round;
        end
    end

    if mode == 1 then  -- 经典模式
        handleClassic();
    elseif mode == 2 then  -- 剧情模式
        handleStory();
    elseif mode == 3 then  -- PK模式
        handlePK();
    end

    handleCommon();     -- 通用处理

    handleComplete();   -- 一轮结束处理

    return 0;
end

-- 主入口函数
function main()

    autoInit();  -- 初始化

    -- 检查授权
    if checkLicense() ~= true then
        notifyMessage("WARNING: License check failed, EXIT!!!", 3000);
        os.exit();
    end

    while true do

        checkAppRunning();

        ret = AutoRun();  -- 自动运行
        if ret ~= 0 then

            -- 领取任务
            if bGetAwards == true then
                handleTask();
            end

            -- 领取邮件
            if bGetMail == true then
                handleMail();
            end

            -- 体力不足退出
            if bNoPower == true then
                logDebug("WARNING: not enough power, EXIT!!!");
                os.exit();
            end

            -- 再进行一轮初始化
            initRound();

            logDebug(string.format("INIT: data update, round=%d, bGivePower=%d, bFightTogether=%d.",
                     round, bGivePower, bFightTogether));
        else
            mSleep(delay + math.random(-500, 500));
        end
    end
end


