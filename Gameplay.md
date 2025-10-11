# GAMEPLAY CHI TIẾT — MMO TANK DUNGEON

## 1. Khái quát

**MMO Tank Dungeon** là game bắn súng góc nhìn từ trên xuống (top-down), nơi người chơi điều khiển một chiếc xe tăng chiến đấu qua các tầng hầm ngục (dungeon) chứa đầy quái vật và boss.
Mục tiêu của người chơi là **tiến sâu nhất có thể**, tiêu diệt boss, thu thập vàng để nâng cấp xe và tồn tại lâu nhất.

Game có ba chế độ:

1. **Solo (1 người)**
2. **Co-op (2 người)**
3. **PvP (đấu tay đôi)**

---

## 2. Vòng lặp gameplay (Game Loop)

1. **Người chơi bắt đầu tại map Safe Zone** — khu vực an toàn có:

   * **Cửa hàng chính:** mua items.
   * **Cổng Dungeon:** dẫn vào ngục tối.

2. **Bước vào Dungeon:**

   * Hệ thống sinh ra ngẫu nhiên bản đồ theo từng tầng (map tile-based).
   * Quái xuất hiện theo tầng (zone):

     * 1.1 → 1.2 → 1.3 → Boss 1
     * 2.1 → 2.2 → 2.3 → Boss 2
   * Mỗi tầng đều có tường, góc khuất, khu tối chỉ nhìn thấy bằng đèn xe.

3. **Chiến đấu:**

   * Người chơi điều khiển xe tank di chuyển, xoay nòng súng độc lập, tiêu diệt quái.
   * Nhặt vàng và vật phẩm hồi máu/đạn.
   * Khi hết đạn: phải nạp lại (bấm R hoặc tự động nếu về 0).

4. **Sau khi hạ Boss:**

   * Xuất hiện **Shop tạm thời trong dungeon** để nâng cấp:

     * Damage, tốc độ bắn, tốc độ di chuyển, giáp, tầm sáng, v.v.
   * Sau đó mở **cổng tiếp theo** dẫn tới tầng sau.

5. **Khi chết:**

   * Game hiển thị **bảng tổng kết**: số quái hạ, tầng đạt được, vàng thu được, tổng thời gian sinh tồn.
   * Người chơi quay lại Safe Zone.

---

## 3. Cơ chế điều khiển

| Hành động            | Phím / Chuột           | Mô tả                                   |
| -------------------- | ---------------------- | --------------------------------------- |
| Di chuyển            | **WASD**               | Tank di chuyển 8 hướng                  |
| Xoay nòng súng       | **Di chuyển chuột**    | Nòng xoay theo hướng trỏ chuột          |
| Bắn                  | **Chuột trái**         | Bắn theo hướng nòng súng                |
| Nạp đạn              | **R**                  | Bắt đầu hoặc hủy nạp đạn                |
| Mở bản đồ nhỏ        | **Tab / M**            | (Tùy chọn) hiển thị mini-map lớn        |
| Mua hàng / tương tác | **E hoặc click chuột** | Dùng tại cửa hàng hoặc vật thể đặc biệt |

---

## 4. Cơ chế chiến đấu

### 4.1. Loại xe tăng

#### (1) Rapid Tank — Xe tốc độ cao

* Bắn **2 viên đạn liên tiếp** tốc độ cao.
* **Sát thương đơn mục tiêu**, nhưng DPS tốt.
* Tốc độ di chuyển nhanh.
* Thời gian nạp đạn ngắn.
* Phù hợp đánh quái nhanh và né boss.

#### (2) Blast Tank — Xe pháo công nặng

* Bắn chậm, **gây sát thương nổ lan**.
* Tốc độ di chuyển thấp.
* Nạp đạn lâu nhưng sát thương cực cao.
* Mỗi viên đạn nổ có bán kính ảnh hưởng 2–3m.

---

### 4.2. Quái vật

* Có nhiều loại:

  * **Runner:** lao nhanh về phía người chơi, ít máu.
  * **Shooter:** bắn đạn thẳng, tầm xa trung bình.
  * **Tanky:** chậm nhưng nhiều máu, có thể chắn đường.
* Khi bị tiêu diệt có **tỷ lệ rơi vật phẩm**.
* Số lượng và độ khó tăng theo tầng dungeon.

---

### 4.3. Boss

* Mỗi khu (zone cuối) có 1 boss.
* Boss có 3 giai đoạn chiến đấu:

  * **Phase 1:** Bắn đạn vòng quanh, tốc độ trung bình.
  * **Phase 2:** Gọi quái phụ trợ, bắn đạn chùm.
  * **Phase 3:** Bắn sóng năng lượng, tốc độ cao, sát thương cực mạnh.
