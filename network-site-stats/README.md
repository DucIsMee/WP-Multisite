# Network Site Stats

Plugin WordPress Multisite giúp Super Admin theo dõi tổng quan tất cả site con trong mạng lưới.

## Tính năng

- Hiển thị bảng thống kê tất cả site con (ID, Tên, URL, Số bài viết, Ngày bài mới nhất, Dung lượng upload, Trạng thái)
- Summary cards tổng hợp (tổng site, site hoạt động, tổng bài viết)
- Truy cập nhanh Dashboard hoặc trang chỉnh sửa từng site
- Chỉ hiển thị với Super Admin trong Network Admin

## Cài đặt

1. Tải thư mục `network-site-stats` vào `/wp-content/plugins/`
2. Vào **Network Admin → Plugins → Network Activate** plugin

## Yêu cầu

- WordPress 5.0+
- PHP 7.4+
- Chế độ Multisite đã bật

## Cấu trúc file

```
network-site-stats/
├── network-site-stats.php   # File plugin chính
└── README.md
```

## Các hàm WordPress Multisite quan trọng

| Hàm | Mô tả |
|-----|-------|
| `get_sites()` | Lấy danh sách tất cả site trong mạng lưới |
| `switch_to_blog($id)` | Chuyển ngữ cảnh sang site con |
| `restore_current_blog()` | Khôi phục ngữ cảnh site ban đầu |
| `wp_count_posts()` | Đếm bài viết trong ngữ cảnh hiện tại |
| `is_multisite()` | Kiểm tra có phải môi trường Multisite không |
