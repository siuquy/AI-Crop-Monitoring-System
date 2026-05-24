import 'package:flutter/material.dart';
import '../../core/service/harvest_service.dart';

class HarvestDetailScreen extends StatefulWidget {
  final String harvestDetailId;

  const HarvestDetailScreen({super.key, required this.harvestDetailId});

  @override
  State<HarvestDetailScreen> createState() => _HarvestDetailScreenState();
}

class _HarvestDetailScreenState extends State<HarvestDetailScreen> {
  Map<String, dynamic>? _harvestDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHarvestDetail();
  }

  Future<void> _fetchHarvestDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data =
          await HarvestService.getHarvestDetail(widget.harvestDetailId);
      if (data != null) {
        setState(() {
          _harvestDetail = data;
        });
      } else {
        setState(() {
          _errorMessage = 'Không tìm thấy thông tin chi tiết thu hoạch.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thu hoạch'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchHarvestDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_harvestDetail == null) {
      return const Center(child: Text('Không có dữ liệu.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoRow('Cây trồng', _harvestDetail!['cropName']),
        _buildInfoRow('Khu vực',
            '${_harvestDetail!['plotName']} - ${_harvestDetail!['bedName']}'),
        _buildInfoRow('Mùa vụ', _harvestDetail!['seasonName']),
        _buildInfoRow('Số lượng', '${_harvestDetail!['cropQuantity']}'),
        _buildInfoRow('Ngày bắt đầu', _harvestDetail!['startDate']),
        _buildInfoRow('Ngày kết thúc', _harvestDetail!['endDate']),
        _buildInfoRow(
            'Trạng thái',
            _harvestDetail!['isHarvested'] == true
                ? 'Đã thu hoạch'
                : 'Chưa thu hoạch'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(
              flex: 3,
              child: Text(value ?? 'N/A',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15))),
        ],
      ),
    );
  }
}
