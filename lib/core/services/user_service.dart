import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static const _key = 'local_user_id';
  final _uuid = const Uuid();

  Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();

    String? userId = prefs.getString(_key);

    if (userId == null) {
      userId = _uuid.v4();
      await prefs.setString(_key, userId);
    }

    return userId;
  }
}