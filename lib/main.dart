import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://ylgdqpixrbhgkcrhqvgj.supabase.co';
const supabasePublishableKey = 'sb_publishable_PydS4Tbscos0eMZyzZAKEA_k6_uFZQ-';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  runApp(const MoratabKhoonehApp());
}

final supabase = Supabase.instance.client;

class MoratabKhoonehApp extends StatelessWidget {
  const MoratabKhoonehApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مرتب خونه',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF218653)),
        fontFamily: 'Roboto',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        if (session == null) return const LoginPage();
        return const ProfileGate();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;

  Future<void> signIn() async {
    setState(() { busy = true; error = null; });
    try {
      await supabase.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
    } on AuthException catch (e) {
      setState(() => error = e.message);
    } catch (e) {
      setState(() => error = 'خطا در اتصال. اینترنت و تنظیمات پروژه را بررسی کنید.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.recycling, size: 72, color: Color(0xFF218653)),
                  const SizedBox(height: 12),
                  const Text('مرتب خونه', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('ایران پاک، خانه‌ای آباد', textAlign: TextAlign.center),
                  const SizedBox(height: 36),
                  TextField(controller: email, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'ایمیل', border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                  TextField(controller: password, obscureText: true,
                    decoration: const InputDecoration(labelText: 'رمز عبور', border: OutlineInputBorder())),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: busy ? null : signIn,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(busy ? 'در حال ورود...' : 'ورود به حساب'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('حساب کاربران باید از قبل توسط مدیر ایجاد شده باشد.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key});
  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late Future<Map<String, dynamic>?> profileFuture;

  Future<Map<String, dynamic>?> loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    final row = await supabase.from('profiles')
        .select('full_name, role, is_active')
        .eq('id', user.id)
        .maybeSingle();
    return row;
  }

  @override
  void initState() {
    super.initState();
    profileFuture = loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || snapshot.data == null) {
          return AccessProblem(message: 'پروفایل این حساب پیدا نشد یا دسترسی خواندن آن وجود ندارد.');
        }
        final profile = snapshot.data!;
        if (profile['is_active'] != true) {
          return const AccessProblem(message: 'این حساب غیرفعال است. با مدیر سیستم تماس بگیرید.');
        }
        return HomePage(
          name: (profile['full_name'] ?? 'کاربر').toString(),
          role: (profile['role'] ?? 'unknown').toString(),
        );
      },
    );
  }
}

class AccessProblem extends StatelessWidget {
  final String message;
  const AccessProblem({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_outline, size: 56, color: Colors.orange),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton(onPressed: () async => supabase.auth.signOut(), child: const Text('خروج')),
      ]),
    )),
  );
}

class HomePage extends StatelessWidget {
  final String name;
  final String role;
  const HomePage({super.key, required this.name, required this.role});

  String roleLabel(String value) {
    switch (value) {
      case 'admin': return 'مدیر';
      case 'buyer': return 'خریدار';
      case 'driver': return 'راننده';
      case 'warehouse': return 'انباردار';
      case 'accountant': return 'حسابدار';
      default: return 'کاربر';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ('خرید ضایعات', Icons.shopping_cart_outlined),
      ('درخواست جمع‌آوری', Icons.local_shipping_outlined),
      ('موجودی انبار', Icons.inventory_2_outlined),
      ('پرداخت‌ها', Icons.payments_outlined),
      ('گزارش‌ها', Icons.bar_chart_outlined),
      ('مدیریت کاربران', Icons.people_outline),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('مرتب خونه'),
        actions: [IconButton(
          tooltip: 'خروج',
          onPressed: () async => supabase.auth.signOut(),
          icon: const Icon(Icons.logout),
        )],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            color: const Color(0xFFE8F5EC),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('سلام $name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('نقش: ${roleLabel(role)}'),
                const SizedBox(height: 4),
                const Text('ایران پاک، خانه‌ای آباد'),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.35),
            itemBuilder: (context, index) => Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('این بخش در نسخه بعدی فعال می‌شود.'))),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(items[index].$2, size: 32, color: const Color(0xFF218653)),
                  const SizedBox(height: 10),
                  Text(items[index].$1, textAlign: TextAlign.center),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('نسخه آزمایشی ۰.۴', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45)),
        ],
      ),
    );
  }
}
