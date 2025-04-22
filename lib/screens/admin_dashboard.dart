import 'package:flutter/material.dart';
import 'question_management_screen.dart'; // Import màn hình quản lý câu hỏi

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void _navigateTo(BuildContext context, String routeName) {
    switch (routeName) {
      case 'Quản lý câu hỏi':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuestionManagementScreen()),
        );
        break;
      case 'Quản lý người dùng':
      case 'Quản lý điểm':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đi tới: $routeName')),
        );
        break;
    }
  }

  void _logout(BuildContext context) {
    // Xử lý đăng xuất và điều hướng về màn hình đăng nhập
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang quản lý Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Thực hiện hành động thông báo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thông báo mới!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Tạo tính năng tìm kiếm
              showSearch(context: context, delegate: CustomSearchDelegate());
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.blue),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Admin',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'admin@domain.com',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person,
              title: 'Quản lý người dùng',
            ),
            _buildDrawerItem(
              context,
              icon: Icons.question_answer,
              title: 'Quản lý câu hỏi',
            ),
            _buildDrawerItem(
              context,
              icon: Icons.bar_chart,
              title: 'Quản lý điểm',
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildDashboardCard(
              context,
              icon: Icons.person,
              title: 'Quản lý người dùng',
              color: Colors.blue,
            ),
            _buildDashboardCard(
              context,
              icon: Icons.question_answer,
              title: 'Quản lý câu hỏi',
              color: Colors.green,
            ),
            _buildDashboardCard(
              context,
              icon: Icons.bar_chart,
              title: 'Quản lý điểm',
              color: Colors.orange,
            ),
            _buildDashboardCard(
              context,
              icon: Icons.settings,
              title: 'Cài đặt',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String title}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => _navigateTo(context, title),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String title, required Color color}) {
    return GestureDetector(
      onTap: () => _navigateTo(context, title),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<dynamic> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = ''; // Xóa truy vấn tìm kiếm
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Đóng khi bấm quay lại
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(child: Text('Kết quả tìm kiếm cho "$query"'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Quản lý người dùng'),
          onTap: () {
            query = 'Quản lý người dùng';
            showResults(context);
          },
        ),
        ListTile(
          title: const Text('Quản lý câu hỏi'),
          onTap: () {
            query = 'Quản lý câu hỏi';
            showResults(context);
          },
        ),
        ListTile(
          title: const Text('Quản lý điểm'),
          onTap: () {
            query = 'Quản lý điểm';
            showResults(context);
          },
        ),
      ],
    );
  }
}
