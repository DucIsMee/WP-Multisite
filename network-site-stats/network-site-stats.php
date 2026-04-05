<?php
/**
 * Plugin Name:       Network Site Stats
 * Plugin URI:        https://github.com/example/network-site-stats
 * Description:       Hiển thị thống kê tổng quan các trang web con trong WordPress Multisite dành cho Super Admin.
 * Version:           1.0.0
 * Author:            Bui Minh Duc
 * Network:           true
 * Text Domain:       network-site-stats
 * Requires at least: 5.0
 * Requires PHP:      7.4
 */

// Ngăn truy cập trực tiếp vào file plugin
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Class chính của plugin Network Site Stats
 * Quản lý toàn bộ chức năng thống kê mạng lưới.
 */
class Network_Site_Stats {

    /**
     * Khởi tạo plugin: đăng ký các action/hook WordPress.
     */
    public function __construct() {
        // Chỉ hiển thị menu trong Network Admin (Super Admin)
        add_action( 'network_admin_menu', array( $this, 'add_network_menu' ) );

        // Đăng ký assets (CSS/JS) cho trang admin
        add_action( 'admin_enqueue_scripts', array( $this, 'enqueue_assets' ) );
    }

    /**
     * Thêm menu vào Network Admin Dashboard.
     *
     * Sử dụng add_menu_page() để tạo mục menu cấp cao nhất
     * chỉ xuất hiện trong Network Admin (/wp-admin/network/).
     */
    public function add_network_menu() {
        add_menu_page(
            __( 'Network Site Stats', 'network-site-stats' ), // Tiêu đề trang
            __( 'Site Stats', 'network-site-stats' ),         // Nhãn menu
            'manage_network',                                  // Quyền: chỉ Super Admin
            'network-site-stats',                             // Slug định danh menu
            array( $this, 'render_stats_page' ),              // Callback render nội dung
            'dashicons-chart-bar',                            // Biểu tượng menu
            30                                                // Vị trí trong menu
        );
    }

    /**
     * Enqueue CSS/JS cho trang thống kê.
     *
     * @param string $hook_suffix Hook hiện tại của trang admin.
     */
    public function enqueue_assets( $hook_suffix ) {
        // Chỉ load assets trên trang plugin của chúng ta
        if ( strpos( $hook_suffix, 'network-site-stats' ) === false ) {
            return;
        }

        // Inline CSS để tránh tạo file riêng
        wp_add_inline_style( 'wp-admin', $this->get_inline_css() );
    }

