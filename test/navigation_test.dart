import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:primesoftware/main.dart';
import 'package:primesoftware/routes/app_routes.dart';

void main() {
  group('Navigation Tests', () {
    testWidgets('Complete app navigation flow', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      
      // Should start with splash screen
      expect(find.text('Property Inspector'), findsOneWidget);
      
      // Wait for splash screen animation
      await tester.pumpAndSettle(const Duration(seconds: 4));
      
      // Should navigate to welcome screen
      expect(find.text('Welcome to'), findsOneWidget);
      expect(find.text('GET STARTED'), findsOneWidget);
      
      // Tap get started button
      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();
      
      // Should navigate to login screen
      expect(find.text('PropInspect'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
      
      // Fill login form and submit
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password');
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();
      
      // Should navigate to dashboard
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('127'), findsOneWidget);
      expect(find.text('This month'), findsOneWidget);
    });
    
    testWidgets('Dashboard to inspection list navigation', (WidgetTester tester) async {
      // Navigate to dashboard
      Get.offAllNamed(AppRoutes.dashboard);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Tap on View Inspections
      await tester.tap(find.text('View\nInspections'));
      await tester.pumpAndSettle();
      
      // Should navigate to inspection list
      expect(find.text('Inspections'), findsOneWidget);
      expect(find.text('3711 Western Avenue'), findsAtLeastNWidgets(1));
    });
    
    testWidgets('Map view toggle functionality', (WidgetTester tester) async {
      // Navigate to inspection list
      Get.offAllNamed(AppRoutes.inspections);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Should show list view initially
      expect(find.text('Inspections'), findsOneWidget);
      
      // Tap map toggle button
      await tester.tap(find.byIcon(Icons.map));
      await tester.pumpAndSettle();
      
      // Should show map view
      expect(find.text('Map View'), findsOneWidget);
      expect(find.text('Open Inspection →'), findsOneWidget);
    });
    
    testWidgets('Inspection detail to checklist flow', (WidgetTester tester) async {
      // Navigate to inspection detail
      Get.offAllNamed(AppRoutes.inspectionDetail);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Should show inspection details
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('3711 Western Avenue'), findsOneWidget);
      expect(find.text('START INSPECTION →'), findsOneWidget);
      
      // Tap start inspection
      await tester.tap(find.text('START INSPECTION →'));
      await tester.pumpAndSettle();
      
      // Should navigate to checklist
      expect(find.text('Checklist'), findsOneWidget);
      expect(find.text('Utilities'), findsOneWidget);
    });
    
    testWidgets('Complete inspection flow', (WidgetTester tester) async {
      // Start from checklist
      Get.offAllNamed(AppRoutes.checklist);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Tap sync now
      await tester.tap(find.text('Sync Now'));
      await tester.pumpAndSettle();
      
      // Should navigate to photo review
      expect(find.text('Photo Review'), findsOneWidget);
      expect(find.text('Add a Photo'), findsOneWidget);
      
      // Continue to report
      await tester.tap(find.text('Continue to Report'));
      await tester.pumpAndSettle();
      
      // Should navigate to routine report
      expect(find.text('Routine Report'), findsOneWidget);
      expect(find.text('1. Summary'), findsOneWidget);
      
      // Generate report
      await tester.tap(find.text('Generate Report'));
      await tester.pumpAndSettle();
      
      // Should navigate to sync progress
      expect(find.text('Sync Progress'), findsOneWidget);
      expect(find.text('87%'), findsOneWidget);
    });
    
    testWidgets('Bottom navigation functionality', (WidgetTester tester) async {
      // Start from dashboard
      Get.offAllNamed(AppRoutes.dashboard);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Test bottom navigation items
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();
      expect(find.text('Inspections'), findsOneWidget);
      
      // Test FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      // Should open inspection form or similar
      
      // Test notifications
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);
    });
  });
  
  group('UI Component Tests', () {
    testWidgets('Color scheme consistency', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Check if primary color is used consistently
      final primaryColorWidgets = find.byWidgetPredicate(
        (widget) => widget is Container && 
        (widget.decoration as BoxDecoration?)?.color?.value == 0xFF00D4AA
      );
      
      expect(primaryColorWidgets, findsAtLeastNWidgets(1));
    });
    
    testWidgets('Responsive design elements', (WidgetTester tester) async {
      // Test different screen sizes
      await tester.binding.setSurfaceSize(const Size(375, 812)); // iPhone X
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Check if elements are properly sized
      expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
      
      // Test tablet size
      await tester.binding.setSurfaceSize(const Size(768, 1024)); // iPad
      await tester.pumpAndSettle();
      
      // Elements should still be visible and properly arranged
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });
    
    testWidgets('Icon consistency', (WidgetTester tester) async {
      // Navigate through different screens and check icons
      Get.offAllNamed(AppRoutes.dashboard);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Check dashboard icons
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.list_alt), findsOneWidget);
      expect(find.byIcon(Icons.map), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}