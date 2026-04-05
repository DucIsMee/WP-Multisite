-- ============================================================
--  WordPress Multisite — Demo Database
--  Plugin: Network Site Stats
--  Cấu trúc: Sub-directories
--    Site chính : localhost/wordpress/         (blog_id = 1)
--    Site A      : localhost/wordpress/site-a/ (blog_id = 2)
--    Site B      : localhost/wordpress/site-b/ (blog_id = 3)
-- ============================================================

SET SQL_MODE   = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone  = "+07:00";
SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- TẠO DATABASE
-- ------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS `wp_multisite`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `wp_multisite`;


-- ============================================================
--  BẢNG DÙNG CHUNG (SHARED TABLES)
--  Các bảng này không có prefix số, dùng cho toàn mạng lưới
-- ============================================================

-- ------------------------------------------------------------
-- wp_site — Thông tin mạng lưới (thường chỉ 1 bản ghi)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `wp_site`;
CREATE TABLE `wp_site` (
  `id`     bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `domain` varchar(200)        NOT NULL DEFAULT '',
  `path`   varchar(100)        NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `domain` (`domain`(140), `path`(51))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `wp_site` (`id`, `domain`, `path`) VALUES
(1, 'localhost', '/wordpress/');


-- ------------------------------------------------------------
-- wp_blogs — Danh sách tất cả site con
--   → get_sites() đọc từ bảng này
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `wp_blogs`;
CREATE TABLE `wp_blogs` (
  `blog_id`     bigint(20)  UNSIGNED NOT NULL AUTO_INCREMENT,
  `site_id`     bigint(20)  UNSIGNED NOT NULL DEFAULT 0,
  `domain`      varchar(200)         NOT NULL DEFAULT '',
  `path`        varchar(100)         NOT NULL DEFAULT '',
  `registered`  datetime             NOT NULL DEFAULT '0000-00-00 00:00:00',
  `last_updated` datetime            NOT NULL DEFAULT '0000-00-00 00:00:00',
  `public`      tinyint(2)           NOT NULL DEFAULT 1,
  `archived`    tinyint(2)           NOT NULL DEFAULT 0,
  `mature`      tinyint(2)           NOT NULL DEFAULT 0,
  `spam`        tinyint(2)           NOT NULL DEFAULT 0,
  `deleted`     tinyint(2)           NOT NULL DEFAULT 0,
  `lang_id`     int(11)              NOT NULL DEFAULT 0,
  PRIMARY KEY (`blog_id`),
  KEY `domain` (`domain`(50), `path`(5)),
  KEY `lang_id` (`lang_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `wp_blogs`
  (`blog_id`, `site_id`, `domain`,    `path`,       `registered`,          `last_updated`,        `public`, `archived`, `deleted`)
VALUES
  (1,          1,         'localhost', '/wordpress/', '2025-01-01 07:00:00', '2025-06-01 10:00:00', 1,        0,          0),
  (2,          1,         'localhost', '/wordpress/site-a/', '2025-01-15 08:00:00', '2025-06-10 09:30:00', 1, 0,         0),
  (3,          1,         'localhost', '/wordpress/site-b/', '2025-01-20 09:00:00', '2025-06-12 14:15:00', 1, 0,         0);


-- ------------------------------------------------------------
-- wp_sitemeta — Cài đặt cấp mạng lưới
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `wp_sitemeta`;
CREATE TABLE `wp_sitemeta` (
  `meta_id`    bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `site_id`    bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `meta_key`   varchar(255)        DEFAULT NULL,
  `meta_value` longtext            DEFAULT NULL,
  PRIMARY KEY (`meta_id`),
  KEY `meta_key` (`meta_key`(191)),
  KEY `site_id` (`site_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `wp_sitemeta` (`site_id`, `meta_key`, `meta_value`) VALUES
(1, 'siteurl',          'http://localhost/wordpress'),
(1, 'admin_email',      'admin@example.com'),
(1, 'admin_user_id',    '1'),
(1, 'subdomain_install',''),                   -- '' = sub-directories
(1, 'active_sitewide_plugins', 'a:1:{s:37:"network-site-stats/network-site-stats.php";i:1;}'),
(1, 'allowedthemes',    'a:1:{s:18:"twentytwentyfour";b:1;}'),
(1, 'blog_count',       '3'),
(1, 'site_name',        'My WordPress Network');


-- ------------------------------------------------------------
-- wp_users — Tất cả người dùng toàn mạng lưới
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `wp_users`;
CREATE TABLE `wp_users` (
  `ID`                  bigint(20)   UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_login`          varchar(60)           NOT NULL DEFAULT '',
  `user_pass`           varchar(255)          NOT NULL DEFAULT '',
  `user_nicename`       varchar(50)           NOT NULL DEFAULT '',
  `user_email`          varchar(100)          NOT NULL DEFAULT '',
  `user_url`            varchar(100)          NOT NULL DEFAULT '',
  `user_registered`     datetime              NOT NULL DEFAULT '0000-00-00 00:00:00',
  `user_activation_key` varchar(255)          NOT NULL DEFAULT '',
  `user_status`         int(11)               NOT NULL DEFAULT 0,
  `display_name`        varchar(250)          NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`),
  KEY `user_login_key` (`user_login`),
  KEY `user_nicename`  (`user_nicename`),
  KEY `user_email`     (`user_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Mật khẩu demo: hash của "Admin@1234" (bcrypt)
INSERT INTO `wp_users`
  (`ID`, `user_login`, `user_pass`,                                            `user_nicename`, `user_email`,             `user_registered`,     `display_name`)
VALUES
  (1,    'admin',      '$P$BIRXVBCe5aExF.aN6oeKmLkLdJy5lp.',                 'admin',         'admin@example.com',       '2025-01-01 07:00:00', 'Super Admin'),
  (2,    'editor_a',   '$P$BIRXVBCe5aExF.aN6oeKmLkLdJy5lp.',                 'editor-a',      'editor.a@example.com',    '2025-01-15 08:00:00', 'Editor Site A'),
  (3,    'editor_b',   '$P$BIRXVBCe5aExF.aN6oeKmLkLdJy5lp.',                 'editor-b',      'editor.b@example.com',    '2025-01-20 09:00:00', 'Editor Site B');


-- ------------------------------------------------------------
-- wp_usermeta — Phân quyền người dùng theo từng site
--   Khoá quan trọng: wp_{blog_id}_capabilities
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `wp_usermeta`;
CREATE TABLE `wp_usermeta` (
  `umeta_id`   bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`    bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `meta_key`   varchar(255)        DEFAULT NULL,
  `meta_value` longtext            DEFAULT NULL,
  PRIMARY KEY (`umeta_id`),
  KEY `user_id`  (`user_id`),
  KEY `meta_key` (`meta_key`(191))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `wp_usermeta` (`user_id`, `meta_key`, `meta_value`) VALUES
-- Super Admin (user_id=1): quyền trên tất cả site
(1, 'wp_capabilities',            'a:1:{s:13:"administrator";b:1;}'),
(1, 'wp_user_level',              '10'),
(1, 'wp_2_capabilities',          'a:1:{s:13:"administrator";b:1;}'),
(1, 'wp_3_capabilities',          'a:1:{s:13:"administrator";b:1;}'),
(1, 'source_domain',              'localhost'),

-- Editor Site A (user_id=2)
(2, 'wp_2_capabilities',          'a:1:{s:6:"editor";b:1;}'),
(2, 'wp_2_user_level',            '7'),

-- Editor Site B (user_id=3)
(3, 'wp_3_capabilities',          'a:1:{s:6:"editor";b:1;}'),
(3, 'wp_3_user_level',            '7');


-- ------------------------------------------------------------
-- wp_blog_versions — Theo dõi phiên bản DB từng site
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `wp_blog_versions`;
CREATE TABLE `wp_blog_versions` (
  `blog_id`    bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `db_version` varchar(20)         NOT NULL DEFAULT '',
  `last_updated` datetime          NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`blog_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `wp_blog_versions` VALUES
(1, '57155', '2025-06-01 10:00:00'),
(2, '57155', '2025-06-10 09:30:00'),
(3, '57155', '2025-06-12 14:15:00');


-- ============================================================
--  BẢNG SITE CHÍNH (blog_id = 1) — prefix: wp_
-- ============================================================

-- ------------------------------------------------------------
-- wp_options — Cài đặt site chính
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `wp_options`;
CREATE TABLE `wp_options` (
  `option_id`    bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `option_name`  varchar(191)        NOT NULL DEFAULT '',
  `option_value` longtext            NOT NULL,
  `autoload`     varchar(20)         NOT NULL DEFAULT 'yes',
  PRIMARY KEY (`option_id`),
  UNIQUE KEY `option_name` (`option_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `wp_options` (`option_name`, `option_value`) VALUES
('siteurl',    'http://localhost/wordpress'),
('blogname',   'My WordPress Network'),
('blogdescription', 'Trang web chính của mạng lưới'),
('admin_email','admin@example.com'),
('template',   'twentytwentyfour'),
('stylesheet', 'twentytwentyfour');


-- ------------------------------------------------------------
-- wp_posts — Bài viết site chính
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `wp_posts`;
CREATE TABLE `wp_posts` (
  `ID`                    bigint(20)   UNSIGNED NOT NULL AUTO_INCREMENT,
  `post_author`           bigint(20)   UNSIGNED NOT NULL DEFAULT 0,
  `post_date`             datetime              NOT NULL DEFAULT '0000-00-00 00:00:00',
  `post_content`          longtext              NOT NULL,
  `post_title`            text                  NOT NULL,
  `post_excerpt`          text                  NOT NULL,
  `post_status`           varchar(20)           NOT NULL DEFAULT 'publish',
  `comment_status`        varchar(20)           NOT NULL DEFAULT 'open',
  `ping_status`           varchar(20)           NOT NULL DEFAULT 'open',
  `post_name`             varchar(200)          NOT NULL DEFAULT '',
  `post_type`             varchar(20)           NOT NULL DEFAULT 'post',
  `comment_count`         bigint(20)            NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`),
  KEY `post_name` (`post_name`(191)),
  KEY `type_status_date` (`post_type`,`post_status`,`post_date`,`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `wp_posts`
  (`ID`, `post_author`, `post_date`,            `post_content`,                              `post_title`,           `post_status`, `post_type`, `post_name`)
VALUES
  (1,    1,             '2025-01-05 08:00:00',  'Chào mừng đến với trang web chính.',        'Giới thiệu mạng lưới', 'publish',     'post',      'gioi-thieu-mang-luoi'),
  (2,    1,             '2025-02-10 09:30:00',  'WordPress Multisite là gì?',                'Tìm hiểu Multisite',   'publish',     'post',      'tim-hieu-multisite'),
  (3,    1,             '2025-03-20 14:00:00',  'Hướng dẫn cài đặt plugin Network Activate.','Hướng dẫn Plugin',     'publish',     'post',      'huong-dan-plugin'),
  (4,    1,             '2025-04-01 10:00:00',  'Trang mẫu về chính sách.',                  'Chính sách',           'publish',     'page',      'chinh-sach'),
  (5,    1,             '2025-05-15 11:00:00',  'Bài viết nháp chưa xuất bản.',              'Bài nháp',             'draft',       'post',      '');


-- ============================================================
--  BẢNG SITE A (blog_id = 2) — prefix: wp_2_
-- ============================================================

-- ------------------------------------------------------------
-- wp_2_options
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `wp_2_options`;
CREATE TABLE `wp_2_options` (
  `option_id`    bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `option_name`  varchar(191)        NOT NULL DEFAULT '',
  `option_value` longtext            NOT NULL,
  `autoload`     varchar(20)         NOT NULL DEFAULT 'yes',
  PRIMARY KEY (`option_id`),
  UNIQUE KEY `option_name` (`option_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `wp_2_options` (`option_name`, `option_value`) VALUES
('siteurl',    'http://localhost/wordpress/site-a'),
('blogname',   'Site A Demo'),
('blogdescription', 'Trang web con Site A'),
('admin_email','admin@example.com'),
('template',   'twentytwentyfour'),
('stylesheet', 'twentytwentyfour');


-- ------------------------------------------------------------
-- wp_2_posts — Bài viết Site A
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `wp_2_posts`;
CREATE TABLE `wp_2_posts` LIKE `wp_posts`;

INSERT INTO `wp_2_posts`
  (`ID`, `post_author`, `post_date`,            `post_content`,                              `post_title`,              `post_status`, `post_type`, `post_name`)
VALUES
  (1,    1,             '2025-01-16 08:00:00',  'Chào mừng đến với Site A!',                 'Giới thiệu Site A',       'publish',     'post',      'gioi-thieu-site-a'),
  (2,    2,             '2025-02-20 10:00:00',  'Nội dung bài viết thứ hai của Site A.',     'Bài viết số 2 - Site A',  'publish',     'post',      'bai-viet-so-2-site-a'),
  (3,    2,             '2025-03-05 09:00:00',  'Chia sẻ kinh nghiệm lập trình WordPress.', 'Kinh nghiệm WordPress',   'publish',     'post',      'kinh-nghiem-wp'),
  (4,    2,             '2025-04-18 15:30:00',  'Cách tối ưu tốc độ website.',               'Tối ưu tốc độ',           'publish',     'post',      'toi-uu-toc-do'),
  (5,    1,             '2025-05-25 11:00:00',  'Hướng dẫn sử dụng Multisite.',              'Hướng dẫn Multisite',     'publish',     'post',      'huong-dan-multisite'),
  (6,    2,             '2025-06-10 09:30:00',  'Bài viết mới nhất của Site A.',             'Tin tức tháng 6 - Site A','publish',     'post',      'tin-tuc-thang-6-site-a');


-- ============================================================
--  BẢNG SITE B (blog_id = 3) — prefix: wp_3_
-- ============================================================

-- ------------------------------------------------------------
-- wp_3_options
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `wp_3_options`;
CREATE TABLE `wp_3_options` (
  `option_id`    bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `option_name`  varchar(191)        NOT NULL DEFAULT '',
  `option_value` longtext            NOT NULL,
  `autoload`     varchar(20)         NOT NULL DEFAULT 'yes',
  PRIMARY KEY (`option_id`),
  UNIQUE KEY `option_name` (`option_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `wp_3_options` (`option_name`, `option_value`) VALUES
('siteurl',    'http://localhost/wordpress/site-b'),
('blogname',   'Site B Demo'),
('blogdescription', 'Trang web con Site B'),
('admin_email','admin@example.com'),
('template',   'twentytwentyfour'),
('stylesheet', 'twentytwentyfour');


-- ------------------------------------------------------------
-- wp_3_posts — Bài viết Site B
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `wp_3_posts`;
CREATE TABLE `wp_3_posts` LIKE `wp_posts`;

INSERT INTO `wp_3_posts`
  (`ID`, `post_author`, `post_date`,            `post_content`,                              `post_title`,              `post_status`, `post_type`, `post_name`)
VALUES
  (1,    1,             '2025-01-21 08:00:00',  'Chào mừng đến với Site B!',                 'Giới thiệu Site B',       'publish',     'post',      'gioi-thieu-site-b'),
  (2,    3,             '2025-02-14 10:00:00',  'Site B chuyên về thiết kế UI/UX.',          'Về chúng tôi - Site B',   'publish',     'post',      've-chung-toi-site-b'),
  (3,    3,             '2025-03-30 14:00:00',  'Top 10 công cụ thiết kế UI năm 2025.',      'Công cụ thiết kế UI',     'publish',     'post',      'cong-cu-thiet-ke-ui'),
  (4,    3,             '2025-06-12 14:15:00',  'Xu hướng thiết kế website năm 2025.',       'Xu hướng thiết kế 2025',  'publish',     'post',      'xu-huong-thiet-ke-2025');


-- ============================================================
--  XÁC NHẬN KẾT QUẢ
--  Query này mô phỏng logic của plugin get_sites() + switch_to_blog()
-- ============================================================

-- Xem danh sách tất cả site (get_sites())
SELECT
    b.blog_id,
    b.domain,
    b.path,
    b.archived,
    b.deleted
FROM wp_blogs b
WHERE b.deleted = 0
ORDER BY b.blog_id;

-- Đếm bài viết từng site (wp_count_posts() sau switch_to_blog())
SELECT 'Site chính (blog_id=1)' AS site, COUNT(*) AS published_posts
FROM wp_posts   WHERE post_status = 'publish' AND post_type = 'post'
UNION ALL
SELECT 'Site A (blog_id=2)',             COUNT(*)
FROM wp_2_posts WHERE post_status = 'publish' AND post_type = 'post'
UNION ALL
SELECT 'Site B (blog_id=3)',             COUNT(*)
FROM wp_3_posts WHERE post_status = 'publish' AND post_type = 'post';

-- Lấy bài mới nhất từng site (get_posts() sau switch_to_blog())
SELECT 'Site chính' AS site, post_title, post_date
FROM wp_posts   WHERE post_status='publish' AND post_type='post' ORDER BY post_date DESC LIMIT 1;
SELECT 'Site A'     AS site, post_title, post_date
FROM wp_2_posts WHERE post_status='publish' AND post_type='post' ORDER BY post_date DESC LIMIT 1;
SELECT 'Site B'     AS site, post_title, post_date
FROM wp_3_posts WHERE post_status='publish' AND post_type='post' ORDER BY post_date DESC LIMIT 1;
