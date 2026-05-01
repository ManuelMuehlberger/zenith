# Coverage Priority Backlog

Scoring method:

- `delta_to_80`: additional covered lines needed for a file to reach 80% line coverage.
- `weight_score`: `delta_to_80` multiplied by an architectural leverage factor.
- Higher scores mean better return on effort for stabilizing the coverage gate.

Notes:

- `lib/models/typedefs.dart` and `lib/services/insights/insight_data_provider.dart` are policy-exception candidates, not good test targets. They have no executable lines to cover.
- Suggested test file paths are where workers should extend or create tests.

| Rank | Weight | File | Current | Delta to 80 | Suggested Test File | Notes |
| --- | ---: | --- | ---: | ---: | --- | --- |
| 1 | 189.00 | lib/services/database_helper.dart | 8.22% | 105 | test/services/database_helper_test.dart | Foundational DB bootstrap and schema path. |
| 2 | 156.40 | lib/services/live_workout_notification_service.dart | 5.69% | 92 | test/services/live_workout_notification_service_test.dart | Cross-cutting runtime side effects; currently almost untested. |
| 3 | 107.25 | lib/services/dao/base_dao.dart | 4.65% | 65 | test/services/dao/base_dao_test.dart | Shared DAO abstraction; coverage here lifts every concrete DAO pattern. |
| 4 | 91.35 | lib/services/dao/workout_exercise_dao.dart | 16.33% | 63 | test/services/dao/workout_exercise_dao_test.dart | Central join layer in workout persistence. |
| 5 | 68.15 | lib/services/dao/workout_set_dao.dart | 19.48% | 47 | test/services/dao/workout_set_dao_test.dart | Core persistence path for sets and session history. |
| 6 | 63.80 | lib/services/dao/workout_dao.dart | 25.93% | 44 | test/services/dao/workout_dao_test.dart | Primary workout record persistence. |
| 7 | 62.90 | lib/services/workout_session_service.dart | 67.68% | 37 | test/services/workout_session_service_test.dart | High-traffic session logic; close enough to finish efficiently. |
| 8 | 53.75 | lib/services/debug_data_service.dart | 0.00% | 43 | test/services/debug_data_service_test.dart | Pure support service with no coverage at all. |
| 9 | 49.30 | lib/services/dao/exercise_dao.dart | 28.12% | 34 | test/services/dao/exercise_dao_test.dart | Read path for exercise catalog. |
| 10 | 49.30 | lib/services/dao/workout_template_dao.dart | 33.33% | 34 | test/services/dao/workout_template_dao_test.dart | Template persistence path. |
| 11 | 46.20 | lib/services/export_import_service.dart | 0.00% | 33 | test/services/export_import_service_test.dart | User data portability; should be covered before enforcing commits broadly. |
| 12 | 44.20 | lib/services/workout_service.dart | 72.14% | 26 | test/services/workout_service_test.dart | Core domain service; modest delta but high leverage. |
| 13 | 34.80 | lib/services/dao/weight_entry_dao.dart | 26.67% | 24 | test/services/dao/weight_entry_dao_test.dart | Persistence for tracked weights. |
| 14 | 14.30 | lib/constants/app_constants.dart | 55.10% | 13 | test/constants/app_constants_test.dart | Low complexity; easy cleanup win. |
| 15 | 10.15 | lib/services/dao/muscle_group_dao.dart | 45.00% | 7 | test/services/dao/muscle_group_dao_test.dart | Small DAO, quick coverage gain. |
| 16 | 10.15 | lib/services/dao/workout_folder_dao.dart | 53.85% | 7 | test/services/dao/workout_folder_dao_test.dart | Small DAO, quick coverage gain. |
| 17 | 8.00 | lib/utils/app_logger.dart | 0.00% | 8 | test/utils/app_logger_test.dart | Small utility with simple behavior assertions. |
| 18 | 6.25 | lib/services/app_startup_service.dart | 63.33% | 5 | test/services/app_startup_service_test.dart | Existing suite likely just needs branch fill-in. |
| 19 | 2.70 | lib/models/muscle_group.dart | 50.00% | 3 | test/models/muscle_group_test.dart | Small model cleanup. |
| 20 | 2.00 | lib/utils/unit_converter.dart | 40.00% | 2 | test/utils/unit_converter_test.dart | Very small utility, quick finish. |
| 21 | 1.45 | lib/services/dao/user_dao.dart | 75.00% | 1 | test/services/dao/user_dao_test.dart | Near threshold; one or two assertions should finish it. |
| 22 | 0.90 | lib/models/weekly_bar_data.dart | 0.00% | 1 | test/models/weekly_bar_data_test.dart | One-line model file, trivial coverage task. |
| 23 | 0.00 | lib/models/typedefs.dart | n/a | 0 | test/models/typedefs_test.dart | Policy-exception candidate: typedef-only file. |
| 24 | 0.00 | lib/services/insights/insight_data_provider.dart | n/a | 0 | test/services/insights/insight_data_provider_test.dart | Policy-exception candidate: abstract interface only. |

Recommended execution waves:

1. Wave 1: ranks 1-8.
2. Wave 2: ranks 9-16.
3. Wave 3: ranks 17-22.
4. Policy review: ranks 23-24.
