--[[
3.2更新日志
    1. 可以完成合体任务
    2. 细化界面调试信息
3.1更新日志
    1. 细微优化
3.0更新日志
    1. 经典模式刷完任务即停止
3.0更新日志
    1. 增加剧情模式
    2. 如果在任务或是邮件页面，则不能继续处理  
2.8更新日志
    1. 解决活动公告出现时间长导致邮件获取不了问题
    2. log信息修改
2.7更新日志
    1. 解决有时候不能收邮件问题,增加收系统邮件功能
    2. 解决菜单中-符号解析问题       
2.6更新日志
    1. 增加自动取邮件功能，只能获取好友邮件
    2. TAB键替换为4空格
    
已知问题
    1. 缺少破纪录的页面处理
]]

-- 适用屏幕参数
SCREEN_RESOLUTION="768x1024";
SCREEN_COLOR_BITS=32;

PAGE_DELAY=1000; --界面读取间隔
FIGHTS_MIN=2;    --每一轮最少比赛场次
FIGHTS_MAX=5;    --每一轮最多比赛场次

--全局变量
g_FightCnt = 0;     -- 每一轮比赛次数
g_bGold_Finish = 0; --每日金币完成
g_bTask_Finish = 0; --每日任务完成
g_bGivePower = 0;   --给好友送体力
g_bWorkTogether = 0; --找好友合体
MAX_ROUND = 0;  --一轮中的比赛次数

mode=0;         -- 1-经典模式 2-剧情模式 3-PK模式
field=0;        -- 888-金币场 2888-超级金币场
g_bCrazyDrv=0;  -- 0-无驱动 1-有驱动

--界面
UI = {
--{ 'TextView{-请选择刷机模式-}' },
{ 'DropList{经典模式|剧情模式|PK模式888金币场-无驱动|PK模式2888金币场-无驱动|PK模式888金币场|PK模式2888金币场}', 
  'menu', '请选择自动运行的模式' },
};

-- 点击
function myClick(x, y)
    touchDown(0, x + math.random(-15, 15), y + math.random(-15, 15));
    mSleep(100 + math.random(-50, 50));
    touchUp(0);
end

function initFights()
    g_FightCnt = 0;
    MAX_ROUND = math.random(FIGHTS_MIN, FIGHTS_MAX); --最大比赛轮数，超过后领取奖励
end

--初始化
function autoInit()

    initFights();
        
    if string.find(menu, "经典模式") then
        mode = 1;
        field = 0;
        g_bCrazyDrv = 0;
    elseif string.find(menu, "剧情模式") then
        mode = 2;
        field = 0;        
        g_bCrazyDrv = 0;
    elseif string.find(menu, "PK模式888金币场%-无驱动") then
        mode = 3;
        field = 888;
        g_bCrazyDrv = 0;
    elseif string.find(menu, "PK模式2888金币场%-无驱动") then
        mode = 3;
        field = 2888;
        g_bCrazyDrv = 0;
    elseif string.find(menu, "PK模式888金币场") then
        mode = 3;
        field = 888;
        g_bCrazyDrv = 1;
    elseif string.find(menu, "PK模式2888金币场") then
        mode = 3;
        field = 2888;
        g_bCrazyDrv = 1;
    end
    
    logDebug(string.format("INIT: mode=%d, field=%d, g_bCrazyDrv=%d, MAX_ROUND=%d.", 
                           mode, field, g_bCrazyDrv, MAX_ROUND));
    return;    
end

