import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiaDiemLichTrinh {
  final int id;
  final String ten;
  final String tinhThanh;
  final String? quanHuyen;
  final String? diaChi;
  final double viDo;
  final double kinhDo;
  final double diemTrungBinh;
  final int tongDanhGia;
  final String? imageUrl;

  const DiaDiemLichTrinh({
    required this.id,
    required this.ten,
    required this.tinhThanh,
    required this.quanHuyen,
    required this.diaChi,
    required this.viDo,
    required this.kinhDo,
    required this.diemTrungBinh,
    required this.tongDanhGia,
    this.imageUrl,
  });

  factory DiaDiemLichTrinh.fromMap(Map<String, dynamic> map) {
    return DiaDiemLichTrinh(
      id: _asInt(map['id']),
      ten: map['name']?.toString() ?? 'Địa điểm',
      tinhThanh: map['province']?.toString() ?? '',
      quanHuyen: map['district']?.toString(),
      diaChi: map['address']?.toString(),
      viDo: _asDouble(map['latitude']),
      kinhDo: _asDouble(map['longitude']),
      diemTrungBinh: _asDouble(map['avg_rating']),
      tongDanhGia: _asInt(map['total_reviews']),
      imageUrl: _firstImageUrl(map['place_media'], map['cover_image']),
    );
  }

  static String? _firstImageUrl(dynamic rawMedia, dynamic coverImage) {
    final coverUrl = coverImage?.toString().trim() ?? '';

    if (coverUrl.isNotEmpty) {
      return coverUrl;
    }

    if (rawMedia is! List || rawMedia.isEmpty) return null;

    for (final item in rawMedia) {
      if (item is! Map) continue;

      final mediaType = item['media_type']?.toString() ?? 'image';
      final url = item['url']?.toString() ?? '';

      if (mediaType == 'image' && url.trim().isNotEmpty) {
        return url;
      }
    }

    return null;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class LichTrinhItem {
  final int id;
  final int itineraryId;
  final int placeId;
  final int orderNo;
  final DateTime? plannedTime;
  final String note;
  final String status;
  final DateTime? actualStartTime;
  final double? gpsDistance;
  final bool gpsConfirmed;
  final DiaDiemLichTrinh? place;

  const LichTrinhItem({
    required this.id,
    required this.itineraryId,
    required this.placeId,
    required this.orderNo,
    required this.plannedTime,
    required this.note,
    required this.status,
    required this.actualStartTime,
    required this.gpsDistance,
    required this.gpsConfirmed,
    required this.place,
  });

  factory LichTrinhItem.fromMap(Map<String, dynamic> map) {
    final rawPlace = map['places'];
    final placeMap = rawPlace is Map
        ? Map<String, dynamic>.from(rawPlace)
        : null;

    return LichTrinhItem(
      id: _asInt(map['id']),
      itineraryId: _asInt(map['itinerary_id']),
      placeId: _asInt(map['place_id']),
      orderNo: _asInt(map['order_no']),
      plannedTime: _asDateTime(map['planned_time']),
      note: map['note']?.toString() ?? '',
      status: map['status']?.toString() ?? 'planned',
      actualStartTime: _asDateTime(map['actual_start_time']),
      gpsDistance: _asNullableDouble(map['gps_distance']),
      gpsConfirmed: map['gps_confirmed'] == true,
      place: placeMap == null ? null : DiaDiemLichTrinh.fromMap(placeMap),
    );
  }

  bool get daDen {
    return status == 'visited' || status == 'completed' || gpsConfirmed;
  }

  bool get daBoQua {
    return status == 'skipped';
  }

  String get tenDiaDiem {
    return place?.ten ?? 'Địa điểm';
  }

  String get thoiGianText {
    final time = plannedTime;
    if (time == null) return 'Chưa có thời gian';

    final d = time.toLocal();
    final gio = d.hour.toString().padLeft(2, '0');
    final phut = d.minute.toString().padLeft(2, '0');

    return 'Th${d.weekday + 1 > 8 ? 8 : d.weekday + 1} - ${d.day}/${d.month}, $gio:$phut';
  }

  String actionText({required bool itineraryPinned}) {
    if (!itineraryPinned) return '';

    if (daDen) return 'Đánh giá';
    if (daBoQua) return 'Đặt lại';
    return 'Xem điểm đến';
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _asDateTime(dynamic value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class LichTrinh {
  final int id;
  final String profileId;
  final String name;
  final String description;
  final String? province;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final bool pinned;
  final DateTime? actualStartTime;
  final List<LichTrinhItem> items;

  const LichTrinh({
    required this.id,
    required this.profileId,
    required this.name,
    required this.description,
    required this.province,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.pinned,
    required this.actualStartTime,
    required this.items,
  });

  factory LichTrinh.fromMap(
      Map<String, dynamic> map, {
        List<LichTrinhItem> items = const [],
      }) {
    return LichTrinh(
      id: _asInt(map['id']),
      profileId: map['profile_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Plan',
      description: map['description']?.toString() ?? '',
      province: map['province']?.toString(),
      startDate: _asDate(map['planned_start_date']),
      endDate: _asDate(map['planned_end_date']),
      status: map['status']?.toString() ?? 'draft',
      pinned: map['pinned'] == true,
      actualStartTime: _asDateTime(map['actual_start_time']),
      items: items,
    );
  }

  String get ngayText {
    if (startDate == null && endDate == null) return 'Từ ngày.. đến ngày ....';

    final start = startDate == null
        ? '...'
        : '${startDate!.day}/${startDate!.month}/${startDate!.year}';
    final end = endDate == null
        ? '...'
        : '${endDate!.day}/${endDate!.month}/${endDate!.year}';

    return 'Từ $start đến $end';
  }

  String get routeText {
    if (items.isEmpty) {
      return description.trim().isEmpty ? 'Chưa có điểm đến' : description;
    }

    final names = items
        .take(3)
        .map((item) => item.tenDiaDiem)
        .where((name) => name.trim().isNotEmpty)
        .toList();

    if (names.isEmpty) return 'Chưa có điểm đến';
    return names.join(' - ');
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _asDate(dynamic value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static DateTime? _asDateTime(dynamic value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }
}

class LichTrinhDraftItem {
  final int placeId;
  final DateTime plannedTime;
  final String note;

  const LichTrinhDraftItem({
    required this.placeId,
    required this.plannedTime,
    this.note = '',
  });
}

class LichTrinhService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get _user => _client.auth.currentUser;

  Future<List<LichTrinh>> layLichTrinhCuaToi() async {
    final user = _user;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để xem lịch trình.');
    }

    final rows = await _client
        .from('itineraries')
        .select()
        .eq('profile_id', user.id)
        .order('pinned', ascending: false)
        .order('created_at', ascending: false);

    final result = <LichTrinh>[];

    for (final raw in rows as List) {
      final map = Map<String, dynamic>.from(raw as Map);
      final id = _asInt(map['id']);
      final items = await layDiaDiemTrongLichTrinh(id);
      result.add(LichTrinh.fromMap(map, items: items));
    }

    return result;
  }

  Future<LichTrinh?> layChiTietLichTrinh(int itineraryId) async {
    final user = _user;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để xem lịch trình.');
    }

    final row = await _client
        .from('itineraries')
        .select()
        .eq('id', itineraryId)
        .eq('profile_id', user.id)
        .maybeSingle();

    if (row == null) return null;

    final items = await layDiaDiemTrongLichTrinh(itineraryId);

    return LichTrinh.fromMap(Map<String, dynamic>.from(row), items: items);
  }

  Future<List<LichTrinhItem>> layDiaDiemTrongLichTrinh(
      int itineraryId,
      ) async {
    final rows = await _client
        .from('itinerary_items')
        .select('''
      id,
      itinerary_id,
      place_id,
      order_no,
      planned_time,
      note,
      status,
      actual_start_time,
      gps_distance,
      gps_confirmed,
      places (
        id,
        name,
        province,
        district,
        address,
        latitude,
        longitude,
        cover_image,
        avg_rating,
        total_reviews,
        status,
        place_media (
          id,
          media_type,
          url
        )
      )
    ''')
        .eq('itinerary_id', itineraryId)
        .order('order_no', ascending: true);

    return List<Map<String, dynamic>>.from(rows)
        .map(LichTrinhItem.fromMap)
        .toList();
  }

  Future<List<DiaDiemLichTrinh>> layDiaDiemDeChon({
    String keyword = '',
  }) async {
    var query = _client
        .from('places')
        .select('''
      id,
      name,
      province,
      district,
      address,
      latitude,
      longitude,
      cover_image,
      avg_rating,
      total_reviews,
      status,
      place_media (
        id,
        media_type,
        url
      )
    ''')
        .eq('status', 'active');

    final userId = _user?.id;

    query = userId == null
        ? query.filter('user_id', 'is', null)
        : query.or('user_id.is.null,user_id.eq.$userId');

    final cleanKeyword = keyword.trim();

    if (cleanKeyword.isNotEmpty) {
      query = query.or(
        'name.ilike.%$cleanKeyword%,province.ilike.%$cleanKeyword%,district.ilike.%$cleanKeyword%,address.ilike.%$cleanKeyword%',
      );
    }

    final rows = await query.order('name', ascending: true).limit(50);

    return List<Map<String, dynamic>>.from(rows)
        .map(DiaDiemLichTrinh.fromMap)
        .toList();
  }

  Future<int> taoLichTrinh({
    required String name,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
    bool pinned = false,
    required List<LichTrinhDraftItem> items,
  }) async {
    final user = _user;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để tạo lịch trình.');
    }

    if (name.trim().isEmpty) {
      throw Exception('Vui lòng nhập tên lịch trình.');
    }

    if (items.isEmpty) {
      throw Exception('Vui lòng thêm ít nhất một địa điểm.');
    }

    if (pinned) {
      await _boGhimTatCa(user.id);
    }

    final firstProvince = await _layTinhThanhDauTien(items.first.placeId);

    final planRow = await _client
        .from('itineraries')
        .insert({
      'profile_id': user.id,
      'name': name.trim(),
      'description': description.trim(),
      'province': firstProvince,
      'planned_start_date': _dateOnly(startDate),
      'planned_end_date': _dateOnly(endDate),
      'status': pinned ? 'active' : 'draft',
      'pinned': pinned,
      'actual_start_time': pinned ? DateTime.now().toIso8601String() : null,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .select('id')
        .single();

    final itineraryId = _asInt(planRow['id']);

    await _themItemsVaNhacNho(itineraryId: itineraryId, items: items);

    return itineraryId;
  }

  Future<void> capNhatLichTrinh({
    required int itineraryId,
    required String name,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
    bool pinned = false,
    required List<LichTrinhDraftItem> items,
  }) async {
    final user = _user;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để sửa lịch trình.');
    }

    if (name.trim().isEmpty) {
      throw Exception('Vui lòng nhập tên lịch trình.');
    }

    if (items.isEmpty) {
      throw Exception('Vui lòng thêm ít nhất một địa điểm.');
    }

    if (pinned) {
      await _boGhimTatCa(user.id);
    }

    final oldItems = await _client
        .from('itinerary_items')
        .select('id')
        .eq('itinerary_id', itineraryId);

    final oldItemIds = List<Map<String, dynamic>>.from(oldItems)
        .map((row) => _asInt(row['id']))
        .where((id) => id > 0)
        .toList();

    if (oldItemIds.isNotEmpty) {
      await _client
          .from('itinerary_reminders')
          .delete()
          .inFilter('itinerary_item_id', oldItemIds);

      await _client
          .from('place_visits')
          .delete()
          .inFilter('itinerary_item_id', oldItemIds);
    }

    await _client
        .from('itinerary_items')
        .delete()
        .eq('itinerary_id', itineraryId);

    final firstProvince = await _layTinhThanhDauTien(items.first.placeId);

    await _client
        .from('itineraries')
        .update({
      'name': name.trim(),
      'description': description.trim(),
      'province': firstProvince,
      'planned_start_date': _dateOnly(startDate),
      'planned_end_date': _dateOnly(endDate),
      'status': pinned ? 'active' : 'draft',
      'pinned': pinned,
      'actual_start_time': pinned ? DateTime.now().toIso8601String() : null,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', itineraryId)
        .eq('profile_id', user.id);

    await _themItemsVaNhacNho(itineraryId: itineraryId, items: items);
  }

  Future<void> doiTrangThaiGhim({
    required int itineraryId,
    required bool pinned,
  }) async {
    final user = _user;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để ghim lịch trình.');
    }

    if (pinned) {
      await _boGhimTatCa(user.id);
    }

    await _client
        .from('itineraries')
        .update({
      'pinned': pinned,
      'status': pinned ? 'active' : 'draft',
      'actual_start_time': pinned ? DateTime.now().toIso8601String() : null,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', itineraryId)
        .eq('profile_id', user.id);
  }

  Future<void> danhDauBoQua(int itemId) async {
    await _client
        .from('itinerary_items')
        .update({
      'status': 'skipped',
      'gps_confirmed': false,
    })
        .eq('id', itemId);
  }

  Future<void> danhDauDaDenBangGps({
    required int itemId,
    required double distance,
  }) async {
    await _client
        .from('itinerary_items')
        .update({
      'status': 'visited',
      'gps_confirmed': true,
      'gps_distance': distance,
      'actual_start_time': DateTime.now().toIso8601String(),
    })
        .eq('id', itemId);

    await _client.from('place_visits').insert({
      'itinerary_item_id': itemId,
      'detected_at': DateTime.now().toIso8601String(),
      'detection_method': 'gps',
      'confidence': _confidenceFromDistance(distance),
      'status': 'detected',
    });
  }

  Future<void> xoaLichTrinh(int itineraryId) async {
    final user = _user;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để xóa lịch trình.');
    }

    await _client
        .from('itineraries')
        .delete()
        .eq('id', itineraryId)
        .eq('profile_id', user.id);
  }

  Future<void> kiemTraLichTrinhDangGhimBangGps() async {
    final user = _user;
    if (user == null) return;

    final pinnedRow = await _client
        .from('itineraries')
        .select('id')
        .eq('profile_id', user.id)
        .eq('pinned', true)
        .maybeSingle();

    if (pinnedRow == null) return;

    final itineraryId = _asInt(pinnedRow['id']);
    if (itineraryId <= 0) return;

    await _guiNhacNhoNeuDenGio(user.id);

    final position = await _layViTriHienTai();
    if (position == null) return;

    final items = await layDiaDiemTrongLichTrinh(itineraryId);
    final now = DateTime.now();

    for (final item in items) {
      if (item.daDen || item.daBoQua || item.place == null) continue;

      final plannedTime = item.plannedTime;
      if (plannedTime != null) {
        final diff = plannedTime.difference(now).inHours;
        if (diff > 24 || diff < -6) {
          continue;
        }
      }

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        item.place!.viDo,
        item.place!.kinhDo,
      );

      if (distance <= 250) {
        await danhDauDaDenBangGps(itemId: item.id, distance: distance);
      }
    }
  }

  Future<void> _guiNhacNhoNeuDenGio(String userId) async {
    final now = DateTime.now();

    final rows = await _client
        .from('itinerary_reminders')
        .select('''
          id,
          itinerary_item_id,
          remind_time,
          title,
          content,
          status,
          itinerary_items (
            id,
            place_id,
            itinerary_id,
            planned_time,
            itineraries (
              id,
              profile_id,
              pinned
            )
          )
        ''')
        .eq('status', 'pending')
        .lte('remind_time', now.toIso8601String())
        .limit(20);

    for (final raw in rows as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final item = row['itinerary_items'];

      if (item is! Map) continue;

      final itemMap = Map<String, dynamic>.from(item);
      final itinerary = itemMap['itineraries'];

      if (itinerary is! Map) continue;

      final itineraryMap = Map<String, dynamic>.from(itinerary);
      final ownerId = itineraryMap['profile_id']?.toString() ?? '';
      final pinned = itineraryMap['pinned'] == true;

      if (ownerId != userId || !pinned) continue;

      await _client.from('notifications').insert({
        'profile_id': userId,
        'notification_type': 'itinerary_reminder',
        'title': row['title']?.toString() ?? 'Nhắc lịch trình',
        'content': row['content']?.toString() ?? 'Sắp đến giờ đi địa điểm trong lịch trình.',
        'place_id': itemMap['place_id'],
        'is_read': false,
      });

      await _client
          .from('itinerary_reminders')
          .update({'status': 'sent'})
          .eq('id', _asInt(row['id']));
    }
  }

  Future<Position?> _layViTriHienTai() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _themItemsVaNhacNho({
    required int itineraryId,
    required List<LichTrinhDraftItem> items,
  }) async {
    final sortedItems = List<LichTrinhDraftItem>.from(items)
      ..sort((a, b) => a.plannedTime.compareTo(b.plannedTime));

    final itemRows = <Map<String, dynamic>>[];

    for (var i = 0; i < sortedItems.length; i++) {
      final item = sortedItems[i];

      itemRows.add({
        'itinerary_id': itineraryId,
        'place_id': item.placeId,
        'order_no': i + 1,
        'planned_time': item.plannedTime.toIso8601String(),
        'note': item.note.trim(),
        'status': 'planned',
        'gps_confirmed': false,
      });
    }

    final insertedItems = await _client
        .from('itinerary_items')
        .insert(itemRows)
        .select('id, place_id, planned_time, places(name)');

    final reminderRows = <Map<String, dynamic>>[];

    for (final raw in insertedItems as List) {
      final item = Map<String, dynamic>.from(raw as Map);
      final plannedTime = DateTime.tryParse(
        item['planned_time']?.toString() ?? '',
      );

      if (plannedTime == null) continue;

      final place = item['places'];
      final placeName = place is Map
          ? place['name']?.toString() ?? 'địa điểm'
          : 'địa điểm';

      reminderRows.add({
        'itinerary_item_id': _asInt(item['id']),
        'remind_time': plannedTime.subtract(const Duration(minutes: 45)).toIso8601String(),
        'remind_before_minutes': 45,
        'title': 'Sắp đến giờ đi $placeName',
        'content': 'GoMate nhắc bạn chuẩn bị di chuyển đến $placeName trong lịch trình đã ghim.',
        'status': 'pending',
      });
    }

    if (reminderRows.isNotEmpty) {
      await _client.from('itinerary_reminders').insert(reminderRows);
    }
  }

  Future<void> _boGhimTatCa(String profileId) async {
    await _client
        .from('itineraries')
        .update({
      'pinned': false,
      'status': 'draft',
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('profile_id', profileId)
        .eq('pinned', true);
  }

  Future<String?> _layTinhThanhDauTien(int placeId) async {
    final row = await _client
        .from('places')
        .select('province')
        .eq('id', placeId)
        .maybeSingle();

    return row?['province']?.toString();
  }

  double _confidenceFromDistance(double distance) {
    final score = 1 - math.min(distance, 250) / 250;
    return double.parse(score.toStringAsFixed(2));
  }

  String? _dateOnly(DateTime? date) {
    if (date == null) return null;

    final d = date.toLocal();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');

    return '${d.year}-$month-$day';
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
