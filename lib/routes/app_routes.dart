import 'package:get/get.dart';
import '../presentation/bindings/auth_binding.dart';
import '../presentation/bindings/dashboard_binding.dart';
import '../presentation/bindings/inspection_binding.dart';
import '../presentation/controllers/inspection_form_controller.dart';
import '../presentation/bindings/inspection_list_binding.dart';
import '../presentation/bindings/main_binding.dart';
import '../presentation/screens/dashboard_screen.dart';
import '../presentation/screens/inspection_detail_screen.dart';
import '../presentation/screens/inspection_form_screen.dart';
import '../presentation/screens/inspection_list_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/notifications_screen.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/welcome_screen.dart';
import '../presentation/screens/checklist_screen.dart';
import '../presentation/screens/photo_review_screen.dart';
import '../presentation/screens/routine_report_screen.dart';
import '../presentation/screens/sync_progress_screen.dart';
import '../presentation/screens/support_screen.dart';
import '../presentation/screens/main_screen.dart';
import '../presentation/screens/edit_profile_screen.dart';
import '../presentation/controllers/edit_profile_controller.dart';
import '../presentation/screens/completed_report_screen.dart';
import '../presentation/controllers/completed_report_controller.dart';

class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const main = '/main';
  static const dashboard = '/dashboard';
  static const inspections = '/inspections';
  static const inspectionDetail = '/inspection-detail';
  static const inspectionForm = '/inspection-form';
  static const checklist = '/checklist';
  static const photoReview = '/photo-review';
  static const routineReport = '/routine-report';
  static const syncProgress = '/sync-progress';
  static const inspectionReport = '/inspection-report';
  static const notifications = '/notifications';
  static const support = '/support';

  static final routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: welcome,
      page: () => const WelcomeScreen(),
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: main,
      page: () =>  MainScreen(),
      binding: MainBinding(),
    ),
    GetPage(
      name: dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: inspections,
      page: () => const InspectionListScreen(),
      binding: InspectionListBinding(),
    ),
    GetPage(
      name: inspectionDetail,
      page: () => const InspectionDetailScreen(),
      binding: InspectionBinding(),
    ),
    GetPage(
      name: inspectionForm,
      page: () {
        Get.put(InspectionFormController());
        return const InspectionFormScreen();
      },
    ),
    GetPage(
      name: checklist,
      page: () => const ChecklistScreen(),
      binding: InspectionBinding(),
    ),
    GetPage(
      name: photoReview,
      page: () => const PhotoReviewScreen(),
      binding: InspectionBinding(),
    ),
    GetPage(
      name: routineReport,
      page: () => const RoutineReportScreen(),
      binding: InspectionBinding(),
    ),
    GetPage(
      name: syncProgress,
      page: () => const SyncProgressScreen(),
      binding: InspectionBinding(),
    ),
    GetPage(
      name: notifications,
      page: () => const NotificationsScreen(),
    ),
    GetPage(
      name: support,
      page: () => const SupportScreen(),
    ),
    GetPage(
      name: '/edit-profile',
      page: () => const EditProfileScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => EditProfileController(), fenix: true)),
    ),
    GetPage(
      name: inspectionReport,
      page: () {
        Get.put(CompletedReportController());
        return const CompletedReportScreen();
      },
    ),
  ];
}