--领取邮件
function getMail()
    
    if getColor(114,767) == 0x18345A  and getColor( 574,108 ) == 0x8C1818 then --主界面有邮件
        myClick( 555,115 );     --进邮件界面
        logDebug("MAIL: Try to get mail.");
        mSleep(3000);
        
        while true
        do
            if getColor( 464,244 ) == 0x8C1818 then   --有好友邮件
                logDebug("MAIL: Get the friend mail.");
                myClick( 380,250 );    --点击好友邮件
            elseif getColor( 283,610 ) == 0xF7CF63 and getColor( 464,641 ) == 0xFFDF4A then
                logDebug("MAIL: Failed to get friend mail, return home.");
                myClick(386, 626);  --弹出错误窗口,点击确认, 返回主界面
                mSleep(2000);
                break;
            else
                break;
            end
            if getColor(658,384 ) == 0x8C1818 then --好友邮件中, 体力条目存在
                myClick(560,955);    --全部收取好友体力
            end
            mSleep(1000);
        end
        
        while true
        do
            if getColor(682,244) == 0x8C1818 then--有系统邮件
                logDebug("MAIL: Get the system mail.");
                myClick( 603,249 );     --点击系统邮件
            elseif getColor( 283,610 ) == 0xF7CF63 and getColor( 464,641 ) == 0xFFDF4A then
                logDebug("MAIL: Failed to get system mail, return home.");
                myClick(386, 626);  --弹出错误窗口,点击确认, 返回主界面
                mSleep(2000);
                break;
            else
                break;
            end
            if getColor( 666,384 ) == 0x8C1818 then  --系统邮件条目存在
                myClick( 553,960 );    --循环收取邮件    
            end
            mSleep(1000);
        end
        mSleep(2000);
        logDebug("MAIL: No more mail to get, return home.");        
        myClick(100, 960);    --返回主界面
    else
        logDebug("MAIL: No new mail to get.");
    end
end

--领取奖励
function getAwards()
    
    if getColor( 114,767 ) == 0x18345A then --主界面
        logDebug("TASK: Try to get awards.");
		myClick(655, 110);     --进任务界面
        mSleep(3000);
        
        while true
        do
            if getColor(275,419) == 0xA51C00 then  --每日任务已完成
                logDebug("TASK: Daily task has finished.");
                g_bTask_Finish = 1;
            end
            --[[
            if getColor( 253,274 ) == 0xD67D08 and getColor( 238,313 ) == 0x844508 then  --向好友送体力
                logDebug("TASK: give friend power.");
                g_bGivePower = 5;
            end
            
            if getColor( 474,282 ) == 0x946D52 and getColor( 465,291 ) == 0x9C7963 and   --每日任务合体
               getColor( 484,291 ) == 0xC6AA8C and getColor( 468,303 ) == 0xC6A284 and 
               getColor( 481,303 ) == 0xC6AA8C and getColor( 491,303 ) == 0xB59A7B 
               and getColor( 501,303 ) == 0xC6AE94 then  --找好友合体
                logDebug("TASK: Daily task, Choose friend to work together.");
                g_bWorkTogether = 3;
            end
            
            if getColor( 474,581 ) == 0x946952 and getColor( 465,590 ) == 0xA5755A and --奖励任务合体
               getColor( 484,590 ) == 0xC6AE8C and getColor( 468,601 ) == 0x946952 and 
               getColor( 481,601 ) == 0x946952 and getColor( 491,601 ) == 0x946D52 
               and getColor( 501,601 ) == 0x946952 then  --找好友合体
                logDebug("TASK: Bonus task, Choose friend to work together.");
                g_bWorkTogether = 3;
            end
            ]]
            if getColor(518,247) == 0xE79210 then  --有每日任务奖励
                logDebug("TASK: Get daily task awards.");
                myClick(595,238);
            elseif getColor(516,562) == 0xE79A18 then
                logDebug("TASK: Get bonus awards.");
                myClick(600,555);     --领取赏金任务            
            elseif getColor( 283,610 ) == 0xF7CF63 and getColor( 464,641 ) == 0xFFDF4A then
                logDebug("TASK: Failed to get task awards, return home.");    
                myClick(386, 626);
                mSleep(2000);
                break;
            else
                logDebug("TASK: No more awards to get, return home.");
                break;
            end
            mSleep(1000);
        end
        mSleep(2000);
        logDebug("TASK: Finish to get awards, return home.");
        myClick(100, 960);    --返回主界面
    end
end

function handleClassic()
    
    --logDebug("Handle Gold mode.");
    if g_bGold_Finish == 1 and g_bTask_Finish == 1 then   --金币刷完，任务做完，则退出进程
        notifyMessage("Note: Gold and task finished, exit.");
        logDebug("NOTE: Gold and task finished, exit.");
        os.exit();
    end
    
    if getColor( 114,767 ) == 0x18345A then  --主界面
        logDebug("PAGE: Home, Enter classic mode.");
        myClick(610, 960);  --进经典模式
    end
