import 'package:englishquizapp/services/ranking_service.dart';
import 'package:flutter/material.dart';
import '../services/score_service.dart';

class RankingScreen extends StatefulWidget {
  final String email;
  final String username;

  const RankingScreen({super.key, required this.email, required this.username});

  @override
  _RankingScreenState createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with SingleTickerProviderStateMixin {

  late TabController _tabController;
  List<Map<String, dynamic>> rankings = [];
  String errorMessage = "";
  final List<String> modes = ['easy', 'normal', 'hard'];
  String selectedMode = 'easy';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: modes.length, vsync: this);
    _loadRankings(selectedMode);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        String mode = modes[_tabController.index];
        _loadRankings(mode);
        setState(() {
          selectedMode = mode;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRankings(String mode) async {
    try {
      List<Map<String, dynamic>> fetchedRankings = await RankingService.fetchRankings(mode);
      setState(() {
        rankings = fetchedRankings;
        errorMessage = "";
      });
    } catch (e) {
      setState(() {
        errorMessage = "Không thể tải xếp hạng. Vui lòng thử lại sau.";
      });
      print("Lỗi khi tải xếp hạng: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xếp Hạng'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: modes.map((mode) => Tab(text: mode.toUpperCase())).toList(),
        ),
      ),
      body: errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
          : rankings.isEmpty
          ? Center(child: Text("Chưa có danh sách xếp hạng"))
          : ListView.builder(
        itemCount: rankings.length,
        itemBuilder: (context, index) {
          final user = rankings[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(user['username']),
            subtitle: Text('Điểm: ${user['maxScore']} | Thời gian: ${user['bestDuration']} giây'),
          );
        },
      ),
    );
  }
}
