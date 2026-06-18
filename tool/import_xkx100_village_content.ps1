$ErrorActionPreference = 'Stop'

function Read-JsonArray($Path) {
    $raw = Get-Content $Path -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @()
    }

    $parsed = $raw | ConvertFrom-Json
    if ($parsed -is [array]) {
        return @($parsed)
    }

    return @($parsed)
}

function Read-GitJsonArray($Path) {
    $raw = git show "HEAD:$Path"
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @()
    }

    $parsed = ($raw -join "`n") | ConvertFrom-Json
    if ($parsed -is [array]) {
        return @($parsed)
    }

    return @($parsed)
}

function Add-UniqueById($Existing, $Additions) {
    $ids = @{}
    $result = @()

    foreach ($item in @($Existing)) {
        if ($null -ne $item.id -and -not $ids.ContainsKey($item.id)) {
            $ids[$item.id] = $true
            $result += $item
        }
    }

    foreach ($item in @($Additions)) {
        if ($null -ne $item.id -and -not $ids.ContainsKey($item.id)) {
            $ids[$item.id] = $true
            $result += $item
        }
    }

    return @($result)
}

function Write-JsonArray($Path, $Data) {
    $json = @($Data) | ConvertTo-Json -Depth 40
    [System.IO.File]::WriteAllText(
        (Resolve-Path $Path),
        $json + [Environment]::NewLine,
        [System.Text.UTF8Encoding]::new($false)
    )
}

$npcPath = 'assets/data/npcs.json'
$dialoguePath = 'assets/data/dialogues.json'
$itemPath = 'assets/data/items.json'
$shopPath = 'assets/data/shops.json'

$npcs = Read-JsonArray $npcPath
$dialogues = Read-JsonArray $dialoguePath
$items = Read-JsonArray $itemPath
$shops = Read-GitJsonArray $shopPath

