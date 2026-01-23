import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_store_screen.dart';
import '../features/auth/presentation/screens/register_business_screen.dart';
import '../features/auth/presentation/screens/staff_pin_screen.dart';
import '../features/auth/presentation/screens/open_shift_screen.dart';
import '../features/auth/presentation/screens/end_shift_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/orders/presentation/screens/create_order_screen.dart';
import '../features/orders/presentation/screens/orders_screen.dart';
import '../features/orders/presentation/screens/order_detail_screen.dart';
import '../features/stock/presentation/screens/receive_goods_screen.dart';
import '../features/stock/presentation/screens/withdraw_goods_screen.dart';
import '../features/stock/presentation/screens/adjust_stock_screen.dart';
import '../features/stock/presentation/screens/low_stock_screen.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/shift/data/shift_repository.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final shiftRepo = ref.watch(shiftRepositoryProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isStoreLoggedIn = authRepo.isStoreLoggedIn();
      final isShiftOpen = shiftRepo.isShiftOpen();
      final isPinVerified = authRepo.isPinVerified();

      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';
      final isOpenShiftRoute = state.matchedLocation == '/open-shift';
      final isPinRoute = state.matchedLocation == '/pin';

      if (!isStoreLoggedIn && !isLoginRoute && !isRegisterRoute) {
        return '/login';
      }

      if (isStoreLoggedIn && !isShiftOpen && !isOpenShiftRoute && !isLoginRoute && !isRegisterRoute) {
        return '/open-shift';
      }

      if (isStoreLoggedIn && isShiftOpen && !isPinVerified && !isPinRoute && !isLoginRoute && !isRegisterRoute) {
        return '/pin';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginStoreScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterBusinessScreen()),
      GoRoute(path: '/open-shift', builder: (context, state) => const OpenShiftScreen()),
      GoRoute(path: '/pin', builder: (context, state) => const StaffPinScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/create-order', builder: (context, state) => const CreateOrderScreen()),
      GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(path: '/receive-goods', builder: (context, state) => const ReceiveGoodsScreen()),
      GoRoute(path: '/withdraw-goods', builder: (context, state) => const WithdrawGoodsScreen()),
      GoRoute(path: '/adjust-stock', builder: (context, state) => const AdjustStockScreen()),
      GoRoute(path: '/low-stock', builder: (context, state) => const LowStockScreen()),
      GoRoute(path: '/end-shift', builder: (context, state) => const EndShiftScreen()),
    ],
  );
});
