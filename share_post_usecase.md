# Tính năng chia sẻ bài viết qua tin nhắn

## Use Case 1: Chia sẻ bài viết cho 1 người bạn
**Actor:** Người gửi

**Luồng chính:**
1. Người dùng mở màn hình chi tiết bài viết
2. Nhấn nút "Chia sẻ"
3. Hệ thống hiển thị danh sách bạn bè
4. Người dùng chọn 1 người bạn
5. Nhấn nút "Gửi"
6. Hệ thống tạo tin nhắn loại `shared_post`
7. Tin nhắn được lưu vào database
8. Tin nhắn xuất hiện trong cuộc trò chuyện của cả hai người
9. Người nhận thấy một card xem trước bài viết
10. Người nhận nhấn vào card → hệ thống mở màn hình chi tiết bài viết

**Kết quả:** Bài viết được gửi thành công và có thể mở lại từ khung chat.

---

## Use Case 2: Chia sẻ bài viết cho nhiều người
**Actor:** Người gửi

**Luồng chính:**
1. Người dùng mở bài viết → nhấn nút "Chia sẻ"
2. Hệ thống hiển thị danh sách bạn bè
3. Người dùng chọn nhiều người → nhấn "Gửi"
4. Hệ thống tạo tin nhắn chia sẻ cho từng cuộc trò chuyện
5. Mỗi người nhận đều nhận được card bài viết

**Kết quả:** Nhiều người nhận cùng lúc nhận được bài viết.

---

## Use Case 3: Tìm kiếm người nhận
**Actor:** Người gửi

**Luồng chính:**
1. Mở cửa sổ chia sẻ
2. Nhập tên bạn bè vào ô tìm kiếm
3. Hệ thống lọc danh sách theo từ khóa
4. Người dùng chọn người cần gửi

**Kết quả:** Dễ dàng tìm người nhận trong danh sách lớn.

---

## Use Case 4: Xem bài viết được chia sẻ
**Actor:** Người nhận

**Luồng chính:**
1. Người nhận mở cuộc trò chuyện
2. Thấy tin nhắn dạng card bài viết, hiển thị:
   - Ảnh đại diện bài viết
   - Tên người đăng
   - Nội dung rút gọn
   - Thời gian đăng
3. Nhấn vào card → hệ thống lấy dữ liệu theo `post_id`
4. Mở màn hình chi tiết bài viết với đầy đủ nội dung

**Kết quả:** Người nhận xem được bài viết như bài gốc.

---

## Use Case 5: Bài viết đã bị xóa
**Actor:** Người nhận

**Luồng chính:**
1. Người nhận nhấn vào card bài viết
2. Hệ thống kiểm tra `post_id` → không tìm thấy bài viết

**Luồng thay thế:**
- Hiển thị: *"Bài viết này hiện không còn khả dụng."*
- Không điều hướng đến trang chi tiết

**Kết quả:** Ứng dụng không bị lỗi khi bài viết đã bị xóa.

---

## Use Case 6: Bài viết bị ẩn hoặc riêng tư
**Actor:** Người nhận

**Luồng chính:**
1. Người nhận nhấn vào bài viết được chia sẻ
2. Hệ thống tìm thấy bài viết → kiểm tra quyền truy cập
3. Người nhận không có quyền xem

**Luồng thay thế:**
- Hiển thị: *"Bạn không có quyền xem bài viết này."*

**Kết quả:** Đảm bảo quyền riêng tư của người đăng.

---

## Use Case 7: Chia sẻ từ cuộc trò chuyện
**Actor:** Người gửi

**Luồng chính:**
1. Người dùng đang ở màn hình chat
2. Chọn chức năng chia sẻ bài viết
3. Chọn một bài viết
4. Hệ thống gửi bài viết vào cuộc trò chuyện hiện tại
5. Tin nhắn bài viết xuất hiện ngay trong khung chat

**Kết quả:** Người dùng có thể chia sẻ bài viết trực tiếp từ chat.

---

## Use Case 8: Nhận thông báo khi có bài viết được chia sẻ
**Actor:** Người nhận

**Luồng chính:**
1. Người gửi chia sẻ bài viết
2. Hệ thống gửi push notification
3. Người nhận nhận thông báo: *"[Tên người gửi] đã chia sẻ một bài viết với bạn."*
4. Nhấn thông báo → mở đúng cuộc trò chuyện chứa bài viết

**Kết quả:** Người nhận được thông báo ngay lập tức.

---

## Ghi chú kỹ thuật

### Bảng liên quan
- `messages`: lưu tin nhắn loại `message_type = 'post'`, có cột `post_id (int8)`
- `conversations`: cuộc trò chuyện giữa các user
- `conversation_members`: thành viên trong cuộc trò chuyện
- `posts`: kiểm tra `status = 'active'` và `visibility` trước khi cho xem

### Logic kiểm tra quyền xem khi nhấn vào card
```
post.status != 'active'       → "Bài viết không còn khả dụng"
post.visibility = 'private'
  và viewer != author         → "Không có quyền xem"
post.visibility = 'follower'
  và viewer không follow      → "Không có quyền xem"
post.visibility = 'public'    → cho xem bình thường
```

### Message type
Tin nhắn chia sẻ bài viết dùng `message_type = 'post'` — đã có sẵn trong schema `messages`.
