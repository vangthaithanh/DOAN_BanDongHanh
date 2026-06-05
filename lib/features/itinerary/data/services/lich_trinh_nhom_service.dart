import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'lich_trinh_service.dart';

const double kTripGroupCheckRadiusM = 300;
const Duration kTripGroupLocationStaleAfter = Duration(minutes: 30);

class TripGroupFriend {
  final String id;
  final String name;
  final String? username;
  final String? avatarUrl;

  const TripGroupFriend({
    required this.id,
    required this.name,
    this.username,
    this.avatarUrl,
  });

  factory TripGroupFriend.fromMap(Map<String, dynamic> map) {
    return TripGroupFriend(
      id: map['id']?.toString() ?? '',
      name: _profileDisplayName(map),
      username: _emptyToNull(map['nickname'] ?? map['username']),
      avatarUrl: _emptyToNull(map['avatar_url']),
    );
  }
}

class TripGroup {
  final int id;
  final String ownerId;
  final String title;
  final String description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final DateTime? createdAt;
  final int memberCount;
  final int stopCount;

  const TripGroup({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.memberCount,
    required this.stopCount,
  });

  factory TripGroup.fromMap(
    Map<String, dynamic> map, {
    int memberCount = 0,
    int stopCount = 0,
  }) {
    final members = map['trip_members'];
    final stops = map['trip_stops'];

    return TripGroup(
      id: _asInt(map['id']),
      ownerId: map['owner_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Lịch trình nhóm',
      description: map['description']?.toString() ?? '',
      startDate: _asDate(map['start_date']),
      endDate: _asDate(map['end_date']),
      status: map['status']?.toString() ?? 'active',
      createdAt: _asDateTime(map['created_at']),
      memberCount: members is List
          ? members
                .where(
                  (item) =>
                      item is Map &&
                      (item['status']?.toString() ?? '') != 'removed',
                )
                .length
          : memberCount,
      stopCount: stops is List
          ? stops
                .where(
                  (item) =>
                      item is Map &&
                      (item['status']?.toString() ?? '') != 'deleted',
                )
                .length
          : stopCount,
    );
  }

  String get dateText {
    if (startDate == null && endDate == null) return 'Chưa đặt ngày';

    final start = startDate == null
        ? '...'
        : '${startDate!.day}/${startDate!.month}/${startDate!.year}';
    final end = endDate == null
        ? '...'
        : '${endDate!.day}/${endDate!.month}/${endDate!.year}';

    return '$start - $end';
  }
}

class TripMember {
  final int id;
  final int tripId;
  final String userId;
  final String role;
  final String status;
  final String name;
  final String? avatarUrl;

  const TripMember({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.role,
    required this.status,
    required this.name,
    this.avatarUrl,
  });

  factory TripMember.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] is Map
        ? Map<String, dynamic>.from(map['profiles'] as Map)
        : <String, dynamic>{};

    return TripMember(
      id: _asInt(map['id']),
      tripId: _asInt(map['trip_id']),
      userId: map['user_id']?.toString() ?? '',
      role: map['role']?.toString() ?? 'member',
      status: map['status']?.toString() ?? 'active',
      name: profile.isEmpty ? 'Thành viên' : _profileDisplayName(profile),
      avatarUrl: _emptyToNull(profile['avatar_url']),
    );
  }

  TripMember copyWithProfile(Map<String, dynamic> profile) {
    return TripMember(
      id: id,
      tripId: tripId,
      userId: userId,
      role: role,
      status: status,
      name: _profileDisplayName(profile),
      avatarUrl: _emptyToNull(profile['avatar_url']),
    );
  }

  bool get isOwner => role == 'owner';
}

class TripStop {
  final int id;
  final int tripId;
  final int? placeId;
  final String title;
  final String note;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime arriveAt;
  final int checkRadiusM;
  final int sortOrder;
  final String status;

  const TripStop({
    required this.id,
    required this.tripId,
    required this.placeId,
    required this.title,
    required this.note,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.arriveAt,
    required this.checkRadiusM,
    required this.sortOrder,
    required this.status,
  });

  factory TripStop.fromMap(Map<String, dynamic> map) {
    return TripStop(
      id: _asInt(map['id']),
      tripId: _asInt(map['trip_id']),
      placeId: _asNullableInt(map['place_id']),
      title: map['title']?.toString() ?? 'Địa điểm',
      note: map['note']?.toString() ?? '',
      latitude: _asDouble(map['latitude']),
      longitude: _asDouble(map['longitude']),
      address: map['address']?.toString() ?? '',
      arriveAt: _asDateTime(map['arrive_at']) ?? DateTime.now(),
      checkRadiusM: _asInt(map['check_radius_m'], fallback: 300),
      sortOrder: _asInt(map['sort_order']),
      status: map['status']?.toString() ?? 'active',
    );
  }

