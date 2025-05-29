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
  bool isLoading = false;

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
    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> fetchedRankings = await RankingService.fetchRankings(mode);
      setState(() {
        rankings = fetchedRankings;
        errorMessage = "";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Không thể tải xếp hạng. Vui lòng thử lại sau.";
        isLoading = false;
      });
      print("Lỗi khi tải xếp hạng: $e");
    }
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'easy':
        return Colors.greenAccent.shade700;
      case 'normal':
        return Colors.orange.shade700;
      case 'hard':
        return Colors.redAccent;
      default:
        return Colors.blue;
    }
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'easy':
        return Icons.lightbulb_outline;
      case 'normal':
        return Icons.auto_graph;
      case 'hard':
        return Icons.local_fire_department;
      default:
        return Icons.quiz;
    }
  }

  String _getModeName(String mode) {
    switch (mode) {
      case 'easy':
        return 'Dễ';
      case 'normal':
        return 'Trung bình';
      case 'hard':
        return 'Khó';
      default:
        return mode;
    }
  }

  Widget _buildRankingCard(Map<String, dynamic> user, int index) {
    Color rankColor;
    IconData rankIcon;

    if (index == 0) {
      rankColor = Colors.amber.shade600; // Vàng cho hạng 1
      rankIcon = Icons.emoji_events;
    } else if (index == 1) {
      rankColor = Colors.grey.shade600; // Bạc cho hạng 2
      rankIcon = Icons.workspace_premium;
    } else if (index == 2) {
      rankColor = Colors.brown.shade600; // Đồng cho hạng 3
      rankIcon = Icons.military_tech;
    } else {
      rankColor = Colors.blue.shade600;
      rankIcon = Icons.person;
    }

    // Kiểm tra xem có phải người dùng hiện tại không
    bool isCurrentUser = user['email'] == widget.email;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? _getModeColor(selectedMode).withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: _getModeColor(selectedMode).withOpacity(0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isCurrentUser
                ? _getModeColor(selectedMode).withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hạng và icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  rankIcon,
                  color: rankColor,
                  size: index < 3 ? 20 : 16,
                ),
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Thông tin người dùng
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user['username'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser ? _getModeColor(selectedMode) : Colors.black87,
                        ),
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getModeColor(selectedMode),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Bạn',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Điểm: ${user['maxScore'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user['bestDuration'] ?? 0}s',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bảng Xếp Hạng',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab bar với thiết kế custom
          Container(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: modes.map((mode) {
                  return Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getModeIcon(mode),
                          size: 18,
                          color: selectedMode == mode ? _getModeColor(mode) : Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(_getModeName(mode)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Nội dung
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : errorMessage.isNotEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _loadRankings(selectedMode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getModeColor(selectedMode),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
                  : rankings.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.leaderboard_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có danh sách xếp hạng',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hãy là người đầu tiên làm bài quiz!',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: () => _loadRankings(selectedMode),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  itemCount: rankings.length,
                  itemBuilder: (context, index) {
                    final user = rankings[index];
                    return _buildRankingCard(user, index);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}