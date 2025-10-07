## 1. Tổng Quan Kiến Trúc

Kiến trúc chia 2 phần tách biệt:

* **Server:** giữ toàn bộ logic gameplay thật, chịu trách nhiệm xử lý tick, combat, AI, dungeon, đồng bộ.
* **Client:** chỉ xử lý hiển thị, render, input, và nhận snapshot từ server.

Pipeline luân chuyển:

```
Client Input → Encode → Send Packet
   ↓
Server → Update Logic (Combat, Physics, AI)
   ↓
Server → Sync Snapshot (WorldState)
   ↓
Client → Interpolate + Render Frame
```

---

## 2. Phân Tầng Hệ Thống

| Hệ thống                | Mô tả                                                        | Vị trí              | Thành phần chính                                  |
| ----------------------- | ------------------------------------------------------------ | ------------------- | ------------------------------------------------- |
| **Network System**      | Quản lý kết nối TCP + UDP, mã hóa/giải mã packet.            | **Server + Client** | TCP handler, UDP socket, packet parser            |
| **Sync System**         | Tick loop đồng bộ entity state (vị trí, HP, ammo, hiệu ứng). | **Server + Client** | Tick delta, snapshot sender, client interpolation |
| **Entity System**       | Quản lý tank, quái, đạn, boss.                               | **Server**          | Entity record, updateState, removeDead            |
| **Physics System**      | Di chuyển, va chạm, giới hạn map.                            | **Server**          | Collider, velocity calc, wall check               |
| **Combat System**       | Tính sát thương, lan nổ, đạn va chạm.                        | **Server**          | Damage formula, projectile handler                |
| **AI System**           | Điều khiển quái, boss (chase, patrol, shoot).                | **Server**          | Behavior tree, pathfinding                        |
| **Dungeon System**      | Tạo dungeon, spawn quái, điều khiển zone/boss.               | **Server**          | Procedural generator, spawn manager               |
| **Item System**         | Quản lý vật phẩm rơi và shop dungeon.                        | **Server**          | Item repo, item drop resolver                     |
| **Upgrade System**      | Cây nâng cấp tank, Multi-Shot / AOE Radius.                  | **Server**          | Modifier resolver, upgrade DB                     |
| **Party / Room System** | Tạo phòng, join theo Room ID, PvP / Co-op.                   | **Server**          | Room manager, player registry                     |
| **Chat System**         | Chat phòng hoặc toàn server.                                 | **Server + Client** | Message handler, broadcast queue                  |
| **Database System**     | Lưu tài khoản, skin, vàng, lịch sử trận.                     | **Server**          | PostgreSQL / SQLite, Redis cache                  |
| **Auth System**         | Đăng nhập, xác thực token.                                   | **Server + Client** | Token validator, session tracker                  |
| **Render System**       | Vẽ map, tank, ánh sáng, hiệu ứng, radar.                     | **Client**          | Sprite renderer, light system                     |
| **Input System**        | Nhận phím, chuột, gửi command.                               | **Client**          | Input capture, encode to packet                   |
| **UI System**           | HUD, radar, shop, endgame summary.                           | **Client**          | Menu renderer, HUD controller                     |
| **Audio System**        | Âm thanh bắn, nổ, boss, UI.                                  | **Client**          | Sound pool, event trigger                         |
| **Effect System**       | Render particle, light trail, nổ.                            | **Client**          | Animation frame, effect timeline                  |

---

## 3. Pipeline Tick Server

**Server Tick Loop (≈ 30–60 tick/s)**

```
for each tick:
  1. read all incoming PlayerCommand
  2. update all Entities:
       - apply Input → Physics
       - apply AI → Combat
       - spawn new objects
  3. resolve collisions and projectiles
  4. update world time, buffs, item timers
  5. build WorldSnapshot (delta)
  6. send snapshot via UDP
```