end

function handleStory()
    
    --logDebug("Handle story mode.");
    if getColor(70, 729) == 0x18345A then  --主界面
        myClick(330, 900);  --进剧情模式
    elseif getColor(  27,162 ) == 0x944900 then  --剧情模式主界面
        myClick( 212,713 );  --进第一关        
        --myClick( 518,568 );  --进第三关          
    elseif getColor( 78,731 ) == 0x08AAFF and getColor( 563,731 ) == 0xF7CF39 then
        myClick(480, 710);  --进开始战斗
    end
end

function handlePK()
    
    --logDebug("Handle PK mode.");
    if getColor( 114,767 ) == 0x18345A then  --主界面
        myClick(215, 955);         --进PK对战
    elseif getColor(444, 689) == 0x18345A then  --PK主界面
        if g_FightCnt >= MAX_ROUND then
            logDebug("PAGE: Main PK, Return home, reach max fights.");
            myClick(100, 960);     --返回
        else
            myClick(380, 270);     --进世界对战
        end
    elseif getColor(500, 205) == 0x2171DE then --世界对战界面
        if g_FightCnt >= MAX_ROUND then
            logDebug("PAGE: World PK, Return home, reach max fights.");
            myClick(100, 960);     --返回
        elseif field == 888 then
            logDebug("PAGE: World PK, eEnter 888 gold field.");
            myClick(222, 360);     --入888场
        elseif field == 2888 then
            logDebug("PAGE: World PK, Enter 2888 gold field.");
            myClick(230, 610);     --入2888场
        else
            myClick(100, 960);    --返回
        end
    end
end

