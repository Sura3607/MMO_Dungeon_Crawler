# Phân tích chi tiết & Mục tiêu thực hiện dự án

Để xây dựng bản cơ bản của game MMO Dungeon Crawler (Safe Zone + Dungeon + Multiplayer 2 máy), toàn bộ thành phần gameplay, vật phẩm, kỹ năng, asset và công nghệ sẽ được gom thành các mục tiêu cụ thể sau:

---

## 1. Hệ thống vật phẩm và cơ chế sử dụng

Trò chơi cần một hệ thống vật phẩm cơ bản để hỗ trợ sinh tồn và chiến đấu. Người chơi sẽ mang theo giới hạn số lượng item, mỗi item có cooldown riêng, buộc người chơi phải tính toán chiến lược.

* Các potion (Small Healing, Greater Healing, Mana) là nguồn hồi phục chính, tạo nhịp độ an toàn trong dungeon.
* Buff item như Scroll of Protection hay Elixir of Fury cho phép tạo lợi thế tạm thời, tăng chiều sâu chiến đấu.

Mục tiêu cần làm:

* Xây dựng module `ItemSystem` trong server quản lý toàn bộ item: tên, hiệu ứng, số lượng tối đa, cooldown.
* Client hiển thị icon item trong túi đồ, cho phép bấm để sử dụng.
* Server kiểm tra cooldown, cập nhật HP/MP hoặc buff rồi sync lại trạng thái cho toàn party.

---

## 2. Hệ thống kỹ năng và sách kỹ năng

Gameplay được mở rộng thông qua hệ thống **Skill Book**. Người chơi học kỹ năng từ sách, gắn vào thanh kỹ năng, tiêu hao mana hoặc HP khi sử dụng.

* Vanguard tập trung vào kỹ năng cận chiến và gây sát thương lớn theo %HP.
* Tank giữ vai trò phòng thủ với skill khiêu khích, giảm damage và làm choáng.
* Mage tạo sát thương phép AOE với khả năng khống chế.
* Priest hồi máu, buff và hồi sinh.

Mục tiêu cần làm:

* Xây dựng module `SkillSystem` trên server với dữ liệu: tên kỹ năng, cost (mana/HP), thời gian hiệu lực (buff), hiệu ứng (dmg/heal).
* Client cần có thanh kỹ năng (skill bar 6 slot), gửi input skill đến server.
* Server xử lý hiệu ứng, tính damage/heal dựa theo công thức, áp dụng lên entity (player/quái).
* Asset bổ sung: icon skill, hiệu ứng hình ảnh (fireball, heal, lightning).

---

## 3. Asset đồ họa và âm thanh

Trò chơi cần bộ asset cơ bản để thể hiện Safe Zone, Dungeon, nhân vật, quái vật và giao diện người chơi.

* Safe Zone dùng tilemap với lớp nền, công trình, NPC.
* Dungeon cần tileset phòng/tầng, sprite quái và boss.
* Nhân vật mỗi class cần sprite sheet: idle, walk, attack, cast, die.
* UI cơ bản gồm HP/MP bar, party frame, skill bar, inventory, chat box.
* Âm thanh cần có nhạc nền (Safe Zone, Dungeon) và hiệu ứng kỹ năng/chiến đấu.

Mục tiêu cần làm:

* Dùng **Tiled Map Editor** để thiết kế map Safe Zone và Dungeon. Xuất JSON để server/client đọc.
* Vẽ hoặc lấy sprite pixel 32x32/64x64 cho nhân vật và quái.
* Tích hợp SDL2 hoặc Gloss để load sprite sheet và render animation.
* Bổ sung hệ thống âm thanh: SFX cho kỹ năng, BGM cho từng khu vực.

---

## 4. Core Gameplay cần hiện thực

Để game có thể chạy ở mức cơ bản, cần hiện thực đầy đủ **hệ thống gameplay cốt lõi**:

* **Entity System**: quản lý player, quái, boss, item drop với thuộc tính HP, MP, pos, status.
* **Combat System**: công thức damage/heal, mana cost, buff/debuff.
* **Dungeon Generator**: ban đầu có thể dùng map tĩnh JSON, spawn quái theo seed cố định.
* **Sync System**: client gửi input (di chuyển, skill) → server xử lý → server trả trạng thái toàn cục.

Mục tiêu cần làm:

* Viết server Haskell quản lý state dungeon và safe zone, xử lý toàn bộ logic chiến đấu.
* Viết client Haskell render bằng Gloss/SDL2, chỉ chịu trách nhiệm hiển thị và gửi input.
* Tích hợp chat trong Safe Zone và sync di chuyển giữa nhiều người chơi.

---

## 5. Hệ thống mạng và lưu trữ

Game cần kiến trúc client-server để đồng bộ trạng thái và hỗ trợ multiplayer.

* **Networking**: sử dụng WebSocket hoặc TCP socket (thư viện `network` hoặc `websockets` Haskell).

  * TCP dùng cho login, trade, sync item.
  * UDP (hoặc WebSocket fast) cho di chuyển và combat tick nhanh.
* **Database**: PostgreSQL để lưu dữ liệu dài hạn: account, nhân vật, inventory. Redis để cache trạng thái online, party, dungeon session.
* Với demo: có thể bỏ DB, dùng Map Haskell in-memory, chỉ cần sync real-time.

Mục tiêu cần làm:

* Xây dựng module `NetworkSystem` trong server, quản lý kết nối client, gửi/nhận packet JSON.
* Đảm bảo cơ chế sync tick 20–30 lần/giây cho di chuyển, còn các action khác xử lý sự kiện.
* Chuẩn bị schema PostgreSQL (players, characters, inventory) cho bước mở rộng.

---

## 6. Công cụ và môi trường phát triển

Dự án chạy bằng Haskell, cần môi trường build và triển khai:

* **Stack hoặc Cabal** để build project.
* **Docker** để đóng gói server, dễ triển khai trên VPS.
* **Local LAN test** để kiểm tra kết nối 2 máy riêng biệt.

Mục tiêu cần làm:

* Thiết lập skeleton dự án Haskell gồm: `Server`, `Client`, `Shared` (model, entity).
* Xây dựng quy trình build & test trên máy local.
* Có thể mở rộng triển khai lên VPS hoặc AWS khi cần.

---

## 7. Mục tiêu tối thiểu (MVP)

Để có một bản **chơi được**, chỉ cần:

* Safe Zone nhỏ, di chuyển được, chat text cơ bản.
* Một dungeon đơn giản (1 phòng) có quái spawn.
* Nhân vật có thể chọn class (Tank, Mage) và dùng ít nhất 1 skill.
* Hệ thống item cơ bản (Potion Nhỏ).
* Multiplayer: 2 máy khác nhau kết nối server, thấy nhau di chuyển, cùng đánh quái, cùng nhận exp.