Tất cả logic này là **pure**, không IO.
Phần IO duy nhất là Network + DB + Logger.

---

## 4. Pipeline Client

**Client Loop:**

```
for each frame (~60fps):
  1. capture Input (move, rotate, fire)
  2. send PlayerCommand via UDP
  3. receive WorldSnapshot
  4. interpolate entity positions
  5. render (map, light, tank, UI)
  6. play sound/effect
```

Client không giữ “truth”, chỉ **hiển thị theo snapshot**.
Nếu mất gói UDP, client tạm giữ state cũ và dự đoán (prediction).

---

## 5. Cấu Trúc Dự Án 

```
MMO_Dungeon_Crawler/
├── server/
│   ├── app/
│   │   ├── Main.hs                        # Entry point khởi động server
│   │   ├── ServerApp.hs                   # Hàm main logic (init system, loop, tick)
│   │   └── CLI.hs                         # Command-line tool (chạy migration, reset DB)
│   │
│   ├── src/
│   │   ├── Core/
│   │   │   ├── Types.hs                   # Kiểu dữ liệu chung (Vec2, EntityID, Tick, Damage, ...)
│   │   │   ├── Config.hs                  # Đọc file config server.yaml, database.yaml
│   │   │   └── Logger.hs                  # Log system, format theo tick
│   │   │
│   │   ├── Network/
│   │   │   ├── TCPServer.hs               # Quản lý kết nối TCP (login, shop, tạo phòng)
│   │   │   ├── UDPServer.hs               # Quản lý UDP (realtime sync)
│   │   │   ├── PacketParser.hs            # Parse/encode packet
│   │   │   ├── Protocol.hs                # Định nghĩa gói tin, opcode
│   │   │   └── SessionManager.hs          # Quản lý session, auth token
│   │   │
│   │   ├── Systems/
│   │   │   ├── EntitySystem.hs            # Quản lý Tank, Enemy, Bullet, Boss
│   │   │   ├── CombatSystem.hs            # Xử lý va chạm, damage, death
│   │   │   ├── DungeonSystem.hs           # Sinh dungeon, spawn quái, boss
│   │   │   ├── ItemSystem.hs              # Rơi vật phẩm, shop dungeon, nâng cấp
│   │   │   ├── SkillSystem.hs             # Multi-Shot, Explosive, Buff/Passive
│   │   │   ├── SyncSystem.hs              # Tick đồng bộ Client <-> Server
│   │   │   ├── AISystem.hs                # Hành vi quái/boss
│   │   │   ├── PartySystem.hs             # Quản lý nhóm (2 người chơi / PvP room)
│   │   │   └── EffectSystem.hs            # Nổ, cháy, đèn, AOE effect logic
│   │   │
│   │   ├── Data/
│   │   │   ├── Database.hs                # Kết nối PostgreSQL (persistent / esqueleto)
│   │   │   ├── Models.hs                  # Định nghĩa model Player, Tank, Item, Inventory
│   │   │   ├── Queries/
│   │   │   │   ├── PlayerQuery.hs         # Đăng nhập, tạo user, update exp
│   │   │   │   ├── TankQuery.hs           # Lấy danh sách tank, update nâng cấp
│   │   │   │   ├── ItemQuery.hs           # Lưu/nhặt vật phẩm
│   │   │   │   └── MatchQuery.hs          # Ghi lại lịch sử trận đấu
│   │   │
│   │   ├── Utils/
│   │   │   ├── Random.hs                  # Hàm random spawn, loot
│   │   │   ├── Math.hs                    # Vector, góc, collision
│   │   │   ├── Timer.hs                   # Tick, cooldown
│   │   │   └── JSON.hs                    # Encode/decode JSON config
│   │   │
│   │   └── Handlers/
│   │       ├── LoginHandler.hs            # Xử lý đăng nhập qua TCP
│   │       ├── RoomHandler.hs             # Tạo phòng, vào phòng
│   │       ├── ShopHandler.hs             # Mua bán, nâng cấp
│   │       ├── CombatHandler.hs           # Xử lý gói tin chiến đấu
│   │       └── SyncHandler.hs             # Xử lý gói tin đồng bộ
│   │
│   ├── tests/
│   │   ├── CombatSpec.hs
│   │   ├── EntitySpec.hs
│   │   ├── DungeonSpec.hs
│   │   └── NetworkSpec.hs
│   │
│   ├── Dockerfile
│   ├── config/
│   │   ├── server.yaml
│   │   ├── database.yaml
│   │   └── logging.yaml
│   │
│   ├── migrations/
│   │   ├── 001_init_schema.sql
│   │   ├── 002_seed_items.sql
│   │   ├── 003_seed_tanks.sql
│   │   └── 004_seed_skills.sql
│   │
│   └── db/
│       ├── schema.sql
│       └── seed/
│           ├── items.sql
│           ├── tanks.sql
│           ├── skills.sql
│
├── client/
│   ├── src/
│   │   ├── Main.hs                        # Entry client
│   │   ├── Core/Renderer.hs               # Render sprite, ánh sáng, map
│   │   ├── Core/Input.hs                  # Xử lý input WASD, chuột
│   │   ├── Core/Audio.hs                  # Âm thanh bắn, nổ
│   │   ├── UI/HUD.hs                      # Thanh máu, radar, ammo
│   │   ├── UI/Shop.hs                     # Cửa hàng nâng cấp
│   │   ├── UI/Menu.hs                     # Menu chính, chọn chế độ
│   │   └── Network/ClientNet.hs           # Giao tiếp TCP/UDP với server
│   │
│   ├── assets/
│   │   ├── textures/
│   │   │   ├── tanks/
│   │   │   ├── enemies/
│   │   │   ├── boss/
│   │   │   └── ui/
│   │   ├── sounds/
│   │   ├── shaders/
│   │   └── ui/
│   │
│   ├── config/
│   │   └── client.yaml
│   ├── Dockerfile
│   ├── build.sh
│   └── dist/
│
├── shared/
│   ├── src/
│   │   ├── Network/
│   │   │   ├── Packet.hs
│   │   │   ├── Protocol.hs
│   │   │   ├── TCPHandler.hs
│   │   │   └── UDPHandler.hs
│   │   └── Types/
│   │       ├── Player.hs
│   │       ├── Tank.hs
│   │       ├── Enemy.hs
│   │       └── Item.hs
│
├── database/
│   ├── Dockerfile
│   ├── init.sql
│   ├── data/
│   └── backup/
│
├── docker-compose.yaml
│
└── scripts/
    ├── run-dev.sh
    ├── build-all.sh
    └── migrate.sh
```