$villageNpcs = @(
    [pscustomobject]@{
        id = 'xkx_village_npc_smith'
        name = '冯铁匠'
        description = '村里的铁匠，粗布短打上落着火星和铁屑。'
        dialogueId = 'dialogue_xkx_village_smith'
        aliases = @('smith', 'feng', '冯铁匠', '铁匠')
        role = 'merchant'
        shopId = 'xkx_village_smith_shop'
        inquiries = @(
            [pscustomobject]@{ id = 'name'; label = '姓名'; aliases = @('name', '名字'); response = '小人姓冯，村里人都叫我冯铁匠。' },
            [pscustomobject]@{ id = 'here'; label = '这里'; aliases = @('here', '此地'); response = '这里是小人糊口的铺子，平日给村里人打些锄头铁锅。' },
            [pscustomobject]@{ id = 'sword'; label = '剑'; aliases = @('剑', 'sword'); response = '那是给华山派岳掌门打的，小人可不敢随便卖。' }
        )
        interactions = @(
            [pscustomobject]@{ type = 'trade'; label = '交易'; itemIds = @('xkx_village_obj_hammer') }
        )
    },
    [pscustomobject]@{
        id = 'xkx_village_npc_seller'
        name = '小贩'
        description = '挑着担子的村中小贩，担子里塞着些零碎日用。'
        dialogueId = 'dialogue_xkx_village_seller'
        aliases = @('seller', '小贩', '货郎')
        role = 'merchant'
        shopId = 'xkx_village_seller_shop'
        inquiries = @(
            [pscustomobject]@{ id = 'name'; label = '姓名'; aliases = @('name', '名字'); response = '我就是个走村串户的小贩，靠这副担子讨生活。' },
            [pscustomobject]@{ id = 'goods'; label = '货物'; aliases = @('货物', '买卖', 'goods'); response = '都是些鞋、木棍、水壶、鸡蛋，赶路用得上。' }
        )
        interactions = @(
            [pscustomobject]@{ type = 'trade'; label = '交易'; itemIds = @('xkx_village_obj_stick', 'xkx_village_obj_shoes', 'xkx_village_obj_bottle', 'xkx_village_obj_egg') }
        )
    },
    [pscustomobject]@{
        id = 'xkx_village_npc_xiejian'
        name = '李四'
        description = '杂货店里的伙计，正懒洋洋地看着门外。'
        dialogueId = 'dialogue_xkx_village_xiejian'
        aliases = @('xiejian', 'li si', '李四')
        inquiries = @(
            [pscustomobject]@{ id = 'name'; label = '姓名'; aliases = @('name', '名字'); response = '小的叫李四，在这里替店家看铺。' },
            [pscustomobject]@{ id = 'here'; label = '杂货店'; aliases = @('here', '杂货店'); response = '这店里没什么好货，村里人来来去去也就买些针线杂物。' }
        )
    },
    [pscustomobject]@{
        id = 'xkx_village_npc_kid'
        name = '小孩'
        description = '村里的小孩，追着同伴在土路上跑来跑去。'
        dialogueId = 'dialogue_xkx_village_kid'
        aliases = @('kid', '小孩')
        inquiries = @(
            [pscustomobject]@{ id = 'name'; label = '姓名'; aliases = @('name', '名字'); response = '我娘不让我随便告诉外乡人名字。' },
            [pscustomobject]@{ id = 'gudui'; label = '谷堆'; aliases = @('谷堆', 'gudui'); response = '广场角上那几个谷堆可好玩啦，不过大人不让我们乱钻。' }
        )
    },
    [pscustomobject]@{
        id = 'xkx_village_npc_boy'
        name = '男孩'
        description = '一个穿着旧布衣的男孩，脚上沾满碎石路的尘土。'
        dialogueId = 'dialogue_xkx_village_boy'
        aliases = @('boy', '男孩')
        inquiries = @(
            [pscustomobject]@{ id = 'road'; label = '村路'; aliases = @('路', '村路'); response = '往北就是打谷场，往南出了村就清静多了。' }
        )
    },
    [pscustomobject]@{
        id = 'xkx_village_npc_girl'
        name = '女孩'
        description = '扎着小辫的女孩，怀里抱着一只旧布娃娃。'
        dialogueId = 'dialogue_xkx_village_girl'
        aliases = @('girl', '女孩')
        inquiries = @(
            [pscustomobject]@{ id = 'village'; label = '村子'; aliases = @('村子', '这里'); response = '村里人不多，大家都认得彼此，外乡人一来就很显眼。' }
        )
    },
    [pscustomobject]@{
        id = 'xkx_village_npc_oldwoman'
        name = '老大娘'
        description = '白发苍苍的老大娘坐在土屋里，手边放着破旧针线。'
        dialogueId = 'dialogue_xkx_village_oldwoman'
        aliases = @('oldwoman', '老大娘')
        inquiries = @(
            [pscustomobject]@{ id = 'village'; label = '村子'; aliases = @('村子', '这里'); response = '这小村靠着华山，日子清苦些，总还能过。' }
        )
    },
    [pscustomobject]@{
        id = 'xkx_village_npc_punk'
        name = '小流氓'
        description = '倚在巷口的小流氓，眼神四处乱瞟。'
        dialogueId = 'dialogue_xkx_village_punk'
        aliases = @('punk', '小流氓')
    },
    [pscustomobject]@{
        id = 'xkx_village_npc_dipi'
        name = '地痞'
        description = '吊儿郎当的地痞挡在暗巷里，一副不好惹的模样。'
        dialogueId = 'dialogue_xkx_village_dipi'
        aliases = @('dipi', '地痞')
    },
    [pscustomobject]@{
        id = 'xkx_village_npc_dibao'
        name = '地保'
        description = '村里的地保，衣着比寻常村民稍整齐些。'
        dialogueId = 'dialogue_xkx_village_dibao'
        aliases = @('dibao', '地保')
        inquiries = @(
            [pscustomobject]@{ id = 'village'; label = '村务'; aliases = @('村务', '村子'); response = '村里虽小，也有些规矩，外乡人别乱闯人家屋子。' }
        )
    },
    [pscustomobject]@{
        id = 'xkx_village_npc_cuihua'
        name = '翠花'
        description = '年轻村妇正在屋里忙活，听见脚步声便抬头望来。'
        dialogueId = 'dialogue_xkx_village_cuihua'
        aliases = @('cuihua', '翠花')
    },
    [pscustomobject]@{
        id = 'xkx_village_npc_dog'
        name = '黄狗'
        description = '一条瘦黄狗趴在村口，耳朵警觉地竖着。'
        dialogueId = 'dialogue_xkx_village_dog'
        aliases = @('dog', '黄狗')
    },
    [pscustomobject]@{
        id = 'xkx_village_npc_poorman'
        name = '穷汉'
        description = '衣衫褴褛的穷汉缩在破屋里，神情疲惫。'
        dialogueId = 'dialogue_xkx_village_poorman'
        aliases = @('poorman', '穷汉')
        inquiries = @(
            [pscustomobject]@{ id = 'village'; label = '近况'; aliases = @('近况', '村子'); response = '村子里能糊口就不错了，哪还有什么闲心谈江湖。' }
        )
    },
    [pscustomobject]@{
        id = 'xkx_village_npc_wang'
        name = '王老汉'
        description = '王老汉守着小棚子，脸上皱纹像干裂的黄土。'
        dialogueId = 'dialogue_xkx_village_wang'
        aliases = @('wang', '王老汉')
    },
    [pscustomobject]@{
        id = 'xkx_taishan_npc_tangzi'
        name = '挑山工'
        description = '挑山工把扁担靠在肩上，像是刚从山路上下来。'
        dialogueId = 'dialogue_xkx_taishan_tangzi'
        aliases = @('tangzi', '挑山工')
        inquiries = @(
            [pscustomobject]@{ id = 'road'; label = '山路'; aliases = @('山路', '泰山'); response = '山路不好走，脚下得稳，心里也得稳。' }
        )
    }
)

