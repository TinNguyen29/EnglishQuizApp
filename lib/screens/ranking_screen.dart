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

class _RankingScreenState extends State<RankingScreen> {
  List<Map<String, dynamic>> rankings = [];
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  Future<void> _loadRankings() async {
    try {
      List<Map<String, dynamic>> fetchedRankings = await RankingService.fetchRankings();
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
      ),
      body: errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
          : rankings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: rankings.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              child: Text(rankings[index]['rank'].toString()),
            ),
            title: Text(rankings[index]['username']),
            subtitle: Text('Điểm: ${rankings[index]['score']}'),
          );
        },
      ),
    );
  }
}
