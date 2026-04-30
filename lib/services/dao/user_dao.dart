import '../../models/user_data.dart';
import '../../models/typedefs.dart';
import 'base_dao.dart';

class UserDao extends BaseDao<UserData> {
  UserDao() : super('UserDao');

  @override
  String get tableName => 'UserData';

  @override
  UserData fromMap(Map<String, dynamic> map) {
    return UserData.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(UserData userData) {
    return {
      'id': userData.id,
      'name': userData.name,
      'birthdate': userData.birthdate.toIso8601String(),
      'units': userData.units.name, // Convert enum to string for storage
      'createdAt': userData.createdAt.toIso8601String(),
      'theme': userData.theme,
    };
  }

  /// Get user data by ID
  Future<UserData?> getUserDataById(UserDataId id) async {
    return await getById(id);
  }

  /// Update user data
  Future<int> updateUserData(UserData userData) async {
    return await update(userData);
  }
}