* Khi boss chết:

  * Rơi **vật phẩm hiếm hoặc nâng cấp đặc biệt**.
  * Mở **Shop tầng boss**.

---

## 5. Hệ thống tầm nhìn

* Môi trường dungeon **tối hoàn toàn**.
* Xe tank có **đèn pha hình nón** chiếu về hướng trước.
* Chỉ thấy trong vùng chiếu sáng, phần còn lại là màu đen.
* Có thể nâng cấp tầm nhìn qua shop:

  * **Light Range:** tăng độ dài ánh sáng.
  * **Light Cone:** mở rộng góc chiếu.
  * **Rear Light:** thêm ánh sáng sau lưng.

---

## 6. Hệ thống vật phẩm và nâng cấp

### 6.1. Vật phẩm rơi (Pickup Items)

| Tên vật phẩm    | Tác dụng                                      |
| --------------- | --------------------------------------------- |
| **Repair Kit**  | Hồi 25–50% máu                                |
| **Ammo Pack**   | Nạp đầy đạn                                   |
| **Gold Coin**   | Dùng để mua nâng cấp                          |
| **Radar Chip**  | Tăng tầm radar mini-map                       |
| **Energy Core** | Buff tạm thời (tăng damage, tốc độ, ánh sáng) |

### 6.2. Cửa hàng dungeon (Shop nâng cấp)

Sau mỗi boss, người chơi có thể mua bằng vàng:

| Nâng cấp           | Tác dụng                 |
| ------------------ | ------------------------ |
| **Damage Upgrade** | +15% sát thương          |
| **Fire Rate**      | +10% tốc độ bắn          |
| **Movement Speed** | +10% tốc độ di chuyển    |
| **Reload Speed**   | -20% thời gian nạp       |
| **Armor Plating**  | Giảm 10% sát thương nhận |
| **Light Range**    | Tăng 20% tầm sáng        |
| **AOE Radius**     | (Tank pháo) +15% vùng nổ |
| **Multi-Shot**     | (Tank rapid) +1 đường đạn|
| **Ammo Capacity**  | +20% số đạn/clip         |
* Các nâng cấp đặt biệt như **AOE Radius**, **Multi-Shot**  sẽ chỉ xuất hiện với loại tank tương ứng.
---

## 7. PvP Mode

* 1 bản đồ nhỏ (arena), có tường, góc khuất và khu vực tối.
* Mỗi người **3 mạng**.
* Khi chết, respawn ngẫu nhiên nếu còn mạng.
* Ai hết 3 mạng trước là thua.
* Có vật phẩm sinh ngẫu nhiên (tăng tốc, tăng sát thương, hồi máu).
* Radar hiển thị vị trí tương đối của đối thủ.

---

## 8. Giao diện người chơi (UI/HUD)

| Vị trí            | Thành phần           | Nội dung hiển thị                                             |
| ----------------- | -------------------- | ------------------------------------------------------------- |
| **Trên trái**     | Thanh máu (HP) + đạn | Hiển thị máu còn lại và số đạn trong clip                     |
| **Trên phải**     | Radar mini-map       | Chấm đỏ: địch / boss, chấm xanh: đồng đội, chấm lam: bản thân |
| **Giữa dưới**     | Icon buff            | Các hiệu ứng tạm thời đang kích hoạt                          |
| **Giữa màn hình** | Thông báo hành động  | “Reloading…”, “Boss incoming”                                 |
| **Cuối game**     | Bảng tổng kết        | Kill count, tầng đạt được, vàng thu được, thời gian sống      |

---

## 9. Cảm giác chơi (Player Experience)

* **Hồi hộp** vì tầm nhìn hạn chế, chỉ thấy trong vùng sáng.
* **Chiến thuật**: chọn nâng cấp phù hợp với lối chơi (tốc độ hay sát thương).
* **Cảm giác tăng tiến:** mỗi lần vượt boss sẽ mạnh hơn, tiến xa hơn.
* **Căng thẳng PvP:** do tầm nhìn tối, người chơi phải dựa vào radar và tiếng động để săn nhau.

---

## 10. Kết thúc và phần thưởng

* Trò chơi kết thúc khi:

  * Người chơi chết (Solo/Co-op).
  * Hết mạng (PvP).
* **Bảng tổng kết:**

  * Tổng số tầng vượt qua.
  * Tổng số quái/boss tiêu diệt.
  * Vàng thu được.
  * Điểm tổng kết (dùng để xếp hạng).
* **Phần thưởng (Meta progression):**

  * Vàng tổng cộng để mua tank mới / skin tại Safe Zone.