  String get timeText {
    final local = arriveAt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '${local.day}/${local.month}/${local.year} $hour:$minute';
  }
}

class TripMemberLocation {
  final String userId;
  final double latitude;
  final double longitude;
  final double? accuracyM;
  final DateTime updatedAt;

  const TripMemberLocation({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.updatedAt,
  });

  factory TripMemberLocation.fromMap(Map<String, dynamic> map) {
    return TripMemberLocation(
      userId: map['user_id']?.toString() ?? '',
      latitude: _asDouble(map['latitude']),
      longitude: _asDouble(map['longitude']),
      accuracyM: _asNullableDouble(map['accuracy_m']),
      updatedAt: _asDateTime(map['updated_at']) ?? DateTime.now(),
    );
  }

  bool get isStale {
    return DateTime.now().difference(updatedAt.toLocal()) >
        kTripGroupLocationStaleAfter;
  }

  String get updatedText {
    final diff = DateTime.now().difference(updatedAt.toLocal());

    if (diff.inMinutes < 1) return 'Vừa cập nhật';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }
}

class TripStopCheckin {
  final int id;
  final int tripStopId;
  final int tripId;
  final String userId;
  final double? distanceM;
  final bool isArrived;
  final DateTime? checkedAt;
  final String status;

  const TripStopCheckin({
    required this.id,
    required this.tripStopId,
    required this.tripId,
    required this.userId,
    required this.distanceM,
    required this.isArrived,
    required this.checkedAt,
    required this.status,
  });

  factory TripStopCheckin.fromMap(Map<String, dynamic> map) {
    return TripStopCheckin(
      id: _asInt(map['id']),
      tripStopId: _asInt(map['trip_stop_id']),
      tripId: _asInt(map['trip_id']),
      userId: map['user_id']?.toString() ?? '',
      distanceM: _asNullableDouble(map['distance_m']),
      isArrived: map['is_arrived'] == true,
      checkedAt: _asDateTime(map['checked_at']),
      status: map['status']?.toString() ?? 'checked',
    );
  }
}

class TripGroupDetail {
  final TripGroup group;
  final List<TripMember> members;
  final List<TripStop> stops;
  final List<TripStopCheckin> checkins;
  final Map<String, TripMemberLocation> locations;

  const TripGroupDetail({
    required this.group,
    required this.members,
    required this.stops,
    required this.checkins,
    required this.locations,
  });

  List<TripStopCheckin> checkinsForStop(int stopId) {
    return checkins.where((item) => item.tripStopId == stopId).toList();
  }
}

class TripStopMemberStatus {
  final TripMember member;
  final String status;
  final bool isArrived;
  final double? distanceM;
  final TripMemberLocation? location;

  const TripStopMemberStatus({
    required this.member,
    required this.status,
    required this.isArrived,
    required this.distanceM,
    required this.location,
  });

  String get statusText {
    switch (status) {
      case 'arrived':
        return 'Đã tới';
      case 'not_arrived':
        return distanceM == null ? 'Chưa tới' : 'Cách ${distanceM!.round()}m';
      case 'stale_location':
        return 'Vị trí quá cũ';
      case 'no_location':
        return 'Chưa có vị trí';
      default:
        return 'Chưa kiểm tra';
    }
  }
}

class TripStopCheckResult {
  final TripStop stop;
  final List<TripStopMemberStatus> members;

  const TripStopCheckResult({required this.stop, required this.members});

  List<TripStopMemberStatus> get arrived =>
      members.where((item) => item.status == 'arrived').toList();

  List<TripStopMemberStatus> get notArrived =>
      members.where((item) => item.status == 'not_arrived').toList();

  List<TripStopMemberStatus> get noLocation => members
      .where(
        (item) =>
            item.status == 'no_location' || item.status == 'stale_location',
      )
      .toList();
}

class TripGroupDraftStop {
  final DiaDiemLichTrinh place;
  final DateTime arriveAt;
  final String note;

  const TripGroupDraftStop({
    required this.place,
    required this.arriveAt,
    this.note = '',
  });
}

class LichTrinhNhomService {
  final SupabaseClient _client = Supabase.instance.client;
  final LichTrinhService _placeService = LichTrinhService();

  User? get _user => _client.auth.currentUser;