function handleCommon()
    
    --logDebug("Handle Common mode.");
    if getColor(442, 862) == 0xE7E7EF then  --选择好友合体界面
        if g_FightCnt >= MAX_ROUND then
            logDebug("PAGE: Get friend, Return home, reach max fights.");
            myClick(100, 960);     --返回
        else
            if g_bWorkTogether > 0 and getColor( 694,250 ) == 0x5A9600 then
                logDebug("PAGE: Get friend, Choose friend to work together.");
                g_bWorkTogether = g_bWorkTogether - 1;
                myClick( 680,248 );   --点击好友合体
            end
            myClick(550, 955);     --开始游戏
        end
    elseif getColor( 313,111 ) == 0xCECFE7 and getColor( 471,104 ) == 0xCEC7D6 then  --购买道具界面
        if g_FightCnt >= MAX_ROUND then
            logDebug("PAGE: Buy property, return home, reach max fights.");
            myClick(100, 960);     --返回
        else
            myClick(550, 955);    --开始游戏
        end
    elseif getColor(291, 553) == 0xFFE318 then   --分数结算中
        logDebug(string.format("PAGE: Counting score now, %d/%d fights finished.", g_FightCnt, MAX_ROUND));
        while getColor(291, 553) == 0xFFE318
        do
            myClick(100, 960);     --返回
            --logDebug("PAGE: Counting score now, sleep for 1 second."); 
            mSleep(1000);
        end
    elseif getColor( 428,236 ) == 0xFFEBD6 then  --失败
        logDebug(string.format("PAGE: You Failed, %d/%d fights finished.", g_FightCnt, MAX_ROUND));            
        while getColor( 428,236 ) == 0xFFEBD6
        do
            myClick(100, 960);      --返回
            --logDebug("PAGE: You Failed, sleep for 1 second."); 
            mSleep(1000);
        end
    elseif getColor(415, 223) == 0x182039 then  --胜利
        logDebug(string.format("PAGE: You succeed, %d/%d fights finished.", g_FightCnt, MAX_ROUND)); 
        while getColor(415, 223) == 0x182039
        do
            myClick(100, 960);      --返回
            --logDebug("PAGE: You succeed, sleep for 1 second.");             
            mSleep(1000);
        end
    elseif getColor(308, 570) == 0x08AAFF and getColor(487, 570) == 0xEFB631 then
        logDebug(string.format("WINDOW: YOU WIN, %d/%d fights finished.", g_FightCnt, MAX_ROUND));
        myClick(260, 560);  --弹出窗口:你战胜了某某, 确定    
    elseif getColor(318, 569) == 0x10A6FF and getColor(581, 569) == 0xF7DF4A then      
        logDebug(string.format("WINDOW: YOU LOSE, %d/%d fights finished.", g_FightCnt, MAX_ROUND));
        myClick(260, 560);  --弹出窗口:你败于某某人,确定
    elseif getColor( 399,304 ) == 0x188A7B and g_bCrazyDrv == 1 then
        logDebug("PAGE: One driver exist, use stand crazy driver.");
        myClick( 399,304 );    --只有一个狂热驱动，使用它
    elseif getColor( 398,303 ) == 0x7B14A5 and g_bCrazyDrv == 1 then
        logDebug("PAGE: One driver exist, use super crazy driver.");    
        myClick( 398,303 );    --只有一个超级狂热驱动，使用它
    elseif getColor(276, 297) == 0x188A7B and g_bCrazyDrv == 1 then
        logDebug("PAGE: Two drivers exist, use standard crazy driver.");    
        myClick(276, 297);    --存在两个狂热驱动，先使用标准, 后使用超级
    elseif getColor(520, 299) == 0x7B14A5 and g_bCrazyDrv == 1 then 
        logDebug("PAGE: Two drivers exist, use super crazy driver.");
        myClick(520, 299);     --存在两个狂热驱动，先使用标准, 后使用超级    
    elseif getColor(135, 45) == 0xD66D10 then --恭喜你获得以下物品
        logDebug(string.format("PAGE: You get something, %d/%d fights finished.", g_FightCnt, MAX_ROUND));    
        --mSleep(2000);
        myClick(378, 740);    --知道了
    elseif getColor(209, 63) == 0xFFD329 and getColor(524, 63) == 0xFFD329 then
        logDebug("PAGE: Rank go up, confirm.");
        myClick(100, 960);      --排名上升了,确定    
    elseif getColor( 378,147 ) == 0xEF7131 and getColor( 478,489 ) == 0x52386B then
        logDebug("PAGE: You upgrade, get awards.");
        myClick(388, 886);     --你升级啦, 领取奖励
    elseif getColor( 251,364 ) == 0xFF9E00 and getColor( 251,551 ) == 0x008EE7 then
        logDebug("PAGE: Continue game.");
        myClick(380, 365);    --继续游戏
    elseif getColor( 501,203 ) == 0x216DAD and getColor( 170,282 ) == 0xFFFB73 then
        logDebug("PAGE: Power shop, return.");
        myClick(100, 960);      --体力商店, 返回    
    elseif getColor( 226,236 ) == 0x009EFF and getColor( 226,355 ) == 0x009AFF and
           getColor( 226,591 ) == 0x009AFF and getColor( 226,828 ) == 0x009EFF then
        logDebug("PAGE: Diamond shop, return.");
        myClick(100, 960);    --购买钻石, 返回
    elseif getColor( 212,233 ) == 0xEFA608 and getColor( 212,352 ) == 0xEFB208 and
           getColor( 212,588 ) == 0xE7A608 and getColor( 212,825 ) == 0xEFA608 then
        logDebug("PAGE: Gold shop, return.");
        myClick(100, 960);    --金币商店, 返回        
    elseif getColor( 283,610 ) == 0xF7CF63 and getColor( 464,641 ) == 0xFFDF4A then
        logDebug("WINDOW: Something is wrong, return to home.");    
        g_FightCnt = MAX_ROUND;
        myClick( 386,626 );     --弹出窗口:只有一个中间的确定按钮,异常情况，需返回
    elseif getColor( 136,630 ) == 0x08AAFF and getColor( 629,642 ) == 0xF7D339 then
        logDebug("WINDOW: network delay, confirm.");
        myClick( 542,625 );     --弹出窗口:网络超时, 确定
    elseif getColor( 134,735) == 0x08B2EF and getColor( 181,778 ) == 0x188ECE then
        logDebug("PAGE: setting or invite friend, return home.");
        myClick(100, 960);     --系统设置界面, 返回主界面
    elseif getColor(84,211) == 0x945110 then
        logDebug("PAGE: mail, return home.");
        myClick(100, 960);     --邮件界面, 返回主界面
    elseif getColor( 160,252 ) == 0xD6B27B and getColor( 161,252 ) == 0xC6A273 then
        logDebug("PAGE: task, return home.");
        myClick(100, 960);     --任务界面, 返回主界面
    elseif getColor( 253,955 ) == 0xB5BEC6 and getColor( 254,955 ) == 0x8C8A8C and
           getColor( 256,955 ) == 0xE7D394 and getColor( 257,955 ) == 0xFFCF6B then
        logDebug("PAGE: activity, OK.");
        myClick(380, 970);     --知道了
    end
    
    return 0;
