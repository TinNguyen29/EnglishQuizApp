// Thêm thư viện showDialog
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/quiz_service.dart';
import '../models/question_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/server_config.dart';

class QuestionManagementScreen extends StatefulWidget {
  const QuestionManagementScreen({super.key});

  @override
  State<QuestionManagementScreen> createState() => _QuestionManagementScreenState();
}

class _QuestionManagementScreenState extends State<QuestionManagementScreen> {
  List<Question> _questions = [];
  bool _isLoading = true;
  String _selectedLevel = 'easy';
  String _searchQuery = '';

  final TextEditingController _contentController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (_) => TextEditingController());
  final TextEditingController _correctAnswerController = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final data = await QuizService.fetchQuestions(_selectedLevel);
      if (!mounted) return;
      setState(() {
        _questions = data.map((e) => Question.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Lỗi khi tải câu hỏi')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    final baseUrl = await ServerConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/upload');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      return json.decode(responseData)['imageUrl'];
    } else {
      return null;
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                if (picked != null) {
                  setState(() => _selectedImage = File(picked.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Thư viện'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  setState(() => _selectedImage = File(picked.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openDialog({Question? question}) {
    bool isEdit = question != null;
    if (isEdit) {
      _contentController.text = question!.content;
      for (int i = 0; i < 4; i++) {
        _optionControllers[i].text = question.options[i];
      }
      _correctAnswerController.text = question.correctAnswer.toString();
    } else {
      _contentController.clear();
      for (var ctrl in _optionControllers) ctrl.clear();
      _correctAnswerController.clear();
      _selectedImage = null;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Sửa câu hỏi' : 'Thêm câu hỏi'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _contentController, decoration: const InputDecoration(labelText: 'Câu hỏi')),
              for (int i = 0; i < 4; i++)
                TextField(
                  controller: _optionControllers[i],
                  decoration: InputDecoration(labelText: 'Đáp án ${i + 1}'),
                ),
              TextField(
                controller: _correctAnswerController,
                decoration: const InputDecoration(labelText: 'Đáp án đúng (0-3)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Chọn ảnh'),
                onPressed: _pickImage,
              ),
              if (_selectedImage != null)
                Image.file(_selectedImage!, height: 100)
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final content = _contentController.text.trim();
              final options = _optionControllers.map((e) => e.text.trim()).toList();
              final correctAnswer = int.tryParse(_correctAnswerController.text.trim());

              if (content.isEmpty || options.any((e) => e.isEmpty) || correctAnswer == null || correctAnswer < 0 || correctAnswer > 3) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❗ Vui lòng nhập đầy đủ và chính xác')),
                );
                return;
              }

              String? uploadedUrl;
              if (_selectedImage != null) {
                uploadedUrl = await _uploadImage(_selectedImage!);
              }

              final newQuestion = Question(
                id: isEdit ? question!.id : '',
                content: content,
                options: options,
                correctAnswer: correctAnswer,
                level: _selectedLevel,
                imageUrl: uploadedUrl,
              );

              if (isEdit) {
                await QuizService.updateQuestion(question!.id, newQuestion.toJson());
              } else {
                print('📦 JSON gửi lên backend:');
                print(jsonEncode(newQuestion.toJson()));
                await QuizService.createQuestion(newQuestion.toJson());
              }

              if (!mounted) return;
              Navigator.pop(context);
              _loadQuestions();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa câu hỏi này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await QuizService.deleteQuestion(id);
              if (!mounted) return;
              _loadQuestions();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _confirmEdit(Question question) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận sửa'),
        content: const Text('Bạn có chắc muốn sửa câu hỏi này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openDialog(question: question);
            },
            child: const Text('Sửa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredQuestions = _questions.where((q) => q.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý câu hỏi'),
        actions: [
          DropdownButton<String>(
            value: _selectedLevel,
            underline: Container(),
            items: ['easy', 'normal', 'hard']
                .map((level) => DropdownMenuItem(value: level, child: Text(level.toUpperCase())))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedLevel = value!;
                _loadQuestions();
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm câu hỏi...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredQuestions.isEmpty
          ? const Center(child: Text('Không có câu hỏi nào.'))
          : ListView.builder(
        itemCount: filteredQuestions.length,
        itemBuilder: (context, index) {
          final q = filteredQuestions[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Câu ${index + 1}: ${q.content}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  if (q.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Image.network(
                        q.imageUrl!,
                        height: 150,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                    ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < q.options.length; i++)
                    Text(
                      '${i + 1}. ${q.options[i]}',
                      style: TextStyle(
                        color: i == q.correctAnswer ? Colors.green : Colors.black,
                        fontWeight: i == q.correctAnswer ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đáp án đúng: ${q.correctAnswer + 1}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _confirmEdit(q),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(q.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}