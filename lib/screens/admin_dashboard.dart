import 'package:flutter/material.dart';
import 'question_management_screen.dart';
import 'ranking_screen.dart';

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
      case 'Xem xếp hạng':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RankingScreen(
              email: 'admin@gmail.com',
              username: 'admin',
            ),
          ),
        );
        break;
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang quản trị'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(navigateTo: _navigateTo),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              accountName: Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text('admin@gmail.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.teal),
              ),
            ),
            _buildDrawerItem(context, icon: Icons.question_answer, title: 'Quản lý câu hỏi'),
            _buildDrawerItem(context, icon: Icons.leaderboard, title: 'Xem xếp hạng'),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
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
              icon: Icons.question_answer,
              title: 'Quản lý câu hỏi',
              color: Colors.teal,
            ),
            _buildDashboardCard(
              context,
              icon: Icons.leaderboard,
              title: 'Xem xếp hạng',
              color: Colors.deepOrange,
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

  Widget _buildDashboardCard(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
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
              Icon(icon, size: 48, color: Colors.white),
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
  final void Function(BuildContext, String) navigateTo;

  CustomSearchDelegate({required this.navigateTo});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    navigateTo(context, query);
    close(context, null);
    return Container(); // Không cần UI kết quả
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = ['Quản lý câu hỏi', 'Xem xếp hạng']
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (_, index) {
        return ListTile(
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}