---

## 6. Dòng Dữ Liệu

### Client → Server

| Gói                 | Dạng | Mô tả                         |
| ------------------- | ---- | ----------------------------- |
| `PlayerCommand`     | UDP  | Di chuyển, hướng, bắn, reload |
| `JoinRoom {roomId}` | TCP  | Tham gia phòng PvP/Co-op      |
| `ChatMessage`       | TCP  | Gửi tin nhắn                  |
| `UpgradeRequest`    | TCP  | Mua nâng cấp hoặc skin        |
| `Disconnect`        | TCP  | Rời trận                      |

### Server → Client

| Gói                        | Dạng | Mô tả                            |
| -------------------------- | ---- | -------------------------------- |
| `WorldSnapshot`            | UDP  | Toàn bộ state tick hiện tại      |
| `CombatEvent`              | UDP  | Hiệu ứng nổ, kill, buff          |
| `RoomUpdate`               | TCP  | Danh sách người chơi trong phòng |
| `ChatBroadcast`            | TCP  | Tin nhắn chat                    |
| `ShopData / UpgradeResult` | TCP  | Kết quả giao dịch                |
| `GameOverSummary`          | TCP  | Tổng kết sau trận                |

---

## 7. GIAO THỨC TRUYỀN THÔNG (TCP & UDP)

