# 1. Phân tích Gameplay Tổng Quan

## Vòng lặp gameplay chính

```
Login → Safe Zone → Party → Dungeon → Combat → Loot → Return → Upgrade Skill → Repeat
```

* Safe Zone: giao tiếp, mua đồ, học kỹ năng, lập đội.
* Dungeon: chiến đấu, phối hợp 4 class, diệt quái và boss, nhận loot/exp.
* Khi chết: quay về Safe Zone, mất exp.
* Khi thắng: nhận phần thưởng, tăng cấp nhân vật và kỹ năng.

---

# 2. Phân tích Hệ Thống Tổng Thể

| Hệ thống            | Mô tả                                                         | Thành phần chính                       |
| ------------------- | ------------------------------------------------------------- | -------------------------------------- |
| **Item System**     | Quản lý vật phẩm, cooldown, số lượng, hiệu ứng.               | Item DB, cooldown tracker, packet sync |
| **Skill System**    | Quản lý kỹ năng, mana cost, damage, buff/debuff.              | Skill DB, combat logic                 |
| **Entity System**   | Đại diện player, quái, boss với chỉ số HP/MP, vị trí, status. | Entity struct, update loop             |
| **Combat System**   | Xử lý chiến đấu, tính toán damage/heal, trigger hiệu ứng.     | Damage formula, skill resolver         |
| **Dungeon System**  | Tạo map, spawn quái, quản lý tiến trình dungeon.              | Map loader, monster spawner            |
| **Party System**    | Quản lý nhóm 4 người, chia exp, loot.                         | Party manager, roll system             |
| **Sync System**     | Đồng bộ client–server (vị trí, HP, skill).                    | Tick loop, delta update                |
| **Chat System**     | Chat toàn, nhóm, whisper.                                     | Chat channel handler                   |
| **Network System**  | Gửi/nhận packet TCP/UDP hoặc WebSocket.                       | Connection manager, packet parser      |
| **Database System** | Lưu account, nhân vật, inventory.                             | PostgreSQL schema, Redis cache         |

---

# 3. Cấu Trúc Thư Mục Dự Án Haskell

```
MMO-Project/
├── Server/
│   ├── Main.hs
│   ├── Network/
│   │   ├── Connection.hs
│   │   ├── PacketHandler.hs
│   │   └── SyncLoop.hs
│   ├── Systems/
│   │   ├── ItemSystem.hs
│   │   ├── SkillSystem.hs
│   │   ├── CombatSystem.hs
│   │   ├── DungeonSystem.hs
│   │   └── PartySystem.hs
│   ├── Database/
│   │   ├── DBInit.hs
│   │   ├── PlayerRepo.hs
│   │   ├── InventoryRepo.hs
│   │   └── DungeonRepo.hs
│   └── Utils/
│       ├── Logger.hs
│       └── Config.hs
│
├── Client/
│   ├── Main.hs
│   ├── UI/
│   │   ├── HUD.hs
│   │   ├── SkillBar.hs
│   │   ├── Inventory.hs
│   │   ├── ChatBox.hs
│   │   └── PartyFrame.hs
│   ├── Renderer/
│   │   ├── SpriteLoader.hs
│   │   ├── Animation.hs
│   │   └── MapRenderer.hs
│   ├── Network/
│   │   ├── ClientSocket.hs
│   │   └── PacketSend.hs
│   └── Input/
│       └── InputHandler.hs
│
├── Shared/
│   ├── Types.hs
│   ├── Entities.hs
│   ├── Packets.hs
│   ├── Constants.hs
│   └── Utils.hs
│
├── Assets/
│   ├── Sprites/
│   ├── Sounds/
│   └── Maps/
│
├── Database/
│   ├── schema.sql
│   ├── seed.sql
│   └── migrate.sh
│
└── docker-compose.yml
```

---

# 4. Phân tích Chi Tiết Từng Thành Phần

## **Server**

### Nhiệm vụ

* Giữ **trạng thái toàn cục** (entity, dungeon, player).
* Xử lý **logic gameplay** và đồng bộ client.
* Giao tiếp với DB và cache.

### Module & Hàm chính

#### `Network/Connection.hs`

