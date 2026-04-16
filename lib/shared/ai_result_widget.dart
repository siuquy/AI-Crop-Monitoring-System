import 'package:flutter/material.dart';

class AiResultWidget extends StatelessWidget {
  final Map<String, dynamic> aiData;

  const AiResultWidget({super.key, required this.aiData});

  @override
  Widget build(BuildContext context) {
    final String diseaseName = aiData['diseaseName'] ??
        aiData['name'] ??
        aiData['Tên bệnh'] ??
        'Không rõ';
    final double confidence = (aiData['confidence'] is num)
        ? (aiData['confidence'] as num).toDouble()
        : 0.0;
    final bool isHealthy = aiData['isHealthy'] ?? false;
    final String description = aiData['description'] ??
        aiData['Description'] ??
        'Không có mô tả chi tiết.';
    final String commonName = aiData['commonName'] ?? '';

    final List<String> symptoms = List<String>.from(aiData['symptoms'] ?? []);
    final List<String> treatment = List<String>.from(aiData['treatment'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: isHealthy ? Colors.green.shade50 : Colors.red.shade50,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(
              isHealthy ? Icons.check_circle : Icons.warning_rounded,
              color: isHealthy ? Colors.green : Colors.red,
              size: 40,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diseaseName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (commonName.isNotEmpty &&
                    commonName != 'Không có tên thông thường')
                  Text(
                    commonName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54),
                  ),
              ],
            ),
            subtitle: Text(
              'Độ tin cậy: ${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: confidence > 0.8 ? Colors.green.shade700 : Colors.orange,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Mô tả chi tiết',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(description, style: const TextStyle(fontSize: 15, height: 1.5)),
        const SizedBox(height: 20),
        if (symptoms.isNotEmpty) ...[
          const Text('Triệu chứng nhận biết',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...symptoms.map((symptom) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(fontSize: 18, color: Colors.orange)),
                    Expanded(
                        child: Text(symptom,
                            style: const TextStyle(fontSize: 15, height: 1.4))),
                  ],
                ),
              )),
          const SizedBox(height: 20),
        ],
        if (treatment.isNotEmpty) ...[
          const Text('Hướng dẫn xử lý',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              children: treatment
                  .map((step) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.healing,
                                size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(step,
                                    style: const TextStyle(
                                        fontSize: 15, height: 1.4))),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}