end

function handleRoundComplete()
    
    --以下三个页面会记录一场比赛结束，需要统计比赛场次，返回主界面时间较长,使用while
    --x, y = findColorInRegionFuzzy(0xFFEFCE, 100, 371 - 3, 254 - 3, 371 + 3, 254 + 3);
    --if x ~= -1 and y ~= -1 then
    --    notifyMessage(string.format("findColorInRegionFuzzy(0x%X) = x:%d, y:%d.", 0xFFEFCE, x, y), 3000);
    --end
    
    if getColor(371, 254) == 0xFFEFCE then  --加油哦!!!
        g_FightCnt = g_FightCnt + 1;
        logDebug(string.format("PAGE: Come on!!! %d/%d fights finished.", g_FightCnt, MAX_ROUND));
        if getColor( 186,650 ) == 0x393839 and getColor( 585,648 ) == 0x393839 and  --每日金币达到最大值
           getColor( 382,583 ) == 0x393839 and getColor( 382,610 ) == 0x393839 then
            logDebug("PAGE: Come on, Can't get any more gold per day.");
            g_bGold_Finish = 1;
        end
        while getColor(371, 254) == 0xFFEFCE
        do
            myClick(100, 960);      --回主界面        
            --logDebug("PAGE: Come on, sleep for 1 second.");        
            mSleep(1000);
        end
    elseif getColor(371, 254) == 0xFFEFCE then  --本周最高，单人
        g_FightCnt = g_FightCnt + 1;
        logDebug(string.format("PAGE: Highest in week, %d/%d fights finished.", g_FightCnt, MAX_ROUND));
        while getColor(371, 254) == 0xFFEFCE
        do
            myClick(100, 960);      --回主界面        
            --logDebug("PAGE: Highest week, sleep for 1 second.");        
            mSleep(1000);
        end    
    --elseif getColor(320, 325) == 0xDE6531 then  --本周最高，双人
    --    logDebug(string.format("PAGE: Highest two people in week, %d/%d rounds finished.", g_FightCnt, MAX_ROUND));    
    --    while getColor(320, 325) == 0xDE6531
    --    do        
    --        myClick(60, 900);      --回主界面
    --        mSleep(3000);
    --    end
    end
        
    return;
end    
function AutoRun()
    
    if getColor( 114,767 ) == 0x18345A then  --主界面
        
        --达到最大轮次，则退出领取任务奖励
        if g_FightCnt >= MAX_ROUND then
            logDebug(string.format("Home page: Need to get awards in home page, reach max %d/%d fights.", 
                                    g_FightCnt, MAX_ROUND));
            return MAX_ROUND;
        end
    end

    keepScreen(true);
    
    if mode == 1 then  --经典模式
        handleClassic();
    elseif mode == 2 then  --剧情模式
        handleStory();
    elseif mode == 3 then  --PK模式
        handlePK();
    end
    
    keepScreen(false);
    
    handleCommon();    --通用处理
        
    handleRoundComplete(); --一轮结束处理
        
    return 0;
end

-- 主入口函数
function main()
    
    autoInit();  --初始化
    
    while true
    do
        ret = AutoRun();    --自动运行
        
        if ret ~= 0 then
            getAwards(); --领取任务奖励
            mSleep(3000);
            getMail();   --领取邮件
            initFights();    --再初始化一次每轮最大飞行次数
            logDebug(string.format("INIT: data update, MAX_ROUND=%d, g_bGivePower=%d, g_bWorkTogether=%d.", 
                                    MAX_ROUND, g_bGivePower, g_bWorkTogether));
        end        
        mSleep(PAGE_DELAY + math.random(-500, 500));
    end
end