* `acceptClients :: IO ()` — chấp nhận client mới.
* `recvPacket :: Socket -> IO Packet` — nhận gói tin JSON.
* `sendPacket :: Socket -> Packet -> IO ()` — gửi dữ liệu về client.

#### `Systems/ItemSystem.hs`

* `useItem :: Player -> ItemId -> GameState -> GameState`
* `checkCooldown :: Player -> ItemId -> Bool`
* `syncInventory :: Player -> IO ()`

#### `Systems/SkillSystem.hs`

* `castSkill :: Player -> SkillId -> Target -> GameState -> GameState`
* `calcDamage :: Skill -> Player -> Target -> Int`
* `applyBuff :: Skill -> Player -> GameState -> GameState`

#### `Systems/CombatSystem.hs`

* `processAttack :: Player -> Monster -> IO ()`
* `checkDeath :: Entity -> IO ()`
* `distributeExp :: Party -> Monster -> IO ()`

#### `Systems/DungeonSystem.hs`

* `loadDungeon :: DungeonId -> IO DungeonMap`
* `spawnMonsters :: Dungeon -> IO [Monster]`
* `checkClearCondition :: Dungeon -> Bool`

#### `Database/PlayerRepo.hs`

* `getPlayerByAccount :: AccountId -> IO Player`
* `savePlayerState :: Player -> IO ()`
* `updateInventory :: PlayerId -> [Item] -> IO ()`

#### `Network/SyncLoop.hs`

* `syncTick :: GameState -> IO ()`
  (20–30 tick/giây, cập nhật vị trí, HP, status cho mọi client)

---

## **Client**

### Nhiệm vụ

* Render hình ảnh, UI, animation.
* Gửi input người chơi đến server.
* Nhận packet và cập nhật trạng thái hiển thị.

### Module & Hàm chính

#### `Renderer/MapRenderer.hs`

* `loadMap :: FilePath -> IO MapData`
* `renderMap :: MapData -> Picture`

#### `UI/HUD.hs`

* `drawHPMPBar :: PlayerState -> Picture`
* `drawSkillBar :: [Skill] -> Picture`
* `drawChatBox :: [Message] -> Picture`

#### `Input/InputHandler.hs`

* `processInput :: Event -> ClientState -> IO ClientState`
* `sendMove :: Direction -> IO ()`
* `sendCastSkill :: SkillId -> TargetId -> IO ()`

#### `Network/ClientSocket.hs`

* `connectServer :: String -> Int -> IO Connection`
* `listenServer :: Connection -> (Packet -> IO ()) -> IO ()`

---

## **Database**

### Cấu trúc cơ bản (PostgreSQL)

| Bảng         | Mô tả                                           |
| ------------ | ----------------------------------------------- |
| `accounts`   | id, username, password_hash                     |
| `characters` | id, account_id, name, class, level, exp, hp, mp |
| `inventory`  | char_id, item_id, quantity                      |
| `skills`     | char_id, skill_id, level                        |
| `dungeons`   | id, seed, name                                  |
| `party`      | id, leader_id                                   |

### Hàm tiêu biểu (qua SQL hoặc Haskell ORM)

* `insertCharacter :: Character -> IO ()`
* `getInventory :: CharId -> IO [Item]`
* `updateSkillLevel :: CharId -> SkillId -> Int -> IO ()`
* `saveDungeonProgress :: Dungeon -> IO ()`

---

# 5. Dòng Dữ Liệu (Data Flow)

```
Client Input → Server Network → Gameplay Logic → State Update → Sync Loop → Client Render
```

| Bước                | Dữ liệu           | Hướng           |
| ------------------- | ----------------- | --------------- |
| Di chuyển           | {x, y, dir}       | Client → Server |
| Dùng skill          | {skillId, target} | Client → Server |
| Cập nhật HP, vị trí | {hp, pos, status} | Server → Client |
| Chat                | {msg, channel}    | 2 chiều         |
| Item / Loot         | {itemId, action}  | 2 chiều         |

---

# 6. Môi trường và Công cụ

* **Ngôn ngữ:** Haskell (Stack hoặc Cabal)
* **Render:** Gloss hoặc SDL2
* **Networking:** `network`, `aeson`, `websockets`
* **Database:** PostgreSQL + Redis (optional)
* **Build/Deploy:** Docker + docker-compose
* **Test Multiplayer:** LAN 2 máy