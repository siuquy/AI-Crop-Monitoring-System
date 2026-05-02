import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/service/report_service.dart';
import '../../screens/task/api_config.dart';

class ReportUpdateScreen extends StatefulWidget {
  final String reportId;
  final String imagePath;
  final String title;
  final String diseaseName;
  final String ownerComment;

  const ReportUpdateScreen({
    super.key,
    required this.reportId,
    required this.imagePath,
    required this.title,
    required this.diseaseName,
    required this.ownerComment,
  });

  @override
  State<ReportUpdateScreen> createState() => _ReportUpdateScreenState();
}

class _ReportUpdateScreenState extends State<ReportUpdateScreen> {
  final TextEditingController descriptionController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  File? newImage;
  bool _isLoading = false;

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  // Logic để chọn ảnh
  Future<void> pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source);

    if (picked != null) {
      setState(() {
        newImage = File(picked.path);
      });
    }
  }

  Future<void> submitUpdate() async {
    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập mô tả bổ sung"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ReportService.updateReport(
        reportId: widget.reportId,
        description: descriptionController.text.trim(),
        newImage: newImage,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cập nhật báo cáo thành công!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true); // Pop with a result to indicate success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi cập nhật báo cáo: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget buildImageSection() {
    final String finalImageUrl = widget.imagePath.startsWith('http') ||
            widget.imagePath.startsWith('assets/')
        ? widget.imagePath
        : '${ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '')}/${widget.imagePath.replaceAll(RegExp(r'^/'), '')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ảnh báo cáo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: newImage != null
                ? Image.file(
                    newImage!,
                    fit: BoxFit.cover,
                  )
                : widget.imagePath.isNotEmpty
                    ? (widget.imagePath.startsWith('assets/')
                        ? Image.asset(
                            widget.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey, size: 48),
                              );
                            },
                          )
                        : Image.network(
                            finalImageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey, size: 48),
                              );
                            },
                          ))
                    : const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            color: Colors.grey, size: 48),
                      ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text("Chụp ảnh"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => pickImage(ImageSource.gallery),
                icon: const Icon(Icons.image),
                label: const Text("Thư viện"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildExpertComment() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.ownerComment,
              style: const TextStyle(fontSize: 14),
            ),
          )
        ],
      ),
    );
  }

  Widget buildDescriptionInput() {
    return TextField(
      controller: descriptionController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: "Nhập mô tả bổ sung...",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bổ sung báo cáo"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// title
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Bệnh: ${widget.diseaseName}",
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            /// image
            buildImageSection(),

            const SizedBox(height: 20),

            const Text(
              "Nhận xét của chuyên gia",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            buildExpertComment(),

            const SizedBox(height: 20),

            const Text(
              "Mô tả bổ sung",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            buildDescriptionInput(),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : submitUpdate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Gửi lại báo cáo",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
