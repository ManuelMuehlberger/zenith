import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zenith/models/user_data.dart';
import 'package:zenith/constants/app_constants.dart';
import 'package:zenith/services/user_service.dart';
import 'package:zenith/services/dao/user_dao.dart';
import 'package:zenith/services/dao/weight_entry_dao.dart';

// Generate mocks
@GenerateMocks([UserDao, WeightEntryDao])
import 'user_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('UserService Tests', () {
    late UserService userService;
    late MockUserDao mockUserDao;
    late MockWeightEntryDao mockWeightEntryDao;
    late UserData testUser;
    late List<WeightEntry> testWeightEntries;

    setUp(() {
      // Create mock DAOs
      mockUserDao = MockUserDao();
      mockWeightEntryDao = MockWeightEntryDao();
      
      // Initialize the user service with mock DAOs
      userService = UserService(userDao: mockUserDao, weightEntryDao: mockWeightEntryDao);
      userService.resetForTesting();

      // Create test data
      testWeightEntries = [
        WeightEntry(
          id: 'weight1',
          timestamp: DateTime(2023, 1, 1),
          value: 75.5,
        ),
        WeightEntry(
          id: 'weight2',
          timestamp: DateTime(2023, 2, 1),
          value: 74.2,
        ),
      ];

      testUser = UserData(
        id: 'user123',
        name: 'John Doe',
        birthdate: DateTime(1990, 1, 1),
        units: Units.metric,
        weightHistory: testWeightEntries,
        createdAt: DateTime(2023, 1, 1),
        theme: 'dark',
      );
    });

    test('should initialize user service', () {
      expect(userService, isNotNull);
      expect(userService.currentProfile, isNull);
      expect(userService.hasProfile, isFalse);
    });

    test('should be a singleton', () {
      final service1 = UserService();
      final service2 = UserService();
      expect(service1, same(service2));
    });

    group('loadUserProfile', () {
      test('should load user profile successfully with weight history', () async {
        // Arrange
        when(mockUserDao.getAll()).thenAnswer((_) async => [testUser]);
        when(mockWeightEntryDao.getWeightEntriesByUserId('user123'))
            .thenAnswer((_) async => testWeightEntries);

        // Act
        await userService.loadUserProfile();

        // Assert
        verify(mockUserDao.getAll()).called(1);
        verify(mockWeightEntryDao.getWeightEntriesByUserId('user123')).called(1);
        expect(userService.currentProfile, isNotNull);
        expect(userService.currentProfile!.id, equals('user123'));
        expect(userService.currentProfile!.name, equals('John Doe'));
        expect(userService.currentProfile!.weightHistory, hasLength(2));
        expect(userService.hasProfile, isTrue);
      });

      test('should handle empty user list', () async {
        // Arrange
        when(mockUserDao.getAll()).thenAnswer((_) async => []);

        // Act
        await userService.loadUserProfile();

        // Assert
        verify(mockUserDao.getAll()).called(1);
        verifyNever(mockWeightEntryDao.getWeightEntriesByUserId(any));
        expect(userService.currentProfile, isNull);
        expect(userService.hasProfile, isFalse);
      });

      test('should handle exception when loading users', () async {
        // Arrange
        when(mockUserDao.getAll()).thenThrow(Exception('Database error'));

        // Act
        await userService.loadUserProfile();

        // Assert
        verify(mockUserDao.getAll()).called(1);
        expect(userService.currentProfile, isNull);
        expect(userService.hasProfile, isFalse);
      });

      test('should handle exception when loading weight entries', () async {
        // Arrange
        when(mockUserDao.getAll()).thenAnswer((_) async => [testUser]);
        when(mockWeightEntryDao.getWeightEntriesByUserId('user123'))
            .thenThrow(Exception('Database error'));

        // Act
        await userService.loadUserProfile();

        // Assert
        verify(mockUserDao.getAll()).called(1);
        verify(mockWeightEntryDao.getWeightEntriesByUserId('user123')).called(1);
        expect(userService.currentProfile, isNull);
        expect(userService.hasProfile, isFalse);
      });

      test('should load first user when multiple users exist', () async {
        // Arrange
        final secondUser = UserData(
          id: 'user456',
          name: 'Jane Smith',
          birthdate: DateTime(1995, 5, 15),
          units: Units.imperial,
          weightHistory: [],
          createdAt: DateTime(2023, 2, 1),
          theme: 'light',
        );
        when(mockUserDao.getAll()).thenAnswer((_) async => [testUser, secondUser]);
        when(mockWeightEntryDao.getWeightEntriesByUserId('user123'))
            .thenAnswer((_) async => testWeightEntries);

        // Act
        await userService.loadUserProfile();

        // Assert
        expect(userService.currentProfile!.id, equals('user123'));
        expect(userService.currentProfile!.name, equals('John Doe'));
      });
    });

    group('saveUserProfile', () {
      test('should create new user profile', () async {
        // Arrange
        when(mockUserDao.getUserDataById('user123')).thenAnswer((_) async => null);
        when(mockUserDao.insert(any)).thenAnswer((_) async => 1);
        when(mockWeightEntryDao.addWeightEntryForUser(any, any))
            .thenAnswer((_) async => 1);

        // Act
        await userService.saveUserProfile(testUser);

        // Assert
        verify(mockUserDao.getUserDataById('user123')).called(1);
        verify(mockUserDao.insert(testUser)).called(1);
        verify(mockWeightEntryDao.addWeightEntryForUser('user123', testWeightEntries[0])).called(1);
        verify(mockWeightEntryDao.addWeightEntryForUser('user123', testWeightEntries[1])).called(1);
        expect(userService.currentProfile, equals(testUser));
      });

      test('should update existing user profile', () async {
        // Arrange
        when(mockUserDao.getUserDataById('user123')).thenAnswer((_) async => testUser);
        when(mockUserDao.updateUserData(any)).thenAnswer((_) async => 1);
        when(mockWeightEntryDao.addWeightEntryForUser(any, any))
            .thenAnswer((_) async => 1);

        // Act
        await userService.saveUserProfile(testUser);

        // Assert
        verify(mockUserDao.getUserDataById('user123')).called(1);
        verify(mockUserDao.updateUserData(testUser)).called(1);
        verifyNever(mockUserDao.insert(any));
        expect(userService.currentProfile, equals(testUser));
      });

      test('should update existing weight entries when add fails', () async {
        // Arrange
        when(mockUserDao.getUserDataById('user123')).thenAnswer((_) async => testUser);
        when(mockUserDao.updateUserData(any)).thenAnswer((_) async => 1);
        when(mockWeightEntryDao.addWeightEntryForUser('user123', testWeightEntries[0]))
            .thenThrow(Exception('Entry already exists'));
        when(mockWeightEntryDao.updateWeightEntry('user123', testWeightEntries[0]))
            .thenAnswer((_) async => 1);
        when(mockWeightEntryDao.addWeightEntryForUser('user123', testWeightEntries[1]))
            .thenAnswer((_) async => 1);

        // Act
        await userService.saveUserProfile(testUser);

        // Assert
        verify(mockWeightEntryDao.addWeightEntryForUser('user123', testWeightEntries[0])).called(1);
        verify(mockWeightEntryDao.updateWeightEntry('user123', testWeightEntries[0])).called(1);
        verify(mockWeightEntryDao.addWeightEntryForUser('user123', testWeightEntries[1])).called(1);
        verifyNever(mockWeightEntryDao.updateWeightEntry('user123', testWeightEntries[1]));
      });

      test('should throw exception when user name is empty', () async {
        // Arrange
        final invalidUser = testUser.copyWith(name: '');

        // Act & Assert
        expect(
          () => userService.saveUserProfile(invalidUser),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'User name cannot be empty',
          )),
        );
        verifyNever(mockUserDao.getUserDataById(any));
      });

      test('should throw exception when user name is only whitespace', () async {
        // Arrange
        final invalidUser = testUser.copyWith(name: '   ');

        // Act & Assert
        expect(
          () => userService.saveUserProfile(invalidUser),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'User name cannot be empty',
          )),
        );
      });

      test('should handle exception when saving user profile', () async {
        // Arrange
        when(mockUserDao.getUserDataById('user123')).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => userService.saveUserProfile(testUser),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to save user profile'),
          )),
        );
      });

      test('should save user with empty weight history', () async {
        // Arrange
        final userWithoutWeights = testUser.copyWith(weightHistory: []);
        when(mockUserDao.getUserDataById('user123')).thenAnswer((_) async => null);
        when(mockUserDao.insert(any)).thenAnswer((_) async => 1);

        // Act
        await userService.saveUserProfile(userWithoutWeights);

        // Assert
        verify(mockUserDao.insert(userWithoutWeights)).called(1);
        verifyNever(mockWeightEntryDao.addWeightEntryForUser(any, any));
        expect(userService.currentProfile, equals(userWithoutWeights));
      });
    });

    group('isOnboardingComplete', () {
      test('should return true when users exist', () async {
        // Arrange
        when(mockUserDao.getAll()).thenAnswer((_) async => [testUser]);

        // Act
        final result = await userService.isOnboardingComplete();

        // Assert
        expect(result, isTrue);
        verify(mockUserDao.getAll()).called(1);
      });

      test('should return false when no users exist', () async {
        // Arrange
        when(mockUserDao.getAll()).thenAnswer((_) async => []);

        // Act
        final result = await userService.isOnboardingComplete();

        // Assert
        expect(result, isFalse);
        verify(mockUserDao.getAll()).called(1);
      });

      test('should return false when exception occurs', () async {
        // Arrange
        when(mockUserDao.getAll()).thenThrow(Exception('Database error'));

        // Act
        final result = await userService.isOnboardingComplete();

        // Assert
        expect(result, isFalse);
        verify(mockUserDao.getAll()).called(1);
      });
    });

    group('updateProfile', () {
      test('should call saveUserProfile', () async {
        // Arrange
        when(mockUserDao.getUserDataById('user123')).thenAnswer((_) async => null);
        when(mockUserDao.insert(any)).thenAnswer((_) async => 1);
        when(mockWeightEntryDao.addWeightEntryForUser(any, any))
            .thenAnswer((_) async => 1);

        // Act
        await userService.updateProfile(testUser);

        // Assert
        verify(mockUserDao.getUserDataById('user123')).called(1);
        verify(mockUserDao.insert(testUser)).called(1);
        expect(userService.currentProfile, equals(testUser));
      });

      test('should propagate exceptions from saveUserProfile', () async {
        // Arrange
        when(mockUserDao.getUserDataById('user123')).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => userService.updateProfile(testUser),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('clearUserData', () {
      test('should clear all user data', () async {
        // Arrange
        final users = [testUser];
        when(mockUserDao.getAll()).thenAnswer((_) async => users);
        when(mockUserDao.delete(any)).thenAnswer((_) async => 1);

        // Act
        await userService.clearUserData();

        // Assert
        verify(mockUserDao.getAll()).called(1);
        verify(mockUserDao.delete('user123')).called(1);
        expect(userService.currentProfile, isNull);
        expect(userService.hasProfile, isFalse);
      });

      test('should clear multiple users', () async {
        // Arrange
        final secondUser = UserData(
          id: 'user456',
          name: 'Jane Smith',
          birthdate: DateTime(1995, 5, 15),
          units: Units.imperial,
          weightHistory: [],
          createdAt: DateTime(2023, 2, 1),
          theme: 'light',
        );
        final users = [testUser, secondUser];
        when(mockUserDao.getAll()).thenAnswer((_) async => users);
        when(mockUserDao.delete(any)).thenAnswer((_) async => 1);

        // Act
        await userService.clearUserData();

        // Assert
        verify(mockUserDao.delete('user123')).called(1);
        verify(mockUserDao.delete('user456')).called(1);
      });

      test('should handle empty user list', () async {
        // Arrange
        when(mockUserDao.getAll()).thenAnswer((_) async => []);

        // Act
        await userService.clearUserData();

        // Assert
        verify(mockUserDao.getAll()).called(1);
        verifyNever(mockUserDao.delete(any));
        expect(userService.currentProfile, isNull);
      });

      test('should handle exception when clearing user data', () async {
        // Arrange
        when(mockUserDao.getAll()).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => userService.clearUserData(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to clear user data'),
          )),
        );
      });

      test('should reset current profile even if loaded', () async {
        // Arrange
        userService.resetForTesting();
        // Simulate having a loaded profile
        when(mockUserDao.getAll()).thenAnswer((_) async => [testUser]);
        when(mockWeightEntryDao.getWeightEntriesByUserId('user123'))
            .thenAnswer((_) async => testWeightEntries);
        await userService.loadUserProfile();
        expect(userService.hasProfile, isTrue);

        // Clear data
        when(mockUserDao.getAll()).thenAnswer((_) async => [testUser]);
        when(mockUserDao.delete(any)).thenAnswer((_) async => 1);

        // Act
        await userService.clearUserData();

        // Assert
        expect(userService.currentProfile, isNull);
        expect(userService.hasProfile, isFalse);
      });
    });

    group('getGreeting', () {
      test('should return welcome when no profile', () {
        // Arrange - no profile loaded
        userService.resetForTesting();

        // Act
        final greeting = userService.getGreeting();

        // Assert
        expect(greeting, equals('Welcome'));
      });

      test('should return morning greeting', () {
        // Arrange
        userService.resetForTesting();
        // Simulate having a profile loaded
        final mockDateTime = DateTime(2023, 1, 1, 8, 0); // 8:00 AM
        
        // We can't easily mock DateTime.now(), so we'll test the logic indirectly
        // by setting up a profile and checking that a greeting is returned
        when(mockUserDao.getAll()).thenAnswer((_) async => [testUser]);
        when(mockWeightEntryDao.getWeightEntriesByUserId('user123'))
            .thenAnswer((_) async => testWeightEntries);

        // Act - load profile first
        return userService.loadUserProfile().then((_) {
          final greeting = userService.getGreeting();
          
          // Assert - should contain the user's name
          expect(greeting, contains('John Doe'));
          expect(greeting, isNot(equals('Welcome')));
        });
      });

      test('should include user name in greeting when profile exists', () async {
        // Arrange
        userService.resetForTesting();
        when(mockUserDao.getAll()).thenAnswer((_) async => [testUser]);
        when(mockWeightEntryDao.getWeightEntriesByUserId('user123'))
            .thenAnswer((_) async => testWeightEntries);
        await userService.loadUserProfile();

        // Act
        final greeting = userService.getGreeting();

        // Assert
        expect(greeting, contains('John Doe'));
        expect(greeting, isNot(equals('Welcome')));
        // Should contain one of the time-based greetings
        expect(
          greeting.contains('Good morning') ||
          greeting.contains('Good afternoon') ||
          greeting.contains('Good evening'),
          isTrue,
        );
      });
    });

    group('formatWeight', () {
      test('should return weight as string when no profile', () {
        // Arrange
        userService.resetForTesting();

        // Act
        final formatted = userService.formatWeight(75.5);

        // Assert
        expect(formatted, equals('75.5'));
      });

      test('should format weight with metric units', () async {
        // Arrange
        userService.resetForTesting();
        when(mockUserDao.getAll()).thenAnswer((_) async => [testUser]);
        when(mockWeightEntryDao.getWeightEntriesByUserId('user123'))
            .thenAnswer((_) async => testWeightEntries);
        await userService.loadUserProfile();

        // Act
        final formatted = userService.formatWeight(75.5);

        // Assert
        expect(formatted, equals('75.5 kg'));
      });

      test('should format weight with imperial units', () async {
        // Arrange
        final imperialUser = testUser.copyWith(units: Units.imperial);
        userService.resetForTesting();
        when(mockUserDao.getAll()).thenAnswer((_) async => [imperialUser]);
        when(mockWeightEntryDao.getWeightEntriesByUserId('user123'))
            .thenAnswer((_) async => testWeightEntries);
        await userService.loadUserProfile();

        // Act
        final formatted = userService.formatWeight(165.2);

        // Assert
        expect(formatted, equals('165.2 lbs'));
      });

      test('should format weight with one decimal place', () async {
        // Arrange
        userService.resetForTesting();
        when(mockUserDao.getAll()).thenAnswer((_) async => [testUser]);
        when(mockWeightEntryDao.getWeightEntriesByUserId('user123'))
            .thenAnswer((_) async => testWeightEntries);
        await userService.loadUserProfile();

        // Act
        final formatted = userService.formatWeight(75);

        // Assert
        expect(formatted, equals('75.0 kg'));
      });
    });

    group('currentProfile and hasProfile getters', () {
      test('should return null for currentProfile when no profile loaded', () {
        // Arrange
        userService.resetForTesting();

        // Act & Assert
        expect(userService.currentProfile, isNull);
      });

      test('should return false for hasProfile when no profile loaded', () {
        // Arrange
        userService.resetForTesting();

        // Act & Assert
        expect(userService.hasProfile, isFalse);
      });

      test('should return profile when loaded', () async {
        // Arrange
        userService.resetForTesting();
        when(mockUserDao.getAll()).thenAnswer((_) async => [testUser]);
        when(mockWeightEntryDao.getWeightEntriesByUserId('user123'))
            .thenAnswer((_) async => testWeightEntries);

        // Act
        await userService.loadUserProfile();

        // Assert
        expect(userService.currentProfile, isNotNull);
        expect(userService.currentProfile!.id, equals('user123'));
        expect(userService.hasProfile, isTrue);
      });
    });

    group('resetForTesting', () {
      test('should reset current profile to null', () async {
        // Arrange - load a profile first
        when(mockUserDao.getAll()).thenAnswer((_) async => [testUser]);
        when(mockWeightEntryDao.getWeightEntriesByUserId('user123'))
            .thenAnswer((_) async => testWeightEntries);
        await userService.loadUserProfile();
        expect(userService.hasProfile, isTrue);

        // Act
        userService.resetForTesting();

        // Assert
        expect(userService.currentProfile, isNull);
        expect(userService.hasProfile, isFalse);
      });
    });

    group('edge cases and error handling', () {
      test('should handle null weight entries list', () async {
        // Arrange
        when(mockUserDao.getAll()).thenAnswer((_) async => [testUser]);
        when(mockWeightEntryDao.getWeightEntriesByUserId('user123'))
            .thenAnswer((_) async => []);

        // Act
        await userService.loadUserProfile();

        // Assert
        expect(userService.currentProfile, isNotNull);
        expect(userService.currentProfile!.weightHistory, isEmpty);
      });

      test('should handle user with different theme', () async {
        // Arrange
        final lightThemeUser = testUser.copyWith(theme: 'light');
        when(mockUserDao.getUserDataById('user123')).thenAnswer((_) async => null);
        when(mockUserDao.insert(any)).thenAnswer((_) async => 1);
        when(mockWeightEntryDao.addWeightEntryForUser(any, any))
            .thenAnswer((_) async => 1);

        // Act
        await userService.saveUserProfile(lightThemeUser);

        // Assert
        expect(userService.currentProfile!.theme, equals('light'));
      });

      test('should handle user with future birthdate', () async {
        // Arrange
        final futureBirthdateUser = testUser.copyWith(
          birthdate: DateTime.now().add(const Duration(days: 365)),
        );
        when(mockUserDao.getUserDataById('user123')).thenAnswer((_) async => null);
        when(mockUserDao.insert(any)).thenAnswer((_) async => 1);
        when(mockWeightEntryDao.addWeightEntryForUser(any, any))
            .thenAnswer((_) async => 1);

        // Act
        await userService.saveUserProfile(futureBirthdateUser);

        // Assert
        expect(userService.currentProfile, isNotNull);
        // Age calculation should handle future dates gracefully
        expect(userService.currentProfile!.age, lessThan(0));
      });
    });
  });
}
