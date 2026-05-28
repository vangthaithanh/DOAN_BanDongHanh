import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/post_model.dart';

enum CheDoPostCard {
  trangChu,
  binhLuan,
}

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final CheDoPostCard cheDo;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onComment,
    this.onShare,
    this.cheDo = CheDoPostCard.trangChu,
  });

  static const Color mauXanh = Color(0xFF4AA8FF);
  static const Color mauVien = Color(0xFF2B2B2B);

  bool get _dangTrangBinhLuan {
    return cheDo == CheDoPostCard.binhLuan;
  }

  @override
  Widget build(BuildContext context) {
    final noiDung = Container(
      padding: EdgeInsets.fromLTRB(
        _dangTrangBinhLuan ? 30 : 12,
        _dangTrangBinhLuan ? 4 : 14,
        0,
        _dangTrangBinhLuan ? 10 : 14,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _dangTrangBinhLuan ? Colors.transparent : mauVien,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thongTinNguoiDang(),
          const SizedBox(height: 10),
          _caption(),
          const SizedBox(height: 10),
          _danhSachAnh(),
          const SizedBox(height: 8),
          _hangTuongTac(),
        ],
      ),
    );

    if (onTap == null) {
      return noiDung;
    }

    return InkWell(
      onTap: onTap,
      child: noiDung,
    );
  }

  Widget _thongTinNguoiDang() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 17,
          backgroundColor: mauXanh,
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    post.authorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '3 ngày',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              if (post.locationName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      color: Colors.white60,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        post.locationName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (post.nearText != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.tag,
                      color: Colors.white60,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        post.nearText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _caption() {
    return Padding(
      padding: const EdgeInsets.only(left: 63),
      child: Text(
        post.caption,
        style: TextStyle(
          color: Colors.white,
          fontSize: _dangTrangBinhLuan ? 14 : 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _danhSachAnh() {
    if (post.mediaUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: _dangTrangBinhLuan ? 135 : 270,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          left: 63,
          right: _dangTrangBinhLuan ? 18 : 16,
        ),
        itemCount: post.mediaUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(
              _dangTrangBinhLuan ? 8 : 12,
            ),
            child: SizedBox(
              width: _dangTrangBinhLuan ? 134 : 270,
              height: _dangTrangBinhLuan ? 135 : 270,
              child: Image.asset(
                post.mediaUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.image,
                      color: Colors.black54,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _hangTuongTac() {
    return Padding(
      padding: const EdgeInsets.only(left: 63),
      child: Row(
        children: [
          Icon(
            LucideIcons.heart,
            color: post.isLiked ? mauXanh : Colors.white,
            size: _dangTrangBinhLuan ? 23 : 21,
          ),
          const SizedBox(width: 7),
          Text(
            '${post.likeCount}',
            style: const TextStyle(
              color: mauXanh,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(width: 31),

          InkWell(
            onTap: onComment,
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.messageCircle,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 7),
                Text(
                  '${post.commentCount}',
                  style: const TextStyle(
                    color: mauXanh,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 31),

          InkWell(
            onTap: onShare,
            borderRadius: BorderRadius.circular(20),
            child: const Icon(
              LucideIcons.sendHorizontal,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}