    /**
     * Trả về CSS nội tuyến cho bảng thống kê.
     *
     * @return string CSS string.
     */
    private function get_inline_css() {
        return '
            .nss-wrap { max-width: 1200px; margin: 20px auto; }
            .nss-header { background: #0073aa; color: #fff; padding: 16px 20px;
                          border-radius: 4px 4px 0 0; display: flex;
                          align-items: center; gap: 10px; }
            .nss-header h1 { color: #fff; margin: 0; font-size: 22px; }
            .nss-summary { display: flex; gap: 16px; margin: 16px 0; flex-wrap: wrap; }
            .nss-card { background: #fff; border: 1px solid #e0e0e0; border-radius: 6px;
                        padding: 16px 24px; flex: 1; min-width: 160px;
                        box-shadow: 0 1px 4px rgba(0,0,0,.06); text-align: center; }
            .nss-card-value { font-size: 32px; font-weight: 700; color: #0073aa; }
            .nss-card-label { font-size: 13px; color: #666; margin-top: 4px; }
            .nss-table-wrap { background: #fff; border: 1px solid #e0e0e0; border-radius: 0 0 4px 4px; }
            .nss-table { width: 100%; border-collapse: collapse; font-size: 14px; }
            .nss-table th { background: #f6f7f7; padding: 10px 14px; text-align: left;
                            border-bottom: 2px solid #e0e0e0; font-weight: 600; color: #444; }
            .nss-table td { padding: 10px 14px; border-bottom: 1px solid #f0f0f0; vertical-align: middle; }
            .nss-table tr:last-child td { border-bottom: none; }
            .nss-table tr:hover td { background: #f9f9f9; }
            .nss-badge { display: inline-block; padding: 2px 8px; border-radius: 12px;
                         font-size: 12px; font-weight: 600; }
            .nss-badge-active { background: #d4edda; color: #155724; }
            .nss-badge-inactive { background: #f8d7da; color: #721c24; }
            .nss-actions a { margin-right: 8px; text-decoration: none; font-size: 13px; }
            .nss-refresh { float: right; margin-top: -4px; }
            .nss-footer { margin-top: 12px; font-size: 12px; color: #999; text-align: right; }
        ';
    }

    /**
     * Thu thập và render toàn bộ trang thống kê.
     *
     * Đây là hàm trung tâm của plugin:
     * 1. Gọi get_sites() lấy danh sách site.
     * 2. Với mỗi site, dùng switch_to_blog() để chuyển ngữ cảnh
     *    và đọc dữ liệu (post count, bài mới nhất).
     * 3. Gọi restore_current_blog() để trả về site gốc.
     * 4. Render bảng HTML.
     */
    public function render_stats_page() {
        // Kiểm tra quyền truy cập
        if ( ! current_user_can( 'manage_network' ) ) {
            wp_die( __( 'Bạn không có quyền truy cập trang này.', 'network-site-stats' ) );
        }

        $stats = $this->collect_network_stats();
        $this->render_html( $stats );
    }

    /**
     * Thu thập thống kê từ tất cả site trong mạng lưới.
     *
     * @return array Mảng chứa ['summary'] và ['sites'] với dữ liệu từng site.
     */
    private function collect_network_stats() {
        /*
         * get_sites() — Lấy tất cả site trong Multisite Network.
         * Mặc định trả về tối đa 100 site. Có thể lọc theo:
         *   'number'     => số lượng tối đa
         *   'public'     => 1 chỉ lấy site công khai
         *   'archived'   => 0 bỏ qua site đã lưu trữ
         *   'deleted'    => 0 bỏ qua site đã xóa
         */
        $all_sites = get_sites( array(
            'number'   => 500,
            'deleted'  => 0,
            'archived' => 0,
        ) );

        $sites_data      = array();
        $total_posts     = 0;
        $total_active    = 0;

        foreach ( $all_sites as $site ) {
            $blog_id = (int) $site->blog_id;

            /*
             * switch_to_blog( $blog_id )
             * ─────────────────────────
             * Chuyển ngữ cảnh WordPress sang site con có ID = $blog_id.
             * Sau lệnh này, tất cả hàm như wp_count_posts(), get_option()
             * sẽ đọc dữ liệu của site con đó thay vì site hiện tại.
             *
             * QUAN TRỌNG: Luôn gọi restore_current_blog() sau khi xong.
             */
            switch_to_blog( $blog_id );

            // Đếm bài viết đã xuất bản của site con
            $post_counts = wp_count_posts( 'post' );
            $published   = isset( $post_counts->publish ) ? (int) $post_counts->publish : 0;

            // Lấy bài viết mới nhất
            $latest_posts = get_posts( array(
                'numberposts' => 1,
                'post_status' => 'publish',
                'orderby'     => 'date',
                'order'       => 'DESC',
            ) );
            $latest_date = '';
            if ( ! empty( $latest_posts ) ) {
                $latest_date = get_the_date( 'd/m/Y H:i', $latest_posts[0]->ID );
            }

            // Tên blog từ option 'blogname'
            $blog_name = get_option( 'blogname' );
            $site_url  = get_option( 'siteurl' );

            // Tính dung lượng upload của site (tùy chọn — sử dụng get_dirsize)
            $upload_dir  = wp_upload_dir();
            $upload_size = $this->get_dir_size_mb( $upload_dir['basedir'] );

            /*
             * restore_current_blog()
             * ──────────────────────
             * Khôi phục ngữ cảnh về site ban đầu (trước khi switch_to_blog).
             * Bắt buộc phải gọi để tránh lỗi dữ liệu sai trên các vòng lặp
             * tiếp theo hoặc các hàm WordPress sau này.
             */
            restore_current_blog();

            $is_active = ! (bool) $site->deleted && ! (bool) $site->archived;
            if ( $is_active ) {
                $total_active++;
            }
            $total_posts += $published;

            $sites_data[] = array(
                'id'          => $blog_id,
                'name'        => $blog_name ?: "(Site #{$blog_id})",
                'url'         => $site_url,
                'domain'      => $site->domain . $site->path,
                'post_count'  => $published,
                'latest_date' => $latest_date ?: '—',
                'upload_size' => $upload_size,
                'is_active'   => $is_active,
            );
        }

        return array(
            'summary' => array(
                'total_sites'  => count( $all_sites ),
                'active_sites' => $total_active,
                'total_posts'  => $total_posts,
                'generated_at' => current_time( 'd/m/Y H:i:s' ),
            ),
            'sites' => $sites_data,
        );
    }

    /**
     * Tính dung lượng thư mục (MB).
     *
     * @param string $path Đường dẫn thư mục.
     * @return string Dung lượng dạng "X.XX MB" hoặc "N/A".
     */
    private function get_dir_size_mb( $path ) {
        if ( ! is_dir( $path ) ) {
            return 'N/A';
        }
        // get_dirsize() là hàm WordPress, đọc đệ quy thư mục
        $size = get_dirsize( $path );
        if ( false === $size || $size === 0 ) {
            return '0 MB';
        }
        return round( $size / 1048576, 2 ) . ' MB';
    }

    /**
     * Render HTML cho trang thống kê.
     *
     * @param array $stats Dữ liệu đã thu thập từ collect_network_stats().
     */
    private function render_html( $stats ) {
        $s = $stats['summary'];
        ?>
        <div class="wrap nss-wrap">

            <!-- ===== HEADER ===== -->
            <div class="nss-header">
                <span class="dashicons dashicons-chart-bar" style="font-size:28px;width:28px;height:28px;"></span>
                <h1><?php _e( 'Network Site Stats', 'network-site-stats' ); ?></h1>
                <a href="<?php echo esc_url( add_query_arg( 'page', 'network-site-stats', network_admin_url( 'admin.php' ) ) ); ?>"
                   class="button button-secondary nss-refresh">
                    &#x21bb; <?php _e( 'Làm mới', 'network-site-stats' ); ?>
                </a>
            </div>

            <!-- ===== SUMMARY CARDS ===== -->
            <div class="nss-summary">
                <div class="nss-card">
                    <div class="nss-card-value"><?php echo esc_html( $s['total_sites'] ); ?></div>
                    <div class="nss-card-label"><?php _e( 'Tổng số Site', 'network-site-stats' ); ?></div>
                </div>
                <div class="nss-card">
                    <div class="nss-card-value"><?php echo esc_html( $s['active_sites'] ); ?></div>
                    <div class="nss-card-label"><?php _e( 'Site đang hoạt động', 'network-site-stats' ); ?></div>
                </div>
                <div class="nss-card">
                    <div class="nss-card-value"><?php echo esc_html( $s['total_posts'] ); ?></div>
                    <div class="nss-card-label"><?php _e( 'Tổng bài viết', 'network-site-stats' ); ?></div>
                </div>
            </div>

            <!-- ===== DATA TABLE ===== -->
            <div class="nss-table-wrap">
                <table class="nss-table">
                    <thead>
                        <tr>
                            <th><?php _e( 'ID', 'network-site-stats' ); ?></th>
                            <th><?php _e( 'Tên Site (Blog Name)', 'network-site-stats' ); ?></th>
                            <th><?php _e( 'Địa chỉ URL', 'network-site-stats' ); ?></th>
                            <th style="text-align:center"><?php _e( 'Số bài viết', 'network-site-stats' ); ?></th>
                            <th><?php _e( 'Bài mới nhất', 'network-site-stats' ); ?></th>
                            <th><?php _e( 'Dung lượng Upload', 'network-site-stats' ); ?></th>
                            <th style="text-align:center"><?php _e( 'Trạng thái', 'network-site-stats' ); ?></th>
                            <th><?php _e( 'Thao tác', 'network-site-stats' ); ?></th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ( $stats['sites'] as $site ) : ?>
                        <tr>
                            <td><strong><?php echo esc_html( $site['id'] ); ?></strong></td>
                            <td><?php echo esc_html( $site['name'] ); ?></td>
                            <td>
                                <a href="<?php echo esc_url( $site['url'] ); ?>" target="_blank">
                                    <?php echo esc_html( $site['domain'] ); ?>
                                </a>
                            </td>
                            <td style="text-align:center">
                                <strong><?php echo esc_html( $site['post_count'] ); ?></strong>
                            </td>
                            <td><?php echo esc_html( $site['latest_date'] ); ?></td>
                            <td><?php echo esc_html( $site['upload_size'] ); ?></td>
                            <td style="text-align:center">
                                <?php if ( $site['is_active'] ) : ?>
                                    <span class="nss-badge nss-badge-active">&#10003; Hoạt động</span>
                                <?php else : ?>
                                    <span class="nss-badge nss-badge-inactive">&#10007; Tạm dừng</span>
                                <?php endif; ?>
                            </td>
                            <td class="nss-actions">
                                <a href="<?php echo esc_url( get_admin_url( $site['id'], 'index.php' ) ); ?>">
                                    Dashboard
                                </a>
                                <a href="<?php echo esc_url( network_admin_url( 'site-info.php?id=' . $site['id'] ) ); ?>">
                                    Chỉnh sửa
                                </a>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>

            <!-- ===== FOOTER ===== -->
            <div class="nss-footer">
                <?php printf(
                    __( 'Cập nhật lúc: %s &mdash; Network Site Stats v1.0.0', 'network-site-stats' ),
                    esc_html( $s['generated_at'] )
                ); ?>
            </div>

        </div><!-- .nss-wrap -->
        <?php
    }
}

// Khởi tạo plugin (chỉ chạy trong môi trường Multisite)
if ( is_multisite() ) {
    new Network_Site_Stats();
}