### **A. Nguyên tắc chọn giao thức**

| Loại dữ liệu                                                     | Đặc điểm                                       | Giao thức | Lý do                                                |
| ---------------------------------------------------------------- | ---------------------------------------------- | --------- | ---------------------------------------------------- |
| **Real-time Gameplay (vị trí, bắn, combat, snapshot)**           | Cập nhật liên tục, mất gói không ảnh hưởng lớn | **UDP**   | Nhanh, không cần đảm bảo thứ tự tuyệt đối            |
| **Chat / Room / Lobby / Mua hàng / Auth / Shop / Database Sync** | Cần đảm bảo chính xác, không mất gói           | **TCP**   | Đảm bảo thứ tự, có retry, phù hợp dữ liệu quan trọng |
| **Ping / Heartbeat**                                             | Gói nhỏ, định kỳ                               | **UDP**   | Kiểm tra độ trễ mà không cần ACK                     |

---

### **B. Khi nào dùng TCP**

1. **Auth & Login:**
   Gửi thông tin đăng nhập, nhận token → cần chắc chắn.
2. **Create Room / Join Room / Leave Room:**
   Tạo session hoặc PvP phòng → cần đảm bảo.
3. **Chat System:**
   Mất tin nhắn là lỗi hiển nhiên → TCP.
4. **Shop & Upgrade:**
   Giao dịch tiền vàng, skin, nâng cấp tank → phải đúng 100%.
5. **Match Result (Endgame Summary):**
   Gửi về điểm, vàng → cần xác thực.

---

### **C. Khi nào dùng UDP**

1. **PlayerCommand:**
   Gửi hướng, tốc độ, hành động mỗi tick. Nếu mất 1 gói → tick sau vẫn cập nhật.
2. **WorldSnapshot:**
   Đồng bộ toàn cục từ server → client.
   Gửi 15–30 lần/giây, không cần đảm bảo tất cả đến.
3. **CombatEvent (Hiệu ứng):**
   Hiển thị vụ nổ, sát thương, killfeed → chỉ cần realtime.
4. **Heartbeat:**
   Ping latency để điều chỉnh interpolation.

---

### **D. Định Dạng Gói (giả định)**

**UDP Packet (binary):**

```
Header: [tickID][entityCount]
Body: [entityID][x][y][rot][hp] ... repeated
CRC: [uint16 checksum]
```

**TCP Packet (JSON/BSON):**

```json
{
  "type": "JoinRoom",
  "payload": { "roomId": "ABC123" }
}
```

---

### **E. Hệ thống Network trong Haskell**

* Dùng `network` hoặc `network-simple` cho TCP/UDP.
* Mỗi Client giữ:

  ```haskell
  data NetConn = NetConn
    { tcpSocket :: Socket
    , udpSocket :: Socket
    , udpAddr   :: SockAddr
    }
  ```
* Packet parser tách biệt:

  ```haskell
  data Packet
    = PlayerCommand CommandData
    | WorldSnapshot SnapshotData
    | ChatMessage Text
    | UpgradeRequest UpgradeData
  ```
* Mã hóa/giải mã dùng `aeson` hoặc `binary` (tùy tốc độ cần thiết).

---

## 8. Tóm tắt mạng Client–Server

| Luồng           | Giao thức | Nội dung           | Tần suất       |
| --------------- | --------- | ------------------ | -------------- |
| Client → Server | UDP       | PlayerCommand      | 30–60 lần/s    |
| Server → Client | UDP       | WorldSnapshot      | 15–30 lần/s    |
| Client ↔ Server | TCP       | Chat / Shop / Room | Khi có sự kiện |
| Client ↔ Server | UDP       | Ping/Pong          | 2–5 lần/s      |