$villageDialogues = @(
    [pscustomobject]@{ id = 'dialogue_xkx_village_smith'; lines = @('叮当、叮当，火候正好，有事就快说。'); events = @() },
    [pscustomobject]@{ id = 'dialogue_xkx_village_seller'; lines = @('客官看看，都是赶路用得上的便宜货。'); events = @() },
    [pscustomobject]@{ id = 'dialogue_xkx_village_xiejian'; lines = @('店里东西不多，别乱翻。'); events = @() },
    [pscustomobject]@{ id = 'dialogue_xkx_village_kid'; lines = @('你是从山外来的么？山外是不是很大？'); events = @() },
    [pscustomobject]@{ id = 'dialogue_xkx_village_boy'; lines = @('我们就在村路上玩，不去远处。'); events = @() },
    [pscustomobject]@{ id = 'dialogue_xkx_village_girl'; lines = @('娘说太阳落山前要回家。'); events = @() },
    [pscustomobject]@{ id = 'dialogue_xkx_village_oldwoman'; lines = @('外乡人啊，村里没什么好招待你的。'); events = @() },
    [pscustomobject]@{ id = 'dialogue_xkx_village_punk'; lines = @('看什么看？这巷子不是你该来的地方。'); events = @() },
    [pscustomobject]@{ id = 'dialogue_xkx_village_dipi'; lines = @('识相点就快走，别在这里碍眼。'); events = @() },
    [pscustomobject]@{ id = 'dialogue_xkx_village_dibao'; lines = @('村里地方小，来客都得守规矩。'); events = @() },
    [pscustomobject]@{ id = 'dialogue_xkx_village_cuihua'; lines = @('我还忙着呢，有话快说。'); events = @() },
    [pscustomobject]@{ id = 'dialogue_xkx_village_dog'; lines = @('黄狗冲你汪汪叫了两声，又低头趴下。'); events = @() },
    [pscustomobject]@{ id = 'dialogue_xkx_village_poorman'; lines = @('唉，日子不好过啊。'); events = @() },
    [pscustomobject]@{ id = 'dialogue_xkx_village_wang'; lines = @('年纪大了，就在这里看个棚子。'); events = @() },
    [pscustomobject]@{ id = 'dialogue_xkx_taishan_tangzi'; lines = @('挑山吃的是脚力饭，一步也急不得。'); events = @() }
)

$villageItems = @(
    [pscustomobject]@{ id = 'xkx_village_obj_hammer'; name = '铁锤'; description = '冯铁匠铺子里常见的铁锤，沉甸甸的。'; type = 'material'; effects = [pscustomobject]@{} },
    [pscustomobject]@{ id = 'xkx_village_obj_stick'; name = '木棍'; description = '削得还算直的一根木棍，可以用来防身。'; type = 'equipment'; slot = 'weapon'; effects = [pscustomobject]@{ attack = 1 } },
    [pscustomobject]@{ id = 'xkx_village_obj_shoes'; name = '布鞋'; description = '粗布鞋，鞋底纳得很厚，适合走土路。'; type = 'equipment'; slot = 'feet'; effects = [pscustomobject]@{ maxStamina = 2 } },
    [pscustomobject]@{ id = 'xkx_village_obj_bottle'; name = '水壶'; description = '普通竹水壶，路上解渴用。'; type = 'material'; effects = [pscustomobject]@{} },
    [pscustomobject]@{ id = 'xkx_village_obj_egg'; name = '鸡蛋'; description = '村里母鸡刚下的鸡蛋。'; type = 'consumable'; effects = [pscustomobject]@{} }
)

$villageShops = @(
    [pscustomobject]@{
        id = 'xkx_village_smith_shop'
        name = '冯铁匠的铁匠铺'
        description = '炉火旁摆着几样新打好的铁器。'
        goods = @(
            [pscustomobject]@{ itemId = 'xkx_village_obj_hammer'; price = 60 }
        )
    },
    [pscustomobject]@{
        id = 'xkx_village_seller_shop'
        name = '小贩的担子'
        description = '担子里放着村里常见的便宜杂货。'
        goods = @(
            [pscustomobject]@{ itemId = 'xkx_village_obj_stick'; price = 12 },
            [pscustomobject]@{ itemId = 'xkx_village_obj_shoes'; price = 18 },
            [pscustomobject]@{ itemId = 'xkx_village_obj_bottle'; price = 10 },
            [pscustomobject]@{ itemId = 'xkx_village_obj_egg'; price = 3 }
        )
    }
)

Write-JsonArray $npcPath (Add-UniqueById $npcs $villageNpcs)
Write-JsonArray $dialoguePath (Add-UniqueById $dialogues $villageDialogues)
Write-JsonArray $itemPath (Add-UniqueById $items $villageItems)
Write-JsonArray $shopPath (Add-UniqueById $shops $villageShops)

Write-Host 'Imported xkx100 village NPCs, dialogues, items, and shops.'