  String? get currentUserId => _user?.id;

  Future<List<TripGroup>> layDanhSachLichTrinhCuaToi() async {
    final user = _user;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để xem lịch trình nhóm.');
    }

    final memberRows = await _client
        .from('trip_members')
        .select('trip_id')
        .eq('user_id', user.id)
        .eq('status', 'active');

    final tripIds = List<Map<String, dynamic>>.from(memberRows)
        .map((row) => _asInt(row['trip_id']))
        .where((id) => id > 0)
        .toSet()
        .toList();

    if (tripIds.isEmpty) return [];

    final rows = await _client
        .from('trip_groups')
        .select('''
          id,
          owner_id,
          title,
          description,
          start_date,
          end_date,
          status,
          created_at,
          trip_members(id, status),
          trip_stops(id, status)
        ''')
        .inFilter('id', tripIds)
        .neq('status', 'deleted')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(
      rows,
    ).map(TripGroup.fromMap).toList();
  }

  Future<TripGroupDetail> layChiTietLichTrinhNhom(int tripId) async {
    final groupRow = await _client
        .from('trip_groups')
        .select('''
          id,
          owner_id,
          title,
          description,
          start_date,
          end_date,
          status,
          created_at
        ''')
        .eq('id', tripId)
        .maybeSingle();

    if (groupRow == null) {
      throw Exception('Không tìm thấy lịch trình nhóm.');
    }

    final members = await _layThanhVien(tripId);
    final stops = await _layDiemDung(tripId);
    final checkins = await _layCheckins(tripId);
    final locations = await layViTriThanhVien(
      members.map((item) => item.userId).where((id) => id.isNotEmpty).toList(),
    );

    return TripGroupDetail(
      group: TripGroup.fromMap(
        Map<String, dynamic>.from(groupRow),
        memberCount: members.length,
        stopCount: stops.length,
      ),
      members: members,
      stops: stops,
      checkins: checkins,
      locations: locations,
    );
  }

  Future<List<TripGroupFriend>> layDanhSachBanBe() async {
    final user = _user;
    if (user == null) return [];

    List<dynamic> followRows;

    try {
      followRows = await _client
          .from('follows')
          .select('follower_id, following_id, status')
          .or('follower_id.eq.${user.id},following_id.eq.${user.id}')
          .eq('status', 'active');
    } catch (_) {
      followRows = await _client
          .from('follows')
          .select('follower_id, following_id')
          .or('follower_id.eq.${user.id},following_id.eq.${user.id}');
    }

    final following = <String>{};
    final followers = <String>{};

    for (final raw in followRows) {
      if (raw is! Map) continue;

      final row = Map<String, dynamic>.from(raw);
      final followerId = row['follower_id']?.toString();
      final followingId = row['following_id']?.toString();

      if (followerId == user.id && followingId != null) {
        following.add(followingId);
      }

      if (followingId == user.id && followerId != null) {
        followers.add(followerId);
      }
    }

    final friendIds = following.intersection(followers).toList();
    if (friendIds.isEmpty) return [];

    final profileRows = await _client
        .from('profiles')
        .select('id, nickname, full_name, email, avatar_url')
        .inFilter('id', friendIds);

    return List<Map<String, dynamic>>.from(profileRows)
        .map(TripGroupFriend.fromMap)
        .where((item) => item.id.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<DiaDiemLichTrinh>> layDiaDiemDeChon({String keyword = ''}) {
    return _placeService.layDiaDiemDeChon(keyword: keyword);
  }

  Future<int> taoLichTrinhNhom({
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
    required List<String> memberIds,
    required List<TripGroupDraftStop> stops,
  }) async {
    final user = _user;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để tạo lịch trình nhóm.');
    }

    _validateDraft(title: title, stops: stops);

    final groupRow = await _client
        .from('trip_groups')
        .insert({
          'owner_id': user.id,
          'title': title.trim(),
          'description': description.trim(),
          'start_date': _dateOnly(startDate),
          'end_date': _dateOnly(endDate),
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    final tripId = _asInt(groupRow['id']);

    await _upsertMembers(
      tripId: tripId,
      ownerId: user.id,
      memberIds: memberIds,
    );
    await _insertStops(tripId: tripId, stops: stops);

    return tripId;
  }

  Future<void> capNhatLichTrinhNhom({
    required int tripId,
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
    required List<String> memberIds,
    required List<TripGroupDraftStop> stops,
  }) async {
    final user = _user;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để sửa lịch trình nhóm.');
    }

    _validateDraft(title: title, stops: stops);

    await _client
        .from('trip_groups')
        .update({
          'title': title.trim(),
          'description': description.trim(),
          'start_date': _dateOnly(startDate),
          'end_date': _dateOnly(endDate),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', tripId)
        .eq('owner_id', user.id);

    await _client
        .from('trip_members')
        .delete()
        .eq('trip_id', tripId)
        .neq('role', 'owner');

    await _client.from('trip_stops').delete().eq('trip_id', tripId);

    await _upsertMembers(
      tripId: tripId,
      ownerId: user.id,
      memberIds: memberIds,
    );
    await _insertStops(tripId: tripId, stops: stops);
  }

  Future<void> xoaLichTrinhNhom(int tripId) async {
    final user = _user;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để xóa lịch trình nhóm.');
    }

    await _client
        .from('trip_groups')
        .delete()
        .eq('id', tripId)
        .eq('owner_id', user.id);
  }

  Future<Position?> capNhatViTriHienTai({bool silent = false}) async {
    final user = _user;
    if (user == null) {
      if (silent) return null;
      throw Exception('Bạn cần đăng nhập để cập nhật vị trí.');
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (silent) return null;
      throw Exception('Bạn cần bật GPS để cập nhật vị trí.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (silent) return null;
      throw Exception('Bạn chưa cấp quyền vị trí.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    await _client.from('user_location_snapshots').upsert({
      'user_id': user.id,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy_m': position.accuracy,
      'source': 'gps',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');

    return position;
  }

  Future<Map<String, TripMemberLocation>> layViTriThanhVien(
    List<String> userIds,
  ) async {
    final cleanIds = userIds
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();

    if (cleanIds.isEmpty) return {};

    final rows = await _client
        .from('user_location_snapshots')
        .select('user_id, latitude, longitude, accuracy_m, updated_at')
        .inFilter('user_id', cleanIds);

    return {
      for (final location in List<Map<String, dynamic>>.from(
        rows,
      ).map(TripMemberLocation.fromMap))
        if (location.userId.isNotEmpty) location.userId: location,
    };
  }

  Future<TripStopCheckResult> kiemTraDiemDung(int tripStopId) async {
    await capNhatViTriHienTai(silent: true);

    final stopRow = await _client
        .from('trip_stops')
        .select()
        .eq('id', tripStopId)
        .maybeSingle();

    if (stopRow == null) {
      throw Exception('Không tìm thấy điểm dừng.');
    }

    final stop = TripStop.fromMap(Map<String, dynamic>.from(stopRow));
    final members = await _layThanhVien(stop.tripId);
    final locations = await layViTriThanhVien(
      members.map((item) => item.userId).toList(),
    );
    final distance = const Distance();
    final now = DateTime.now();
    final statuses = <TripStopMemberStatus>[];
    final checkinRows = <Map<String, dynamic>>[];

    for (final member in members) {
      final location = locations[member.userId];
      double? distanceM;
      var status = 'no_location';
      var isArrived = false;

      if (location != null) {
        if (now.difference(location.updatedAt.toLocal()) >
            kTripGroupLocationStaleAfter) {
          status = 'stale_location';
        } else {
          distanceM = distance.as(
            LengthUnit.Meter,
            LatLng(location.latitude, location.longitude),
            LatLng(stop.latitude, stop.longitude),
          );
          isArrived = distanceM <= kTripGroupCheckRadiusM;
          status = isArrived ? 'arrived' : 'not_arrived';
        }
      }

      checkinRows.add({
        'trip_stop_id': stop.id,
        'trip_id': stop.tripId,
        'user_id': member.userId,
        'distance_m': distanceM,
        'is_arrived': isArrived,
        'location_latitude': location?.latitude,
        'location_longitude': location?.longitude,
        'checked_at': now.toIso8601String(),
        'status': status,
      });

      statuses.add(
        TripStopMemberStatus(
          member: member,
          status: status,
          isArrived: isArrived,
          distanceM: distanceM,
          location: location,
        ),
      );
    }

    if (checkinRows.isNotEmpty) {
      await _client
          .from('trip_stop_checkins')
          .upsert(checkinRows, onConflict: 'trip_stop_id,user_id');
    }

    return TripStopCheckResult(stop: stop, members: statuses);
  }

  Future<List<TripMember>> _layThanhVien(int tripId) async {
    try {
      final rows = await _client
          .from('trip_members')
          .select('''
            id,
            trip_id,
            user_id,
            role,
            status,
            profiles(id, nickname, full_name, email, avatar_url)
          ''')
          .eq('trip_id', tripId)
          .eq('status', 'active')
          .order('role', ascending: false)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(
        rows,
      ).map(TripMember.fromMap).toList();
    } catch (_) {
      final rows = await _client
          .from('trip_members')
          .select('id, trip_id, user_id, role, status, created_at')
          .eq('trip_id', tripId)
          .eq('status', 'active')
          .order('role', ascending: false)
          .order('created_at', ascending: true);

      final members = List<Map<String, dynamic>>.from(
        rows,
      ).map(TripMember.fromMap).toList();
      final userIds = members.map((item) => item.userId).toSet().toList();

      if (userIds.isEmpty) return members;

      final profiles = await _client
          .from('profiles')
          .select('id, nickname, full_name, email, avatar_url')
          .inFilter('id', userIds);
      final profileMap = {
        for (final raw in List<Map<String, dynamic>>.from(profiles))
          raw['id']?.toString() ?? '': raw,
      };

      return members
          .map(
            (member) => profileMap[member.userId] == null
                ? member
                : member.copyWithProfile(profileMap[member.userId]!),
          )
          .toList();
    }
  }

  Future<List<TripStop>> _layDiemDung(int tripId) async {
    final rows = await _client
        .from('trip_stops')
        .select()
        .eq('trip_id', tripId)
        .neq('status', 'deleted')
        .order('sort_order', ascending: true)
        .order('arrive_at', ascending: true);

    return List<Map<String, dynamic>>.from(rows).map(TripStop.fromMap).toList();
  }

  Future<List<TripStopCheckin>> _layCheckins(int tripId) async {
    final rows = await _client
        .from('trip_stop_checkins')
        .select()
        .eq('trip_id', tripId)
        .order('checked_at', ascending: false);

    return List<Map<String, dynamic>>.from(
      rows,
    ).map(TripStopCheckin.fromMap).toList();
  }

  Future<void> _upsertMembers({
    required int tripId,
    required String ownerId,
    required List<String> memberIds,
  }) async {
    final ids = <String>{
      ownerId,
      ...memberIds,
    }.where((id) => id.trim().isNotEmpty).toList();

    final rows = ids.map((id) {
      final isOwner = id == ownerId;

      return {
        'trip_id': tripId,
        'user_id': id,
        'role': isOwner ? 'owner' : 'member',
        'status': 'active',
      };
    }).toList();

    if (rows.isEmpty) return;

    await _client
        .from('trip_members')
        .upsert(rows, onConflict: 'trip_id,user_id');
  }

  Future<void> _insertStops({
    required int tripId,
    required List<TripGroupDraftStop> stops,
  }) async {
    final sortedStops = List<TripGroupDraftStop>.from(stops)
      ..sort((a, b) => a.arriveAt.compareTo(b.arriveAt));

    final rows = <Map<String, dynamic>>[];

    for (var index = 0; index < sortedStops.length; index++) {
      final stop = sortedStops[index];

      rows.add({
        'trip_id': tripId,
        'place_id': stop.place.id,
        'title': stop.place.ten,
        'note': stop.note.trim(),
        'latitude': stop.place.viDo,
        'longitude': stop.place.kinhDo,
        'address': stop.place.diaChi,
        'arrive_at': stop.arriveAt.toIso8601String(),
        'check_radius_m': kTripGroupCheckRadiusM.round(),
        'sort_order': index + 1,
        'status': 'active',
      });
    }

    if (rows.isNotEmpty) {
      await _client.from('trip_stops').insert(rows);
    }
  }

  void _validateDraft({
    required String title,
    required List<TripGroupDraftStop> stops,
  }) {
    if (title.trim().isEmpty) {
      throw Exception('Vui lòng nhập tên lịch trình nhóm.');
    }

    if (stops.isEmpty) {
      throw Exception('Vui lòng thêm ít nhất một địa điểm.');
    }
  }
}

String? _dateOnly(DateTime? value) {
  if (value == null) return null;
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');

  return '${local.year}-$month-$day';
}

String _profileDisplayName(Map<String, dynamic> map) {
  return _firstText([
    map['nickname'],
    map['full_name'],
    map['email'],
  ], fallback: 'Người dùng');
}

String _firstText(List<dynamic> values, {required String fallback}) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';

    if (text.isNotEmpty) return text;
  }

  return fallback;
}

String? _emptyToNull(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  final text = value?.toString();
  if (text == null || text.trim().isEmpty) return null;
  return DateTime.tryParse(text);
}

DateTime? _asDateTime(dynamic value) {
  final text = value?.toString();
  if (text == null || text.trim().isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}
